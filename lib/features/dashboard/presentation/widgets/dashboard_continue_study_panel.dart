import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/study_progress_store.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

class DashboardContinueStudyPanel extends StatefulWidget {
  final StudyMaterialProgress? liveProgress;
  const DashboardContinueStudyPanel({super.key, this.liveProgress});

  @override
  State<DashboardContinueStudyPanel> createState() =>
      _DashboardContinueStudyPanelState();
}

class _DashboardContinueStudyPanelState
    extends State<DashboardContinueStudyPanel> {
  final StudyProgressStore _store = StudyProgressStore();
  Future<StudyMaterialProgress?>? _localFuture;

  @override
  void initState() {
    super.initState();
    if (widget.liveProgress == null) {
      _localFuture = _store.loadLastMaterial();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.liveProgress != null) {
      return _ContinueCard(progress: widget.liveProgress!);
    }

    if (_localFuture == null) return const SizedBox.shrink();

    return FutureBuilder<StudyMaterialProgress?>(
      future: _localFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: DesignTokens.spMd),
            child: ShimmerBox(height: 90, radius: 16),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return const SizedBox.shrink();
        }
        return _ContinueCard(progress: snapshot.data!)
            .animate()
            .fadeIn(delay: 200.ms);
      },
    );
  }
}

class _ContinueCard extends StatelessWidget {
  final StudyMaterialProgress progress;
  const _ContinueCard({required this.progress});

  IconData get _icon {
    switch (progress.contentType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'video':
        return Icons.play_circle_fill_rounded;
      default:
        return Icons.menu_book_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ratio = progress.completionRatio <= 0 ? 0.05 : progress.completionRatio;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          DesignTokens.spMd, 0, DesignTokens.spMd, DesignTokens.spMd),
      child: AnimatedPress(
        onTap: () => context.push('/materials/${progress.slug}/read'),
        child: Container(
          padding: const EdgeInsets.all(DesignTokens.spMd),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1B6CA8), Color(0xFF0D2E4A)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1B6CA8).withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: DesignTokens.spMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CONTINUE STUDYING',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      progress.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      progress.subjectName.isEmpty
                          ? progress.progressLabel
                          : '${progress.subjectName} \u00b7 ${progress.progressLabel}',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: ratio),
                              duration: DesignTokens.durSlow,
                              curve: Curves.easeOutCubic,
                              builder: (_, v, __) =>
                                  LinearProgressIndicator(
                                minHeight: 5,
                                value: v,
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.15),
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                        Color(0xFFFFD700)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${(ratio * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
