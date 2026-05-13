import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/design_tokens.dart';

/// Detail for a curated past paper from [kPastPapers] (matches web paper list / detail intent).
class PastPaperDetailScreen extends StatelessWidget {
  const PastPaperDetailScreen({super.key, required this.paper});

  final Map<String, dynamic> paper;

  Future<void> _openFile(BuildContext context) async {
    final raw = paper['fileUrl'] as String?;
    if (raw == null || raw.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No PDF file is linked for this paper yet.')),
        );
      }
      return;
    }
    final uri = Uri.tryParse(raw);
    if (uri == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid file link.')),
        );
      }
      return;
    }
    if (!await canLaunchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot open this link on this device.')),
        );
      }
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = paper['title']?.toString() ?? 'Past paper';
    final subject = paper['subject']?.toString() ?? '';
    final exam = paper['examType']?.toString() ?? '';
    final year = paper['year']?.toString() ?? '';
    final level = paper['educationLevel']?.toString() ?? '';
    final hasFile = (paper['fileUrl'] as String?)?.isNotEmpty == true;

    return Scaffold(
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: ListView(
        padding: const EdgeInsets.all(DesignTokens.spMd),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(DesignTokens.spMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Details', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: DesignTokens.spSm),
                  if (subject.isNotEmpty) _kv(context, 'Subject', subject),
                  if (exam.isNotEmpty) _kv(context, 'Exam', exam),
                  if (year.isNotEmpty) _kv(context, 'Year', year),
                  if (level.isNotEmpty) _kv(context, 'Level', level),
                  if (subject.isEmpty && exam.isEmpty && year.isEmpty && level.isEmpty)
                    Text('No extra metadata.', style: theme.textTheme.bodyMedium?.copyWith(color: DesignTokens.textSecondary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.spMd),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: hasFile ? () => _openFile(context) : null,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: Text(hasFile ? 'Open PDF' : 'PDF not available'),
            ),
          ),
          const SizedBox(height: DesignTokens.spSm),
          Text(
            'Opens in your browser or PDF app. You can also practice questions from similar papers in Quizzes.',
            style: theme.textTheme.bodySmall?.copyWith(color: DesignTokens.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _kv(BuildContext context, String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.spXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(k, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: DesignTokens.textSecondary)),
          ),
          Expanded(child: Text(v, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
