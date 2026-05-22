import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../../core/theme/design_tokens.dart';
import '../providers/ai_tutor_provider.dart';
import '../widgets/ai_tutor_app_bar.dart';
import '../widgets/ai_tutor_header.dart';
import '../widgets/ai_tutor_input_bar.dart';
import '../widgets/ai_tutor_preferences_sheet.dart';
import '../widgets/ai_tutor_typing_indicator.dart';
import 'ai_tutor_chat_widgets.dart';
import 'ai_tutor_mode_helpers.dart';

class AiTutorScreen extends ConsumerStatefulWidget {
  const AiTutorScreen({super.key});
  @override
  ConsumerState<AiTutorScreen> createState() => _AiTutorScreenState();
}

class _AiTutorScreenState extends ConsumerState<AiTutorScreen>
    with SingleTickerProviderStateMixin {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  late final http.Client _httpClient;
  late final AnimationController _cursorCtrl;
  late final Animation<double> _cursorAnim;

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
    _cursorCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _cursorAnim = Tween<double>(begin: 0, end: 1).animate(_cursorCtrl);
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
    ref.read(aiTutorProvider.notifier).send(text, _httpClient);
    _scrollDown();
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
    await ref.read(aiTutorProvider.notifier).loadChatHistory();
    if (!mounted) return;
    final state = ref.read(aiTutorProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => AiTutorChatHistoryContent(
        chatHistory: state.chatHistory,
        onRestoreSession: (id) {
          Navigator.pop(ctx);
          ref.read(aiTutorProvider.notifier).restoreSession(id);
        },
      ),
    );
  }

  void _openPreferences() async {
    final st = ref.read(aiTutorProvider);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AiTutorPreferencesSheet(
          initialLearningStyle: st.learningStyle,
          initialPrefersExamples: st.prefersExamples,
          initialPrefersStepByStep: st.prefersStepByStep,
          initialDetailLevel: st.detailLevel,
          saving: st.profileSaving,
          onSave: ref.read(aiTutorProvider.notifier).saveLearningProfile,
        ),
      ),
    );
  }

  Widget _buildBody() {
    final st = ref.watch(aiTutorProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        AiTutorHeader(
          studyMode: st.studyMode,
          modes: _modes,
          modeHint: modeHint(st.studyMode),
          snapshotLoading: st.snapshotLoading,
          topicStates: st.topicStates,
          memories: st.memories,
          activePlan: st.activePlan,
          reviewCount: st.reviewCount,
          showInsights: st.showInsights,
          onModeSelect: ref.read(aiTutorProvider.notifier).setStudyMode,
          onGeneratePlan: () => ref
              .read(aiTutorProvider.notifier)
              .createAdaptivePlan(_msgCtrl.text),
          onToggleInsights: ref.read(aiTutorProvider.notifier).toggleInsights,
        ),
        Expanded(
          child: AiTutorMessageList(
            conversationItems: st.conversationItems,
            surfaceController:
                ref.read(aiTutorProvider.notifier).surfaceController,
            streaming: st.streaming,
            streamingText: st.streamingText,
            cursorAnim: _cursorAnim,
            dark: dark,
            scrollCtrl: _scrollCtrl,
            suggestions: st.conversationItems.isEmpty
                ? suggestionsForMode(st.studyMode)
                : const [],
            onSuggestion: _send,
            onFeedback: ref.read(aiTutorProvider.notifier).setMessageFeedback,
          ),
        ),
        if (st.sending) const AiTypingIndicator(),
        AiTutorInputBar(
          ctrl: _msgCtrl,
          sending: st.sending,
          placeholder: modePlaceholder(st.studyMode),
          suggestions: st.conversationItems.isEmpty
              ? suggestionsForMode(st.studyMode)
              : const [],
          onSend: _send,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(aiTutorProvider.select((s) => s.error), (_, error) {
      if (error == null) return;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: DesignTokens.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      ref.read(aiTutorProvider.notifier).clearError();
    });

    return Scaffold(
      appBar: AiTutorAppBar(
        onHistory: _openHistory,
        onPreferences: _openPreferences,
      ),
      body: _buildBody(),
    );
  }
}
