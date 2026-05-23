const String kMarkOc = r'''
mutation MarkOc($postId: ID!) {
  markOc(postId: $postId) { success }
}
''';

const String kMarkSpoiler = r'''
mutation MarkSpoiler($postId: ID!) {
  markSpoiler(postId: $postId) { success }
}
''';

const String kAddRule = r'''
mutation AddRule($communitySlug: String!, $text: String!, $description: String) {
  addRule(communitySlug: $communitySlug, text: $text, description: $description) {
    communityRule { id text }
    errors
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
mutation PinPost($postId: ID!) {
  pinPost(postId: $postId) { success }
}
''';

const String kLockPost = r'''
mutation LockPost($postId: ID!) {
  lockPost(postId: $postId) { success }
}
''';

const String kBanUser = r'''
mutation BanUser($communitySlug: String!, $username: String!, $reason: String) {
  banUser(communitySlug: $communitySlug, username: $username, reason: $reason) {
    membership { id isBanned }
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
mutation MuteUser($communitySlug: String!, $username: String!, $durationHours: Int) {
  muteUser(communitySlug: $communitySlug, username: $username, durationHours: $durationHours) {
    membership { id }
    errors
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
