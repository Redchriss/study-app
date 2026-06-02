# PROGRESS.md — Yaza Flutter App

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
