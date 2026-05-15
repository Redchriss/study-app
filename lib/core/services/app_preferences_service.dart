import 'package:shared_preferences/shared_preferences.dart';

class AppPreferencesService {
  static const _lowDataModeKey = 'pref_low_data_mode';
  static const _studyRemindersKey = 'pref_study_reminders';
  static const _preferredLevelKey = 'pref_preferred_level';
  static const _preferredGoalKey = 'pref_preferred_goal';

  Future<bool> isLowDataMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_lowDataModeKey) ?? false;
  }

  Future<void> setLowDataMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_lowDataModeKey, enabled);
  }

  Future<bool> studyRemindersEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_studyRemindersKey) ?? true;
  }

  Future<void> setStudyRemindersEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_studyRemindersKey, enabled);
  }

  Future<String?> preferredLevel() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_preferredLevelKey)?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  Future<void> setPreferredLevel(String? level) async {
    final prefs = await SharedPreferences.getInstance();
    if (level == null || level.trim().isEmpty) {
      await prefs.remove(_preferredLevelKey);
      return;
    }
    await prefs.setString(_preferredLevelKey, level.trim());
  }

  Future<String?> preferredGoal() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_preferredGoalKey)?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  Future<void> setPreferredGoal(String? goal) async {
    final prefs = await SharedPreferences.getInstance();
    if (goal == null || goal.trim().isEmpty) {
      await prefs.remove(_preferredGoalKey);
      return;
    }
    await prefs.setString(_preferredGoalKey, goal.trim());
  }
}
