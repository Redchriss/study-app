# Circles ↔ Backend Coverage Audit (Step 1)

This document maps the app's Circles feature against the `studyplatform`
`communities` (+ `notifications` modmail) backend. It is the contract for
Step 2 (add the missing pieces) and Step 3 (redesign).

- **App GraphQL ops:** `studyapp/lib/core/graphql/queries/domain/community_queries_*.dart`
  (6 barrels) + modmail in `notification_queries.dart`.
- **Backend:** `studyplatform/apps/communities/schema/*` (`CommunitiesQuery` /
  `CommunitiesMutation`) and `apps/notifications/schema.py` (modmail).
- **New data seam (this step):** `lib/features/circles/data/circles_repository.dart`
  (+ `_reads` / `_actions_content` / `_actions_mod` parts), typed models in
  `lib/features/circles/domain/`, providers in
  `lib/features/circles/presentation/providers/`.

## 1. Coverage matrix (op ↔ backend ↔ screen)

### Queries

| App const | Backend resolver | Used by (screen/area) |
|---|---|---|
| `kHomeFeed` / `kPopularPosts` | `home_feed` / `popular_posts` | `home_screen` |
| `kCommunityPosts` | `community_posts` | `community_screen`, `community_post_list` |
| `kPost` / `kPostById` | `post` / `post_by_id` | `post_detail_screen` |
| `kPostComments` | `post_comments` | `post_detail_comments` |
| `kSavedPosts` | `saved_posts` | `saved_tab` |
| `kSearch` / `kSearchPosts` | `search` / `search_posts` | `search_screen` |
| `kCommunity` | `community` (+ `community_flair`) | `community_screen`, `sliver_community_header` |
| `kCommunities` | `communities` | `discover_screen` |
| `kMyCommunities` | `my_communities` | `home_drawer` |
| `kTrendingCommunities` / `kSuggestedCommunities` | `trending_/suggested_communities` | `discover_screen` |
| `kCommunityModerators` | `community_moderators` | `community_moderators_section`, `mod_panel_members_tab` |
| `kCommunityRules` | `community_rules` | `community_rules_section`, `mod_panel_rules_tab` |
| `kCommunityFlairs` | `community_flair` | `flair_bar`, `create_post` |
| `kCommunityStats` | `community_stats` | `mod_panel_settings_tab` |
| `kUserProfile` / `kMyProfile` | `user_profile` / `my_profile` | `user_profile_screen` |
| `kUserPosts` / `kUserComments` | `user_posts` / `user_comments` | `user_profile_posts_tab` / `_comments_tab` |
| `kReportsQuery` | `reports` | `mod_panel_reports_tab` |
| `kModLogQuery` | `mod_log` | `mod_panel_mod_log_tab` |
| `kBannedMembers` / `kMutedMembers` / `kApprovedUsers` | `banned_/muted_/approved_*` | `mod_panel_members_tab` |
| `kModmailThreads` / `kModmailThread` | `modmail_threads` / `modmail_thread` (notifications) | `inbox_modmail_tab`, `mod_panel_modmail_tab`, `modmail_thread_detail` |

### Mutations

