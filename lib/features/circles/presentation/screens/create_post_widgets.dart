import 'dart:io';
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

class PollDurationSelector extends StatefulWidget {
  final List<TextEditingController> options;
  final int duration;
  final VoidCallback onAddOption;
  final void Function(int) onRemoveOption;
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
  State<PollDurationSelector> createState() => _PollDurationSelectorState();
}

class _PollDurationSelectorState extends State<PollDurationSelector> {
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 8),
      ...widget.options.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: e.key,
                  child: const Icon(Icons.drag_handle,
                      color: DesignTokens.textTertiary),
                ),
                const SizedBox(width: 4),
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
                if (widget.options.length > 2)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    onPressed: () => widget.onRemoveOption(e.key),
                  ),
              ],
            ),
          )),
      OutlinedButton.icon(
        onPressed: widget.options.length < 6 ? widget.onAddOption : null,
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Add option'),
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<int>(
        value: widget.duration,
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
          if (v != null) widget.onDurationChanged(v);
        },
      ),
    ]);
  }
}

class GalleryItem {
  final String imageBase64;
  final String imagePath;
  final TextEditingController captionCtrl;

  GalleryItem({
    required this.imageBase64,
    required this.imagePath,
    required this.captionCtrl,
  });
}

class GalleryPicker extends StatelessWidget {
  final List<GalleryItem> items;
  final VoidCallback onPick;
  final ValueChanged<int> onRemove;
  final void Function(int, int)? onReorder;

  const GalleryPicker({
    super.key,
    required this.items,
    required this.onPick,
    required this.onRemove,
    this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 8),
      if (items.isNotEmpty)
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          onReorder: onReorder ?? (_, __) {},
          proxyDecorator: (child, _, __) => Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(8),
              child: child),
          itemBuilder: (_, i) => Padding(
            key: ValueKey('gallery_$i'),
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ReorderableDragStartListener(
                index: i,
                child: const Icon(Icons.drag_handle,
                    color: DesignTokens.textTertiary),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(File(items[i].imagePath),
                    width: 60, height: 60, fit: BoxFit.cover),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: items[i].captionCtrl,
                  decoration: InputDecoration(
                    labelText: 'Caption ${i + 1}',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline,
                    size: 20, color: DesignTokens.error),
                onPressed: () => onRemove(i),
              ),
            ]),
          ),
        ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: items.length < 20 ? onPick : null,
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: Text(items.isNotEmpty
            ? 'Add more (${items.length}/20)'
            : 'Select images'),
      ),
    ]);
  }
}
