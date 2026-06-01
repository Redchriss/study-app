# PROGRESS.md — Yaza Flutter App

## 2026-06-01

- Fixed GitHub Actions test failures caused by stale Flutter tests after the login/auth refactor.
- Made `AppConfig` tests independent of a committed `.env` and added fallback coverage for missing env files.
- Updated login screen widget tests to override `authProvider` with an idle fake notifier.
- Added CI `.env` generation for test and release jobs using GitHub variables/secrets with safe defaults.
- Verified `flutter test test/widget_test.dart test/features test/core --coverage` passes locally.
