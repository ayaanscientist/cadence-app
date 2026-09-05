import 'package:drift/drift.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 1. HABITS — Atomic Habit Stacking & Never-Miss-Twice Streaks
// ═══════════════════════════════════════════════════════════════════════════

/// Status states for the Never-Miss-Twice state machine.
///
/// Transition rules (evaluated daily at 23:59:59):
///   ACTIVE  → missed day 1 → AT_RISK
///   AT_RISK → completed     → ACTIVE
///   AT_RISK → missed day 2  → BROKEN (streak resets to 0)
enum HabitStatus { active, atRisk, broken }

/// Supported habit repeat frequencies.
enum HabitFrequency { daily, weekdays, weekly, custom }

@DataClassName('HabitEntry')
class Habits extends Table {
  /// UUID v4 primary key.
  TextColumn get id => text()();

  /// Human-readable habit name, e.g. "Morning Business Strategy".
  TextColumn get title => text().withLength(min: 1, max: 200)();

  /// Optional FK to another habit's [id] — enables habit stacking.
  /// When non-null, this habit is triggered *after* the referenced habit.
  TextColumn get triggerHabitId => text().nullable()();

  /// Descriptive formula: "After I complete Meditation, I will do 20m Planning".
  TextColumn get stackFormula => text().nullable()();

  /// How often this habit repeats.
  TextColumn get targetFrequency =>
      text().withDefault(const Constant('daily'))();

  /// ISO-8601 timestamp when this habit was first created.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Number of consecutive days the habit has been completed.
  IntColumn get currentStreak => integer().withDefault(const Constant(0))();

  /// Current state in the Never-Miss-Twice state machine.
  TextColumn get statusState =>
      text().withDefault(const Constant('active'))();

  /// Set to `true` if the user missed yesterday — the "one grace day" flag.
  BoolColumn get neverMissTwiceFlag =>
      boolean().withDefault(const Constant(false))();

  /// Last time this habit was marked completed (epoch ms or null).
  DateTimeColumn get lastCompletedTimestamp => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ═══════════════════════════════════════════════════════════════════════════
// 2. EXERCISE TARGETS — Dynamic Progressive Overload Engine
// ═══════════════════════════════════════════════════════════════════════════

/// Rounding strategy for the progressive overload formula.
///
/// - [ceil]:  `R_t = max(R_{t-1} + 1, ⌈R_{t-1} × (1 + r)⌉)` (default for reps)
/// - [floor]: Conservative rounding down.
/// - [accumulate]: Fractional micro-accumulator for weight/distance.
enum RoundingMode { ceil, floor, accumulate }

@DataClassName('ExerciseTargetEntry')
class ExerciseTargets extends Table {
  TextColumn get id => text()();

  TextColumn get exerciseName => text().withLength(min: 1, max: 150)();

  /// The baseline rep count when the exercise was first added.
  RealColumn get baseReps => real()();

  /// The current target rep count (float to support fractional tracking).
  RealColumn get currentReps => real()();

  /// User-configurable growth rate, default 0.01 (1%).
  /// Constrained to [0.01, 0.10] in the business logic layer.
  RealColumn get incrementRate =>
      real().withDefault(const Constant(0.01))();

  /// Rounding strategy: CEIL | FLOOR | ACCUMULATE.
  TextColumn get roundingMode =>
      text().withDefault(const Constant('ceil'))();

  /// Running accumulator for the ACCUMULATE rounding mode.
  /// Tracks sub-unit remainders across days to avoid precision loss.
  RealColumn get fractionalAccumulator =>
      real().withDefault(const Constant(0.0))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ═══════════════════════════════════════════════════════════════════════════
// 3. EXERCISE HISTORY — Per-day completion log (normalized from blueprint)
// ═══════════════════════════════════════════════════════════════════════════

@DataClassName('ExerciseHistoryEntry')
class ExerciseHistory extends Table {
  /// Auto-incrementing surrogate key.
  IntColumn get id => integer().autoIncrement()();

  /// FK → exercise_targets.id
  TextColumn get exerciseTargetId => text()();

  /// The calendar date of this entry (stored as yyyy-MM-dd text).
  TextColumn get date => text()();

