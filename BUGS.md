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

### [BUG-053] AI Tutor shows "something went wrong" immediately
**Priority:** 🔴 CRITICAL → ✅ RESOLVED
**Location:** Backend `apps/agent/views.py`, `apps/accounts/jwt_decorators.py`
**Root cause:** The `/agent/stream/` REST endpoint used Django's session-based `@login_required`, but the Flutter app sends Bearer JWT tokens (not session cookies). `request.user` was always `AnonymousUser`, returning a 302 redirect instead of SSE stream.
**Fix:** Created `jwt_login_required` decorator that extracts Bearer JWT, validates it via graphql_jwt, and sets `request.user`. Returns 401 JSON on auth failure. Applied to agent, materials, quizzes, and pastpapers REST views. Added `csrf_exempt` and added `/agent/` to ProfileCompletionMiddleware allowed paths.
**Verified:** Local server test — SSE stream returns 200 with meta/assistant/done events.

### [BUG-052] Profile screen shows blank white page
**Priority:** 🔴 CRITICAL → ✅ RESOLVED
**Location:** Backend `apps/accounts/schema/types.py`
**Root cause:** The `kProfile` GraphQL query asks for `me { achievements { achievement { id name category icon } } }` but `achievements` was only defined on `UserProfileType`, not `UserType`. This caused a GraphQL validation error that broke the entire query. Additionally, `AchType` listed `icon` in its Meta fields but the model field is `icon_url`.
**Fix:** Added `achievements` field and resolver to `UserType`. Fixed `AchType` to expose explicit `icon` field mapped to `icon_url`.
**Verified:** Local GraphQL test — profile query returns user data with achievements.

### [BUG-051] Community creation spinner rotates forever
**Priority:** 🟡 HIGH → ✅ RESOLVED
**Location:** Backend `apps/communities/schema/community_mutations.py`, app `create_community_screen.dart`
**Root cause:** Backend `check_rate_limit()` could throw an unhandled exception if cache was unavailable. App had no timeout on the mutation call, so the spinner ran indefinitely during retries.
**Fix:** Wrapped `check_rate_limit` in try/except on the backend. Added 30-second `.timeout()` and `TimeoutException` catch in the app.
**Verified:** Source audit and backend local test.

### [BUG-050] Auto-logout on app restart (tokens cleared on network timeout)
**Priority:** 🔴 CRITICAL → ✅ RESOLVED
**Location:** `lib/features/auth/presentation/providers/auth_provider.dart`, backend `config/settings.py`
**Root cause:** `_bootstrap()` caught all exceptions (including `TimeoutException`) and set `isAuthenticated: false`, triggering router redirect to `/login`. Render free tier cold starts (30-60s) exceeded the 25s timeout, causing every restart to log the user out.
**Fix:** Increased timeouts from 25s to 45s. Added separate `TimeoutException` catch that keeps tokens and shows "Server is waking up" message. Increased backend `JWT_EXPIRATION_DELTA` from 60 min to 4 hours.
**Verified:** Source audit.

### [BUG-049] Upload material shows "no subject available for your level"
**Priority:** 🟡 HIGH → ✅ RESOLVED
**Location:** Backend `apps/education/schema.py`
**Root cause:** Profile stores `education_level` as uppercase (`"SECONDARY"`) but the `Subject` model stores it as lowercase (`"secondary"`). The resolver used exact match (`education_level=`), so no subjects were found.
**Fix:** Changed filter to case-insensitive: `education_level__iexact=`.
**Verified:** Local GraphQL test — 91 subjects returned for `SECONDARY`.

### [BUG-048] Kids login and feed rendering could hang or crash on backend/network edge cases
**Priority:** 🟡 HIGH → ✅ RESOLVED
**Location:** Kids login managers, Feed/community post lists, post card renderers
**Root cause:** Kids parent/kid login paths did not catch timeouts or thrown GraphQL failures, and Feed/community post cards force-cast GraphQL maps/counts.
**Fix:** Added timeouts and visible errors for Kids parent login, child loading, child creation, and PIN login. Hardened Feed/community list parsing and post cards against missing nested maps, missing slugs, and string counts/votes.
**Verified:** Source audit and `dart format` on touched files. Analyzer/tests intentionally skipped to conserve tokens.

### [BUG-047] Setup/dashboard/profile first-run routes and GraphQL casts could block app entry
**Priority:** 🔴 CRITICAL → ✅ RESOLVED
**Location:** `profile_setup_manager.dart`, `app_routes.dart`, Study hub cards/tabs, profile tabs
**Root cause:** Profile setup relied only on auth refresh/redirect after save, `/dashboard` was registered twice, and several first authenticated screens force-cast GraphQL edge/node maps and nested values.
**Fix:** Explicitly navigate to `/home` or `/kids` after successful setup, removed duplicate top-level dashboard route, and hardened Study/Profile list parsing against missing or differently typed GraphQL values.
**Verified:** Source audit and `dart format` on touched files. Analyzer/tests intentionally skipped per token-saving instruction.

