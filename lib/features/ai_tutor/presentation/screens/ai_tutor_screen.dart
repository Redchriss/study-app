import 'dart:convert';
import 'package:flutter/material.dart';
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
  bool _profileLoading = true;
  bool _profileSaving = false;
  bool _snapshotLoading = true;
  List<Map<String, dynamic>> _topicStates = [];
  List<Map<String, dynamic>> _memories = [];
  Map<String, dynamic>? _activePlan;
  int _reviewCount = 0;
  late final http.Client _httpClient;
  late final AnimationController _cursorCtrl;
  late final Animation<double> _cursorAnim;

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

  Future<String?> _getToken() async {
    return SecureStorage.getToken();
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();

    setState(() {
      _messages.add({'messageText': text, 'displayText': text, 'isUser': true, 'timestamp': DateTime.now().toIso8601String()});
      _sending = true;
      _streaming = true;
      _streamingText = '';
    });
    _scrollDown();

    final token = await _getToken();
    if (token == null) { setState(() { _sending = false; _streaming = false; }); return; }

    try {
      final request = http.StreamedRequest('POST', Uri.parse('${AppConfig.apiUrl}/ai/stream/'));
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tutor response ended unexpectedly. Please try again.'),
            backgroundColor: DesignTokens.error,
          ),
        );
      } else {
        _loadTutorSnapshot();
        _scrollDown();
      }
    } catch (e) {
      if (mounted) {
        setState(() { _sending = false; _streaming = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection lost: $e'), backgroundColor: DesignTokens.error),
        );
      }
    }
  }

  Future<void> _loadLearningProfile() async {
    try {
      final client = ref.read(graphqlClientProvider);
      final result = await client.query(
        QueryOptions(document: gql(kLearningProfile), fetchPolicy: FetchPolicy.networkOnly),
      );
      final profile = result.data?['learningProfile'] as Map<String, dynamic>?;
      if (!mounted) return;
      setState(() {
        _learningStyle = profile?['learningStyle']?.toString().trim().isNotEmpty == true
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
        QueryOptions(document: gql(kTutorSnapshot), fetchPolicy: FetchPolicy.networkOnly),
      );
      final snapshot = result.data?['tutorSnapshot'] as Map<String, dynamic>?;
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

  Future<void> _createAdaptivePlan() async {
    final client = ref.read(graphqlClientProvider);
    final result = await client.mutate(
      MutationOptions(
        document: gql(kCreateAdaptiveStudyPlan),
        variables: {
          'goal': _msgCtrl.text.trim().isEmpty ? null : _msgCtrl.text.trim(),
          'subjectName': _topicStates.isNotEmpty ? _topicStates.first['subjectName']?.toString() : null,
          'studyMode': _studyMode,
        },
      ),
    );
    final payload = result.data?['createAdaptiveStudyPlan'] as Map<String, dynamic>?;
    if (!mounted) return;
    if (payload?['success'] == true && payload?['plan'] is Map) {
      setState(() {
        _activePlan = Map<String, dynamic>.from(payload!['plan'] as Map);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adaptive study plan updated.')),
      );
      await _loadTutorSnapshot();
      return;
    }
    final errors = (payload?['errors'] as List?)?.map((item) => item.toString()).join(', ');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(errors?.isNotEmpty == true ? errors! : 'Could not build a study plan.')),
    );
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
      final payload = result.data?['updateLearningProfile'] as Map<String, dynamic>?;
      final errors = (payload?['errors'] as List?)?.whereType<String>().toList() ?? const <String>[];
      if (result.hasException || payload?['success'] != true) {
        final message = errors.firstOrNull ??
            result.exception?.graphqlErrors.firstOrNull?.message ??
            'Could not save tutor preferences.';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: DesignTokens.error),
          );
        }
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
      if (mounted) {
        setState(() => _profileSaving = false);
      }
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
        return const [
          'Quiz me on photosynthesis',
          'Ask me 5 biology revision questions',
          'Test me on algebra step by step',
        ];
      case 'plan':
        return const [
          'Make me a 30-minute revision plan',
          'Plan my study for tomorrow',
          'What should I study first for exams?',
        ];
      case 'memorize':
        return const [
          'Help me memorize the parts of the heart',
          'Give me a mnemonic for acids and bases',
          'Turn this topic into fast recall cues',
        ];
      case 'revise':
        return const [
          'Give me a quick summary of respiration',
          'Create memory hooks for acids and bases',
          'Revise this topic fast',
        ];
      default:
        return const [
          'Explain fractions simply',
          'Help me understand osmosis',
          'Teach me this topic like a beginner',
        ];
    }
  }

  String _modeHint() {
    switch (_studyMode) {
      case 'quiz':
        return 'The tutor will test you one question at a time.';
      case 'plan':
        return 'The tutor will organize what to study and in what order.';
      case 'memorize':
        return 'The tutor will build mnemonics, memory hooks, and active recall prompts.';
      case 'revise':
        return 'The tutor will compress the topic into fast revision help.';
      default:
        return 'The tutor will explain first, then check understanding.';
    }
  }

  String _detailLabel() {
    switch (_detailLevel) {
      case 1:
        return 'Short';
      case 3:
        return 'Deep';
      default:
        return 'Balanced';
    }
  }

  List<String> _profilePills() {
    return <String>[
      _learningStyle[0].toUpperCase() + _learningStyle.substring(1),
      _detailLabel(),
      if (_prefersStepByStep) 'Step by step',
      if (_prefersExamples) 'Examples',
    ];
  }

  Future<void> _sendSuggestion(String suggestion) async {
    _msgCtrl.text = suggestion;
    await _send();
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
            _messages.add({'messageText': _streamingText, 'isUser': false, 'timestamp': DateTime.now().toIso8601String()});
            _streamingText = '';
            _sending = false;
            _streaming = false;
          });
          _loadTutorSnapshot();
          _scrollDown();
          break;
        case 'meta':
          if (payload['session_id'] != null) _sessionId = payload['session_id'].toString();
          break;
        case 'error':
          setState(() { _sending = false; _streaming = false; _streamingText = ''; });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(payload['message'] ?? 'Error'), backgroundColor: DesignTokens.error),
            );
          }
          break;
      }
    } catch (_) {
      debugPrint('AI Tutor: failed to parse SSE event: $type $data');
    }
  }

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted && _scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 100), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Tutor', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, size: 20),
            tooltip: 'Tutor preferences',
            onPressed: _openPreferences,
          ),
          if (_messages.isNotEmpty)
            IconButton(icon: const Icon(Icons.refresh, size: 20),
              onPressed: () => setState(() { _sessionId = null; _messages.clear(); })),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spMd, vertical: DesignTokens.spXs),
            color: DesignTokens.primary.withValues(alpha: 0.05),
            child: const Row(children: [
              Icon(Icons.auto_awesome, size: 14, color: DesignTokens.primary),
              SizedBox(width: 6),
              Text('Powered by Gemini', style: TextStyle(color: DesignTokens.textSecondary, fontSize: 12)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AiTutorModeBar(
                  selectedMode: _studyMode,
                  modes: const [
                    ('coach', 'Coach', Icons.school_outlined),
                    ('quiz', 'Quiz Me', Icons.quiz_outlined),
                    ('revise', 'Revise', Icons.bolt_outlined),
                    ('memorize', 'Memorize', Icons.psychology_alt_outlined),
                    ('plan', 'Plan', Icons.event_note_outlined),
                  ],
                  onSelect: (mode) => setState(() => _studyMode = mode),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark ? DesignTokens.darkSurfaceVariant : DesignTokens.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _modeHint(),
                    style: const TextStyle(
                      fontSize: 13,
                      color: DesignTokens.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (_profileLoading)
                      const Chip(
                        avatar: SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        label: Text('Loading tutor profile'),
                      )
                    else
                      ..._profilePills().map((item) => Chip(label: Text(item))),
                  ],
                ),
                const SizedBox(height: 10),
                if (_snapshotLoading)
                  const LinearProgressIndicator(minHeight: 3)
                else
                  AiTutorSnapshotCards(
                    reviewCount: _reviewCount,
                    topicStates: _topicStates,
                    memories: _memories,
                    planSummary: _activePlan?['planSummary']?.toString(),
                    onGeneratePlan: _createAdaptivePlan,
                  ),
              ],
            ),
          ),
          Expanded(
            child: _messages.isEmpty && !_streaming
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.smart_toy_outlined, size: 80, color: DesignTokens.primary.withValues(alpha: 0.3)),
                  const SizedBox(height: DesignTokens.spMd),
                  const Text('Use a study mode, then start with one focused prompt', style: TextStyle(color: DesignTokens.textSecondary)),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: _suggestionsForMode().map((item) {
                        return ActionChip(
                          label: Text(item),
                          onPressed: () => _sendSuggestion(item),
                        );
                      }).toList(),
                    ),
                  ),
                ]))
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(DesignTokens.spMd),
                  itemCount: _messages.length + (_streaming ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (_streaming && i == _messages.length) {
                      return _buildAiMessage(_streamingText, true, dark);
                    }
                    final msg = _messages[i];
                    final isUser = msg['isUser'] == true;
                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                        margin: const EdgeInsets.only(bottom: DesignTokens.spXs),
                        padding: const EdgeInsets.all(DesignTokens.spMd),
                        decoration: BoxDecoration(
                          color: isUser ? DesignTokens.primary : (dark ? DesignTokens.darkSurfaceVariant : DesignTokens.surfaceVariant),
                          borderRadius: BorderRadius.circular(DesignTokens.radiusLg).copyWith(
                            bottomRight: isUser ? const Radius.circular(4) : null,
                            bottomLeft: !isUser ? const Radius.circular(4) : null,
                          ),
                        ),
                        child: Text((msg['displayText'] ?? msg['messageText'] ?? '').toString(), style: TextStyle(color: isUser ? Colors.white : null, fontSize: 14)),
                      ),
                    );
                  },
                ),
          ),
          if (_sending && !_streaming)
            _buildTypingIndicator(),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(DesignTokens.spSm),
              child: Column(
                children: [
                  SizedBox(
                    height: 34,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _suggestionsForMode().length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final item = _suggestionsForMode()[i];
                        return ActionChip(
                          label: Text(item, style: const TextStyle(fontSize: 12)),
                          onPressed: _sending ? null : () => _sendSuggestion(item),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _msgCtrl,
                        decoration: InputDecoration(
                          hintText: 'Type your study request...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusXl)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: DesignTokens.spMd, vertical: DesignTokens.spSm - 2),
                          isDense: true,
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sending ? null : _send(),
                      ),
                    ),
                    const SizedBox(width: DesignTokens.spXs),
                    AnimatedPress(
                      onTap: _sending ? null : _send,
                      child: const SizedBox(
                        width: 48,
                        height: 48,
                        child: DecoratedBox(
                          decoration: BoxDecoration(color: DesignTokens.primary, shape: BoxShape.circle),
                          child: Icon(Icons.send, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiMessage(String text, bool streaming, bool dark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        margin: const EdgeInsets.only(bottom: DesignTokens.spXs),
        padding: const EdgeInsets.all(DesignTokens.spMd),
        decoration: BoxDecoration(
          color: dark ? DesignTokens.darkSurfaceVariant : DesignTokens.surfaceVariant,
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg).copyWith(
            bottomLeft: const Radius.circular(4),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(text, style: const TextStyle(fontSize: 14)),
            ),
            if (streaming)
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: FadeTransition(
                  opacity: _cursorAnim,
                  child: Container(
                    width: 8, height: 16,
                    color: DesignTokens.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _dot(0),
          const SizedBox(width: 4),
          _dot(200),
          const SizedBox(width: 4),
          _dot(400),
          const SizedBox(width: 6),
          const Text('Thinking', style: TextStyle(color: DesignTokens.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _dot(int delay) {
    return delay == 0
        ? const _Dot(0)
        : _Dot(delay);
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot(this.delay);
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _ctrl.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 8, height: 8,
        decoration: const BoxDecoration(
          color: DesignTokens.primary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
