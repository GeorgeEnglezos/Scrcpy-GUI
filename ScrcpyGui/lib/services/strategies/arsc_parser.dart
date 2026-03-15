/// Minimal Android resources.arsc + binary AndroidManifest.xml parser.
///
/// Resolves the app icon path from an APK without requiring aapt2 or apktool.
///
/// Approach:
///   1. Parse binary AndroidManifest.xml to extract the android:icon resource ID.
///   2. Parse resources.arsc to resolve that resource ID to a file path string
///      (e.g. "res/Ab.png"), picking the highest-density configuration available.
library;

import 'dart:typed_data';

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/// Returns the icon file path(s) inside the APK for the given [arscBytes] and
/// [manifestBytes], ordered best-density-first.
///
/// Returns an empty list if parsing fails or no icon is found.
/// If [outResId] is provided, it will be set to the raw android:icon resource
/// ID found in the manifest (useful for debugging when resolution fails).
List<String> resolveIconPaths({
  required Uint8List arscBytes,
  required Uint8List manifestBytes,
  List<int?>? outResId,
}) {
  try {
    final iconResId = _parseManifestIconResId(manifestBytes);
    if (outResId != null) outResId.add(iconResId);
    if (iconResId == null) return [];
    return _resolveResId(arscBytes, iconResId);
  } catch (_) {
    return [];
  }
}

/// Resolves a resource ID directly against the given [arscBytes].
///
/// Useful for resolving a known res ID against a split APK's resources.arsc.
/// Returns an empty list if parsing fails or the ID is not found.
List<String> resolveResIdFromArsc({
  required Uint8List arscBytes,
  required int resId,
}) {
  try {
    return _resolveResId(arscBytes, resId);
  } catch (_) {
    return [];
  }
}

// ---------------------------------------------------------------------------
// Binary AndroidManifest.xml parser — extract android:icon resource ID
// ---------------------------------------------------------------------------

/// Chunk types used in binary XML.
const int _xmlChunkType = 0x0003;
const int _stringPoolType = 0x0001;
const int _xmlStartElement = 0x0102;
const String _attrNamespaceAndroid =
    'http://schemas.android.com/apk/res/android';

/// Parses binary AndroidManifest.xml and returns the android:icon resource ID,
/// or null if not found.
int? _parseManifestIconResId(Uint8List bytes) {
  final bd = ByteData.sublistView(bytes);
  int pos = 0;

  // File header: must be XML chunk (0x0003)
  if (bd.getUint16(0, Endian.little) != _xmlChunkType) return null;
  final fileSize = bd.getUint32(4, Endian.little);
  pos = bd.getUint16(2, Endian.little); // skip file header

  // String pool — we need it to find attribute names
  if (bd.getUint16(pos, Endian.little) != _stringPoolType) return null;
  final pool = _StringPool.parse(bd, pos);
  pos += bd.getUint32(pos + 4, Endian.little);

  // Walk remaining chunks looking for START_ELEMENT "application"
  while (pos < fileSize) {
    final chunkType = bd.getUint16(pos, Endian.little);
    final chunkSize = bd.getUint32(pos + 4, Endian.little);
    if (chunkSize == 0) break;

    if (chunkType == _xmlStartElement) {
      // ResXMLTree_attrExt starts after 16-byte ResXMLTree_node header
      final extOffset = pos + 16;
      final nameIdx = bd.getInt32(extOffset + 4, Endian.little);
      final elementName = pool.getString(nameIdx);

      if (elementName == 'application') {
        final attrCount = bd.getUint16(extOffset + 12, Endian.little);
        final attrStart = extOffset + 20; // 20-byte attrExt header
        const attrSize = 20;

        for (var i = 0; i < attrCount; i++) {
          final aOff = attrStart + i * attrSize;
          final attrNsIdx = bd.getInt32(aOff, Endian.little);
          final attrNameIdx = bd.getInt32(aOff + 4, Endian.little);
          final attrName = pool.getString(attrNameIdx);
          final attrNs = attrNsIdx >= 0 ? pool.getString(attrNsIdx) : '';

          if (attrName == 'icon' && attrNs == _attrNamespaceAndroid) {
            // typedValue: size(2) + res0(1) + dataType(1) + data(4)
            final dataType = bd.getUint8(aOff + 15);
            final data = bd.getUint32(aOff + 16, Endian.little);
            if (dataType == 0x01 /* TYPE_REFERENCE */) return data;
          }
        }
      }
    }

    pos += chunkSize;
  }
  return null;
}

// ---------------------------------------------------------------------------
// resources.arsc parser — resolve resource ID to file path(s)
// ---------------------------------------------------------------------------

const int _tableChunkType = 0x0002;
const int _packageChunkType = 0x0200;
// const int _typeSpecChunkType = 0x0202; // reserved for future use
const int _typeChunkType = 0x0201;
const int _noEntry = 0xFFFFFFFF;

