import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
export 'create_post_community_widgets.dart';
export 'create_post_poll_widgets.dart';
export 'create_post_gallery_widgets.dart';

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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: postTypes.map((t) {
          final sel = selected == t['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text('${t['icon']} ${t['label']}',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600)),
              selected: sel,
              onSelected: (_) => onChanged(t['key']!),
            ),
          );
        }).toList(),
      ),
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
            topLeft: Radius.circular(8), topRight: Radius.circular(8)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _btn(null, Icons.format_bold, () => onInsert('**', '**')),
            _btn(null, Icons.format_italic, () => onInsert('*', '*')),
            _btn(null, Icons.link, () => onInsert('[', '](url)')),
            _btn(null, Icons.code, () => onInsert('`', '`')),
            _btn(null, Icons.format_quote, () => onInsert('> ', '')),
            _btn(null, Icons.format_list_bulleted, () => onInsert('- ', '')),
            _btn(null, Icons.format_list_numbered, () => onInsert('1. ', '')),
            _btn(null, Icons.title, () => onInsert('## ', '')),
            _btn(null, Icons.table_chart_outlined, () => onInsert('| ', ' |')),
            _btn(null, Icons.visibility_off, () => onInsert('||', '||')),
          ],
        ),
      ),
    );
  }

  Widget _btn(String? label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: DesignTokens.border)),
        ),
        child: Icon(icon, size: 16, color: DesignTokens.textSecondary),
      ),
    );
  }
}

class LinkPreviewFetcher extends StatelessWidget {
  final TextEditingController urlCtrl;
  final ValueChanged<String> onUrlChanged;
  final String? previewTitle, previewThumbnail, previewDescription;
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
          keyboardType: TextInputType.url,
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
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                      if (previewDescription != null)
                        Text(previewDescription!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 11,
                                color: DesignTokens.textSecondary)),
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