  /// How many reps the user actually completed.
  IntColumn get repsCompleted => integer()();

  /// What the target was on this day (snapshot for auditability).
  IntColumn get targetWas => integer()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ═══════════════════════════════════════════════════════════════════════════
// 4. MENTAL LOGS — Meditation & Sleep (single row per day)
// ═══════════════════════════════════════════════════════════════════════════

@DataClassName('MentalLogEntry')
class MentalLogs extends Table {
  TextColumn get id => text()();

  /// Calendar date (yyyy-MM-dd).
  TextColumn get date => text().unique()();

  // ── Meditation fields ─────────────────────────────────────────────────
  /// Scheduled meditation time (HH:mm) for exact alarm scheduling.
  TextColumn get meditationScheduledTime => text().nullable()();

  /// Target duration in seconds (default 900 = 15 min).
  IntColumn get meditationDurationTargetSeconds =>
      integer().withDefault(const Constant(900))();

  /// Actual elapsed seconds (null if not yet completed).
  IntColumn get meditationDurationActualSeconds => integer().nullable()();

  BoolColumn get meditationCompleted =>
      boolean().withDefault(const Constant(false))();

  /// Audio preset key, e.g. "singing_bowl_chime".
  TextColumn get ambientPreset => text().nullable()();

  // ── Sleep fields ──────────────────────────────────────────────────────
  /// Wind-down alarm time (HH:mm) — triggers DND / screen dimming.
  TextColumn get windDownAlarm => text().nullable()();

  /// Target bedtime (HH:mm).
  TextColumn get targetBedtime => text().nullable()();

  /// Actual bedtime (HH:mm) — logged by user or inferred.
  TextColumn get actualBedtime => text().nullable()();

  /// Wake-up alarm time (HH:mm).
  TextColumn get wakeAlarm => text().nullable()();

  /// Actual wake time (HH:mm).
  TextColumn get actualWakeTime => text().nullable()();

  /// Subjective morning energy score (1–5 scale).
  IntColumn get subjectiveEnergyScore => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ═══════════════════════════════════════════════════════════════════════════
// 5. DAILY ENERGY LOGS — Nutrition summary per day
// ═══════════════════════════════════════════════════════════════════════════

@DataClassName('DailyEnergyLogEntry')
class DailyEnergyLogs extends Table {
  TextColumn get id => text()();

  /// Calendar date (yyyy-MM-dd), unique per row.
  TextColumn get date => text().unique()();

  IntColumn get calorieTarget =>
      integer().withDefault(const Constant(2400))();
  IntColumn get caloriesConsumed =>
      integer().withDefault(const Constant(0))();

  IntColumn get proteinTargetGrams =>
      integer().withDefault(const Constant(160))();
  IntColumn get proteinConsumedGrams =>
      integer().withDefault(const Constant(0))();

  IntColumn get carbsGrams => integer().withDefault(const Constant(0))();
  IntColumn get fatGrams => integer().withDefault(const Constant(0))();

  /// Total calories burned from active workouts today.
  IntColumn get activeEnergyBurned =>
      integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

// ═══════════════════════════════════════════════════════════════════════════
// 6. MEAL ENTRIES — Individual meals within a day (normalized from blueprint)
// ═══════════════════════════════════════════════════════════════════════════

@DataClassName('MealEntryRow')
class MealEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// FK → daily_energy_logs.id
  TextColumn get energyLogId => text()();

  /// Time of the meal (HH:mm).
  TextColumn get time => text()();

  /// Raw user input, e.g. "4 whole eggs, 2 slices oats bread".
  TextColumn get rawText => text()();

  /// Whether Gemini AI was used to parse macros.
  BoolColumn get parsedByGemini =>
      boolean().withDefault(const Constant(false))();

  IntColumn get calories => integer().withDefault(const Constant(0))();
  IntColumn get protein => integer().withDefault(const Constant(0))();
  IntColumn get carbs => integer().withDefault(const Constant(0))();
  IntColumn get fat => integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ═══════════════════════════════════════════════════════════════════════════
// 7. FOUNDER RECORDS — Daily founder log (One Big Thing + retro)
// ═══════════════════════════════════════════════════════════════════════════

@DataClassName('FounderRecordEntry')
class FounderRecords extends Table {
  TextColumn get id => text()();

