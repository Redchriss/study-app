# BUGS.md — Yaza Flutter App Known Issues

Verified against real codebase at `/home/vincent/agreements/studyapp`.

---

## Priority Key
- 🔴 CRITICAL — crash, data loss, or security
- 🟡 HIGH — feature broken, visible to users
- 🟢 MEDIUM — works but unreliable or messy
- ⚪ LOW — cosmetic or tech debt
- ✅ RESOLVED

---

## Active Bugs

### [BUG-001] 31 files exceed 250-line limit
**Priority:** 🟡 HIGH → ✅ RESOLVED
**Description:** Major god-widget problem. All 31 offenders split into focused sub-files. Last 3 resolved: kids_home_screen_manager.dart (314→162), kid_login_manager.dart (260→164), quiz_take_screen.dart (254→215). BUGS.md updated 2025-05-22.
**Fix:** Extract build methods into named widget classes in separate files.
**Status:** ✅ RESOLVED — BUG-001 (2025-05-22)

### [BUG-002] GraphQL error handling inconsistent
**Priority:** 🟡 HIGH → ✅ RESOLVED
**Description:** Multiple screens silently fail on GraphQL errors: circle_detail_screen shows "Circle not found" with no retry, post_detail_screen has no error state, bookmarks/history/past_papers/leaderboard screens show blank screen on error (only check loading, not hasException). dashboard_screen has proper ErrorState — use that pattern everywhere.
**Fix:** Added `result.hasException` check + `ErrorState` with `refetch` retry to all 17 files that were missing it. 10 files had no error state at all; 7 files had error text but no retry button. All now use the shared `ErrorState` widget with retry.
**Status:** ✅ RESOLVED — BUG-002 (2025-05-22)

### [BUG-003] CircularProgressIndicator in 37 files instead of shared widget
**Priority:** 🟢 MEDIUM
**Description:** `CircularProgressIndicator` appears in 37 unique files. Shared `LoadingOverlay` widget exists at `core/widgets/loading_overlay.dart` but most screens inline their own loading spinner instead.
**Fix:** Replace inline `Center(child: CircularProgressIndicator())` with shared `LoadingOverlay`.
**Status:** 🟢 MEDIUM — OPEN

### [BUG-004] setState used for state that should be in providers
**Priority:** 🟢 MEDIUM
**Description:** 201 setState calls across 29 files. Most are local widget state (valid), but scanner_screen uses setState for subjects/capturedImage, kids_home_screen uses setState for loading/selectedTopic — these should be Riverpod providers.
**Fix:** Audit setState calls. Move anything used by >1 widget to a provider.
**Status:** 🟢 MEDIUM — OPEN

### [BUG-005] Missing AppException / error type system
**Priority:** 🟢 MEDIUM
**Description:** No `core/errors/` directory. Errors are handled ad-hoc per screen. No standard way to map GraphQL errors to user-facing messages.
**Fix:** Create `core/errors/app_exception.dart` with typed error classes. Map GraphQL operation errors to AppException in each datasource.
**Status:** 🟢 MEDIUM — OPEN

### [BUG-006] No core/constants/ directory
**Priority:** ⚪ LOW
**Description:** API URLs, action codes, and other constants are scattered across files instead of centralized.
**Fix:** Create `core/constants/` with api_constants.dart, action_codes.dart.
**Status:** ⚪ LOW — OPEN

---

## Resolved Bugs

### [BUG-007] Navigator.push used instead of go_router
**Priority:** 🟡 HIGH → ✅ RESOLVED
**Verification:** Searched entire codebase — 0 occurrences of Navigator.push. All navigation uses context.go() or context.push(). Correctly implemented.
**Status:** ✅ RESOLVED

### [BUG-008] No route guard for authenticated screens
**Priority:** 🔴 CRITICAL → ✅ RESOLVED
**Verification:** `router.dart` has a full `redirect` function (lines 61-88) checking auth state, onboarding completion, kids routes. Uses `refreshListenable` with authProvider. Fully implemented.
**Status:** ✅ RESOLVED

### [BUG-009] Router not at core/router/router.dart
**Priority:** ⚪ LOW → ✅ RESOLVED
**Verification:** Router is at `lib/router.dart` (top level), not at `lib/core/router/router.dart` as previously documented. Updated AGENTS.md to match.
**Status:** ✅ RESOLVED
