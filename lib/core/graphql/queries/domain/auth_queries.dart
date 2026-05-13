const String kTokenAuth = r'''
mutation Login($username: String!, $password: String!) {
  tokenAuth(username: $username, password: $password) {
    token
    refreshToken
    payload
  }
}
''';

const String kRegister = r'''
mutation Register($username: String!, $email: String!, $password: String!, $phone: String) {
  register(username: $username, email: $email, password: $password, phone: $phone) {
    success
    errors
    token
    refreshToken
  }
}
''';

const String kRefreshToken = r'''
mutation RefreshToken($refreshToken: String!) {
  refreshToken(refreshToken: $refreshToken) {
    token
    refreshToken
  }
}
''';

const String kUpdateProfile = r'''
mutation UpdateProfile($input: ProfileInput!) {
  updateProfile(input: $input) {
    success
    errors
    profile {
      educationLevel
      standard
      form
      term
      onboardingComplete
      aiCredits
      studyStreak
      studyPoints
    }
  }
}
''';
