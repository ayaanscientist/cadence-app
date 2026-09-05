Master Technical Blueprint: Project AtomicOS1. System Architecture & Tech Stack                                  [ AtomicOS UI Layer ]
                                             │
      ┌───────────────────┬──────────────────┼───────────────────┬──────────────────┐
      ▼                   ▼                  ▼                   ▼                  ▼
[ Dashboard ]    [ Physical Engine ]  [ Mental Engine ]  [ Founder Hub ]    [ Gemini Core ]
      │                   │                  │                   │                  │
      └───────────────────┴──────────────────┼───────────────────┴──────────────────┘
                                             ▼
                                  [ Core State Managers ]
                                             │
                       ┌─────────────────────┴─────────────────────┐
                       ▼                                           ▼
             [ Local Database Engine ]                   [ Background Services ]
             - SQLite / Room / WatermelonDB             - AlarmManager (Exact Alarms)
             - Encrypted KeyStore (API Keys)            - Foreground Audio (Meditation)
             - Health Connect / Pedometer               - NotificationScheduler
                       │
                       ▼
             [ Remote Sync / Backup ]
             - Firebase Auth & Cloud Firestore (Optional / Secondary)
Recommended Technology StackFramework: Flutter (Dart) or React Native (TypeScript). Flutter is optimal for low-latency audio timers, complex custom canvas rendering (progress rings, heat maps), and background alarms.Local Storage & Database: SQLite via Drift (Flutter) or WatermelonDB/SQLite (React Native) for zero-latency local-first operation.Secure Storage: flutter_secure_storage or react-native-keychain for the Gemini API key.Native Android Services: Android AlarmManager with USE_EXACT_ALARM / SCHEDULE_EXACT_ALARM, Android Health Connect API for passive step logging.AI Integration: Google Gen AI SDK (google-generative-ai) communicating with gemini-1.5-flash for low-latency tools and gemini-1.5-pro for deep daily synthesis.2. Directory & File StructurePlaintextatomicos/
├── android/                        # Android native configurations & manifests
├── assets/
│   ├── audio/                      # Chimes, singing bowls, white noise
│   └── fonts/                      # Typography
├── lib/ (or src/)
│   ├── core/
│   │   ├── constants/              # Theme, colors, strings
│   │   ├── database/               # SQLite schema, migrations, DAOs
│   │   ├── services/
│   │   │   ├── alarm_service.dart  # Exact alarm scheduling & notifications
│   │   │   ├── health_service.dart # Health Connect step counter
│   │   │   └── secure_store.dart   # API key encryption
│   │   └── utils/                  # Math formulas, date parsers
│   ├── features/
│   │   ├── ai_assistant/
│   │   │   ├── data/gemini_repository.dart
│   │   │   ├── models/chat_message.dart
│   │   │   ├── prompts/system_prompts.dart
│   │   │   └── presentation/screens/ai_chat_screen.dart
│   │   ├── dashboard/
│   │   │   └── presentation/screens/dashboard_screen.dart
│   │   ├── founder_hub/
│   │   │   ├── models/business_canvas.dart
│   │   │   ├── models/journal_entry.dart
│   │   │   ├── models/book_note.dart
│   │   │   └── presentation/
│   │   ├── habits/
│   │   │   ├── models/habit.dart
│   │   │   ├── logic/streak_calculator.dart
│   │   │   └── presentation/
│   │   ├── mental/
│   │   │   ├── models/meditation_log.dart
│   │   │   ├── models/sleep_log.dart
│   │   │   ├── services/timer_service.dart
│   │   │   └── presentation/
│   │   └── physical/
│   │       ├── models/exercise_target.dart
│   │       ├── models/nutrition_log.dart
│   │       ├── logic/overload_engine.dart
│   │       └── presentation/
│   └── main.dart                   # App entrypoint & provider setup
└── pubspec.yaml (or package.json)
3. Database Schema & Data Models3.1. Habits & Habit Stacking (habits)JSON{
  "id": "uuid_v4",
  "title": "Morning Business Strategy",
  "trigger_habit_id": "uuid_meditation", 
  "stack_formula": "After I complete Meditation, I will do 20m Business Planning",
  "target_frequency": "daily",
  "created_at": 1720000000,
  "current_streak": 14,
  "status_state": "ACTIVE", // Options: ACTIVE, AT_RISK, BROKEN
  "never_miss_twice_flag": false, // true if missed yesterday
  "last_completed_timestamp": 1720086400
}
3.2. Dynamic Progressive Overload (exercise_targets)JSON{
  "id": "pushups_core",
  "exercise_name": "Pushups",
  "base_reps": 10.0,
  "current_reps": 12.0,
  "increment_rate": 0.01, // 1% default (user configurable: 0.01 - 0.10)
  "rounding_mode": "CEIL", // Options: CEIL, FLOOR, ACCUMULATE
  "fractional_accumulator": 0.12, // Keeps track of unrounded decimals
  "history": [
    { "date": "2026-09-01", "reps_completed": 10, "target_was": 10 },
    { "date": "2026-09-02", "reps_completed": 11, "target_was": 11 },
    { "date": "2026-09-03", "reps_completed": 12, "target_was": 12 }
  ]
}
3.3. Nutrition & Energy (daily_energy_logs)JSON{
  "date": "2026-09-05",
  "calorie_target": 2400,
  "calories_consumed": 1850,
  "protein_target_grams": 160,
  "protein_consumed_grams": 125,
  "carbs_grams": 190,
  "fat_grams": 60,
  "meals": [
    {
      "time": "08:30",
      "raw_text": "4 whole eggs, 2 slices oats bread",
      "parsed_by_gemini": true,
      "calories": 420,
      "protein": 32
    }
  ]
}
3.4. Mental: Meditation & Sleep Logs (mental_logs)JSON{
  "date": "2026-09-05",
  "meditation": {
    "scheduled_time": "06:30",
    "duration_target_seconds": 900,
    "duration_actual_seconds": 920,
    "completed": true,
    "ambient_preset": "singing_bowl_chime"
  },
  "sleep": {
    "wind_down_alarm": "22:15",
    "target_bedtime": "23:00",
    "actual_bedtime": "23:15",
    "wake_alarm": "06:00",
    "actual_wake_time": "06:05",
    "subjective_energy_score": 4 // 1 to 5 scale
  }
}
3.5. Founder Hub (founder_records)JSON{
  "business_canvas": [
    {
      "id": "canvas_01",
      "idea_title": "Local Service Aggregator",
      "problem": "Unorganized local laundry delivery",
      "target_customer": "College students and working professionals",
      "solution": "1-tap subscription pickup",
      "monetization": "Commission + monthly recurring plan",
      "validation_score": 7.5,
      "status": "VALIDATING"
    }
  ],
  "daily_founder_log": [
    {
      "date": "2026-09-05",
      "one_big_thing": "Finalize MVP wireframes and pricing model",
      "one_big_thing_completed": true,
      "focus_duration_minutes": 110,
      "needle_moved": "Completed complete user onboarding flow",
      "friction_point": "Lost 45 mins scrolling YouTube before lunch",
      "tomorrow_top_3": [
        "Deploy landing page on Vercel",
        "Cold message 10 initial users",
        "Set up Stripe test payments"
      ]
    }
  ],
  "book_notes": [
    {
      "book_title": "Atomic Habits",
      "author": "James Clear",
      "core_quote": "You do not rise to the level of your goals. You fall to the level of your systems.",
      "actionable_takeaway": "Make habits obvious, attractive, easy, and satisfying.",
      "show_in_widget": true
    }
  ]
}
4. Core Algorithmic Engines4.1. The 1% Dynamic Progressive Overload FormulaTo calculate progressive adaptation without messy infinite floating numbers:Let $R_{t}$ be the target reps for day $t$, $R_{t-1}$ be completed reps on day $t-1$, and $r$ be the user-defined percentage growth (default $r = 0.01$).Discrete Ceiling Mode (Default for Repetitions):$$R_{t} = \max(R_{t-1} + 1, \lceil R_{t-1} \times (1 + r) \rceil)$$Example: If user completed $10$ pushups, $10 \times 1.01 = 10.1 \rightarrow$ ceiling yields $11$ reps next day.Continuous Micro-Accumulator Mode (For distance/weights):$$A_{t} = A_{t-1} + (R_{t-1} \times r)$$$$\text{Target Weight} = W_{\text{base}} + \lfloor A_{t} / \text{StepSize} \rfloor \times \text{StepSize}$$4.2. The "Never Miss Twice" State MachineEvery habit transitions through states based on a daily 23:59:59 evaluation daemon:[ State: ACTIVE ]
       │
       ▼ (Day 1 Missed)
