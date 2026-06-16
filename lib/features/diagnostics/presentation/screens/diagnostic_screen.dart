import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import 'package:studyapp/features/auth/presentation/providers/auth_provider.dart';

class DiagnosticScreen extends ConsumerStatefulWidget {
  final String subjectCode;

  const DiagnosticScreen({super.key, required this.subjectCode});

  @override
  ConsumerState<DiagnosticScreen> createState() => _DiagnosticScreenState();
}

class _DiagnosticScreenState extends ConsumerState<DiagnosticScreen>
    with SingleTickerProviderStateMixin {
  // Session state
  String? _sessionId;
  Map<String, dynamic>? _currentQuestion;
  List<Map<String, dynamic>> _answers = [];
  int _questionNumber = 0;
  bool _sessionComplete = false;
  bool _loading = true;
  String? _error;
  double? _finalAbilityTheta;
  double? _finalAbilitySe;

  // Animation
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  // Timer for response time tracking
  DateTime? _questionStartTime;
  Timer? _autoAdvanceTimer;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOutSine),
    );
    _startDiagnostic();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _autoAdvanceTimer?.cancel();
    super.dispose();
  }

  Future<void> _startDiagnostic() async {
    setState(() {
      _loading = true;
      _error = null;
      _questionNumber = 0;
      _answers = [];
      _sessionComplete = false;
    });

    try {
      final client = ref.read(graphqlClientProvider);
      final result = await client.mutate(
        MutationOptions(
          document: gql(kStartDiagnostic),
          variables: {'subjectCode': widget.subjectCode, 'scope': 'quick'},
        ),
      );

      if (result.hasException) {
        setState(() => _error = result.exception.toString());
        return;
      }

      final data = result.data?['startDiagnostic'] as Map<String, dynamic>?;
      if (data == null) {
        setState(() => _error = 'Could not start diagnostic.');
        return;
      }

      final session = data['session'] as Map<String, dynamic>?;
      final firstQuestion = data['firstQuestion'] as Map<String, dynamic>?;

      setState(() {
        _sessionId = session?['id']?.toString();
        _currentQuestion = firstQuestion;
        _loading = false;
      });

      _questionStartTime = DateTime.now();
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _submitAnswer(String? answerId, String? textAnswer) async {
    if (_sessionId == null || _currentQuestion == null) return;

    final elapsed = _questionStartTime != null
        ? DateTime.now().difference(_questionStartTime!).inMilliseconds
        : null;

    setState(() {
      _loading = true;
      _autoAdvanceTimer?.cancel();
    });

    try {
      final client = ref.read(graphqlClientProvider);
      final result = await client.mutate(
        MutationOptions(
          document: gql(kSubmitDiagnosticAnswer),
          variables: {
            'sessionId': _sessionId,
            'questionId': _currentQuestion!['id'].toString(),
            'answerId': answerId,
            'textAnswer': textAnswer ?? '',
            'responseTimeMs': elapsed,
          },
        ),
      );

      if (result.hasException) {
        setState(() => _error = result.exception.toString());
        return;
      }

      final response =
          result.data?['submitDiagnosticAnswer'] as Map<String, dynamic>?;
      if (response == null) return;

      final correct = response['correct'] as bool? ?? false;
      final nextQ = response['nextQuestion'] as Map<String, dynamic>?;
      final completed = response['sessionComplete'] as bool? ?? false;

      setState(() {
        _currentQuestion = nextQ;
        _questionNumber++;
        _sessionComplete = completed;
        _loading = false;

        if (completed) {
          _finalAbilityTheta = (response['abilityTheta'] as num?)?.toDouble();
          _finalAbilitySe = (response['abilitySe'] as num?)?.toDouble();
        }

        _answers.add({
          'correct': correct,
          'concept': (_currentQuestion?['conceptSlug'] ?? ''),
        });
      });

      _questionStartTime = DateTime.now();

      if (completed) {
        _autoAdvanceTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) {
            context.pushReplacement(
              '/knowledge-map',
              extra: {
                'subjectCode': widget.subjectCode,
                'theta': _finalAbilityTheta,
                'se': _finalAbilitySe,
              },
            );
          }
        });
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: dark ? DesignTokens.darkBackground : DesignTokens.background,
      appBar: AppBar(
        title: Text('Quick Diagnostic — ${widget.subjectCode}'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _buildBody(dark),
    );
  }

  Widget _buildBody(bool dark) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: DesignTokens.error),
              const SizedBox(height: 16),
              Text('Something went wrong', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: DesignTokens.textSecondary), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _startDiagnostic,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_loading && _currentQuestion == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_sessionComplete) {
      return _buildResults(dark);
    }

    return _buildQuestion(dark);
  }

  Widget _buildQuestion(bool dark) {
    final q = _currentQuestion;
    if (q == null) return const Center(child: Text('No question available'));

    final answers = (q['answers'] as List?) ?? [];
    final difficulty = (q['difficulty'] as num?)?.toDouble() ?? 0.0;
    final difficultyLabel = difficulty <= -1.0
        ? 'Easy'
        : difficulty <= 0.5
            ? 'Medium'
            : 'Hard';

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress indicator
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_questionNumber / 10).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: dark ? Colors.white12 : Colors.black12,
                    valueColor: const AlwaysStoppedAnimation<Color>(DesignTokens.primary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text('$_questionNumber/10',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),

          // Difficulty badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: difficulty <= 0
                      ? DesignTokens.success.withValues(alpha: 0.15)
                      : DesignTokens.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(difficultyLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: difficulty <= 0 ? DesignTokens.success : DesignTokens.warning,
                    )),
              ),
              const SizedBox(width: 8),
              if (q['conceptSlug'] != null && (q['conceptSlug'] as String).isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: DesignTokens.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(q['conceptSlug'],
                      style: TextStyle(
                          fontSize: 11,
                          color: DesignTokens.accent,
                          fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Question
          AnimatedSwitcher(
            duration: 200.ms,
            child: Container(
              key: ValueKey(_questionNumber),
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: dark ? DesignTokens.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: dark ? Colors.white12 : Colors.black12),
              ),
              child: Text(
                q['questionText'] as String? ?? '',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                    ),
              ),
            ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.1),
          ),
          const SizedBox(height: 24),

          // Answers
          Expanded(
            child: ListView.separated(
              itemCount: answers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final answer = answers[index] as Map<String, dynamic>;
                final letter = String.fromCharCode(65 + index);
                return AnimatedPress(
                  onTap: _loading
                      ? null
                      : () => _submitAnswer(answer['id']?.toString(), null),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: dark ? Colors.white12 : Colors.black12),
                      color: dark ? DesignTokens.darkSurface : Colors.white,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: DesignTokens.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(letter,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: DesignTokens.primary)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            answer['text'] as String? ?? '',
                            style: const TextStyle(fontSize: 15, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(bool dark) {
    final correctCount = _answers.where((a) => a['correct'] == true).length;
    final totalQ = _answers.length;
    final accuracy = totalQ > 0 ? (correctCount / totalQ * 100).round() : 0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated icon
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (context, child) => Transform.scale(
                scale: _pulseAnim.value,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: accuracy >= 70
                          ? [DesignTokens.success, const Color(0xFF27AE60)]
                          : [DesignTokens.warning, const Color(0xFFE67E22)],
                    ),
                  ),
                  child: Icon(
                    accuracy >= 70 ? Icons.emoji_events_rounded : Icons.trending_up_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Diagnostic Complete',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text('You answered $correctCount of $totalQ correctly',
                style: TextStyle(color: DesignTokens.textSecondary, fontSize: 16)),
            const SizedBox(height: 24),

            // Stats card
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _statRow('Accuracy', '$accuracy%', accuracy >= 60),
                    const Divider(height: 20),
                    _statRow('Ability (θ)', _finalAbilityTheta?.toStringAsFixed(2) ?? '-', true),
                    const Divider(height: 20),
                    _statRow('Std Error', _finalAbilitySe?.toStringAsFixed(3) ?? '-', _finalAbilitySe != null && _finalAbilitySe! < 0.5),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.pushReplacement(
                    '/knowledge-map',
                    extra: {
                      'subjectCode': widget.subjectCode,
                      'theta': _finalAbilityTheta,
                      'se': _finalAbilitySe,
                    },
                  );
                },
                icon: const Icon(Icons.map_rounded),
                label: const Text('View Knowledge Map'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Back to Dashboard'),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _statRow(String label, String value, bool good) {
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
        Text(value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: good ? DesignTokens.success : DesignTokens.warning,
            )),
      ],
    );
  }
}
