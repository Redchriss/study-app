import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import 'material_reader_models.dart';

class ReaderAnnotationDraft {
  const ReaderAnnotationDraft({required this.noteText, required this.color});
  final String noteText;
  final String color;
}

Color annotationColor(String? color) {
  switch (color) {
    case 'mint':
      return const Color(0xFF62C7A5);
    case 'sky':
      return const Color(0xFF6FA8FF);
    default:
      return const Color(0xFFEEC66D);
  }
}

Future<ReaderAnnotationDraft?> showReaderAnnotationComposer(
  BuildContext context, {
  required ReaderStudySelection selection,
}) {
  final noteCtrl = TextEditingController();
  String color = 'amber';
  return showModalBottomSheet<ReaderAnnotationDraft>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Save Highlight',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  selection.selectedText.trim().isEmpty
                      ? selection.anchorLabel
                      : selection.selectedText.trim(),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: DesignTokens.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final entry in const [
                      ('amber', Color(0xFFEEC66D)),
                      ('mint', Color(0xFF62C7A5)),
                      ('sky', Color(0xFF6FA8FF)),
                    ])
                      ChoiceChip(
                        label: Text(entry.$1),
                        selected: color == entry.$1,
                        onSelected: (_) =>
                            setModalState(() => color = entry.$1),
                        selectedColor: entry.$2.withValues(alpha: 0.22),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Your note',
                    hintText:
                        'Optional: add a memory hook, definition, or reminder.',
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(
                      ReaderAnnotationDraft(
                          noteText: noteCtrl.text.trim(), color: color),
                    ),
                    child: const Text('Save Annotation'),
                  ),
                ),
              ],
            );
          },
        ),
      );
    },
  ).whenComplete(noteCtrl.dispose);
}

Future<void> showReaderAnnotationsSheet(
  BuildContext context, {
  required List<ReaderAnnotationData> annotations,
  required Future<void> Function(ReaderAnnotationData annotation) onDelete,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (context, controller) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Saved Notes',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                if (annotations.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text(
                          'No annotations yet. Save highlights while reading to build your revision trail.'),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      controller: controller,
                      itemCount: annotations.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final annotation = annotations[index];
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: DesignTokens.border),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 10,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: annotationColor(annotation.color),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(annotation.displayAnchor,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700)),
                                    if (annotation.selectedText.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        annotation.selectedText,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            color: DesignTokens.textSecondary,
                                            height: 1.4),
                                      ),
                                    ],
                                    if (annotation.noteText.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(annotation.noteText),
                                    ],
                                    if (annotation.isHighlight) ...[
                                      const SizedBox(height: 6),
                                      const Text('Highlight only',
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color:
                                                  DesignTokens.textTertiary)),
                                    ],
                                  ],
                                ),
                              ),
                              IconButton(
                                  onPressed: () => onDelete(annotation),
                                  icon: const Icon(Icons.delete_outline)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      );
    },
  );
}