[ State: AT_RISK ] ───► Trigger Amber Warning & Morning Priority Notification
       │
       ├───► (Day 2 Completed) ───► Return to [ State: ACTIVE ]
       │
       ▼ (Day 2 Missed)
[ State: BROKEN ]  ───► Trigger Red System Notification & Reset Current Streak to 0
5. Gemini API Integration Architecture5.1. Integration SpecsAuthentication: Store key in hardware-backed Android KeyStore.SDK: Native REST endpoints or official Google Gen AI Client SDK.Endpoints:Fast utilities (nutrition parsing, one-tap idea feedback): gemini-1.5-flashSynthesis & Strategy (Evening Founder's review, Canvas critique): gemini-1.5-pro5.2. System Prompts & Structured OutputsA. Semantic Meal & Calorie ParserTypeScriptconst NUTRITION_SYSTEM_PROMPT = `
You are an expert sports nutritionist and deterministic data parser.
Parse the user's plain-text food description into structured nutrition metrics.
Respond ONLY with valid JSON conforming to this schema:
{
  "calories": number,
  "protein_grams": number,
  "carbs_grams": number,
  "fat_grams": number,
  "confidence_score": number, // 0.0 to 1.0
  "short_summary": string
}
Never include Markdown code fences or extra conversational text.
`;
B. Evening Executive Synthesis CoachTypeScriptconst FOUNDER_REVIEW_PROMPT = `
You are an elite high-performance coach and startup mentor operating on principles from 'Atomic Habits' and 'High Output Management'.
Analyze the user's daily data:
- Habits Completed vs Missed
- Exercise progression (Pushup target vs actual)
- Nutrition intake vs targets
- Focus block duration on 'One Big Thing'
- Journal entries and friction logs

Provide an actionable performance review in this format:
1. THE COMPOUNDING AUDIT (1 sentence on whether today moved the needle by 1%)
2. ROOT FRICTION ELIMINATION (Identify the exact breakdown that caused lost focus or missed goals)
3. TOMORROW'S LEVERAGE DIRECTIVE (1 concrete behavioral adjustment for tomorrow)
Be direct, ruthless with excuses, yet constructive. Max 150 words.
`;
6. Android Native Requirements & PermissionsAdd these declarations inside android/app/src/main/AndroidManifest.xml:XML<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- Exact Alarms for Meditation, Wind-Down, and Wake-Up -->
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
    <uses-permission android:name="android.permission.USE_EXACT_ALARM" />
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
    <uses-permission android:name="android.permission.VIBRATE" />

    <!-- Audio playback for background meditation bell -->
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK" />

    <!-- Push Notifications & DND access -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.ACCESS_NOTIFICATION_POLICY" />

    <!-- Health Connect (Step Counter & Calorie sync) -->
    <uses-permission android:name="android.permission.health.READ_STEPS"/>
    <uses-permission android:name="android.permission.health.READ_TOTAL_CALORIES_BURNED"/>

    <application
        android:name=".MainApplication"
        android:label="AtomicOS"
        android:icon="@mipmap/ic_launcher">

        <!-- Boot receiver to re-register scheduled alarms after phone reboot -->
        <receiver 
            android:name=".AlarmBootReceiver"
            android:enabled="true"
            android:exported="false">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED" />
            </intent-filter>
        </receiver>

    </application>
</manifest>
7. Direct Base Prompt for Your AI Coding AgentCopy and paste the block below into your AI coding tool (Antigravity, Cursor, or Windsurf) as your initial master prompt:PlaintextYou are the lead architect and senior software engineer building "AtomicOS" - a high-performance Android personal operating system.

Core Objective:
Build an offline-first mobile app combining:
1. Dynamic 1% Progressive Overload Tracker: Pushup and workout rep counter where completing X reps automatically increments the next target by a user-configured percentage (default 1%, auto-rounding with ceiling logic).
2. Atomic Habit Engine: Sequential habit stacking ("After [Habit A], I will [Habit B]"), visual streak calendars, and a strict "Never Miss Twice" alert system.
3. Health & Mental Suite: Scheduled exact meditation timer with background chime audio, dual sleep alarms (Wind-Down screen lock and Wake-Up alarm), and calorie/protein tracker.
4. Founder Hub: One Big Thing (deep work focus timer), Business Idea Canvas with lean validation checklist, book note quotes with home screen widget, and Evening Founder's Log.
5. Gemini AI Integration: User-configurable API key stored in secure local storage. Implement endpoints for:
   - Plain-text meal description to JSON macro parser.
   - Evening daily audit generating high-performance feedback.
   - Interactive startup/fitness copilot chat.

Architecture Constraints:
- Clean Architecture with feature-first modular folder structure.
- Local SQLite database as the primary source of truth.
- Zero boilerplate UI: High-contrast dark dashboard inspired by industrial minimalism (slate grey, matte black, amber warnings, emerald progress rings).
- Android AlarmManager integration with boot persistence for guaranteed alarm execution.

Start by setting up the project structure, SQLite schema migrations, and core state mode