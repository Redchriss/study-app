import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'kids_home_state.dart';

export 'kids_home_state.dart';

class KidsHomeStateNotifier extends Notifier<KidsHomeState> {
  Timer? _debounce;
  String _childId = '';

  @override
  KidsHomeState build() => const KidsHomeState();

  void setChildId(String id) {
    _childId = id;
    _restoreState();
  }

  void apply(KidsHomeState Function(KidsHomeState) cb) {
    state = cb(state);
    _schedulePersist();
  }

  void _schedulePersist() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _persistState);
  }

  Future<void> _persistState() async {
    if (_childId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final data = state.toPersistable();
    final json = jsonEncode(data);
    await prefs.setString('kids_state_$_childId', json);
  }

  Future<void> _restoreState() async {
    if (_childId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('kids_state_$_childId');
    if (json == null || json.isEmpty) return;
    try {
      final data = jsonDecode(json) as Map<String, dynamic>;
      apply(KidsHomeState.fromPersistable(data));
    } catch (_) {
      clearSavedState();
    }
  }

  Future<void> clearSavedState() async {
    _debounce?.cancel();
    if (_childId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('kids_state_$_childId');
  }

  void startSession(int durationSeconds) {
    apply((s) => s.copyWith(
          sessionDuration: durationSeconds,
          sessionRemaining: durationSeconds,
          sessionActive: true,
          sessionWarningShown: false,
          sessionExpired: false,
        ));
  }

  void tickSession() {
    if (!state.sessionActive || state.sessionExpired) return;
    final remaining = state.sessionRemaining - 1;
    if (remaining <= 0) {
      apply((s) => s.copyWith(
            sessionRemaining: 0,
            sessionExpired: true,
            sessionActive: false,
          ));
    } else if (remaining <= 120 && !state.sessionWarningShown) {
      apply((s) => s.copyWith(
            sessionRemaining: remaining,
            sessionWarningShown: true,
          ));
    } else {
      apply((s) => s.copyWith(sessionRemaining: remaining));
    }
  }

  void endSession() {
    apply((s) => s.copyWith(
          sessionActive: false,
          sessionRemaining: state.sessionDuration,
          sessionWarningShown: false,
          sessionExpired: false,
        ));
  }

  void dismissExpired() {
    apply((s) => s.copyWith(
          sessionExpired: false,
          sessionActive: false,
          sessionRemaining: state.sessionDuration,
        ));
  }

  void cancelDebounce() {
    _debounce?.cancel();
  }
}

final kidsHomeStateProvider =
    NotifierProvider<KidsHomeStateNotifier, KidsHomeState>(
  KidsHomeStateNotifier.new,
);
