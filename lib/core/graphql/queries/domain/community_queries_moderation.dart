const String kMarkOc = r'''
mutation MarkOc($postId: ID!) {
  markOc(postId: $postId) { success }
}
''';

const String kMarkSpoiler = r'''
mutation MarkSpoiler($postId: ID!, $isSpoiler: Boolean!) {
  markSpoiler(postId: $postId, isSpoiler: $isSpoiler) { success }
}
''';

const String kAddRule = r'''
mutation AddRule($slug: String!, $title: String!, $description: String) {
  addRule(slug: $slug, title: $title, description: $description) {
    id title description order
  }
}
''';

const String kAddModerator = r'''
mutation AddModerator($slug: String!, $username: String!) {
  addModerator(slug: $slug, username: $username) {
    membership { id role user { username } }
    errors
  }
}
''';

const String kRemoveModerator = r'''
mutation RemoveModerator($slug: String!, $username: String!) {
  removeModerator(slug: $slug, username: $username) { success }
}
''';

const String kRemovePost = r'''
mutation RemovePost($postId: ID!) {
  removePost(postId: $postId) { success }
}
''';

const String kApprovePost = r'''
mutation ApprovePost($postId: ID!) {
  approvePost(postId: $postId) { success }
}
''';

const String kPinPost = r'''
mutation PinPost($postId: ID!, $pinned: Boolean!) {
  pinPost(postId: $postId, pinned: $pinned) { post { id isPinned } errors }
}
''';

const String kLockPost = r'''
mutation LockPost($postId: ID!, $locked: Boolean!) {
  lockPost(postId: $postId, locked: $locked) { post { id isLocked } errors }
}
''';

const String kDistinguishPost = r'''
mutation DistinguishPost($postId: ID!) {
  distinguishPost(postId: $postId) { post { id } errors }
}
''';

const String kBanUser = r'''
mutation BanUser($communitySlug: String!, $username: String!, $reason: String!, $isPermanent: Boolean, $durationDays: Int, $modNote: String) {
  banUser(communitySlug: $communitySlug, username: $username, reason: $reason, isPermanent: $isPermanent, durationDays: $durationDays, modNote: $modNote) {
    membership { id isBanned banReason banExpiresAt }
    errors
  }
}
''';

const String kUnbanUser = r'''
mutation UnbanUser($communitySlug: String!, $username: String!) {
  unbanUser(communitySlug: $communitySlug, username: $username) { success }
}
''';

const String kMuteUser = r'''
mutation MuteUser($communitySlug: String!, $username: String!, $durationDays: Int!, $modNote: String) {
  muteUser(communitySlug: $communitySlug, username: $username, durationDays: $durationDays, modNote: $modNote) {
    membership { id isMuted muteExpiresAt }
    errors
  }
}
''';

const String kUnmuteUser = r'''
mutation UnmuteUser($communitySlug: String!, $username: String!) {
  unmuteUser(communitySlug: $communitySlug, username: $username) { success }
}
''';

const String kBannedMembers = r'''
query BannedMembers($slug: String!) {
  bannedMembers(slug: $slug) {
    id role
    isBanned banReason banExpiresAt
    user { id username }
  }
}
''';

const String kMutedMembers = r'''
query MutedMembers($slug: String!) {
  mutedMembers(slug: $slug) {
    id role
    isMuted muteExpiresAt
    user { id username }
  }
}
''';

const String kApprovedUsers = r'''
query ApprovedUsers($slug: String!) {
  approvedUsers(slug: $slug) {
    id role
    user { id username }
    joinedAt
  }
}
''';

const String kReportsQuery = r'''
query Reports($communitySlug: String!, $status: String) {
  reports(communitySlug: $communitySlug, status: $status) {
    id
    reason
    status
    modNote
    createdAt
    reporter { username }
    reviewedBy { username }
    post { id title slug author { username } }
    comment { id body author { username } }
  }
}
''';

const String kModLogQuery = r'''
query ModLog($communitySlug: String!) {
  modLog(communitySlug: $communitySlug) {
    id
    action
    details
    createdAt
    moderator { username }
    targetUser { username }
    post { id title slug }
  }
}
''';

const String kResolveReport = r'''
mutation ResolveReport($reportId: ID!, $action: String!, $modNote: String) {
  resolveReport(reportId: $reportId, action: $action, modNote: $modNote) {
    id
    status
  }
}
''';

const String kUpdateRule = r'''
mutation UpdateRule($ruleId: ID!, $title: String, $description: String, $order: Int) {
  updateRule(ruleId: $ruleId, title: $title, description: $description, order: $order) {
    id title description order
  }
}
''';

const String kDeleteRule = r'''
mutation DeleteRule($ruleId: ID!) {
  deleteRule(ruleId: $ruleId) { success }
}
''';
