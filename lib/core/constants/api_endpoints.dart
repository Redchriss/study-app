import '../config/app_config.dart';

class ApiEndpoints {
  ApiEndpoints._();

  static String get aiStream => '${AppConfig.apiUrl}/ai/stream/';
  static String get agentStream => '${AppConfig.apiUrl}/agent/stream/';
  static String agentReplay(int jobId) => '${AppConfig.apiUrl}/agent/jobs/$jobId/replay/';
  static String get scannerStream => '${AppConfig.apiUrl}/pastpapers/stream/';
  static String get materialUpload =>
      '${AppConfig.apiUrl}/materials/api/upload/';
  static String get agentExport => '${AppConfig.apiUrl}/agent/export/';
}
