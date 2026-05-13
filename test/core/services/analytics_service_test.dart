import 'package:flutter_test/flutter_test.dart';
import 'package:studyapp/core/services/analytics_service.dart';

void main() {
  group('AnalyticsService', () {
    test('should initialize without errors when disabled', () async {
      // Firebase is disabled by default in .env
      expect(() async => await AnalyticsService.initialize(), returnsNormally);
    });

    test('should handle logEvent gracefully when disabled', () async {
      expect(
        () async => await AnalyticsService.logEvent('test_event'),
        returnsNormally,
      );
    });

    test('should handle logScreenView gracefully when disabled', () async {
      expect(
        () async => await AnalyticsService.logScreenView('test_screen'),
        returnsNormally,
      );
    });

    test('should handle logLogin gracefully when disabled', () async {
      expect(
        () async => await AnalyticsService.logLogin('test_method'),
        returnsNormally,
      );
    });
  });
}
