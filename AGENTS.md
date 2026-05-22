# AGENTS.md — Yaza Flutter App

Flutter client for Yaza AI study platform. Talks to Django backend via GraphQL.

**Stack:** Flutter, Riverpod, go_router, graphql_flutter, flutter_secure_storage, hive, Sentry.

---

## Architecture

```
lib/
├── core/
│   ├── config/              app_config.dart
│   ├── graphql/             client, options, queries/domain/ (14 query files)
│   ├── services/            8 service files
│   ├── storage/             secure_storage.dart
│   ├── theme/               app_theme.dart, design_tokens.dart
│   └── widgets/             loading_overlay, error_state, empty_state, shimmer_box, etc.
├── features/
│   ├── account/             9 screens (upgrade, history, bookmarks, past papers, etc.)
│   ├── ai_tutor/            1 screen + widgets
│   ├── auth/                5 screens + auth_provider
│   ├── circles/             3 screens
│   ├── dashboard/           1 screen + 6 widgets
│   ├── kids_mode/           4 screens + 12 widgets
│   ├── leaderboard/         1 screen
│   ├── materials/           4 screens + reader/ subsystem
│   ├── notifications/       1 screen
│   ├── profile/             3 screens
│   ├── quizzes/             3 screens
│   └── scanner/             2 screens
├── main.dart
├── router.dart              ALL routes defined here
└── shell.dart               bottom nav shell (5 tabs)
```

Most features have `presentation/` only (no data/domain/ layers). This is intentional — keep it simple. If a feature grows complex, extract data/domain.

---

## Non-Negotiable Rules

- **No file > 250 lines.** Currently 31 files violate this — fix them.
- **No widget method > 50 lines.** Extract to named widget class.
- **No build() with > 3 levels of nesting.**
- **No Navigator.push/pop** outside dialogs/sheets. Use `context.go()` / `context.push()`.
- **No setState for shared state.** Use Riverpod providers.
- **No dynamic types.** Use typed models.
- **Every GraphQL call must handle loading + error + success.** Use shared widgets (`LoadingOverlay`, `ErrorState`).
- **Use shared widgets from `core/widgets/`** instead of inlining `CircularProgressIndicator`.
- **Auth routes are in `router.dart` redirect.** Never duplicate auth checks in screens.

---

## Routes

Router at `lib/router.dart` (350 lines). 32 routes total. Shell routes (bottom nav): `/home`, `/materials`, `/circles`, `/profile` plus AI tutor center tab.

Key routes: `/splash`, `/onboarding`, `/login`, `/register`, `/setup`, `/kids/*`, `/home`, `/materials/:slug`, `/materials/:slug/read`, `/circles/:slug`, `/circles/:slug/post/:postSlug`, `/scanner`, `/quiz/:slug`, `/quiz-results/:attemptId`, `/ai-tutor`, `/profile`, `/upgrade`, `/history`, `/bookmarks`, `/edit-profile`, `/past-papers`, `/paper-library`, `/upload-material`, `/my-uploads`, `/quizzes`, `/about`, `/legal/*`.

---

## Commands

```bash
flutter run
flutter analyze
flutter test
flutter build apk --release
dart format lib/path/to/file.dart
flutter pub outdated
```

After every edit: `flutter analyze lib/path/to/file.dart && dart format lib/path/to/file.dart`

---

## Kids Mode

4 screens (kid_login, kids_home, kids_journey, parent_progress). PIN-based login (4-digit). Companion system (Sprout, Flame, etc.), badges, daily chest, XP/levels. Lessons have chunks_json for visual {emoji, text} format. Uses flutter_tts for reading aloud.

---

## Updating Docs

After every session: update BUGS.md (mark resolved, add new), update PROGRESS.md.
