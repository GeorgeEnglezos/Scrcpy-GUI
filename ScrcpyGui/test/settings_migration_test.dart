import 'package:flutter_test/flutter_test.dart';
import 'package:scrcpy_gui_prod/models/settings_model.dart';
import 'package:scrcpy_gui_prod/services/settings_service.dart';

AppSettings settingsWith(List<PanelSettings> panels) =>
    AppSettings.defaultSettings().copyWith(panelOrder: panels);

void main() {
  final service = SettingsService();

  group('migratePanels', () {
    test('removes the deprecated shortcuts panel', () {
      final input = settingsWith([
        ...buildDefaultPanels(),
        const PanelSettings(id: 'shortcuts', displayName: 'Shortcuts'),
      ]);

      final migrated = service.migratePanels(input);
      expect(
        migrated.panelOrder.map((p) => p.id),
        isNot(contains('shortcuts')),
      );
      expect(migrated.panelOrder.length, buildDefaultPanels().length);
    });

    test('appends newly-introduced default panels at the end', () {
      final defaults = buildDefaultPanels();
      final missingLast = defaults.sublist(0, defaults.length - 1);

      final migrated = service.migratePanels(settingsWith(missingLast));
      expect(migrated.panelOrder.length, defaults.length);
      expect(migrated.panelOrder.last.id, defaults.last.id);
    });

    test('returns the identical instance when nothing changes', () {
      final input = settingsWith(buildDefaultPanels());
      expect(identical(service.migratePanels(input), input), isTrue);
    });

    test('preserves the user\'s custom panel order', () {
      final reordered = buildDefaultPanels().reversed.toList();
      final migrated = service.migratePanels(settingsWith(reordered));
      expect(
        migrated.panelOrder.map((p) => p.id).toList(),
        reordered.map((p) => p.id).toList(),
      );
    });
  });
}
