import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ReleaseInfo {
  final String version;
  final String? releaseNotes;
  final String? downloadUrl;

  ReleaseInfo({
    required this.version,
    this.releaseNotes,
    this.downloadUrl,
  });
}

class UpdateService {
  static const String _releasesUrl =
      'https://api.github.com/repos/GeorgeEnglezos/Scrcpy-GUI/releases';
  static const String _repoUrl = 'https://github.com/GeorgeEnglezos/Scrcpy-GUI/releases';
  static const Duration _requestTimeout = Duration(seconds: 10);

  /// Result of an update check
  final bool hasUpdate;
  final String latestVersion;
  final String currentVersion;
  final String? releaseNotes;
  final String? downloadUrl;

  /// Nightly update info
  final bool hasNightlyUpdate;
  final ReleaseInfo? nightlyInfo;
  final ReleaseInfo? stableInfo;

  UpdateService({
    required this.hasUpdate,
    required this.latestVersion,
    required this.currentVersion,
    this.releaseNotes,
    this.downloadUrl,
    this.hasNightlyUpdate = false,
    this.nightlyInfo,
    this.stableInfo,
  });

  /// Fetches releases from GitHub and compares them with the local version.
  static Future<UpdateService> checkForUpdate() async {
    // Resolve current version once, before any network work.
    String currentVersion;
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      currentVersion = packageInfo.version;
    } catch (_) {
      currentVersion = '1.0.0';
    }

    HttpClient? client;
    try {
      client = HttpClient();
      client.connectionTimeout = _requestTimeout;
      client.userAgent = 'Scrcpy-GUI-App';

      // Fetch stable releases and the fixed "nightly" release in parallel.
      final stableRequest = await client.getUrl(Uri.parse(_releasesUrl));
      final stableResponse = await stableRequest.close();

      if (stableResponse.statusCode != 200) {
        throw HttpException(
          'GitHub API returned ${stableResponse.statusCode}',
          uri: Uri.parse(_releasesUrl),
        );
      }

      final stableContent = await stableResponse
          .transform(utf8.decoder)
          .join()
          .timeout(_requestTimeout);
      final List<dynamic> releases = jsonDecode(stableContent);

      // Find the latest stable release (prerelease=false, no "nightly" tag).
      ReleaseInfo? latestStable;
      for (final data in releases) {
        final rawTag = data['tag_name'] as String?;
        if (rawTag == null) continue;
        final isPrerelease = data['prerelease'] as bool? ?? true;
        if (!isPrerelease && rawTag != 'nightly') {
          latestStable = ReleaseInfo(
            version: rawTag.startsWith('v') ? rawTag.substring(1) : rawTag,
            releaseNotes: data['body'] as String?,
            downloadUrl: data['html_url'] as String?,
          );
          break;
        }
      }

      if (latestStable == null) throw Exception('No stable releases found');

      // Fetch the dedicated "nightly" release by its fixed tag.
      final latestNightly = await _fetchNightlyRelease(client);

      final hasUpdate = isVersionGreater(latestStable.version, currentVersion);

      // Nightly must be newer than CURRENT and newer than latest STABLE to be relevant.
      var hasNightlyUpdate = false;
      if (latestNightly != null) {
        hasNightlyUpdate =
            isVersionGreater(latestNightly.version, currentVersion) &&
                isVersionGreater(latestNightly.version, latestStable.version);
      }

      return UpdateService(
        hasUpdate: hasUpdate,
        latestVersion: latestStable.version,
        currentVersion: currentVersion,
        releaseNotes: latestStable.releaseNotes,
        downloadUrl: latestStable.downloadUrl,
        hasNightlyUpdate: hasNightlyUpdate,
        nightlyInfo: latestNightly,
        stableInfo: latestStable,
      );
    } on TimeoutException catch (_) {
      // Request exceeded the timeout — silently fail.
    } on SocketException catch (_) {
      // No internet connectivity — expected, silently fail.
    } on HttpException catch (_) {
      // Non-200 or redirect — expected, silently fail.
    } on FormatException catch (e) {
      // Malformed JSON — unexpected, log in debug builds.
      debugPrint('[UpdateService] Malformed JSON response: $e');
    } catch (e) {
      // Truly unexpected error — log in debug builds.
      debugPrint('[UpdateService] Unexpected error during update check: $e');
    } finally {
      client?.close();
    }

    // Default to no update available when the check cannot complete.
    return UpdateService(
      hasUpdate: false,
      latestVersion: currentVersion,
      currentVersion: currentVersion,
    );
  }

  /// Fetches the fixed "nightly" release and parses the version from its body.
  /// The workflow writes: "Latest nightly: v`<version>`" in the release body.
  static Future<ReleaseInfo?> _fetchNightlyRelease(HttpClient client) async {
    try {
      final request = await client.getUrl(Uri.parse('$_releasesUrl/tags/nightly'));
      final response = await request.close();
      if (response.statusCode != 200) return null;

      final content = await response
          .transform(utf8.decoder)
          .join()
          .timeout(_requestTimeout);
      final data = jsonDecode(content) as Map<String, dynamic>;

      final body = data['body'] as String? ?? '';
      final match = RegExp(r'Latest nightly: v([^\s]+)').firstMatch(body);
      if (match == null) return null;

      return ReleaseInfo(
        version: match.group(1)!,
        releaseNotes: body,
        downloadUrl: data['html_url'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  /// Launches a release page in the browser. Defaults to the main releases page if no URL is provided.
  static Future<void> launchReleasePage([String? url]) async {
    final uri = Uri.parse(url ?? _repoUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Simple semantic version comparison.
  /// Returns true if [latest] is greater than [current].
  ///
  /// Pre-release suffixes are compared lexicographically. This works correctly
  /// for date-based nightly suffixes (e.g. nightly.20260301 > nightly.20260228)
  /// because the dates are zero-padded. Stable releases always sort above any
  /// pre-release of the same base version (e.g. 1.6.0 > 1.6.0-rc.1).
  static bool isVersionGreater(String latest, String current) {
    final latestParts = latest.split('-')[0].split('.');
    final currentParts = current.split('-')[0].split('.');

    for (int i = 0; i < latestParts.length && i < currentParts.length; i++) {
      final latestVal = int.tryParse(latestParts[i]) ?? 0;
      final currentVal = int.tryParse(currentParts[i]) ?? 0;

      if (latestVal > currentVal) return true;
      if (latestVal < currentVal) return false;
    }

    if (latestParts.length > currentParts.length) return true;

    // At this point the base versions are equal. Compare suffixes.
    if (latest == current) return false;

    // Stable (no suffix) beats any pre-release of the same base version.
    if (current.contains('-') && !latest.contains('-')) return true;
    if (!current.contains('-') && latest.contains('-')) return false;

    // Both have suffixes — compare lexicographically.
    if (current.contains('-') && latest.contains('-')) {
      final latestSuffix = latest.split('-')[1];
      final currentSuffix = current.split('-')[1];
      return latestSuffix.compareTo(currentSuffix) > 0;
    }

    return false;
  }
}
