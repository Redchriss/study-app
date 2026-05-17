import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http/http.dart' as http;
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/ai_tutor_preferences_sheet.dart';
import '../widgets/ai_tutor_header.dart';
import '../widgets/ai_tutor_bubbles.dart';
import '../widgets/ai_tutor_empty_state.dart';
import '../widgets/ai_tutor_input_bar.dart';

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
      });
    } catch (_) {
      if (!mounted) return;
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
          AiTutorHeader(
            studyMode: _studyMode,
            modes: _modes,
            modeHint: _modeHint(),
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
                ? AiTutorEmptyState(
                    suggestions: _suggestionsForMode(),
                    onSuggestion: (s) => _send(s),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: _messages.length + (_streaming ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (_streaming && i == _messages.length) {
                        return AiAssistantBubble(
                          text: _streamingText,
                          streaming: true,
                          cursorAnim: _cursorAnim,
                          dark: dark,
                        );
                      }
                      final msg = _messages[i];
                      final isUser = msg['isUser'] == true;
                      return isUser
                          ? AiUserBubble(text: (msg['displayText'] ?? msg['messageText'] ?? '').toString())
                          : AiAssistantBubble(
                              text: (msg['messageText'] ?? '').toString(),
                              streaming: false,
                              cursorAnim: _cursorAnim,
                              dark: dark,
                            );
                    },
                  ),
          ),

          if (_sending && !_streaming) const AiTypingIndicator(),

          AiTutorInputBar(
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
