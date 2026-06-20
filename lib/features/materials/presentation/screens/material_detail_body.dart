import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../../../core/services/download_service.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import 'material_detail_widgets.dart';
import 'study_pack_sheet.dart';

class MaterialDetailBody extends StatelessWidget {
  final ThemeData theme;
  final Map<String, dynamic> m;
  final String slug;
  final String materialId;
  final bool offline;
  final bool lowDataMode;
  final String? aiTaskLoading;
  final void Function(String taskType)? onRequestAiTask;
  final bool supportsStudyMode;
  final bool hasYoutube;
  final ValueChanged<YoutubePlayerController>? onYoutubeControllerReady;

  const MaterialDetailBody({
    super.key,
    required this.theme,
    required this.m,
    required this.slug,
    required this.materialId,
    this.offline = false,
    required this.lowDataMode,
    this.aiTaskLoading,
    this.onRequestAiTask,
    required this.supportsStudyMode,
    required this.hasYoutube,
    this.onYoutubeControllerReady,
  });

  Map<String, dynamic>? get _studyPackTask {
    final tasks = (m['aiTasks'] as List?) ?? const [];
    for (final task in tasks) {
      if (task is Map && task['taskType'] == 'study_pack') {
        return Map<String, dynamic>.from(task);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final studyPack = StudyPackData.parse(m['studyPack']);
    final studyPackTask = _studyPackTask;
    final studyPackGenerating = aiTaskLoading == 'study_pack' ||
        studyPackTask?['isActive'] == true;
    final studyPackFailed = studyPackTask?['status'] == 'failed';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.spMd),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (offline)
          Container(
            margin: const EdgeInsets.only(bottom: DesignTokens.spMd),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DesignTokens.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: DesignTokens.warning.withValues(alpha: 0.2)),
            ),
            child: const Row(children: [
              Icon(Icons.offline_bolt_outlined,
                  color: DesignTokens.warning, size: 18),
              SizedBox(width: 10),
              Expanded(
                  child: Text(
                      'Showing cached material details while you are offline.',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700))),
            ]),
          ),
        GlassCard(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: DesignTokens.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(m['subject']?['name'] ?? '',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: DesignTokens.primary)),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: DesignTokens.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(m['contentType'] ?? '',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: DesignTokens.accent)),
            ),
          ]),
          if (m['description'] != null &&
              m['description'].toString().isNotEmpty) ...[
            const SizedBox(height: DesignTokens.spMd),
            Text(m['description']!, style: theme.textTheme.bodyMedium),
          ],
        ])),
        const SizedBox(height: DesignTokens.spMd),
        if (supportsStudyMode) ...[
          AnimatedPress(
            onTap: () => context.push('/materials/$slug/read'),
            child: GlassCard(
                child: Row(children: [
              Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                      color: DesignTokens.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.chrome_reader_mode_rounded,
                      color: DesignTokens.success, size: 24)),
              const SizedBox(width: DesignTokens.spMd),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Study now',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    const Text(
                        'Open this material in a focused reader and continue where you left off.',
                        style: TextStyle(
                            fontSize: 12, color: DesignTokens.textSecondary)),
                  ])),
              const Icon(Icons.chevron_right, color: DesignTokens.textTertiary),
            ])),
          ),
          const SizedBox(height: DesignTokens.spMd),
        ],
        if (hasYoutube && !lowDataMode)
          MaterialDetailYoutubePlayer(
              url: m['youtubeEmbedUrl'] as String? ?? '',
              onControllerReady: onYoutubeControllerReady!)
        else if (hasYoutube)
          GlassCard(
              child: Row(children: [
            const Icon(Icons.data_saver_on_outlined, color: DesignTokens.info),
            const SizedBox(width: DesignTokens.spSm),
            Expanded(
                child: Text(
                    'Video preview is hidden in low-data mode. Open Study now when you are ready.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: DesignTokens.textSecondary))),
          ])),
        if (m['fileUrl'] != null) ...[
          const SizedBox(height: DesignTokens.spSm),
          AnimatedPress(
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              final url = m['fileUrl'] as String?;
              final name = m['title'] as String? ?? 'download';
              if (url == null) return;
              final fname =
                  '${name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')}.pdf';
              final path = await DownloadService.downloadFile(url, fname);
              if (path != null && context.mounted) {
                messenger.showSnackBar(const SnackBar(
                    content: Text('Saved to Downloads/Yaza/'),
                    backgroundColor: DesignTokens.success));
              } else if (context.mounted) {
                messenger.showSnackBar(const SnackBar(
                    content: Text('Download failed. Try again.'),
                    backgroundColor: DesignTokens.error));
              }
            },
            child: GlassCard(
                child: Row(children: [
              Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                      color: DesignTokens.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.download,
                      color: DesignTokens.primary, size: 22)),
              const SizedBox(width: DesignTokens.spSm),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Download',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                Text(('${m['contentType'] ?? ''} file').toUpperCase(),
                    style: const TextStyle(
                        fontSize: 11, color: DesignTokens.textTertiary)),
              ]),
            ])),
          ),
        ],
        if (materialId.isNotEmpty) ...[
          const SizedBox(height: DesignTokens.spMd),
          StudyPackCard(
            pack: studyPack,
            isGenerating: studyPackGenerating,
            hasFailed: studyPackFailed,
            statusLabel: studyPackTask?['statusLabel']?.toString() ?? '',
            onGenerate: () => onRequestAiTask?.call('study_pack'),
            onOpen: studyPack == null
                ? null
                : () => showStudyPackSheet(context, pack: studyPack),
          ),
        ],
        const SizedBox(height: DesignTokens.spMd),
        GlassCard(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('AI Tools',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: DesignTokens.spSm),
          Row(children: [
            MaterialDetailAiBtn(
                label: 'Flashcards',
                icon: Icons.style,
                cost: 1,
                loading: aiTaskLoading == 'flashcards',
                onTap: materialId.isNotEmpty
                    ? () => onRequestAiTask?.call('flashcards')
                    : null),
            const SizedBox(width: DesignTokens.spXs),
            MaterialDetailAiBtn(
                label: 'Summary',
                icon: Icons.summarize,
                cost: 1,
                loading: aiTaskLoading == 'summary',
                onTap: materialId.isNotEmpty
                    ? () => onRequestAiTask?.call('summary')
                    : null),
            const SizedBox(width: DesignTokens.spXs),
            MaterialDetailAiBtn(
                label: 'Quiz',
                icon: Icons.quiz,
                cost: 1,
                loading: aiTaskLoading == 'quiz',
                onTap: materialId.isNotEmpty
                    ? () => onRequestAiTask?.call('quiz')
                    : null),
          ]),
        ])),
        if (m['aiSummary'] != null && m['aiSummary'].toString().isNotEmpty) ...[
          const SizedBox(height: DesignTokens.spMd),
          GlassCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  const Icon(Icons.psychology_rounded,
                      size: 16, color: DesignTokens.warning),
                  const SizedBox(width: 6),
                  Text('AI Summary',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700))
                ]),
                const SizedBox(height: DesignTokens.spSm),
                Text(m['aiSummary']!, style: theme.textTheme.bodyMedium),
              ])),
        ],
      ]),
    );
  }
}
