const String kCommunity = r'''
query StudyCircle($slug: String!) {
  studyCircle(slug: $slug) {
    id name slug description memberCount isMember
  }
}
''';

const String kCommunities = r'''
query StudyCircles($search: String, $educationLevel: String) {
  studyCircles(search: $search, educationLevel: $educationLevel) {
    id name slug description memberCount
  }
}
''';

const String kMyCommunities = r'''
query MyCircles {
  myCircles {
    id name slug memberCount
  }
}
''';

const String kJoinCommunity = r'''
mutation JoinCircle($circleSlug: String!) {
  joinCircle(circleSlug: $circleSlug) {
    circle { id name slug }
    success
  }
}
''';

const String kLeaveCommunity = r'''
mutation LeaveCircle($circleSlug: String!) {
  leaveCircle(circleSlug: $circleSlug) {
    success
  }
}
''';

const String kToggleFavourite = r'''
mutation ToggleFavouriteCircle($circleSlug: String!) {
  toggleFavouriteCircle(circleSlug: $circleSlug) {
    circle { id name slug }
  }
}
''';

const String kTrendingCommunities = r'''query TrendingCommunities { __typename }''';
const String kSuggestedCommunities = r'''query SuggestedCommunities { __typename }''';
const String kCommunityModerators = r'''query CommunityModerators($slug: String!) { __typename }''';
const String kCommunityRules = r'''query CommunityRules($slug: String!) { __typename }''';
const String kCommunityFlairs = r'''query CommunityFlairs($slug: String!) { __typename }''';
const String kCreateCommunity = r'''mutation CreateCommunity { __typename }''';
const String kUpdateCommunity = r'''mutation UpdateCommunity { __typename }''';
const String kCommunityStats = r'''query CommunityStats { __typename }''';
