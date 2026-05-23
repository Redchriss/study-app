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

### [BUG-026] AI Tutor gray screen — setStudyMode() orphaned Conversation + streaming never set + SSE timeout + http.Client leak
**Priority:** 🔴 CRITICAL → ✅ RESOLVED
**Location:** `ai_tutor_provider.dart:65-71`, `ai_tutor_provider.dart:110-112`, `ai_tutor_stream_service.dart:42`
**Root cause:** Multiple issues: (1) `setStudyMode()` created a new Conversation/SurfaceController without re-attaching event listeners — subsequent AI responses were silently dropped. (2) `onToken` never updated `streaming`/`streamingText` state, so UI never showed incremental output. (3) SSE stream had no timeout — if backend hung, the AI tutor was permanently stuck in "sending" state. (4) `http.Client()` created per request but never closed.
**Fix:** Extracted `_listenConversation()` method, called from both `build()` and `setStudyMode()`. Streaming state now updated in `onToken` callback. Added 90s timeout to SSE stream. `http.Client()` wrapped in try/finally.

### [BUG-027] Kids mode blank lesson — currentLesson: {} instead of null + text ignored
**Priority:** 🔴 CRITICAL → ✅ RESOLVED
**Location:** `kids_home_screen_manager.dart:52-55,111`
**Root cause:** `startGenUiLesson()` set `currentLesson: {}` (empty Map), not `null`. The check `currentLesson == null && lessonItems.isEmpty` failed, so the "No lesson available" fallback never showed — instead the full layout rendered with empty content. Also, `ConversationContentReceived` events were silently ignored (the AI's text responses were never added to `lessonItems`), and `http.Client()` was created per request but never closed.
**Fix:** Changed `currentLesson: {}` to `currentLesson: null`. `ConversationContentReceived` now adds a `TextItem` to `lessonItems`. Added `TextItem` rendering in `kids_lesson_view_section.dart`. `http.Client()` wrapped in try/finally.

### [BUG-028] Auto logout — token refresh silently stops after first failure
**Priority:** 🔴 CRITICAL → ✅ RESOLVED
**Location:** `auth_provider.dart:45-59`
**Root cause:** `_doRefresh()` only called `_scheduleRefresh()` on SUCCESS. If the refresh request ever failed (network hiccup, server restart), the 50-minute timer was never rescheduled. After the original JWT expired (~50-60 min), all subsequent API calls failed with auth errors — the user was effectively logged out but the UI still showed them as authenticated. Every screen silently broke.
**Fix:** On success, the normal 50-min schedule continues. On catch/error, a retry is scheduled in 2 minutes. Refresh always keeps churning.

### [BUG-029] Materials screen — fromGraphQL() called before error check (crash on null data)
**Priority:** 🟡 HIGH → ✅ RESOLVED
**Location:** `materials_screen.dart:123-130`
**Root cause:** `StudyMaterialProgress.fromGraphQL()` was called BEFORE the `result.hasException && rawMaterials.isEmpty` check. If the GraphQL query failed with `result.data == null`, the `result.data!['latestMaterialProgress']` expression would crash with a null error.
**Fix:** Moved `latestMaterialProgress` computation after all error/empty checks, guarded by `result.data?['latestMaterialProgress'] is Map`.

### [BUG-030] Upload subjects — stale cache (cacheFirst) shows wrong level subjects
**Priority:** 🟢 MEDIUM → ✅ RESOLVED
**Location:** `upload_material_manager.dart:68`
**Root cause:** `loadSubjects()` used `FetchPolicy.cacheFirst`. If the user changed their education level, the old cached subjects (for a previous level) were returned — showing subjects like "Primary Mathematics" to a tertiary user (or nothing if the cache miss fell through to an error state).
**Fix:** Changed to `FetchPolicy.cacheAndNetwork`, ensuring fresh subject data is fetched for the correct education level.

## Bypassed

### [BUG-012] Kids lesson — fails silently, spinner vanishes with no output
**Priority:** 🔴 CRITICAL → ⬜ BYPASSED
**Location:** `kids_mode/presentation/widgets/kids_lesson_actions.dart:72-108`
**Root cause:** `fetchLesson` GraphQL mutation returns `result.data == null` → no error branch.
**Fix:** This method is no longer called from the UI. Kids Mode now uses GenUI streaming via `startGenUiLesson()` for all lesson content. If the GenUI path fails, the stream error handler shows a SnackBar. The legacy `fetchLesson` remains as dead code fallback. Remove in cleanup pass.

---

## Resolved Bugs

### [BUG-022] Kids VisualTheme missing color constants (skyBlue, grassGreen)
**Priority:** 🟢 MEDIUM → ✅ RESOLVED
**Description:** `emoji_story_card.dart` and `interactive_match.dart` referenced `KidsVisualTheme.skyBlue` and `KidsVisualTheme.grassGreen` which don't exist. Replaced with `pathBlue` and `trailGreen`.

### [BUG-023] Duplicate ConversationItem sealed class definitions
**Priority:** 🟢 MEDIUM → ✅ RESOLVED
**Description:** `ConversationItem`, `TextItem`, `SurfaceItem` were defined in both `ai_tutor_state.dart` and `ai_tutor_manager.dart`. Removed duplicates from `ai_tutor_manager.dart` and re-exported from `ai_tutor_state.dart`.

### [BUG-024] Kids home state provider — broken import path + invalid copyWith body
**Priority:** 🔴 CRITICAL → ✅ RESOLVED
**Description:** `kids_home_state_provider.dart` had wrong relative import path (`../../` instead of `../../../`) and a spurious `this.lessonItems = const []` assignment inside `copyWith()` body (would cause runtime crash).

### [BUG-025] Kids lesson — retry button calls dead GraphQL mutation instead of GenUI
**Priority:** 🔴 CRITICAL → ✅ RESOLVED
**Description:** `_onRetryFetchLesson`, `_onTopicTap`, `_onNextLesson`, and `openRoadmapTopicById` all called the legacy `fetchLesson` GraphQL mutation (`kFetchKidLesson`). The updated `KidsLessonViewSection` only renders GenUI `Surface` widgets from `lessonItems`, not the old `currentLesson` data. All call sites now use `mgr.startGenUiLesson(topicName)` instead.

### [BUG-013] ShellRoute loses tab state — everything rebuilds on switch
**Priority:** 🟡 HIGH → ✅ RESOLVED
**Location:** `router.dart:116` — uses `ShellRoute` instead of `StatefulShellRoute`
**Root cause:** Plain `ShellRoute` destroys and rebuilds tab content on every switch. Root cause of most "state lost" complaints: kid data resets, scroll positions lost, form inputs cleared.
**Fix:** Replaced with `StatefulShellRoute.indexedStack()` + `StatefulNavigationShell` for tab switching. `MainShell` now receives `StatefulNavigationShell` and calls `goBranch()` to switch tabs.

### [BUG-014] Upload material — subject dropdown disabled with no fix path
**Priority:** 🟡 HIGH → ✅ RESOLVED
**Location:** `account/presentation/screens/upload_material_manager.dart:45-53`
**Root cause:** If profile has no `educationLevel`, `loadSubjects()` shows `ErrorState` replacing the dropdown. No button to go fix their profile. Upload flow is locked.
**Fix:** Added `actionLabel`/`onAction` params to `ErrorState` widget. `upload_form_fields.dart` now passes `actionLabel: 'Complete Profile'` + `onAction: () => context.go('/edit-profile')`.

### [BUG-015] Adding a kid — sheet dismisses, no loading/error feedback
**Priority:** 🟡 HIGH → ✅ RESOLVED
**Location:** `kids_mode/presentation/widgets/kid_login_manager.dart:134-163`
**Root cause:** `createKid()` is fire-and-forget. Bottom sheet closes immediately. No loading indicator on dashboard during mutation. Mutation failure shows nothing (only `fetchChildren()` on success). User waits with no feedback on slow networks.
**Fix:** Added error snackbar in `createKid()` on failure. Added loading overlay in `kid_login_screen.dart` when `creatingKid` is true.

### [BUG-016] Scanner — "Solve" blocks UI thread on large images
**Priority:** 🟡 HIGH → ✅ RESOLVED
**Location:** `scanner/presentation/screens/scanner_submit_service.dart:27`
**Root cause:** `image.readAsBytes()` reads entire file into memory on the main isolate. For 3-5MB images this freezes the UI for noticeable time. The 5MB limit at line 28 is checked after the read starts. Also no loading progress indicator during the upload.
**Fix:** Replaced `image.readAsBytes()` with `compute(_readFileBytes, image.path)` — runs on a background isolate via `package:flutter/foundation.dart`.

### [BUG-017] Uploaded material — "nothing happens" because upload is fire-and-forget HTTP
**Priority:** 🟡 HIGH → ✅ RESOLVED
**Location:** `core/services/material_upload_service.dart:78-116` hits REST endpoint at `/materials/api/upload/` (separate from GraphQL)
**Root cause:** The upload uses `http.MultipartRequest` directly (not GraphQL). If the server returns `success != true` or there's a network error mid-flight, the user gets a snackbar they may miss. No retry mechanism. No progress bar. 
**Backend clarification:** The GraphQL mutation `UploadMaterial` at `material_queries.dart:103` is defined but unused because the Django backend schema (`apps/materials/schema.py`) does *not* accept file uploads via GraphQL (it only accepts text and YouTube URLs). So the REST API *must* be used for PDFs/Images.
**Fix:** Added retry loop (max 3 attempts with exponential backoff). Added `onProgress` callback via `finalize()` + `StreamedRequest` for upload progress tracking.

### [BUG-019] Placeholders stale — `ref.read` instead of `ref.watch`
**Priority:** 🟢 MEDIUM → ✅ RESOLVED
**Location:** `account/presentation/screens/upload_material_manager.dart:84,101,141`
**Root cause:** `levelLabel()`, `titlePlaceholder()`, `descPlaceholder()` call `ref.read(authProvider)` — snapshot, never reactive. If auth data loads late, placeholders stay at default `'secondary'` forever.
**Fix:** Added `educationLevel` field + `updateEducationLevel()` setter to manager. `UploadMaterialScreen.build()` calls `ref.watch(authProvider)` and passes the value reactively.

### [BUG-020] Registration → setup loop — `onboardingComplete` never set
**Priority:** 🔴 CRITICAL
**Location:** `auth/presentation/screens/profile_setup_manager.dart:116-155`
**Root cause:** `saveAndFinish()` sends `updateProfile` with education fields only. It never sends `onboardingComplete: true`. Backend doesn't auto-set it. After setup, `refreshUser()` loads `me` with `onboardingComplete == false` → router redirects back to `/setup`. User loops forever.
**Fix:** Add `'onboardingComplete': true` to the `updateProfile` input in `saveAndFinish()`.

---

## Resolved Bugs

### [BUG-001] 31 files exceed 250-line limit
**Priority:** 🟡 HIGH
**Description:** Major god-widget problem. All 31 offenders split into focused sub-files.
**Status:** ✅ RESOLVED (2025-05-22)

### [BUG-002] GraphQL error handling inconsistent
**Priority:** 🟡 HIGH
**Description:** Multiple screens silently fail on GraphQL errors. Added `result.hasException` check + `ErrorState` with `refetch` retry to 17 files.
**Status:** ✅ RESOLVED (2025-05-22)

### [BUG-003] CircularProgressIndicator in 37 files instead of shared widget
**Priority:** 🟢 MEDIUM
**Description:** Created `LoadingWidget` in `core/widgets/`. Replaced inline spinners in 30 files.
**Status:** ✅ RESOLVED (2025-05-22)

### [BUG-004] setState used for state that should be in providers
**Priority:** 🟢 MEDIUM
**Description:** Created Riverpod providers for scanner subjects and kids home state. Removed ~17 setState calls.
**Status:** ✅ RESOLVED (2025-05-22)

### [BUG-005] Missing AppException / error type system
**Priority:** 🟢 MEDIUM
**Description:** Created `core/errors/app_exception.dart` with `graphQLErrorMessage()` helper. Migrated 33 files.
**Status:** ✅ RESOLVED (2025-05-22)

### [BUG-006] No core/constants/ directory
**Priority:** ⚪ LOW
**Description:** Created `core/constants/` with api_endpoints.dart, action_codes.dart.
**Status:** ✅ RESOLVED (2025-05-22)

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

### [BUG-010] Circle posts GraphQL — variable `$slug` not provided
**Priority:** 🔴 CRITICAL → ✅ RESOLVED
**Description:** Changed `circle_posts_list.dart` to send `{'slug': slug}` instead of `{'circleSlug': slug}` to match the GraphQL query variable name.
**Status:** ✅ RESOLVED (2025-05-23)

### [BUG-021] Payment history query fails — backend rejects `limit` argument
**Priority:** 🔴 CRITICAL → ✅ RESOLVED
**Description:** Removed the `limit` argument from `kPaymentHistory` in `payment_queries.dart` and `history_screen.dart` since the Django backend doesn't support it for that field.
**Status:** ✅ RESOLVED (2025-05-23)
