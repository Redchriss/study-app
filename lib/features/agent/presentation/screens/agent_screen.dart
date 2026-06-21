import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../providers/agent_provider.dart';
import '../widgets/agent_app_bar.dart';
import '../widgets/agent_header.dart';
import '../widgets/agent_input_bar.dart';
import '../widgets/agent_preferences_sheet.dart';
import '../widgets/agent_typing_indicator.dart';
import 'agent_chat_widgets.dart';
import 'agent_error_bottom_sheet.dart';
import 'agent_mode_helpers.dart';
import 'coursework_export_sheet.dart';

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
    ('coursework', 'Coursework', Icons.article_rounded),
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

  void _openCourseworkExport() {
    // Collect drafted sections from conversation text items
    final state = ref.read(agentProvider);
    final sections = <Map<String, String>>[];
    String topic = 'Coursework';

    for (final item in state.conversationItems) {
      if (item is TextItem && !item.isUser) {
        final text = item.text;
        // Extract section titles from "Here is the draft for..." messages
        final titleMatch = RegExp(r'Here is the draft for "(.+?)"').firstMatch(text);
        if (titleMatch != null) {
          sections.add({
            'title': titleMatch.group(1)!,
            'content': text,
          });
        }
      }
    }

    // If no sections found, use all assistant messages
    if (sections.isEmpty) {
      for (final item in state.conversationItems) {
        if (item is TextItem && !item.isUser && item.text.length > 50) {
          sections.add({
            'title': 'Section ${sections.length + 1}',
            'content': item.text,
          });
        }
      }
    }

    if (sections.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No drafted sections to export yet.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => CourseworkExportSheet(
        topic: topic,
        deliverable: 'essay',
        referencing: '',
        sections: sections,
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
    final agentFreeRemaining =
        ref.watch(agentProvider.select((s) => s.agentFreeRemaining));
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
        if (sending) AgentTypingIndicator(freeRemaining: agentFreeRemaining),
        if (!sending && !streaming && items.isNotEmpty)
          AgentInputBar(
            ctrl: _msgCtrl,
            sending: sending,
            placeholder: modePlaceholder(studyMode),
            suggestions: const [],
            onSend: _send,
            onCancel: () => ref.read(agentProvider.notifier).cancel(),
          ),
        if (sending || streaming)
          AgentInputBar(
            ctrl: _msgCtrl,
            sending: true,
            placeholder: modePlaceholder(studyMode),
            suggestions: const [],
            onSend: _send,
            onCancel: () => ref.read(agentProvider.notifier).cancel(),
          ),
        if (items.isEmpty)
          AgentInputBar(
            ctrl: _msgCtrl,
            sending: sending,
            placeholder: modePlaceholder(studyMode),
            suggestions: suggestionsForMode(studyMode),
            onSend: _send,
            onCancel: () => ref.read(agentProvider.notifier).cancel(),
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
      floatingActionButton: studyMode == 'coursework' && items.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _openCourseworkExport,
              icon: const Icon(Icons.file_download_rounded, size: 18),
              label: const Text('Export',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            )
          : null,
    );
  }
}