/// Resolves [resId] against [arscBytes], returning candidate file paths
/// ordered by density (highest first).
List<String> _resolveResId(Uint8List arscBytes, int resId, [Set<int>? visited]) {
  if (visited != null && !visited.add(resId)) return []; // cycle guard
  final bd = ByteData.sublistView(arscBytes);

  // File header
  if (bd.getUint16(0, Endian.little) != _tableChunkType) return [];
  final fileHeaderSize = bd.getUint16(2, Endian.little);

  // Global string pool immediately follows header
  final globalPool = _StringPool.parse(bd, fileHeaderSize);
  final globalPoolSize = bd.getUint32(fileHeaderSize + 4, Endian.little);

  final targetPkgId = (resId >> 24) & 0xFF;
  final targetTypeId = (resId >> 16) & 0xFF; // 1-based
  final targetEntryIdx = resId & 0xFFFF;

  int pos = fileHeaderSize + globalPoolSize;
  final fileSize = bd.getUint32(4, Endian.little);

  while (pos < fileSize) {
    final chunkType = bd.getUint16(pos, Endian.little);
    final chunkSize = bd.getUint32(pos + 4, Endian.little);
    if (chunkSize == 0) break;

    if (chunkType == _packageChunkType) {
      final pkgId = bd.getUint32(pos + 8, Endian.little);
      if (pkgId == targetPkgId) {
        final result = _resolveInPackage(
          arscBytes, bd, pos, chunkSize, globalPool,
          targetTypeId, targetEntryIdx, visited ?? {resId},
        );
        if (result.isNotEmpty) return result;
      }
    }

    pos += chunkSize;
  }
  return [];
}

List<String> _resolveInPackage(
  Uint8List arscBytes,
  ByteData bd,
  int pkgStart,
  int pkgSize,
  _StringPool globalPool,
  int targetTypeId, // 1-based
  int targetEntryIdx,
  Set<int> visited,
) {
  final pkgHeaderSize = bd.getUint16(pkgStart + 2, Endian.little);

  // ResTable_package layout after ResChunk_header(8):
  //   id(4), name(char16[128]=256), typeStrings(4), lastPublicType(4),
  //   keyStrings(4), lastPublicKey(4), typeIdOffset(4)
  // typeStrings field is at offset 8 + 4 + 256 = 268 from package start.
  final typeStringsOffset = bd.getUint32(pkgStart + 268, Endian.little);
  final typePool = _StringPool.parse(bd, pkgStart + typeStringsOffset);

  // typeIdOffset: some packages shift type IDs (type chunk id - typeIdOffset = 0-based type index).
  // When non-zero, the type chunk's id field is (typeIdOffset + 1-based-index).
  // We adjust targetTypeId by subtracting typeIdOffset before comparing.
  final typeIdOffset = bd.getUint32(pkgStart + 280, Endian.little);
  final adjustedTargetTypeId = targetTypeId - typeIdOffset;

  // Collect all matching paths with their config density
  final candidates = <_IconCandidate>[];

  int pos = pkgStart + pkgHeaderSize;
  final pkgEnd = pkgStart + pkgSize;

  while (pos < pkgEnd) {
    if (pos + 8 > pkgEnd) break;
    final chunkType = bd.getUint16(pos, Endian.little);
    final chunkSize = bd.getUint32(pos + 4, Endian.little);
    if (chunkSize == 0) break;

    if (chunkType == _typeChunkType) {
      final typeId = bd.getUint8(pos + 8); // 1-based within this package
      if (typeId == adjustedTargetTypeId) {
        _extractFromTypeChunk(
          arscBytes, bd, pos, chunkSize, globalPool, typePool,
          targetEntryIdx, candidates, visited,
        );
      }
    }

    pos += chunkSize;
  }

  if (candidates.isEmpty) return [];

  // Filter out XML paths (adaptive icon descriptors, not raster images) and
  // ANYDPI sentinel (0xFFFE = 65534) which sorts numerically above real densities
  // but cannot be rendered directly as a bitmap.
  final rasterCandidates = candidates
      .where((c) => !c.path.endsWith('.xml') && c.density < 0xFFFE)
      .toList();

  // If filtering removed everything (e.g. app only ships adaptive icons), fall
  // back to the full list so callers can at least attempt extraction.
  final sorted = rasterCandidates.isNotEmpty ? rasterCandidates : candidates;

  // Sort: highest density first (density=0 means "any", treat as medium)
  sorted.sort((a, b) {
    final da = a.density == 0 ? 160 : a.density;
    final db = b.density == 0 ? 160 : b.density;
    return db.compareTo(da); // descending
  });

  return sorted.map((c) => c.path).toList();
}