  /// Calendar date (yyyy-MM-dd), unique per row.
  TextColumn get date => text().unique()();

  /// The single most important task for today.
  TextColumn get oneBigThing => text()();

  BoolColumn get oneBigThingCompleted =>
      boolean().withDefault(const Constant(false))();

  /// Minutes spent in deep-work focus blocks.
  IntColumn get focusDurationMinutes =>
      integer().withDefault(const Constant(0))();

  /// Evening retro: what actually moved the needle.
  TextColumn get needleMoved => text().nullable()();

  /// Evening retro: what caused friction or wasted time.
  TextColumn get frictionPoint => text().nullable()();

  /// JSON-encoded list of up to 3 priorities for tomorrow.
  TextColumn get tomorrowTopThree => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ═══════════════════════════════════════════════════════════════════════════
// 8. BUSINESS CANVASES — Lean startup idea validation
// ═══════════════════════════════════════════════════════════════════════════

/// Validation lifecycle for a business idea.
enum CanvasStatus { brainstorming, validating, building, launched, archived }

@DataClassName('BusinessCanvasEntry')
class BusinessCanvases extends Table {
  TextColumn get id => text()();

  TextColumn get ideaTitle => text().withLength(min: 1, max: 200)();
  TextColumn get problem => text()();
  TextColumn get targetCustomer => text()();
  TextColumn get solution => text()();
  TextColumn get monetization => text().nullable()();

  /// Subjective validation score (0.0 – 10.0).
  RealColumn get validationScore =>
      real().withDefault(const Constant(0.0))();

  TextColumn get status =>
      text().withDefault(const Constant('brainstorming'))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ═══════════════════════════════════════════════════════════════════════════
// 9. BOOK NOTES — Reading journal with home screen widget flag
// ═══════════════════════════════════════════════════════════════════════════

@DataClassName('BookNoteEntry')
class BookNotes extends Table {
  TextColumn get id => text()();

  TextColumn get bookTitle => text().withLength(min: 1, max: 200)();
  TextColumn get author => text().withLength(min: 1, max: 150)();
  TextColumn get coreQuote => text()();
  TextColumn get actionableTakeaway => text()();

  /// When true, this note surfaces in the home screen widget rotation.
  BoolColumn get showInWidget =>
      boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ═══════════════════════════════════════════════════════════════════════════
// 10. BAD HABITS — Inverted Atomic Habits & Clean Streaks
// ═══════════════════════════════════════════════════════════════════════════

@DataClassName('BadHabitEntry')
class BadHabits extends Table {
  TextColumn get id => text()();

  /// E.g. "Vaping / Nicotine", "Mindless Doomscrolling", "Alcohol", "Junk Food".
  TextColumn get title => text().withLength(min: 1, max: 200)();

  /// Estimated financial cost incurred per day by this habit.
  RealColumn get costPerDay => real().withDefault(const Constant(0.0))();

  /// Currency code (USD, EUR, GBP, INR, etc.).
  TextColumn get currency => text().withDefault(const Constant('USD'))();

  /// The timestamp when the clean streak officially started.
  DateTimeColumn get quitDate => dateTime()();

  /// Cached clean days streak (recalculated against current date).
  IntColumn get cleanStreakDays => integer().withDefault(const Constant(0))();

  /// Count of cravings resisted via SOS Delay Timer.
  IntColumn get cravingsResisted => integer().withDefault(const Constant(0))();

  /// Active status flag.
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ═══════════════════════════════════════════════════════════════════════════
// 11. BAD HABIT RELAPSES — Relapse Auditing & Trigger Analysis
// ═══════════════════════════════════════════════════════════════════════════

@DataClassName('BadHabitRelapseEntry')
class BadHabitRelapses extends Table {
  TextColumn get id => text()();

  /// Foreign key referencing the parent [BadHabits] entry.
  TextColumn get badHabitId => text()();

  /// Exact timestamp when the relapse occurred.
  DateTimeColumn get relapseTimestamp => dateTime()();

