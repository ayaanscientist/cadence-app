import 'package:drift/drift.dart';

import 'package:cadence/core/database/app_database.dart';
import 'package:cadence/core/database/tables.dart';

part 'settings_dao.g.dart';

/// Data Access Object for dynamic key-value system configuration.
@DriftAccessor(tables: [AppSettings])
class SettingsDao extends DatabaseAccessor<AppDatabase> with _$SettingsDaoMixin {
  SettingsDao(super.db);

  /// Fetch setting value by key.
  Future<String?> getSetting(String key) async {
    final entry = await (select(appSettings)..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return entry?.value;
  }

  /// Watch a specific setting reactively.
  Stream<String?> watchSetting(String key) {
    return (select(appSettings)..where((t) => t.key.equals(key)))
        .watchSingleOrNull()
        .map((entry) => entry?.value);
  }

  /// Upserts a key-value setting.
  Future<void> setSetting(String key, String value) async {
    await into(appSettings).insertOnConflictUpdate(
      AppSettingsCompanion.insert(
        key: key,
        value: value,
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Fetch all system settings as a key-value map.
  Future<Map<String, String>> getAllSettings() async {
    final rows = await select(appSettings).get();
    return {for (var row in rows) row.key: row.value};
  }

  /// Remove a setting by key.
  Future<int> deleteSetting(String key) {
    return (delete(appSettings)..where((t) => t.key.equals(key))).go();
  }
}
