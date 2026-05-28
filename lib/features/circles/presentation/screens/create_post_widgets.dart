import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
export 'create_post_community_widgets.dart';

const kPostTypes = [
  {'key': 'text', 'icon': '📝', 'label': 'Text'},
  {'key': 'link', 'icon': '🔗', 'label': 'Link'},
  {'key': 'image', 'icon': '🖼', 'label': 'Image'},
  {'key': 'gallery', 'icon': '🎠', 'label': 'Gallery'},
  {'key': 'video', 'icon': '🎬', 'label': 'Video'},
  {'key': 'poll', 'icon': '📊', 'label': 'Poll'},
];

class PostTypeSelector extends StatelessWidget {
  final List<Map<String, String>> postTypes;
  final String selected;
  final ValueChanged<String> onChanged;
  const PostTypeSelector({
    super.key,
    required this.postTypes,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: postTypes.map((t) {
        final sel = selected == t['key'];
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text('${t['icon']} ${t['label']}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              selected: sel,
              onSelected: (_) => onChanged(t['key']!),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class MarkdownToolbar extends StatelessWidget {
  final void Function(String, String) onInsert;
  const MarkdownToolbar({super.key, required this.onInsert});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: DesignTokens.border),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _btn('B', Icons.format_bold, true, () => onInsert('**', '**')),
            _btn('I', Icons.format_italic, false, () => onInsert('*', '*')),
            _btn('', Icons.link, false, () => onInsert('[', '](url)')),
            _btn('', Icons.code, false, () => onInsert('`', '`')),
            _btn('', Icons.format_quote, false, () => onInsert('> ', '')),
            _btn('', Icons.format_list_bulleted, false, () => onInsert('- ', '')),
            _btn('', Icons.visibility_off, false, () => onInsert('||', '||')),
          ],
        ),
      ),
    );
  }

  Widget _btn(String label, IconData icon, bool isBold, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: DesignTokens.border)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: DesignTokens.textSecondary),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 2),
              Text(label, style: TextStyle(
                fontSize: 12,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.normal,
                color: DesignTokens.textSecondary,
              )),
            ],
          ],
        ),
      ),
    );
  }
}

class LinkPreviewFetcher extends StatelessWidget {
  final TextEditingController urlCtrl;
  final ValueChanged<String> onUrlChanged;
  final String? previewTitle;
  final String? previewThumbnail;
  final String? previewDescription;
  const LinkPreviewFetcher({
    super.key,
    required this.urlCtrl,
    required this.onUrlChanged,
    this.previewTitle,
    this.previewThumbnail,
    this.previewDescription,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: urlCtrl,
          decoration: const InputDecoration(
            labelText: 'URL',
            border: OutlineInputBorder(),
            hintText: 'https://...',
          ),
          onChanged: onUrlChanged,
        ),
        if (previewTitle != null)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DesignTokens.border),
              color: DesignTokens.surfaceVariant,
            ),
            child: Row(
              children: [
                if (previewThumbnail != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(previewThumbnail!,
                        width: 40, height: 40, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(previewTitle ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      if (previewDescription != null)
                        Text(previewDescription!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: DesignTokens.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class PollDurationSelector extends StatelessWidget {
  final List<TextEditingController> options;
  final int duration;
  final VoidCallback onAddOption;
  final ValueChanged<int> onRemoveOption;
  final ValueChanged<int> onDurationChanged;
  const PollDurationSelector({
    super.key,
    required this.options,
    required this.duration,
    required this.onAddOption,
    required this.onRemoveOption,
    required this.onDurationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        ...options.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: e.value,
                      decoration: InputDecoration(
                        labelText: 'Option ${e.key + 1}',
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    onPressed: options.length > 2 ? () => onRemoveOption(e.key) : null,
                  ),
                ],
              ),
            )),
        OutlinedButton.icon(
          onPressed: options.length < 6 ? onAddOption : null,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add option'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          value: duration,
          decoration: const InputDecoration(
            labelText: 'Poll duration',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: const [
            DropdownMenuItem(value: 24, child: Text('1 day')),
            DropdownMenuItem(value: 72, child: Text('3 days')),
            DropdownMenuItem(value: 168, child: Text('7 days')),
          ],
          onChanged: (v) {
            if (v != null) onDurationChanged(v);
          },
        ),
      ],
    );
  }
}
