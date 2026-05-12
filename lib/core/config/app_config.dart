class AppConfig {
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://yaza-ai-tutor.onrender.com',
  );
  static const String graphqlUrl = '$apiUrl/graphql/';
}
