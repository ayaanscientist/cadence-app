import 'package:drift/drift.dart';
import 'package:cadence/core/database/app_database.dart';
import 'package:cadence/core/database/tables.dart';

part 'gamification_dao.g.dart';

@DriftAccessor(tables: [GamificationProfiles])
class GamificationDao extends DatabaseAccessor<AppDatabase> with _$GamificationDaoMixin {
  GamificationDao(super.db);

  final _profileId = 'primary_gamification_profile';

  /// Ensures the profile exists and returns it.
  Future<GamificationProfileEntry> getProfile() async {
    final query = select(gamificationProfiles)..where((p) => p.id.equals(_profileId));
    final profile = await query.getSingleOrNull();
    if (profile != null) return profile;

    final newProfile = GamificationProfilesCompanion.insert(
      id: _profileId,
    );
    await into(gamificationProfiles).insert(newProfile);
    return (await query.getSingleOrNull())!;
  }

  /// Grants XP and handles leveling up.
  Future<void> grantXp(int xpToGrant) async {
    return transaction(() async {
      final profile = await getProfile();
      final newTotalXp = profile.totalXp + xpToGrant;
      
      // Simple leveling formula: 1000 XP per level
      final newLevel = 1 + (newTotalXp ~/ 1000);

      await update(gamificationProfiles).replace(
        profile.copyWith(
          totalXp: newTotalXp,
          level: newLevel,
        ),
      );
    });
  }

  /// Attempts to consume a streak freeze token. Returns true if successful.
  Future<bool> consumeFreezeToken() async {
    return transaction(() async {
      final profile = await getProfile();
      if (profile.streakFreezeTokensLeft > 0) {
        await update(gamificationProfiles).replace(
          profile.copyWith(
            streakFreezeTokensLeft: profile.streakFreezeTokensLeft - 1,
          ),
        );
        return true;
      }
      return false;
    });
  }
}
