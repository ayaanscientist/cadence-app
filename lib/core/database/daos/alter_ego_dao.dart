import 'package:drift/drift.dart';
import 'package:cadence/core/database/app_database.dart';
import 'package:cadence/core/database/tables.dart';

part 'alter_ego_dao.g.dart';

@DriftAccessor(tables: [AlterEgoProfiles])
class AlterEgoDao extends DatabaseAccessor<AppDatabase> with _$AlterEgoDaoMixin {
  AlterEgoDao(super.db);

  /// Get the active alter ego profile
  Future<AlterEgoProfileEntry?> getActiveProfile() {
    return (select(alterEgoProfiles)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Insert a new alter ego profile, deactivating all others
  Future<void> saveProfile(AlterEgoProfilesCompanion profile) async {
    return transaction(() async {
      // Deactivate all existing profiles
      await (update(alterEgoProfiles)..where((t) => t.isActive.equals(true)))
          .write(const AlterEgoProfilesCompanion(isActive: Value(false)));

      // Insert the new one
      await into(alterEgoProfiles).insert(profile);
    });
  }

  /// Update an existing profile (e.g. editing rules/backstory)
  Future<bool> updateProfile(AlterEgoProfileEntry entry) {
    return update(alterEgoProfiles).replace(entry);
  }
}
