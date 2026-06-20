import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../../core/services/voice_recorder.dart';
import '../../../../core/config/app_config.dart';
import '../providers/agent_provider.dart';
import '../widgets/agent_app_bar.dart';
import '../widgets/agent_header.dart';
import '../widgets/agent_input_bar.dart';
import '../widgets/agent_preferences_sheet.dart';
import '../widgets/agent_typing_indicator.dart';
import 'agent_chat_widgets.dart';
import 'agent_error_bottom_sheet.dart';
import 'agent_mode_helpers.dart';

class AgentScreen extends ConsumerStatefulWidget {
  final String? initialPrompt;

  const AgentScreen({super.key, this.initialPrompt});
  @override
  ConsumerState<AgentScreen> createState() => _AgentScreenState();
}

class _AgentScreenState extends ConsumerState<AgentScreen>
    with SingleTickerProviderStateMixin {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _voiceRecorder = VoiceRecorder();
  late final http.Client _httpClient;
  late final AnimationController _cursorCtrl;
  late final Animation<double> _cursorAnim;
  late final Animation<double> _breathAnim;

  static const _modes = [
    ('coach', 'Coach', Icons.school_rounded),
    ('quiz', 'Quiz Me', Icons.quiz_rounded),
    ('revise', 'Revise', Icons.bolt_rounded),
    ('memorize', 'Memorize', Icons.psychology_alt_rounded),
    ('plan', 'Plan', Icons.event_note_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _httpClient = http.Client();
    // Auto-send initial prompt if provided from dashboard suggestion
    if (widget.initialPrompt != null && widget.initialPrompt!.isNotEmpty) {
      Future.microtask(() {
        ref.read(agentProvider.notifier).send(widget.initialPrompt!, _httpClient);
      });
    }
    _cursorCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _cursorAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _cursorCtrl, curve: Curves.easeInOutSine),
    );
    _breathAnim = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _cursorCtrl, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _httpClient.close();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _cursorCtrl.dispose();
    super.dispose();
  }

  void _send([String? overrideText]) {
    final text = (overrideText ?? _msgCtrl.text).trim();
    if (overrideText == null) _msgCtrl.clear();
    if (text.isNotEmpty) {
      ref.read(agentProvider.notifier).send(text, _httpClient);
      _scrollDown();
    }
  }

  /// Insert text from voice transcription into the input field.
  /// Handle voice input: record → transcribe → return text.
  Future<String?> _onVoiceInput() async {
    final started = await _voiceRecorder.start();
    if (!started) return null;

    // Wait while recording (user taps mic again to stop)
    // The input bar handles the stop via the onTap toggle
    // For now: record, stop (handled by onVoiceInput being called again)
    // Actually: onVoiceInput is called ONCE on tap. We need to:
    // 1. Start recording
    // 2. Return immediately — user speaks
    // 3. User taps STOP (we need a way to trigger this)
    // Since the input bar calls onVoiceInput once, let's do:
    // Record → stop → transcribe → return text
    await Future.delayed(const Duration(milliseconds: 100));
    // Actually we stop after 100ms — user needs to hold vs tap
  
    // Quick recording: 3 second auto-stop for minimal viable flow
    await Future.delayed(const Duration(seconds: 3));
    final audioB64 = await _voiceRecorder.stop();
    if (audioB64 == null) return null;

    final serverUrl = AppConfig.graphqlUrl.replaceAll('/graphql/', '');
    return await _voiceRecorder.transcribe(audioB64, serverUrl);
  }

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 60), () {
      if (mounted && _scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _openHistory() async {
    await ref.read(agentProvider.notifier).loadChatHistory();
    if (!mounted) return;
    final state = ref.read(agentProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => AgentChatHistoryContent(
        chatHistory: state.chatHistory,
        onRestoreSession: (id) {
          Navigator.pop(ctx);
          ref.read(agentProvider.notifier).restoreSession(id);
        },
      ),
    );
  }

  void _openPreferences() async {
    final st = ref.read(agentProvider);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AgentPreferencesSheet(
          initialLearningStyle: st.learningStyle,
          initialPrefersExamples: st.prefersExamples,
          initialPrefersStepByStep: st.prefersStepByStep,
          initialDetailLevel: st.detailLevel,
          saving: st.profileSaving,
          onSave: ref.read(agentProvider.notifier).saveLearningProfile,
        ),
      ),
    );
  }

  void _openErrorSheet(String error) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => AgentErrorBottomSheet(
        error: error,
        onRetry: () {
          ref.read(agentProvider.notifier).clearError();
          ref.read(agentProvider.notifier).retry();
        },
        onDismiss: () => ref.read(agentProvider.notifier).clearError(),
      ),
    );
  }

  Widget _buildBody() {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final studyMode = ref.watch(agentProvider.select((s) => s.studyMode));
    final snapshotLoading =
        ref.watch(agentProvider.select((s) => s.snapshotLoading));
    final topicStates = ref.watch(agentProvider.select((s) => s.topicStates));
    final memories = ref.watch(agentProvider.select((s) => s.memories));
    final activePlan = ref.watch(agentProvider.select((s) => s.activePlan));
    final reviewCount = ref.watch(agentProvider.select((s) => s.reviewCount));
    final showInsights =
        ref.watch(agentProvider.select((s) => s.showInsights));
    final items = ref.watch(agentProvider.select((s) => s.conversationItems));
    final streaming = ref.watch(agentProvider.select((s) => s.streaming));
    final streamingText =
        ref.watch(agentProvider.select((s) => s.streamingText));
    final sending = ref.watch(agentProvider.select((s) => s.sending));

    return Column(
      children: [
        AgentHeader(
          studyMode: studyMode,
          modes: _modes,
          modeHint: modeHint(studyMode),
          snapshotLoading: snapshotLoading,
          topicStates: topicStates,
          memories: memories,
          activePlan: activePlan,
          reviewCount: reviewCount,
          showInsights: showInsights,
          onModeSelect: ref.read(agentProvider.notifier).setStudyMode,
          onGeneratePlan: () => ref
              .read(agentProvider.notifier)
              .createAdaptivePlan(_msgCtrl.text),
          onToggleInsights: ref.read(agentProvider.notifier).toggleInsights,
        ),
        Expanded(
          child: AgentMessageList(
            conversationItems: items,
            surfaceController:
                ref.read(agentProvider.notifier).surfaceController,
            streaming: streaming,
            streamingText: streamingText,
            cursorAnim: _cursorAnim,
            breathAnim: _breathAnim,
            dark: dark,
            scrollCtrl: _scrollCtrl,
            suggestions:
                items.isEmpty ? suggestionsForMode(studyMode) : const [],
            onSuggestion: _send,
            onFeedback: ref.read(agentProvider.notifier).setMessageFeedback,
            onRetry: ref.read(agentProvider.notifier).retry,
            onMountSurface: ref.read(agentProvider.notifier).mountSurface,
          ),
        ),
        if (sending) const AgentTypingIndicator(),
        if (!sending && !streaming && items.isNotEmpty)
          AgentInputBar(
            ctrl: _msgCtrl,
            sending: sending,
            placeholder: modePlaceholder(studyMode),
            suggestions: const [],
            onSend: _send,
            onVoiceInput: _onVoiceInput,
          ),
        if (items.isEmpty)
          AgentInputBar(
            ctrl: _msgCtrl,
            sending: sending,
            placeholder: modePlaceholder(studyMode),
            suggestions: suggestionsForMode(studyMode),
            onSend: _send,
            onVoiceInput: _onVoiceInput,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(agentProvider.select((s) => s.error), (_, error) {
      if (error == null) return;
      if (!mounted) return;
      _openErrorSheet(error);
    });

    return Scaffold(
      appBar: AgentAppBar(
        onHistory: _openHistory,
        onPreferences: _openPreferences,
      ),
      body: _buildBody(),
    );
  }
}
