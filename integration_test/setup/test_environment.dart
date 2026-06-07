/// Test environment configuration.
/// Points tests at the live staging/production backend.
/// Override YAZA_API_URL env var to use a different server.

const String kTestApiUrl =
    String.fromEnvironment('YAZA_API_URL', defaultValue: 'https://yaza-ai-tutor.onrender.com');

const String kTestGraphqlUrl = '$kTestApiUrl/graphql/';

// Test credentials — existing account on staging
const String kTestUsername = 'madalakoso';
const String kTestPassword = 'madalakoso';

// A username that definitely does not exist
const String kNonExistentUsername = 'zz_no_such_user_xyz_999';
