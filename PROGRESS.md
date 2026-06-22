# PROGRESS.md — Yaza Flutter App

## 2026-06-22
- Fixed all 28 GraphQL operations that were broken against the live backend schema (BUG-056).
- Restored the entire Circles feed by concatenating the `PostFields`/`CommentFields` fragments into the 10 queries that referenced them (they were never sent before — `Unknown fragment` error).
- Pruned schema-absent post/poll fields, renamed `communityFlair.color`/`sidebarMarkdown`, fixed moderation payload shapes (`post`/`errors`, bare `MembershipType`) and their repo call sites.
- Corrected variable types: vote `direction` → `VoteDirectionEnum!` (mapped ints to `UP`/`DOWN` at all call sites), `resolveReport.action` → `ReportActionEnum!`, scanner `uuid` → `ID!`.
- Aliased diagnostics fields (`conceptSlug: concept`, `text: answerText`, dropped `difficulty`) so the screen parsing stays unchanged; fixed profile mutations and rewrote `updateProfileBio` to use `input: ProfileInput!`.
- Verified: in-process validation against the live schema → 196/196 valid (0 invalid); live curl confirmed feed + enum coercion; `flutter analyze` 0 errors/warnings on touched areas; `dart format` clean.
- Realigned the scanner into a true "AI Paper Solver" matching the Django web flow (BUG-055).
- "Upload to Solve" now uses `FilePicker` and accepts a full past paper as PDF, JPG or PNG (was image-only via `ImagePicker`); camera "Snap to Solve" is unchanged.
- The picked file's real extension flows through the existing `fileName` field so the backend `/pastpapers/stream/` solves PDFs as documents; raised the upload cap from 5MB to 10MB to match the web.
- Added a PDF preview card so uploaded PDFs render instead of breaking `Image.file`; refreshed landing/camera copy and icons and removed a duplicated "1 AI credit" badge.
- Verified: `flutter analyze lib/features/scanner` (no new issues), `flutter test test/scanner_stream_service_test.dart` (3/3), `dart format` clean.

## 2026-06-12
- Fixed auth routing so unauthenticated startup leaves `/splash` for onboarding.
- Fixed successful login/register with incomplete profile to continue to `/setup`.
- Changed registration to use submit loading instead of global auth bootstrap loading.
- Added persistent inline register errors and clearer timeout/network/server messages.
- Corrected login field copy from "Username or Email" to "Username" to match the current `tokenAuth` mutation.
- Continued source audit of first authenticated screens.
- Made profile setup explicitly route to `/home` or `/kids` after successful save.
- Removed duplicate `/dashboard` route outside the shell.
- Hardened Study/Profile list cards and tabs against malformed GraphQL maps, empty difficulty, missing slugs, and string view counts.
- Hardened Kids Mode login/create-learner flows so backend/network failures reset loading and show messages.
- Hardened Feed/community post lists and post card renderers against malformed GraphQL edge/node data and string count/vote values.

## 2026-06-02 (Full Audit Refactor)

### Navigation & Architecture
- Restructured bottom nav from 4 social tabs to 4 study-first tabs:
  - Tab 0: Home → DashboardScreen (was circles feed)
  - Tab 1: Study → StudyHubScreen (new: Materials + Quizzes + Tools)
  - Centre: AI Tutor button (pushes `/ai-tutor` full-screen)
  - Tab 2: Circles → HomeScreen (community feed + Discover + Inbox)
  - Tab 3: Profile → ProfileScreen
- Created `StudyHubScreen` (`lib/study_hub_screen.dart`) with three sub-tabs:
  Materials (search + type filter + infinite-scroll ready), Quizzes, Tools
- AI Tutor is now always accessible via the centre nav button (was buried)
- Updated router: `/home` → DashboardScreen, `/study` → StudyHubScreen,
  `/circles` → HomeScreen with `/circles/discover` and `/circles/inbox` children

### Bug Fixes
- Fixed `HomeScreen` TabBar crash: added proper `TabController` with `SingleTickerProviderStateMixin`
- Fixed Dashboard notifications navigation: `context.go('/notifications')` →
  `context.push('/home/notifications')` (correct shell path)
- Fixed stale route references: `/discover` → `/circles/discover`,
  `/inbox` → `/circles/inbox` across `home_drawer.dart`, `user_profile_header.dart`,
  `settings_screen.dart`, `home_screen.dart`
- Removed duplicate `/discover` route from `community_routes.dart`

### Profile & Social
- Expanded `kProfile` GraphQL query to include bannerUrl, bio, createdAt, karma fields,
  achievements, and new `myFollowersCount`/`myFollowingCount` top-level fields
- Profile screen now shows real follower/following counts (was hardcoded 0)
- Added `followersCount`, `followingCount` resolvers to backend `UserProfileType`
- Added `myFollowersCount`, `myFollowingCount` to backend `AccountsQuery`

### Leaderboard
- Fixed "Top Contributors" tab to show `postKarma`, `commentKarma`, `totalKarma`,
  `helpfulAnswers` instead of quiz stats
- Updated `leaderboard_schema.py` contributors query to sort by karma
- Added `avatarUrl` field to `LeaderboardEntryType`
- Updated `kLeaderboardRankings` GraphQL query with new fields

### Scanner
- Added credit cost banner (1 AI credit) to `ScannerLandingPage` before user submits

### Dashboard Hero Header
- Split 250+ line `DashboardHeroHeader` into:
  - `dashboard_hero_header.dart` (≤200 lines)
  - `dashboard_hero_tiles.dart` (HeroStatTile, DailyGoalRingTile, StreakDotsRow)

### Notification Preferences
- Wired `NotificationPreferencesScreen` to GraphQL: loads preferences from backend,
  saves on "Save" button tap via `kUpdateProfileNotificationPreferences` mutation

## 2026-06-02 (earlier)
- Improved login UX so invalid credentials and server/network failures show clear user-facing messages.
- Split auth bootstrap loading from login submission loading with `AuthState.isSubmitting`.
- Removed unused `payload` from the `tokenAuth` GraphQL mutation.
- Clarified biometric login copy as local quick unlock for supported phones only.
- Added login widget coverage for incorrect credential messaging.

## 2026-06-01
- Fixed GitHub Actions test failures caused by stale Flutter tests after the login/auth refactor.
- Made `AppConfig` tests independent of a committed `.env` and added fallback coverage for missing env files.
- Updated login screen widget tests to override `authProvider` with an idle fake notifier.
- Added CI `.env` generation for test and release jobs using GitHub variables/secrets with safe defaults.
- Verified `flutter test test/widget_test.dart test/features test/core --coverage` passes locally.


- Improved login UX so invalid credentials and server/network failures show clear user-facing messages.
- Split auth bootstrap loading from login submission loading with `AuthState.isSubmitting`.
- Removed unused `payload` from the `tokenAuth` GraphQL mutation.
- Clarified biometric login copy as local quick unlock for supported phones only.
- Added login widget coverage for incorrect credential messaging.

## 2026-06-01

- Fixed GitHub Actions test failures caused by stale Flutter tests after the login/auth refactor.
- Made `AppConfig` tests independent of a committed `.env` and added fallback coverage for missing env files.
- Updated login screen widget tests to override `authProvider` with an idle fake notifier.
- Added CI `.env` generation for test and release jobs using GitHub variables/secrets with safe defaults.
- Verified `flutter test test/widget_test.dart test/features test/core --coverage` passes locally.
