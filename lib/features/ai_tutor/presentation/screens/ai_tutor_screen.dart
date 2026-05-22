import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../../core/theme/design_tokens.dart';
import '../widgets/ai_tutor_bubbles.dart';
import '../widgets/ai_tutor_header.dart';
import '../widgets/ai_tutor_input_bar.dart';
import '../widgets/ai_tutor_preferences_sheet.dart';
import 'ai_tutor_chat_widgets.dart';
import 'ai_tutor_manager.dart';
import 'ai_tutor_mode_helpers.dart';

class AiTutorScreen extends ConsumerStatefulWidget {
  const AiTutorScreen({super.key});
  @override
  ConsumerState<AiTutorScreen> createState() => _AiTutorScreenState();
}

class _AiTutorScreenState extends ConsumerState<AiTutorScreen>
    with SingleTickerProviderStateMixin {
  final _manager = AiTutorManager();
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
    _manager.attach(
      ref: ref,
      setState: setState,
      isMounted: () => mounted,
      onScrollDown: _scrollDown,
      onShowError: _showError,
    );
    _manager.loadLearningProfile();
    _manager.loadTutorSnapshot();
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
    _manager.send(text, _httpClient);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: DesignTokens.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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
    await _manager.loadChatHistory();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => AiTutorChatHistoryContent(
        chatHistory: _manager.chatHistory,
        onRestoreSession: (id) {
          Navigator.pop(ctx);
          _manager.restoreSession(id);
        },
      ),
    );
  }

  void _openPreferences() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AiTutorPreferencesSheet(
          initialLearningStyle: _manager.learningStyle,
          initialPrefersExamples: _manager.prefersExamples,
          initialPrefersStepByStep: _manager.prefersStepByStep,
          initialDetailLevel: _manager.detailLevel,
          saving: _manager.profileSaving,
          onSave: _manager.saveLearningProfile,
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final theme = Theme.of(context);
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C4DFF), Color(0xFF1B6CA8)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Text('AI Tutor',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.history_rounded, size: 22),
          tooltip: 'Chat history',
          onPressed: _openHistory,
        ),
        IconButton(
          icon: const Icon(Icons.tune_rounded, size: 22),
          tooltip: 'Tutor preferences',
          onPressed: _openPreferences,
        ),
        if (_manager.messages.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            tooltip: 'New conversation',
            onPressed: () => showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Start new conversation?'),
                content:
                    const Text('This will clear your current chat history.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _manager.newConversation();
                    },
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBody() {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        AiTutorHeader(
          studyMode: _manager.studyMode,
          modes: _modes,
          modeHint: modeHint(_manager.studyMode),
          snapshotLoading: _manager.snapshotLoading,
          topicStates: _manager.topicStates,
          memories: _manager.memories,
          activePlan: _manager.activePlan,
          reviewCount: _manager.reviewCount,
          showInsights: _manager.showInsights,
          onModeSelect: _manager.setStudyMode,
          onGeneratePlan: () => _manager.createAdaptivePlan(_msgCtrl.text),
          onToggleInsights: _manager.toggleInsights,
        ),
        Expanded(
          child: AiTutorMessageList(
            messages: _manager.messages,
            streaming: _manager.streaming,
            streamingText: _manager.streamingText,
            cursorAnim: _cursorAnim,
            dark: dark,
            scrollCtrl: _scrollCtrl,
            suggestions: _manager.messages.isEmpty
                ? suggestionsForMode(_manager.studyMode)
                : const [],
            onSuggestion: _send,
          ),
        ),
        if (_manager.sending && !_manager.streaming) const AiTypingIndicator(),
        AiTutorInputBar(
          ctrl: _msgCtrl,
          sending: _manager.sending,
          placeholder: modePlaceholder(_manager.studyMode),
          suggestions: _manager.messages.isEmpty
              ? suggestionsForMode(_manager.studyMode)
              : const [],
          onSend: _send,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: _buildAppBar(),
        body: _buildBody(),
      );
}