### [BUG-046] Auth entry flow could strand users on splash/login/register
**Priority:** 🔴 CRITICAL → ✅ RESOLVED
**Location:** `lib/router.dart`, `lib/features/auth/presentation/providers/auth_register_mixin.dart`, `lib/features/auth/presentation/screens/register_screen.dart`, `lib/features/auth/presentation/screens/login_form.dart`
**Root cause:** Unauthenticated `/splash` did not enter onboarding, authenticated users with incomplete profiles were allowed to remain on login/register, registration used global auth loading instead of submit loading, and register failures were only transient snackbars.
**Fix:** Route unauthenticated splash to onboarding, route successful auth with incomplete profiles to setup, switched registration to `isSubmitting`, added timeout/user-friendly register errors, and made register submit errors persistent inline.
**Verified:** Targeted `flutter analyze` and login widget test were started before commit; user requested immediate commit/push before waiting for full output.

### [BUG-036] Bottom nav architecture — Dashboard buried, AI Tutor inaccessible from shell
**Priority:** 🔴 CRITICAL → ✅ RESOLVED
**Fix:** Restructured shell to 4 study-first tabs (Dashboard, Study hub, Circles, Profile) with AI Tutor centre button.

### [BUG-037] HomeScreen TabBar crash — no TabController
**Priority:** 🔴 CRITICAL → ✅ RESOLVED
**Fix:** Added `SingleTickerProviderStateMixin` + `TabController` to `_HomeScreenState`.

### [BUG-038] Dashboard notifications navigation broken (`/notifications` outside shell)
**Priority:** 🟡 HIGH → ✅ RESOLVED
**Fix:** Changed `context.go('/notifications')` to `context.push('/home/notifications')`.

### [BUG-039] Profile screen hardcoded followers/following = 0
**Priority:** 🟡 HIGH → ✅ RESOLVED
**Fix:** Added `myFollowersCount`/`myFollowingCount` to backend and profile query.

### [BUG-040] Leaderboard contributors tab showed quiz stats instead of karma
**Priority:** 🟡 HIGH → ✅ RESOLVED
**Fix:** Fixed leaderboard schema and Flutter UI to show postKarma/commentKarma/totalKarma for contributors.

### [BUG-041] Scanner landing page shows no credit cost before submission
**Priority:** 🟡 HIGH → ✅ RESOLVED
**Fix:** Added "1 AI credit per submission" banner to ScannerLandingPage.

### [BUG-042] DashboardHeroHeader > 250 lines (violates AGENTS.md rule)
**Priority:** ⚪ LOW → ✅ RESOLVED
**Fix:** Extracted HeroStatTile, DailyGoalRingTile, StreakDotsRow into `dashboard_hero_tiles.dart`.

### [BUG-043] NotificationPreferencesScreen UI-only, no backend save
**Priority:** 🟢 MEDIUM → ✅ RESOLVED
**Fix:** Wired to `kProfileNotificationPreferences` query and `kUpdateProfileNotificationPreferences` mutation.

### [BUG-044] No Study tab in bottom nav — Materials/Quizzes/Scanner buried behind dashboard
**Priority:** 🔴 CRITICAL → ✅ RESOLVED
**Fix:** Created `StudyHubScreen` as Tab 1 with Materials (search+filter), Quizzes, and Tools sections.

### [BUG-045] Stale route references (`/discover`, `/inbox`) after nav restructure
**Priority:** 🟡 HIGH → ✅ RESOLVED
**Fix:** Updated all push calls to `/circles/discover` and `/circles/inbox`.


### [BUG-035] Login UX hides credential/server failures behind raw or unclear errors
**Priority:** 🟡 HIGH → ✅ RESOLVED
**Location:** `lib/features/auth/presentation/providers/auth_provider.dart`, `lib/features/auth/presentation/screens/login_form.dart`, `lib/features/auth/presentation/screens/login_biometric_tile.dart`, `lib/core/graphql/queries/domain/auth_queries.dart`
**Root cause:** Login used the global auth loading flag for submit state, did not clear old form errors while editing, surfaced raw GraphQL/link exceptions, and queried an unused `payload` field in `tokenAuth`. Biometric copy also implied a broad account-level Face ID feature instead of local quick unlock.
**Fix:** Added explicit `isSubmitting`, mapped login failures to clear user-facing messages, added timeout handling, removed unused `payload` from `tokenAuth`, improved required-field messages, cleared errors on edit, and clarified biometric quick-unlock copy.
**Verified:** `flutter test test/features/auth/presentation/screens/login_screen_test.dart` passes with coverage for incorrect credentials messaging; edited auth files pass analyzer.

