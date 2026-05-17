import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http/http.dart' as http;
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/ai_tutor_mode_bar.dart';
import '../widgets/ai_tutor_preferences_sheet.dart';
import '../widgets/ai_tutor_snapshot_cards.dart';

class AiTutorScreen extends ConsumerStatefulWidget {
  const AiTutorScreen({super.key});
  @override
  ConsumerState<AiTutorScreen> createState() => _AiTutorScreenState();
}

class _AiTutorScreenState extends ConsumerState<AiTutorScreen>
    with SingleTickerProviderStateMixin {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _messages = <Map<String, dynamic>>[];
  String? _sessionId;
  bool _sending = false;
  bool _streaming = false;
  String _streamingText = '';
  String _studyMode = 'coach';
  String _learningStyle = 'mixed';
  bool _prefersExamples = true;
  bool _prefersStepByStep = true;
  int _detailLevel = 2;
  bool _showInsights = false;

  void _toggleInsights() => setState(() => _showInsights = !_showInsights);
  bool _profileLoading = true;
  bool _profileSaving = false;
  bool _snapshotLoading = true;
  List<Map<String, dynamic>> _topicStates = [];
  List<Map<String, dynamic>> _memories = [];
  Map<String, dynamic>? _activePlan;
  int _reviewCount = 0;
  List<Map<String, dynamic>> _chatHistory = [];
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
    _loadLearningProfile();
    _loadTutorSnapshot();
  }

  @override
  void dispose() {
    _httpClient.close();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _cursorCtrl.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async => SecureStorage.getToken();

  Future<void> _send([String? overrideText]) async {
    final text = (overrideText ?? _msgCtrl.text).trim();
    if (text.isEmpty || _sending) return;
    if (overrideText == null) _msgCtrl.clear();

    setState(() {
      _messages.add({
        'messageText': text,
        'displayText': text,
        'isUser': true,
        'timestamp': DateTime.now().toIso8601String(),
      });
      _sending = true;
      _streaming = true;
      _streamingText = '';
    });
    _scrollDown();

    final token = await _getToken();
    if (token == null) {
      setState(() {
        _sending = false;
        _streaming = false;
      });
      return;
    }

    try {
      final request = http.StreamedRequest(
          'POST', Uri.parse('${AppConfig.apiUrl}/ai/stream/'));
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Content-Type'] = 'application/json';
      request.headers['Accept'] = 'text/event-stream';
      request.sink.add(utf8.encode(jsonEncode({
        'message': text,
        'session_id': _sessionId,
        'study_mode': _studyMode,
      })));
      request.sink.close();
      final response = await _httpClient.send(request);

      final lines = response.stream.transform(utf8.decoder);
      String eventType = '';
      StringBuffer dataBuffer = StringBuffer();

      await for (final chunk in lines) {
        for (final line in chunk.split('\n')) {
          if (line.startsWith('event: ')) {
            eventType = line.substring(7).trim();
            dataBuffer = StringBuffer();
          } else if (line.startsWith('data: ')) {
            dataBuffer.write(line.substring(6));
          } else if (line.isEmpty && eventType.isNotEmpty) {
            _handleEvent(eventType, dataBuffer.toString());
            eventType = '';
            dataBuffer = StringBuffer();
          }
        }
      }
      if (!mounted || !_streaming) return;
      final partialText = _streamingText.trim();
      setState(() {
        if (partialText.isNotEmpty) {
          _messages.add({
            'messageText': partialText,
            'isUser': false,
            'timestamp': DateTime.now().toIso8601String(),
          });
        }
        _streamingText = '';
        _sending = false;
        _streaming = false;
      });
      if (partialText.isEmpty) {
        _showError('Tutor response ended unexpectedly. Please try again.');
      } else {
        _loadTutorSnapshot();
        _scrollDown();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _sending = false;
          _streaming = false;
        });
        _showError('Connection lost. Please try again.');
      }
    }
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

  Future<void> _loadLearningProfile() async {
    try {
      final client = ref.read(graphqlClientProvider);
      final result = await client.query(
        QueryOptions(
            document: gql(kLearningProfile),
            fetchPolicy: FetchPolicy.networkOnly),
      );
      final profile =
          result.data?['learningProfile'] as Map<String, dynamic>?;
      if (!mounted) return;
      setState(() {
        _learningStyle =
            profile?['learningStyle']?.toString().trim().isNotEmpty == true
                ? profile!['learningStyle'].toString()
                : 'mixed';
        _prefersExamples = profile?['prefersExamples'] as bool? ?? true;
        _prefersStepByStep = profile?['prefersStepByStep'] as bool? ?? true;
        _detailLevel = profile?['detailLevel'] as int? ?? 2;
        _profileLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _profileLoading = false);
    }
  }

  Future<void> _loadTutorSnapshot() async {
    try {
      final client = ref.read(graphqlClientProvider);
      final result = await client.query(
        QueryOptions(
            document: gql(kTutorSnapshot),
            fetchPolicy: FetchPolicy.networkOnly),
      );
      final snapshot =
          result.data?['tutorSnapshot'] as Map<String, dynamic>?;
      if (!mounted) return;
      setState(() {
        _topicStates = ((snapshot?['topicStates'] as List?) ?? const [])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        _memories = ((snapshot?['memories'] as List?) ?? const [])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        _activePlan = snapshot?['latestPlan'] is Map
            ? Map<String, dynamic>.from(snapshot!['latestPlan'] as Map)
            : null;
        _reviewCount = (snapshot?['reviewCount'] as num?)?.toInt() ?? 0;
        _snapshotLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _snapshotLoading = false);
    }
  }

  Future<void> _loadChatHistory() async {
    try {
      final client = ref.read(graphqlClientProvider);
      final result = await client.query(QueryOptions(
        document: gql(kChatSessions),
        fetchPolicy: FetchPolicy.networkOnly,
      ));
      if (!mounted) return;
      final sessions = (result.data?['chatSessions'] as List?) ?? [];
      setState(() {
        _chatHistory = sessions.whereType<Map>().map((s) => Map<String, dynamic>.from(s)).toList();
      });
    } catch (_) {}
  }

  void _openHistory() async {
    await _loadChatHistory();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Row(
                children: [
                  const Icon(Icons.history_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text('Chat History', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            Expanded(
              child: _chatHistory.isEmpty
                  ? const Center(child: Text('No past sessions yet.', style: TextStyle(color: DesignTokens.textSecondary)))
                  : ListView.builder(
                      controller: scrollCtrl,
                      itemCount: _chatHistory.length,
                      itemBuilder: (_, i) {
                        final s = _chatHistory[i];
                        final updatedAt = s['updatedAt']?.toString() ?? '';
                        final dateLabel = updatedAt.length >= 10 ? updatedAt.substring(0, 10) : updatedAt;
                        return ListTile(
                          leading: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF7C4DFF), Color(0xFF1B6CA8)]),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 16),
                          ),
                          title: Text(s['title']?.toString() ?? 'Chat', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(dateLabel, style: const TextStyle(fontSize: 12, color: DesignTokens.textSecondary)),
                          onTap: () async {
                            Navigator.pop(ctx);
                            await _restoreSession(s['id'].toString());
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _restoreSession(String sessionId) async {
    try {
      final client = ref.read(graphqlClientProvider);
      final result = await client.query(QueryOptions(
        document: gql(kChatMessages),
        variables: {'sessionId': sessionId},
        fetchPolicy: FetchPolicy.networkOnly,
      ));
      if (!mounted) return;
      final msgs = (result.data?['chatMessages'] as List?) ?? [];
      setState(() {
        _sessionId = sessionId;
        _messages.clear();
        for (final m in msgs) {
          if (m is Map) _messages.add(Map<String, dynamic>.from(m));
        }
      });
      _scrollDown();
    } catch (_) {}
  }

  Future<void> _createAdaptivePlan() async {
    final client = ref.read(graphqlClientProvider);
    final result = await client.mutate(
      MutationOptions(
        document: gql(kCreateAdaptiveStudyPlan),
        variables: {
          'goal': _msgCtrl.text.trim().isEmpty ? null : _msgCtrl.text.trim(),
          'subjectName': _topicStates.isNotEmpty
              ? _topicStates.first['subjectName']?.toString()
              : null,
          'studyMode': _studyMode,
        },
      ),
    );
    final payload =
        result.data?['createAdaptiveStudyPlan'] as Map<String, dynamic>?;
    if (!mounted) return;
    if (payload?['success'] == true && payload?['plan'] is Map) {
      setState(() {
        _activePlan =
            Map<String, dynamic>.from(payload!['plan'] as Map);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adaptive study plan updated.')),
      );
      await _loadTutorSnapshot();
      return;
    }
    final errors = (payload?['errors'] as List?)
        ?.map((item) => item.toString())
        .join(', ');
    _showError(errors?.isNotEmpty == true ? errors! : 'Could not build a plan.');
  }

  Future<void> _saveLearningProfile({
    required String learningStyle,
    required bool prefersExamples,
    required bool prefersStepByStep,
    required int detailLevel,
  }) async {
    setState(() => _profileSaving = true);
    final client = ref.read(graphqlClientProvider);
    try {
      final result = await client.mutate(
        MutationOptions(
          document: gql(kUpdateLearningProfile),
          variables: {
            'learningStyle': learningStyle,
            'prefersExamples': prefersExamples,
            'prefersStepByStep': prefersStepByStep,
            'detailLevel': detailLevel,
          },
        ),
      );
      final payload =
          result.data?['updateLearningProfile'] as Map<String, dynamic>?;
      final errors = (payload?['errors'] as List?)
              ?.whereType<String>()
              .toList() ??
          const <String>[];
      if (result.hasException || payload?['success'] != true) {
        final message = errors.firstOrNull ??
            result.exception?.graphqlErrors.firstOrNull?.message ??
            'Could not save preferences.';
        if (mounted) _showError(message);
        return;
      }
      if (!mounted) return;
      setState(() {
        _learningStyle = learningStyle;
        _prefersExamples = prefersExamples;
        _prefersStepByStep = prefersStepByStep;
        _detailLevel = detailLevel;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tutor preferences updated.')),
      );
    } finally {
      if (mounted) setState(() => _profileSaving = false);
    }
  }

  Future<void> _openPreferences() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AiTutorPreferencesSheet(
          initialLearningStyle: _learningStyle,
          initialPrefersExamples: _prefersExamples,
          initialPrefersStepByStep: _prefersStepByStep,
          initialDetailLevel: _detailLevel,
          saving: _profileSaving,
          onSave: _saveLearningProfile,
        ),
      ),
    );
  }

  List<String> _suggestionsForMode() {
    switch (_studyMode) {
      case 'quiz':
        return [
          'Quiz me on photosynthesis',
          'Test me on Form 2 algebra',
          'Ask 5 MSCE revision questions',
        ];
      case 'plan':
        return [
          'Plan my revision for tomorrow',
          'Make a 30-minute study session',
          'What should I study first for exams?',
        ];
      case 'memorize':
        return [
          'Help me memorize the parts of the heart',
          'Give me a mnemonic for acids and bases',
          'Memory hooks for respiration steps',
        ];
      case 'revise':
        return [
          'Quick summary of respiration',
          'Key points for photosynthesis',
          'Revise this topic fast',
        ];
      default:
        return [
          'Explain fractions simply',
          'Help me understand osmosis',
          'What is Newton\'s 3rd law?',
        ];
    }
  }

  String _modePlaceholder() {
    switch (_studyMode) {
      case 'quiz':
        return 'Ask me a quiz question...';
      case 'plan':
        return 'Tell me your goal to plan...';
      case 'memorize':
        return 'What do you need to memorize?';
      case 'revise':
        return 'What topic to revise?';
      default:
        return 'Ask anything about your studies...';
    }
  }

  String _modeHint() {
    switch (_studyMode) {
      case 'quiz':
        return 'I\'ll test you one question at a time.';
      case 'plan':
        return 'I\'ll organize what to study and when.';
      case 'memorize':
        return 'I\'ll build mnemonics and memory hooks.';
      case 'revise':
        return 'I\'ll compress topics into fast revision.';
      default:
        return 'I\'ll explain, then check your understanding.';
    }
  }

  void _handleEvent(String type, String data) {
    if (!mounted) return;
    try {
      final payload = jsonDecode(data) as Map<String, dynamic>;
      switch (type) {
        case 'token':
          setState(() => _streamingText += payload['text'] as String? ?? '');
          _scrollDown();
          break;
        case 'done':
          setState(() {
            _messages.add({
              'messageText': _streamingText,
              'isUser': false,
              'timestamp': DateTime.now().toIso8601String(),
            });
            _streamingText = '';
            _sending = false;
            _streaming = false;
          });
          _loadTutorSnapshot();
          _scrollDown();
          break;
        case 'meta':
          if (payload['session_id'] != null) {
            _sessionId = payload['session_id'].toString();
          }
          break;
        case 'error':
          setState(() {
            _sending = false;
            _streaming = false;
            _streamingText = '';
          });
          _showError(payload['message'] ?? 'Something went wrong.');
          break;
      }
    } catch (_) {
      debugPrint('AI Tutor: failed to parse SSE event: $type $data');
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
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
          if (_messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 22),
              tooltip: 'New conversation',
              onPressed: () => showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Start new conversation?'),
                  content: const Text(
                      'This will clear your current chat history.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel')),
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _sessionId = null;
                          _messages.clear();
                        });
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Mode bar + compact insights toggle
          _CompactHeader(
            studyMode: _studyMode,
            modes: _modes,
            modeHint: _modeHint(),
            profileLoading: _profileLoading,
            learningStyle: _learningStyle,
            detailLevel: _detailLevel,
            prefersExamples: _prefersExamples,
            prefersStepByStep: _prefersStepByStep,
            snapshotLoading: _snapshotLoading,
            topicStates: _topicStates,
            memories: _memories,
            activePlan: _activePlan,
            reviewCount: _reviewCount,
            showInsights: _showInsights,
            onModeSelect: (m) => setState(() => _studyMode = m),
            onGeneratePlan: _createAdaptivePlan,
            onToggleInsights: _toggleInsights,
          ),

          // Chat area
          Expanded(
            child: _messages.isEmpty && !_streaming
                ? _EmptyState(
                    studyMode: _studyMode,
                    suggestions: _suggestionsForMode(),
                    onSuggestion: (s) => _send(s),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: _messages.length + (_streaming ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (_streaming && i == _messages.length) {
                        return _AiBubble(
                          text: _streamingText,
                          streaming: true,
                          cursorAnim: _cursorAnim,
                          dark: dark,
                        );
                      }
                      final msg = _messages[i];
                      final isUser = msg['isUser'] == true;
                      return isUser
                          ? _UserBubble(
                              text: (msg['displayText'] ?? msg['messageText'] ?? '').toString(),
                            )
                          : _AiBubble(
                              text: (msg['messageText'] ?? '').toString(),
                              streaming: false,
                              cursorAnim: _cursorAnim,
                              dark: dark,
                            );
                    },
                  ),
          ),

          // Typing indicator
          if (_sending && !_streaming) _TypingIndicator(),

          // Input bar — hide quick suggestions mid-conversation
          _InputBar(
            ctrl: _msgCtrl,
            sending: _sending,
            placeholder: _modePlaceholder(),
            suggestions: _messages.isEmpty ? _suggestionsForMode() : const [],
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

// ── Compact Header (replaces _ModeSection) ───────────────────────────────────
class _CompactHeader extends StatelessWidget {
  final String studyMode;
  final List<(String, String, IconData)> modes;
  final String modeHint;
  final bool profileLoading;
  final String learningStyle;
  final int detailLevel;
  final bool prefersExamples;
  final bool prefersStepByStep;
  final bool snapshotLoading;
  final List<Map<String, dynamic>> topicStates;
  final List<Map<String, dynamic>> memories;
  final Map<String, dynamic>? activePlan;
  final int reviewCount;
  final bool showInsights;
  final ValueChanged<String> onModeSelect;
  final VoidCallback onGeneratePlan;
  final VoidCallback onToggleInsights;

  const _CompactHeader({
    required this.studyMode,
    required this.modes,
    required this.modeHint,
    required this.profileLoading,
    required this.learningStyle,
    required this.detailLevel,
    required this.prefersExamples,
    required this.prefersStepByStep,
    required this.snapshotLoading,
    required this.topicStates,
    required this.memories,
    required this.activePlan,
    required this.reviewCount,
    required this.showInsights,
    required this.onModeSelect,
    required this.onGeneratePlan,
    required this.onToggleInsights,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final bg = dark ? DesignTokens.darkSurfaceVariant : DesignTokens.surfaceVariant;

    return Container(
      color: bg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mode bar + insights toggle on same row
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: AiTutorModeBar(
                    selectedMode: studyMode,
                    modes: modes,
                    onSelect: onModeSelect,
                  ),
                ),
                const SizedBox(width: 4),
                // Insights toggle chip
                GestureDetector(
                  onTap: onToggleInsights,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: showInsights
                          ? const Color(0xFF7C4DFF).withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: showInsights
                            ? const Color(0xFF7C4DFF)
                            : DesignTokens.textTertiary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.psychology_rounded,
                          size: 16,
                          color: showInsights ? const Color(0xFF7C4DFF) : DesignTokens.textSecondary,
                        ),
                        if (reviewCount > 0) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: DesignTokens.warning,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '$reviewCount',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Mode hint
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 6),
            child: Row(
              children: [
                Container(width: 5, height: 5, decoration: const BoxDecoration(color: Color(0xFF7C4DFF), shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(modeHint, style: theme.textTheme.bodySmall?.copyWith(color: DesignTokens.textSecondary, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          // Collapsible insights panel
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: showInsights && !snapshotLoading
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                    child: AiTutorSnapshotCards(
                      reviewCount: reviewCount,
                      topicStates: topicStates,
                      memories: memories,
                      planSummary: activePlan?['planSummary']?.toString(),
                      onGeneratePlan: onGeneratePlan,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String studyMode;
  final List<String> suggestions;
  final ValueChanged<String> onSuggestion;

  const _EmptyState({
    required this.studyMode,
    required this.suggestions,
    required this.onSuggestion,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF7C4DFF).withValues(alpha: 0.15),
                    const Color(0xFF1B6CA8).withValues(alpha: 0.15),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 38,
                color: Color(0xFF7C4DFF),
              ),
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 20),
            const Text(
              'What do you want to learn?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.2),
            const SizedBox(height: 8),
            const Text(
              'Tap a suggestion or type your own question.',
              style: TextStyle(color: DesignTokens.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ).animate(delay: 200.ms).fadeIn(),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: suggestions.map((s) {
                return ActionChip(
                  label: Text(s),
                  onPressed: () => onSuggestion(s),
                  avatar: const Icon(Icons.lightbulb_outline_rounded, size: 16),
                ).animate(delay: 300.ms).fadeIn().scale(begin: const Offset(0.9, 0.9));
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── User Bubble ───────────────────────────────────────────────────────────────
class _UserBubble extends StatelessWidget {
  final String text;
  const _UserBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        margin: const EdgeInsets.only(bottom: 10, left: 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1B6CA8), Color(0xFF7C4DFF)],
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).slideX(begin: 0.1);
  }
}

// ── AI Bubble ─────────────────────────────────────────────────────────────────
class _AiBubble extends StatelessWidget {
  final String text;
  final bool streaming;
  final Animation<double> cursorAnim;
  final bool dark;

  const _AiBubble({
    required this.text,
    required this.streaming,
    required this.cursorAnim,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI avatar
          Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.only(right: 8, top: 2),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C4DFF), Color(0xFF1B6CA8)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 14),
          ),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.78),
              margin: const EdgeInsets.only(bottom: 10, right: 48),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: dark
                    ? DesignTokens.darkSurfaceVariant
                    : DesignTokens.surfaceVariant,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
              ),
              child: text.isEmpty && streaming
                  ? const SizedBox(
                      width: 40,
                      child: LinearProgressIndicator(minHeight: 2),
                    )
                  : Stack(
                      children: [
                        MarkdownBody(
                          data: text,
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(fontSize: 14, height: 1.55),
                            code: TextStyle(
                              fontSize: 13,
                              fontFamily: 'monospace',
                              backgroundColor:
                                  dark ? Colors.black26 : const Color(0xFFEEF0F2),
                            ),
                            codeblockDecoration: BoxDecoration(
                              color: dark
                                  ? const Color(0xFF161B22)
                                  : const Color(0xFFEEF0F2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        if (streaming)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: FadeTransition(
                              opacity: cursorAnim,
                              child: Container(
                                width: 8,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7C4DFF),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
          // Copy button (for completed messages)
          if (!streaming && text.isNotEmpty)
            IconButton(
              iconSize: 16,
              icon: const Icon(Icons.copy_rounded),
              color: DesignTokens.textTertiary,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: text));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Copied to clipboard'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).slideX(begin: -0.05);
  }
}

// ── Typing Indicator ──────────────────────────────────────────────────────────
class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Row(
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
                color: Colors.white, size: 14),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: DesignTokens.surfaceVariant,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _BouncingDot(delay: 0),
                const SizedBox(width: 4),
                _BouncingDot(delay: 200),
                const SizedBox(width: 4),
                _BouncingDot(delay: 400),
                const SizedBox(width: 8),
                const Text(
                  'Thinking...',
                  style: TextStyle(
                    fontSize: 12,
                    color: DesignTokens.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BouncingDot extends StatefulWidget {
  final int delay;
  const _BouncingDot({required this.delay});

  @override
  State<_BouncingDot> createState() => _BouncingDotState();
}

class _BouncingDotState extends State<_BouncingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _anim = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _anim.value),
        child: Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: const Color(0xFF7C4DFF).withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

// ── Input Bar ─────────────────────────────────────────────────────────────────
class _InputBar extends StatelessWidget {
  final TextEditingController ctrl;
  final bool sending;
  final String placeholder;
  final List<String> suggestions;
  final void Function([String?]) onSend;

  const _InputBar({
    required this.ctrl,
    required this.sending,
    required this.placeholder,
    required this.suggestions,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Suggestions row
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: suggestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final s = suggestions[i];
                return ActionChip(
                  label: Text(s, style: const TextStyle(fontSize: 11)),
                  onPressed: sending ? null : () => onSend(s),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: dark ? DesignTokens.darkSurface : DesignTokens.surface,
              border: Border(
                top: BorderSide(
                  color: dark ? DesignTokens.darkBorder : DesignTokens.border,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 120),
                    child: TextField(
                      controller: ctrl,
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: placeholder,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: dark
                            ? DesignTokens.darkSurfaceVariant
                            : DesignTokens.surfaceVariant,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        isDense: true,
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) =>
                          sending ? null : onSend(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedPress(
                  onTap: sending ? null : () => onSend(),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: sending
                          ? null
                          : const LinearGradient(
                              colors: [Color(0xFF7C4DFF), Color(0xFF1B6CA8)],
                            ),
                      color: sending
                          ? DesignTokens.textTertiary.withValues(alpha: 0.3)
                          : null,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: sending
                        ? const Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.send_rounded,
                            color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