  /// Number of clean days maintained prior to this relapse event.
  IntColumn get cleanDaysPrior => integer()();

  /// Trigger category (e.g., "Work Stress", "Social Setting", "Fatigue", "Boredom").
  TextColumn get trigger => text()();

  /// Contextual reflection on what broke the boundary.
  TextColumn get notes => text().nullable()();

  /// Financial setback associated with the relapse event.
  RealColumn get moneyLost => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ═══════════════════════════════════════════════════════════════════════════
// 12. APP SETTINGS — Dynamic Key-Value System Configuration
// ═══════════════════════════════════════════════════════════════════════════

@DataClassName('AppSettingEntry')
class AppSettings extends Table {
  /// Unique setting identifier key, e.g. "overload_increment_rate", "custom_alarm_sound".
  TextColumn get key => text().withLength(min: 1, max: 100)();

  /// Serialized value (String, JSON, double, or bool encoded).
  TextColumn get value => text()();

  /// Last modification timestamp.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {key};
}

// ═══════════════════════════════════════════════════════════════════════════
// 13. USER BIOMETRICS — Metabolic Baseline & Energy Targets
// ═══════════════════════════════════════════════════════════════════════════

@DataClassName('UserBiometricEntry')
class UserBiometrics extends Table {
  /// Primary profile identifier (e.g. 'primary_user').
  TextColumn get id => text()();

  IntColumn get age => integer()();

  /// Biological sex for Mifflin-St Jeor formula ('male' | 'female').
  TextColumn get gender => text().withDefault(const Constant('male'))();

  RealColumn get heightCm => real()();

  RealColumn get weightKg => real()();

  RealColumn get targetWeightKg => real()();

  /// Baseline daily sleep need in hours (default 8.0).
  RealColumn get baselineSleepNeedHours =>
      real().withDefault(const Constant(8.0))();

  /// Activity factor: sedentary (1.2), light (1.375), moderate (1.55), active (1.725), veryActive (1.9).
  TextColumn get activityLevel =>
      text().withDefault(const Constant('moderate'))();

  /// Fitness target: 'fatLoss' | 'maintenance' | 'muscleGain'.
  TextColumn get goal =>
      text().withDefault(const Constant('maintenance'))();

  /// Basal Metabolic Rate (kcal).
  RealColumn get calculatedBmr => real().withDefault(const Constant(0.0))();

  /// Total Daily Energy Expenditure (kcal).
  RealColumn get calculatedTdee => real().withDefault(const Constant(0.0))();

  /// Adjusted daily calorie intake goal.
  IntColumn get targetCalories => integer().withDefault(const Constant(2000))();

  /// Protein target in grams (1.8g per kg bodyweight).
  IntColumn get targetProteinGrams =>
      integer().withDefault(const Constant(140))();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ═══════════════════════════════════════════════════════════════════════════
// 14. DAILY BIOMETRIC LOGS — Daily Weight, Sleep Debt, & Energy Score
// ═══════════════════════════════════════════════════════════════════════════

@DataClassName('DailyBiometricLogEntry')
class DailyBiometricLogs extends Table {
  TextColumn get id => text()();

  /// Date string (yyyy-MM-dd) — unique constraint per day.
  TextColumn get date => text()();

  /// Morning weigh-in (nullable if skipped).
  RealColumn get weightKg => real().nullable()();

  /// Actual hours of sleep logged.
  RealColumn get actualSleepHours => real().withDefault(const Constant(0.0))();

  /// Target baseline sleep hours for this day.
  RealColumn get targetSleepHours => real().withDefault(const Constant(8.0))();

  /// Single day sleep debt (target - actual).
  RealColumn get sleepDebtHours => real().withDefault(const Constant(0.0))();

  /// Rolling 7-day cumulative sleep debt.
  RealColumn get rollingSleepDebtHours =>
      real().withDefault(const Constant(0.0))();

  /// Subjective morning energy score (1 to 10 scale).
  IntColumn get energyScore => integer().withDefault(const Constant(7))();

  TextColumn get notes => text().nullable()();

