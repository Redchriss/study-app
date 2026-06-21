const String kTokenAuth = r'''
mutation Login($username: String!, $password: String!) {
  tokenAuth(username: $username, password: $password) {
    token
    refreshToken
    errors
  }
}
''';

const String kRegister = r'''
mutation Register($username: String!, $email: String!, $password: String!, $password2: String, $phone: String, $firstName: String, $lastName: String) {
  register(username: $username, email: $email, password: $password, password2: $password2, phone: $phone, firstName: $firstName, lastName: $lastName) {
    success
    errors
    token
    refreshToken
  }
}
''';

const String kCheckUsername = r'''
query CheckUsername($username: String!) {
  checkUsername(username: $username)
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

const String kDeleteAccount = r'''
mutation DeleteAccount($password: String!) {
  deleteAccount(password: $password) {
    success
    errors
  }
}
''';

const String kRequestPasswordReset = r'''
mutation RequestPasswordReset($email: String!) {
  requestPasswordReset(email: $email) {
    success
    errors
  }
}
''';

const String kResetPassword = r'''
mutation ResetPassword($uid: String!, $token: String!, $newPassword: String!) {
  resetPassword(uid: $uid, token: $token, newPassword: $newPassword) {
    success
    errors
  }
}
''';
