import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import 'study_pack_data.dart';

/// Opens the study-pack viewer: lesson → quiz → flashcards for a material.
Future<void> showStudyPackSheet(
  BuildContext context, {
  required StudyPackData pack,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => StudyPackSheet(pack: pack),
  );
}

class StudyPackSheet extends StatelessWidget {
  const StudyPackSheet({super.key, required this.pack});

  final StudyPackData pack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: DesignTokens.background,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusXxl)),
          ),
          child: Column(
            children: [
              const SizedBox(height: DesignTokens.spSm),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: DesignTokens.borderLight,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(DesignTokens.spMd),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: DesignTokens.brandGradient,
                        borderRadius:
                            BorderRadius.circular(DesignTokens.radiusMd),
                      ),
                      child: const Icon(Icons.auto_stories_rounded,
                          color: Colors.white),
                    ),
                    const SizedBox(width: DesignTokens.spMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Your Study Pack',
                              style: theme.textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800)),
                          Text(
                            'A lesson, a quiz, and flashcards — built for you.',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: DesignTokens.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(
                      DesignTokens.spMd, 0, DesignTokens.spMd, DesignTokens.spXl),
                  children: [
                    _sectionTitle(theme, 'Lesson', Icons.menu_book_rounded),
                    const SizedBox(height: DesignTokens.spSm),
                    if (pack.lesson.isEmpty)
                      Text('No lesson chunks were generated.',
                          style: theme.textTheme.bodySmall)
                    else
                      for (var i = 0; i < pack.lesson.length; i++) ...[
                        _LessonChunkCard(
                          index: i + 1,
                          chunk: pack.lesson[i],
                        ),
                        const SizedBox(height: DesignTokens.spSm),
                      ],
                    const SizedBox(height: DesignTokens.spMd),
                    _sectionTitle(theme, 'Quiz', Icons.quiz_rounded),
                    const SizedBox(height: DesignTokens.spSm),
                    _QuizCard(pack: pack),
                    const SizedBox(height: DesignTokens.spMd),
                    _sectionTitle(theme, 'Flashcards', Icons.style_rounded),
                    const SizedBox(height: DesignTokens.spSm),
                    if (!pack.hasFlashcards)
                      Text('No flashcards were generated.',
                          style: theme.textTheme.bodySmall)
                    else
                      for (final card in pack.flashcards) ...[
                        _FlashcardTile(card: card),
                        const SizedBox(height: DesignTokens.spXs),
                      ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionTitle(ThemeData theme, String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: DesignTokens.primary),
        const SizedBox(width: 8),
        Text(label,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _LessonChunkCard extends StatelessWidget {
  const _LessonChunkCard({required this.index, required this.chunk});

  final int index;
  final StudyPackLessonChunk chunk;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: DesignTokens.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('$index',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: DesignTokens.primary,
                        fontSize: 13)),
              ),
              const SizedBox(width: DesignTokens.spSm),
              Expanded(
                child: Text(
                  chunk.heading.isEmpty ? 'Key idea $index' : chunk.heading,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spXs),
          Text(chunk.body,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4)),
        ],
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  const _QuizCard({required this.pack});

  final StudyPackData pack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!pack.hasQuiz) {
      return Text('No quiz is linked to this pack.',
          style: theme.textTheme.bodySmall);
    }
    return AnimatedPress(
      onTap: () {
        Navigator.of(context).pop();
        context.push('/quiz/${pack.quizSlug}');
      },
      child: GlassCard(
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: DesignTokens.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: DesignTokens.accent),
            ),
            const SizedBox(width: DesignTokens.spMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pack.quizTitle.isEmpty ? 'Practice quiz' : pack.quizTitle,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${pack.quizQuestionCount} questions · tap to start',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: DesignTokens.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: DesignTokens.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _FlashcardTile extends StatelessWidget {
  const _FlashcardTile({required this.card});

  final StudyPackFlashcard card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: DesignTokens.spXs),
        shape: const Border(),
        title: Text(card.front,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(card.back,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: DesignTokens.textSecondary)),
          ),
        ],
      ),
    );
  }
}

/// Status card shown in the material detail body. Drives the
/// generating → ready states with a retry on failure.
class StudyPackCard extends StatelessWidget {
  const StudyPackCard({
    super.key,
    required this.pack,
    required this.isGenerating,
    required this.hasFailed,
    required this.statusLabel,
    required this.onGenerate,
    required this.onOpen,
  });

  final StudyPackData? pack;
  final bool isGenerating;
  final bool hasFailed;
  final String statusLabel;
  final VoidCallback? onGenerate;
  final VoidCallback? onOpen;

  bool get isReady => pack != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const Key('study_pack_card'),
      padding: const EdgeInsets.all(DesignTokens.spMd),
      decoration: BoxDecoration(
        gradient: DesignTokens.brandGradient,
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        boxShadow: DesignTokens.shadowMd(false),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                ),
                child: const Icon(Icons.auto_stories_rounded,
                    color: Colors.white),
              ),
              const SizedBox(width: DesignTokens.spMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI Study Pack',
                        style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                      _subtitle(),
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spMd),
          _buildAction(theme),
        ],
      ),
    );
  }

  String _subtitle() {
    if (isReady) return 'Lesson, quiz & flashcards are ready to study.';
    if (isGenerating) {
      return statusLabel.isNotEmpty
          ? statusLabel
          : 'Building your lesson, quiz, and flashcards…';
    }
    if (hasFailed) {
      return 'That last attempt failed. Try again — no credit is charged for failures.';
    }
    return 'Turn this material into a lesson, quiz & flashcards · 1 credit.';
  }

  Widget _buildAction(ThemeData theme) {
    if (isReady) {
      return _FilledPill(
        key: const Key('study_pack_open'),
        label: 'Open Study Pack',
        icon: Icons.arrow_forward_rounded,
        onTap: onOpen,
      );
    }
    if (isGenerating) {
      return Row(
        key: const Key('study_pack_generating'),
        children: const [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          SizedBox(width: DesignTokens.spSm),
          Text('Generating…',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      );
    }
    return _FilledPill(
      key: const Key('study_pack_generate'),
      label: hasFailed ? 'Try again' : 'Make Study Pack',
      icon: hasFailed ? Icons.refresh_rounded : Icons.auto_awesome_rounded,
      onTap: onGenerate,
    );
  }
}

class _FilledPill extends StatelessWidget {
  const _FilledPill({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: DesignTokens.primary),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      color: DesignTokens.primary,
                      fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}