  DateTimeColumn get loggedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ═══════════════════════════════════════════════════════════════════════════
// 15. ALTER EGO PROFILES — Secondary Persona Definition
// ═══════════════════════════════════════════════════════════════════════════

@DataClassName('AlterEgoProfileEntry')
class AlterEgoProfiles extends Table {
  TextColumn get id => text()();

  /// E.g. "Arvane Mirza"
  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// E.g. "The Machine", "The Sovereign"
  TextColumn get archetype => text().withLength(min: 1, max: 100)();

  /// AI Generated backstory
  TextColumn get backstory => text()();

  /// JSON-encoded list of strings representing the 5 Iron Rules.
  TextColumn get ironRules => text()();

  /// Physical totem anchor, e.g. "Matte black ring"
  TextColumn get totem => text().nullable()();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ═══════════════════════════════════════════════════════════════════════════
// 16. EXERCISES — Static definitions for the workout engine
// ═══════════════════════════════════════════════════════════════════════════

@DataClassName('ExerciseEntry')
class Exercises extends Table {
  TextColumn get id => text()();
  
  TextColumn get name => text().withLength(min: 1, max: 150)();
  
  TextColumn get targetMuscleGroup => text()();
  
  IntColumn get defaultReps => integer().withDefault(const Constant(10))();
  
  IntColumn get defaultDurationSec => integer().withDefault(const Constant(0))();
  
  /// Metabolic Equivalent of Task
  RealColumn get metValue => real().withDefault(const Constant(3.0))();
  
  TextColumn get iconPath => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ═══════════════════════════════════════════════════════════════════════════
// 17. WORKOUT SESSIONS — Single continuous workout logs
// ═══════════════════════════════════════════════════════════════════════════

@DataClassName('WorkoutSessionEntry')
class WorkoutSessions extends Table {
  TextColumn get id => text()();
  
  DateTimeColumn get startTimestamp => dateTime()();
  
  DateTimeColumn get endTimestamp => dateTime().nullable()();
  
  IntColumn get totalEnergyBurnedKcal => integer().withDefault(const Constant(0))();
  
  /// IN_PROGRESS or COMPLETED
  TextColumn get status => text().withDefault(const Constant('IN_PROGRESS'))();

  @override
  Set<Column> get primaryKey => {id};
}

// ═══════════════════════════════════════════════════════════════════════════
// 18. COMPLETED EXERCISE LOGS — Normalized ledger of exercises done
// ═══════════════════════════════════════════════════════════════════════════

@DataClassName('CompletedExerciseLogEntry')
class CompletedExerciseLogs extends Table {
  TextColumn get id => text()();
  
  TextColumn get sessionId => text()();
  
  TextColumn get exerciseId => text()();
  
  IntColumn get repsDone => integer().withDefault(const Constant(0))();
  
  IntColumn get durationSec => integer().withDefault(const Constant(0))();
  
  IntColumn get caloriesBurnedKcal => integer().withDefault(const Constant(0))();
  
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ═══════════════════════════════════════════════════════════════════════════
// 19. EXERCISE STATS — Aggregated frequency tracking
// ═══════════════════════════════════════════════════════════════════════════

@DataClassName('ExerciseStatEntry')
class ExerciseStats extends Table {
  TextColumn get exerciseId => text()();
  
  IntColumn get lifetimeCompletionsCount => integer().withDefault(const Constant(0))();
  
  IntColumn get allTimeRepsCount => integer().withDefault(const Constant(0))();
  
  IntColumn get allTimeEnergyBurned => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {exerciseId};
}

// ═══════════════════════════════════════════════════════════════════════════
// 20. GAMIFICATION PROFILES — XP, Leveling, and Streak Freeze Engine
// ═══════════════════════════════════════════════════════════════════════════

@DataClassName('GamificationProfileEntry')
class GamificationProfiles extends Table {
  TextColumn get id => text()();
  
  IntColumn get level => integer().withDefault(const Constant(1))();
  
  IntColumn get totalXp => integer().withDefault(const Constant(0))();
  
  IntColumn get streakFreezeTokensLeft => integer().withDefault(const Constant(2))();

  @override
  Set<Column> get primaryKey => {id};
}

