export 'package:graphql_flutter/graphql_flutter.dart' show gql;

const String kProfile = r'''
query Profile {
  me {
    id username email
    profile {
      avatarUrl
      bannerUrl
      bio
      createdAt
      studyStreak studyPoints aiCredits
      educationLevel
      onboardingComplete
      postKarma commentKarma awardKarma
    }
    achievements { achievement { id name category icon } }
  }
  myFollowersCount
  myFollowingCount
}
''';

const String kUpdateProfileBanner = r'''
mutation UpdateProfileBanner($imageBase64: String!) {
  updateProfileBanner(imageBase64: $imageBase64) {
    profile { id bannerUrl }
    errors
  }
}
''';

const String kUpdateProfileAvatar = r'''
mutation UpdateProfileAvatar($imageBase64: String!) {
  updateProfileAvatar(imageBase64: $imageBase64) {
    profile { id avatarUrl }
    errors
  }
}
''';

const String kUpdateProfileBio = r'''
mutation UpdateProfileBio($bio: String!) {
  updateProfile(bio: $bio) {
    profile { id bio }
    errors
  }
}
''';

const String kChangePassword = r'''
mutation ChangePassword($oldPassword: String!, $newPassword: String!) {
  changePassword(oldPassword: $oldPassword, newPassword: $newPassword) {
    success
    errors
  }
}
''';

const String kUpdateProfileNotificationPreferences = r'''
mutation UpdateNotificationPreferences($input: NotificationPrefsInput!) {
  updateNotificationPreferences(input: $input) {
    success
    errors
  }
}
''';

// kUpdateProfile is defined in auth_queries.dart — do not duplicate here.
// kNotificationPreferences is defined in notification_queries.dart — do not duplicate here.

const String kMyFollowers = r'''
query MyFollowers($limit: Int) {
  myFollowers(limit: $limit) {
    id username
    profile { avatarUrl bio postKarma commentKarma totalKarma }
  }
}
''';

const String kMyFollowing = r'''
query MyFollowing($limit: Int) {
  myFollowing(limit: $limit) {
    id username
    profile { avatarUrl bio postKarma commentKarma totalKarma }
  }
}
''';
