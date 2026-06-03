import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/kid_auth_widgets.dart';
import '../widgets/kids_home_screen_manager.dart';
import '../widgets/kids_home_state_provider.dart';
import '../widgets/kids_session_ended_screen.dart';
import 'kids_home_builders.dart';
import 'kids_home_screen_actions.dart';
import 'kids_home_screen_body.dart';

class KidsHomeScreen extends ConsumerStatefulWidget {
  const KidsHomeScreen({super.key});
  @override
  ConsumerState<KidsHomeScreen> createState() => _KidsHomeScreenState();
}

class _KidsHomeScreenState extends ConsumerState<KidsHomeScreen>
    with SingleTickerProviderStateMixin {
  late final KidsHomeScreenManager _mgr;
  final _tts = FlutterTts();
  bool _redirectScheduled = false;
  late final AnimationController _burstCtrl;
  Timer? _sessionTimer;
  bool _isOffline = false;
  late final KidsHomeScreenActions _actions;

  @override
  void initState() {
    super.initState();
    _burstCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _mgr = KidsHomeScreenManager(ref);
    _mgr.attach(
      getContext: () => context,
      isMounted: () => mounted,
    );
    _tts.setSpeechRate(0.45);
    _tts.setVolume(1.0);
    _tts.setCompletionHandler(() {
      if (mounted) {
        ref
            .read(kidsHomeStateProvider.notifier)
            .apply((s) => s.copyWith(isSpeaking: false));
      }
    });
    _actions = KidsHomeScreenActions(
      ref: ref,
      tts: _tts,
      mgr: _mgr,
      burstCtrl: _burstCtrl,
      isMounted: () => mounted,
      startSessionTimer: _startSessionTimer,
      stopSessionTimer: _stopSessionTimer,
      setState: setState,
    );
    final auth = ref.read(kidAuthStateProvider);
    if (auth.isAuthenticated && auth.token != null) {
      ref.read(kidsHomeStateProvider.notifier).setChildId(auth.token ?? '');
    }
    _checkConnectivity();
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _burstCtrl.dispose();
    _tts.stop();
    _tts.setCompletionHandler(() {});
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastOnline = prefs.getBool('_last_online') ?? true;
      if (mounted) setState(() => _isOffline = !lastOnline);
    } catch (_) {
      if (mounted) setState(() => _isOffline = true);
    }
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    final auth = ref.read(kidAuthStateProvider);
    final duration = auth.standard <= 2 ? 1200 : 1800;
    ref.read(kidsHomeStateProvider.notifier).startSession(duration);
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        _sessionTimer?.cancel();
        return;
      }
      final notifier = ref.read(kidsHomeStateProvider.notifier);
      notifier.tickSession();
      final state = ref.read(kidsHomeStateProvider);
      if (state.sessionWarningShown && !_actions.showWarningOverlay) {
        setState(() => _actions.showWarningOverlay = true);
      }
      if (state.sessionExpired) {
        _sessionTimer?.cancel();
      }
    });
  }

  void _stopSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
    setState(() => _actions.showWarningOverlay = false);
    ref.read(kidsHomeStateProvider.notifier).endSession();
  }

  void _onBack() {
    _stopSessionTimer();
    ref.read(kidsHomeStateProvider.notifier).clearSavedState();
    ref.read(kidsHomeStateProvider.notifier).apply((s) => s.copyWith(
        selectedSubject: null,
        selectedTopic: null,
        currentLesson: null,
        subjectProgress: null,
        topics: []));
  }

  void _onDismissSessionExpired() {
    _actions.onDismissSessionExpired();
    context.go('/kids');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(kidAuthStateProvider);
    final state = ref.watch(kidsHomeStateProvider);
    if (!auth.isAuthenticated) {
      if (!_redirectScheduled) {
        _redirectScheduled = true;
        WidgetsBinding.instance
            .addPostFrameCallback((_) => context.go('/kids'));
      }
      return const KidsHomeRedirect();
    }
    if (!state.fetchedSubjects) {
      return KidsHomeLoading(onFetchSubjects: () => _mgr.fetchSubjects());
    }
    if (state.sessionExpired) {
      return KidsSessionEndedScreen(
        starsEarned: state.stars,
        onDismiss: _onDismissSessionExpired,
      );
    }
    return KidsHomeScreenBody(
      auth: auth,
      state: state,
      actions: _actions,
      mgr: _mgr,
      burstCtrl: _burstCtrl,
      isOffline: _isOffline,
      onBack: _onBack,
    );
  }
}
