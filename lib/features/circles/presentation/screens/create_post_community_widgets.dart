import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/graphql/queries/queries.dart';

const String kCommunityFlairs = r'''query CommunityFlairs { __typename }''';

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
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Autocomplete<String>(
            optionsBuilder: (textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return communities.map((c) => c['slug']?.toString() ?? '');
              }
              return communities.map((c) => c['slug']?.toString() ?? '').where(
                  (slug) => slug
                      .toLowerCase()
                      .contains(textEditingValue.text.toLowerCase()));
            },
            initialValue:
                selected != null ? TextEditingValue(text: 'y/$selected') : null,
            displayStringForOption: (option) => 'y/$option',
            onSelected: (slug) => onChanged(slug),
            fieldViewBuilder: (_, ctrl, focusNode, onSubmit) {
              return TextField(
                controller: ctrl,
                focusNode: focusNode,
                decoration: const InputDecoration(
                  labelText: 'Community',
                  border: OutlineInputBorder(),
                  hintText: 'Search communities...',
                  prefixIcon: Icon(Icons.search, size: 20),
                ),
                onSubmitted: (_) => onSubmit(),
              );
            },
            optionsViewBuilder: (_, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: 200,
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: options.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final slug = options.elementAt(i);
                        final comm = communities.firstWhere(
                            (c) => c['slug'] == slug,
                            orElse: () => {});
                        return ListTile(
                          dense: true,
                          leading: comm['icon'] != null &&
                                  comm['icon'].toString().isNotEmpty
                              ? CircleAvatar(
                                  radius: 14,
                                  backgroundImage:
                                      NetworkImage(comm['icon'].toString()),
                                )
                              : CircleAvatar(
                                  radius: 14,
                                  child: Text(
                                      'y/${comm['name']?.toString()[0] ?? '?'}',
                                      style: const TextStyle(fontSize: 10)),
                                ),
                          title: Text('y/${comm['name'] ?? slug}',
                              style: const TextStyle(fontSize: 13)),
                          subtitle: comm['memberCount'] != null
                              ? Text('${comm['memberCount']} members',
                                  style: const TextStyle(fontSize: 11))
                              : null,
                          onTap: () => onSelected(slug),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
          if (selectedCommunity != null && onFlairChanged != null)
            FlairPicker(
              communitySlug: selectedCommunity['slug']?.toString() ?? '',
              selectedFlairId: flairId,
              onChanged: onFlairChanged!,
            ),
        ]);
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Flair',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FlairChip(
                      label: 'None',
                      selected: selectedFlairId == null,
                      onTap: () => onChanged(null),
                    ),
                    ...flairs.map((f) => _FlairChip(
                          label:
                              '${f['emoji'] ?? ''} ${f['text'] ?? ''}'.trim(),
                          color: f['color']?.toString(),
                          selected: selectedFlairId == f['id']?.toString(),
                          onTap: () => onChanged(f['id']?.toString()),
                        )),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FlairChip extends StatelessWidget {
  final String label;
  final String? color;
  final bool selected;
  final VoidCallback onTap;
  const _FlairChip({
    required this.label,
    this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: color != null
            ? Color(int.parse(color!.replaceFirst('#', '0xFF')))
                .withValues(alpha: 0.2)
            : null,
      ),
    );
  }
}

Future<({String base64, String path})?> pickPostImage() async {
  final file = await ImagePicker()
      .pickImage(source: ImageSource.gallery, maxWidth: 1920);
  if (file == null) return null;
  return (base64: base64Encode(await file.readAsBytes()), path: file.path);
}

Future<({String base64, String path})?> pickPostVideo() async {
  final file = await ImagePicker().pickVideo(source: ImageSource.gallery);
  if (file == null) return null;
  return (base64: base64Encode(await file.readAsBytes()), path: file.path);
}

Future<List<({String base64, String path})>> pickPostGalleryImages() async {
  final files =
      await ImagePicker().pickMultiImage(imageQuality: 85, maxWidth: 1920);
  final results = <({String base64, String path})>[];
  for (final file in files) {
    results
        .add((base64: base64Encode(await file.readAsBytes()), path: file.path));
  }
  return results;
}

void insertMarkdown(TextEditingController ctrl, String prefix, String suffix) {
  final s = ctrl.selection;
  final t = ctrl.text;
  if (s.isValid && s.start != s.end) {
    final sel = t.substring(s.start, s.end);
    ctrl.text = t.replaceRange(s.start, s.end, '$prefix$sel$suffix');
    ctrl.selection = TextSelection.collapsed(
        offset: s.start + prefix.length + sel.length + suffix.length);
  } else {
    final p = s.baseOffset;
    ctrl.text = '${t.substring(0, p)}$prefix$suffix${t.substring(p)}';
    ctrl.selection = TextSelection.collapsed(offset: p + prefix.length);
  }
}
