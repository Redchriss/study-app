import 'package:shared_preferences/shared_preferences.dart';

import 'app_preferences_service.dart';
import 'notification_service.dart';
import 'study_progress_store.dart';

class RetentionService {
  static const _lastActiveKey = 'retention_last_active_ms';
  static const _studyReminderId = 71001;

  final AppPreferencesService _preferences = AppPreferencesService();
  final StudyProgressStore _progressStore = StudyProgressStore();

  Future<void> markAppOpened() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastActiveKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> refreshStudyReminder({
    String? weakTopic,
  }) async {
    final enabled = await _preferences.studyRemindersEnabled();
    if (!enabled) {
      await NotificationService.cancelNotification(_studyReminderId);
      return;
    }

    final progress = await _progressStore.loadLastMaterial();
    final title =
        progress == null ? 'Come back to Yaza' : 'Continue ${progress.title}';
    final body = weakTopic != null && weakTopic.trim().isNotEmpty
        ? 'Revise $weakTopic and keep your study habit going today.'
        : progress == null
            ? 'Do one short lesson, one quiz, or one AI revision session today.'
            : '${progress.subjectName.isEmpty ? 'Pick up where you left off' : 'Resume ${progress.subjectName}'} in one focused session.';

    await NotificationService.scheduleDailyReminder(
      id: _studyReminderId,
      title: title,
      body: body,
      payload: progress?.slug,
    );
  }
}
