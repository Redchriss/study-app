import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/graphql/queries/queries.dart';
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
  const GalleryPicker({
    super.key,
    required this.items,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        if (items.isNotEmpty)
          ...items.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(File(e.value.imagePath),
                          width: 60, height: 60, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: e.value.captionCtrl,
                        decoration: InputDecoration(
                          labelText: 'Caption ${e.key + 1}',
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
                      onPressed: () => onRemove(e.key),
                    ),
                  ],
                ),
              )),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: items.length < 20 ? onPick : null,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: Text(items.isNotEmpty ? 'Add more (${items.length}/20)' : 'Select images'),
        ),
      ],
    );
  }
}

class CommunityPicker extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onChanged;
  final ValueChanged<String?>? onFlairChanged;
  final String? flairId;
  const CommunityPicker({
    super.key,
    required this.selected,
    required this.onChanged,
    this.onFlairChanged,
    this.flairId,
  });

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(document: gql(kMyCommunities)),
      builder: (result, {fetchMore, refetch}) {
        final communities = (result.data?['myCommunities'] as List?) ?? [];
        final selectedCommunity = communities.firstWhere(
          (c) => c['slug'] == selected,
          orElse: () => null,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: selected,
              decoration: const InputDecoration(
                labelText: 'Community',
                border: OutlineInputBorder(),
              ),
              hint: const Text('Select community'),
              items: communities.map((c) {
                return DropdownMenuItem(
                  value: c['slug']?.toString(),
                  child: Text('y/${c['name'] ?? c['slug']}'),
                );
              }).toList(),
              onChanged: onChanged,
            ),
            if (selectedCommunity != null && onFlairChanged != null)
              FlairPicker(
                communitySlug: selectedCommunity['slug']?.toString() ?? '',
                selectedFlairId: flairId,
                onChanged: onFlairChanged!,
              ),
          ],
        );
      },
    );
  }
}

class FlairPicker extends StatelessWidget {
  final String communitySlug;
  final String? selectedFlairId;
  final ValueChanged<String?> onChanged;
  const FlairPicker({
    super.key,
    required this.communitySlug,
    required this.selectedFlairId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(
        document: gql(kCommunityFlairs),
        variables: {'slug': communitySlug},
      ),
      builder: (result, {fetchMore, refetch}) {
        final flairs = (result.data?['communityFlair'] as List?) ?? [];
        if (flairs.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: DropdownButtonFormField<String>(
            value: selectedFlairId,
            decoration: const InputDecoration(
              labelText: 'Flair',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            hint: const Text('Select flair (optional)'),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('None', style: TextStyle(color: DesignTokens.textTertiary)),
              ),
              ...flairs.map((f) {
                return DropdownMenuItem(
                  value: f['id']?.toString(),
                  child: Text(f['text']?.toString() ?? ''),
                );
              }),
            ],
            onChanged: onChanged,
          ),
        );
      },
    );
  }
}

Future<({String base64, String path})?> pickPostImage() async {
  final file = await ImagePicker()
      .pickImage(source: ImageSource.gallery, maxWidth: 1920);
  if (file == null) return null;
  return (
    base64: base64Encode(await file.readAsBytes()),
    path: file.path,
  );
}

Future<({String base64, String path})?> pickPostVideo() async {
  final file = await ImagePicker()
      .pickVideo(source: ImageSource.gallery);
  if (file == null) return null;
  return (
    base64: base64Encode(await file.readAsBytes()),
    path: file.path,
  );
}

Future<List<({String base64, String path})>>
    pickPostGalleryImages() async {
  final files = await ImagePicker()
      .pickMultiImage(imageQuality: 85, maxWidth: 1920);
  final results = <({String base64, String path})>[];
  for (final file in files) {
    results.add((
      base64: base64Encode(await file.readAsBytes()),
      path: file.path,
    ));
  }
  return results;
}

void insertMarkdown(
  TextEditingController ctrl,
  String prefix,
  String suffix,
) {
  final s = ctrl.selection;
  final t = ctrl.text;
  if (s.isValid && s.start != s.end) {
    final sel = t.substring(s.start, s.end);
    ctrl.text =
        t.replaceRange(s.start, s.end, '$prefix$sel$suffix');
    ctrl.selection = TextSelection.collapsed(
        offset:
            s.start + prefix.length + sel.length + suffix.length);
  } else {
    final p = s.baseOffset;
    ctrl.text =
        '${t.substring(0, p)}$prefix$suffix${t.substring(p)}';
    ctrl.selection =
        TextSelection.collapsed(offset: p + prefix.length);
  }
}