| App const | Backend mutation | Used by (screen/area) |
|---|---|---|
| `kCreatePost` / `kEditPost` / `kDeletePost` / `kCrosspost` | `create_post` / `edit_post` / `delete_post` / `crosspost` | `create_post_*`, `post_actions_menu` |
| `kVotePost` / `kVoteComment` | `vote_post` / `vote_comment` | `post_card_*`, `comment_actions` |
| `kSavePost` / `kUnsavePost` / `kSaveComment` / `kUnsaveComment` | `save_*` / `unsave_*` | `post_actions_menu`, `comment_actions` |
| `kVotePoll` | `vote_poll` | `post_detail_poll` |
| `kAskAiOnPost` | `ask_ai_on_post` | post detail (AI action) |
| `kGiveAward` | `give_award` | `post_detail_action_bar` |
| `kAddComment` / `kEditComment` / `kDeleteComment` | `add_comment` / `edit_comment` / `delete_comment` | `post_detail_comments`, `comment_item` |
| `kCreateCommunity` / `kUpdateCommunity` | `create_community` / `update_community` | `create_community_screen`, `mod_panel_settings_tab` |
| `kJoinCommunity` / `kLeaveCommunity` / `kToggleFavourite` | `join_/leave_community`, `toggle_favourite` | `join_fav_buttons` |
| `kReportPost` / `kReportComment` | `report_post` / `report_comment` | `report_ban_dialog` |
| `kFollowUser` / `kUnfollowUser` / `kBlockUser` / `kUnblockUser` | `follow_/block_*` | `user_profile_header` |
| `kMarkOc` / `kMarkSpoiler` | `mark_oc` / `mark_spoiler` | `post_actions_menu` |
| `kRemovePost` / `kApprovePost` / `kPinPost` / `kLockPost` / `kDistinguishPost` | `remove_/approve_/pin_/lock_/distinguish_post` | `mod_panel_actions_widgets`, `post_actions_menu` |
| `kBanUser` / `kUnbanUser` / `kMuteUser` / `kUnmuteUser` | `ban_/unban_/mute_/unmute_user` | `mod_panel_ban_widgets`, `report_ban_dialog` |
| `kResolveReport` | `resolve_report` | `mod_panel_reports_tab`, `report_card` |
| `kAddRule` / `kUpdateRule` / `kDeleteRule` | `add_/update_/delete_rule` | `mod_panel_rules_tab` |
| `kAddModerator` / `kRemoveModerator` | `add_/remove_moderator` | `mod_panel_members_tab` |
| `kSendModmail` / `kReplyModmail` / `kArchiveModmailThread` | notifications modmail mutations | `modmail_thread_detail`, `inbox_modmail_tab` |

## 2. Gaps — backend ops with NO app GraphQL const (unreachable from UI)

These mature backend mutations are exposed in `CommunitiesMutation` but have no
matching `k*` constant in the app, so the UI cannot reach them. **Step 2** adds
the constants + repository methods + wires the UI:

- `upload_community_icon`, `upload_community_banner` — community image uploads.
- `create_post_flair`, `update_post_flair`, `delete_post_flair` — flair management.
- `set_user_flair`, `set_post_flair` — assigning flair to users/posts.
- `approve_comment`, `pin_comment`, `distinguish_comment` — comment moderation.
- `mark_answer`, `collapse_comment` — comment actions (Q&A / threading).
- `add_approved_user`, `remove_approved_user` — approved-users management.

## 3. Gaps — app UI with thin/scattered state (to harden in Steps 2–3)

- **Scattered state (no data layer, now addressed):** state lived in
  `presentation/providers/pending_posts_provider.dart` and
  `presentation/screens/post_detail_screen_state.dart`; all other screens issued
  raw inline `graphql_flutter` `Query`/`Mutation` widgets. Step 1 introduces the
  typed `data/`/`domain/` seam + `circles_providers.dart` to migrate onto.
- **Mutated-comment fields:** `add_comment` returns only a minimal comment; the
  reads use the richer `CommentFields` fragment — keep parsing null-safe (handled
  by `CircleComment.fromJson`).
- **`muted_members`:** query const exists (`kMutedMembers`) but no repository read
  yet — add when wiring the members tab (Step 2).

## 4. Step 1 deliverables (done)

- `domain/`: `circle_parse`, `circle_page`, `circle_author`, `circle_community`,
  `circle_poll`, `circle_post`, `circle_comment`, `circle_user_profile`,
  `circles_domain` (barrel) — typed, null-safe.
- `data/`: `circles_repository` + `_reads` / `_actions_content` / `_actions_mod`
  parts — every existing community op reachable through one typed seam, with
  payload-error surfacing and `{success}` handling.
- `presentation/providers/`: `circles_providers` (repository provider) and
  `home_feed_provider` (paginated `AsyncNotifier` — the migration template).

> No UI redesign in Step 1 — screens still use their existing widgets; the seam
> is in place to migrate them in Steps 2–3.