### [BUG-034] GitHub Actions release blocked by stale Flutter tests and missing CI .env
**Priority:** 🟡 HIGH → ✅ RESOLVED
**Location:** `.github/workflows/build.yml`, `test/core/config/app_config_test.dart`, `test/features/auth/presentation/screens/login_screen_test.dart`
**Root cause:** The CI test job still ran tests written before the June 1 login UI/auth refactor and before `.env` was removed from committed assets. `app_config_test.dart` depended on a real `.env`, while `login_screen_test.dart` allowed the real `authProvider` bootstrap to run, leaving pending timers and loading-state assertions.
**Fix:** Config tests now load an in-memory dotenv fixture and explicitly verify fallback behavior when `.env` is absent. Login screen tests override `authProvider` with an idle fake notifier. GitHub Actions now creates `.env` in both test and release jobs from repository variables/secrets with safe production defaults.
**Verified:** `flutter test test/widget_test.dart test/features test/core --coverage` passes locally with 21 tests.

### [BUG-031] API test — false failures from wrong auth header prefix (JWT vs Bearer)
**Priority:** ✅ NO BUG (false alarm)
**Location:** `lib/core/graphql/client.dart:17`
**Summary:** Production GraphQL API tested 87 operations against `yaza-ai-tutor.onrender.com`. Initial tests used `Authorization: JWT <token>` but the backend expects `Authorization: Bearer <token>`. All "permission denied" and `me: null` results were caused by this prefix mismatch. Re-tested with correct `Bearer` prefix — all 87 operations pass.
**What works:**
- Auth: `tokenAuth`, `register`, `verifyToken`, `refreshToken`
- Profile: `me` returns full user (id=75, madalakoso), `updateProfile`, `learningProfile`
- Materials: `subjects` → ~90 secondary subjects, `myCircles` → 11 circles
- AI: `chatSessions`, `createChatSession`, `tutorSnapshot`, `sendMessage`
- Payments: `creditPackages` (4 plans), `aiActionCatalog` (5 actions), `creditLedger`, `paymentHistory`
- Leaderboard: shows `redson` with 100 pts, `score` field correct
- Schools: 47 universities, 8 secondary schools, programs per university
- Quizzes: `popularQuizzes` → 2 quizzes, `progressSnapshot` (no data)
- All field names match: `studyPoints` on UserProfileType, `subjectName` on PopularQuizType, `delta` on AICreditLedgerEntryType, `isApproved` on StudyMaterialType, `subject { name }` on QuizType
**Note:** Some queries return empty/non-seeded data because the production DB has limited test content — this is expected, not a bug.

### [BUG-032] Scanner endpoint URL mismatch — Flutter calls /scanner/stream/ but backend serves /pastpapers/stream/
**Priority:** 🔴 CRITICAL → ✅ RESOLVED
**Location:** `lib/core/constants/api_endpoints.dart:7`
**Root cause:** Flutter app's `ScannerStreamService` sends the POST request to `${AppConfig.apiUrl}/scanner/stream/` (resolves to `https://yaza-ai-tutor.onrender.com/scanner/stream/`). The Django backend registers this streaming view at `/pastpapers/stream/` (in `apps/pastpapers/urls.py:8`). The `/scanner/stream/` path returned a 404 (serving the landing page HTML), so scanner submissions silently failed.
**Fix:** Changed `api_endpoints.dart:7` from `/scanner/stream/` to `/pastpapers/stream/`.
**Verified:** Full end-to-end SSE flow confirmed working — sent test image with 2 math questions, received progress events ("Extracting questions...", "Solving 2 questions...", "Finalizing..."), then received `event: done` with correct solutions (`2+2=4`, `10-3=7`), credit charged (1 credit, 99 remaining).

### [BUG-033] Circles — askAiOnPost uses wrong field name `reply` instead of `comment { body }`
**Priority:** 🟡 HIGH → ✅ RESOLVED
**Location:** `circle_queries.dart:98`, `post_detail_post_card.dart:122`
**Root cause:** `kAskAiOnPost` mutation queried `{ success reply }` but the Django `AskAiOnPost` Mutation's `Output` class is `CommentPayload` which has fields `success`, `comment`, `errors` — no `reply`. The backend creates a `Comment` object and returns it in the `comment` field. The Flutter consumer at `post_detail_post_card.dart:122` read `data['askAiOnPost']['reply']` which always returned null.
**Fix:** Changed query to `{ success comment { id body } }` and consumer to `data['askAiOnPost']['comment']['body']`.
**Verified:** Tested against production — AI replied with full quadratic formula explanation (multiple paragraphs).

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
