export 'package:graphql_flutter/graphql_flutter.dart' show gql;

const String kProfile = r'''
query Profile {
  me {
    id username email firstName lastName
    profile {
      id bio avatarUrl bannerUrl
      postKarma commentKarma awardKarma totalKarma
      studyStreak studyPoints aiCredits
      educationLevel
      onboardingComplete
      createdAt
    }
    achievements {
      id
      achievement { id slug name description iconUrl category }
      earnedAt
    }
  }
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

const String kProfileNotificationPreferences = r'''
query NotificationPreferences {
  notificationPreferences {
    pushEnabled
    emailEnabled
    studyReminders
    communityReplies
    mentorshipUpdates
    marketingEmails
  }
}
''';
