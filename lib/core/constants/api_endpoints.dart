import '../config/app_config.dart';

class ApiEndpoints {
  ApiEndpoints._();

  static String get aiStream => '${AppConfig.apiUrl}/ai/stream/';
  static String get scannerStream => '${AppConfig.apiUrl}/scanner/stream/';
  static String get materialUpload =>
      '${AppConfig.apiUrl}/materials/api/upload/';
}
