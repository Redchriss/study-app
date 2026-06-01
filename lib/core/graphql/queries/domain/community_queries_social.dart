const String kVotePost = r'''
mutation VotePost($postId: ID!, $direction: Int!) {
  votePost(postId: $postId, direction: $direction) {
    post { id upvoteCount downvoteCount }
    errors
  }
}
''';

const String kSavePost = r'''mutation Placeholder { __typename }''';
const String kUnsavePost = r'''mutation Placeholder { __typename }''';
const String kVoteComment = r'''mutation Placeholder { __typename }''';
const String kSaveComment = r'''mutation Placeholder { __typename }''';

const String kReportPost = r'''mutation Placeholder { __typename }''';
const String kReportComment = r'''mutation Placeholder { __typename }''';
const String kFollowUser = r'''mutation Placeholder { __typename }''';
const String kUnfollowUser = r'''mutation Placeholder { __typename }''';
const String kBlockUser = r'''mutation Placeholder { __typename }''';
const String kUnblockUser = r'''mutation Placeholder { __typename }''';

const String kAskAiOnPost = r'''
mutation AskAiOnPost($postId: ID!) {
  askAiOnPost(postId: $postId) { comment { id body } }
}
''';

const String kGiveAward = r'''mutation Placeholder { __typename }''';
const String kVotePoll = r'''mutation Placeholder { __typename }''';