void _extractFromTypeChunk(
  Uint8List arscBytes,
  ByteData bd,
  int chunkStart,
  int chunkSize,
  _StringPool globalPool,
  _StringPool typePool,
  int targetEntryIdx,
  List<_IconCandidate> out,
  Set<int> visited,
) {
  // ResTable_type header
  final headerSize = bd.getUint16(chunkStart + 2, Endian.little);
  final entryCount = bd.getUint32(chunkStart + 12, Endian.little);
  final entriesStart = bd.getUint32(chunkStart + 16, Endian.little);

  if (targetEntryIdx >= entryCount) return;

  // ResTable_config starts at chunkStart+20 (after typeId,res0,res1,entryCount,entriesStart).
  // Layout: size(4), mcc(2), mnc(2), language(2), country(2),
  //         orientation(1), touchscreen(1), density(2), ...
  // → density is at config offset 12.
  final configOffset = chunkStart + 20;
  final density = bd.getUint16(configOffset + 12, Endian.little);

  // Offset table: headerSize bytes into chunk
  final offsetTableStart = chunkStart + headerSize;
  final entryOffset = bd.getUint32(
    offsetTableStart + targetEntryIdx * 4, Endian.little,
  );
  if (entryOffset == _noEntry) return;

  final entryStart = chunkStart + entriesStart + entryOffset;

  // ResTable_entry: size(2), flags(2), key(4)
  final entryFlags = bd.getUint16(entryStart + 2, Endian.little);
  final isComplex = (entryFlags & 0x0001) != 0;
  if (isComplex) return; // complex (style) entries don't have a simple value

  // Res_value immediately follows simple entry: size(2),res0(1),dataType(1),data(4)
  final valueOffset = entryStart + 8;
  final dataType = bd.getUint8(valueOffset + 3);
  final data = bd.getUint32(valueOffset + 4, Endian.little);

  if (dataType == 0x03 /* TYPE_STRING */) {
    // data is a global string pool index → file path
    final path = globalPool.getString(data);
    if (path.isNotEmpty) {
      out.add(_IconCandidate(path, density));
    }
  } else if (dataType == 0x01 /* TYPE_REFERENCE */) {
    // Resolve the referenced resource ID recursively (cycle-safe via visited)
    final resolved = _resolveResId(arscBytes, data, visited);
    for (final path in resolved) {
      out.add(_IconCandidate(path, density));
    }
  }
}

class _IconCandidate {
  final String path;
  final int density;
  _IconCandidate(this.path, this.density);
}

// ---------------------------------------------------------------------------
// String pool reader
// ---------------------------------------------------------------------------

class _StringPool {
  final List<String> _strings;
  _StringPool(this._strings);

  String getString(int idx) {
    if (idx < 0 || idx >= _strings.length) return '';
    return _strings[idx];
  }

  static _StringPool parse(ByteData bd, int start) {
    // Chunk header: type(2), headerSize(2), size(4)
    final headerSize = bd.getUint16(start + 2, Endian.little);
    final stringCount = bd.getUint32(start + 8, Endian.little);
    final flags = bd.getUint32(start + 16, Endian.little);
    final stringsStart = bd.getUint32(start + 20, Endian.little);
    final isUtf8 = (flags & 0x0100) != 0;

    final strings = <String>[];
    final offsetsBase = start + headerSize;

    for (var i = 0; i < stringCount; i++) {
      final strOffset = bd.getUint32(offsetsBase + i * 4, Endian.little);
      final absOffset = start + stringsStart + strOffset;
      try {
        strings.add(isUtf8
            ? _readUtf8String(bd, absOffset)
            : _readUtf16String(bd, absOffset));
      } catch (_) {
        strings.add('');
      }
    }
    return _StringPool(strings);
  }

  static String _readUtf16String(ByteData bd, int offset) {
    // uint16 charCount, then chars, then null terminator
    int len = bd.getUint16(offset, Endian.little);
    if (len == 0) return '';
    // Handle multi-word length (high bit set)
    int pos = offset + 2;
    if ((len & 0x8000) != 0) {
      len = ((len & 0x7FFF) << 16) | bd.getUint16(pos, Endian.little);
      pos += 2;
    }
    final chars = <int>[];
    for (var i = 0; i < len; i++) {
      chars.add(bd.getUint16(pos + i * 2, Endian.little));
    }
    return String.fromCharCodes(chars);
  }

  static String _readUtf8String(ByteData bd, int offset) {
    // uint8 charLen (UTF-16 char count), then uint8 byteLen, then bytes
    int pos = offset;
    int charLen = bd.getUint8(pos++);
    if ((charLen & 0x80) != 0) {
      charLen = ((charLen & 0x7F) << 8) | bd.getUint8(pos++);
    }
    int byteLen = bd.getUint8(pos++);
    if ((byteLen & 0x80) != 0) {
      byteLen = ((byteLen & 0x7F) << 8) | bd.getUint8(pos++);
    }
    if (byteLen == 0) return '';
    final bytes = Uint8List(byteLen);
    for (var i = 0; i < byteLen; i++) {
      bytes[i] = bd.getUint8(pos + i);
    }
    return String.fromCharCodes(bytes);
  }
}
