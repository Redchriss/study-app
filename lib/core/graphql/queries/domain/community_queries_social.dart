const String kVotePost = r'''
mutation VotePost($postId: ID!, $direction: Int!) {
  votePost(postId: $postId, direction: $direction) {
    post { id fuzzedUpvotes fuzzedDownvotes fuzzedScore }
    errors
  }
}
''';

const String kSavePost = r'''
mutation SavePost($postId: ID!) {
  savePost(postId: $postId) { success }
}
''';

const String kUnsavePost = r'''
mutation UnsavePost($postId: ID!) {
  unsavePost(postId: $postId) { success }
}
''';

const String kVoteComment = r'''
mutation VoteComment($commentId: ID!, $direction: Int!) {
  voteComment(commentId: $commentId, direction: $direction) {
    comment { id fuzzedUpvotes fuzzedDownvotes fuzzedScore }
    errors
  }
}
''';

const String kSaveComment = r'''
mutation SaveComment($commentId: ID!) {
  saveComment(commentId: $commentId) { success }
}
''';

const String kUnsaveComment = r'''
mutation UnsaveComment($commentId: ID!) {
  unsaveComment(commentId: $commentId) { success }
}
''';

const String kReportPost = r'''
mutation ReportPost($postId: ID!, $reason: String!) {
  reportPost(postId: $postId, reason: $reason) { success }
}
''';

const String kReportComment = r'''
mutation ReportComment($commentId: ID!, $reason: String!) {
  reportComment(commentId: $commentId, reason: $reason) { success }
}
''';

const String kFollowUser = r'''
mutation FollowUser($username: String!) {
  followUser(username: $username) { success }
}
''';

const String kUnfollowUser = r'''
mutation UnfollowUser($username: String!) {
  unfollowUser(username: $username) { success }
}
''';

const String kBlockUser = r'''
mutation BlockUser($username: String!) {
  blockUser(username: $username) { success }
}
''';

const String kUnblockUser = r'''
mutation UnblockUser($username: String!) {
  unblockUser(username: $username) { success }
}
''';

const String kAskAiOnPost = r'''
mutation AskAiOnPost($postId: ID!) {
  askAiOnPost(postId: $postId) { comment { id body } errors }
}
''';

const String kGiveAward = r'''
mutation GiveAward($postId: ID!, $awardTypeId: ID!) {
  giveAward(postId: $postId, awardTypeId: $awardTypeId) { success errors }
}
''';

const String kVotePoll = r'''
mutation VotePoll($pollId: ID!, $optionId: ID!) {
  votePoll(pollId: $pollId, optionId: $optionId) {
    poll { id options { id text voteCount } voteCount }
    errors
  }
}
''';
