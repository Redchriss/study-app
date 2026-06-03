import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

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
