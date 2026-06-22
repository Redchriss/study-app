import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';

/// A searchable YouTube video picker that eliminates copy-paste friction.
/// Shows search results with thumbnails — tap to select and auto-fill URL.
class YouTubeSearchPicker extends StatefulWidget {
  final ValueChanged<String> onSelected; // returns the YouTube URL
  final String? initialUrl;

  const YouTubeSearchPicker({
    super.key,
    required this.onSelected,
    this.initialUrl,
  });

  @override
  State<YouTubeSearchPicker> createState() => _YouTubeSearchPickerState();
}

class _YouTubeSearchPickerState extends State<YouTubeSearchPicker> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  bool _searched = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search bar
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search YouTube...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  isDense: true,
                ),
                onSubmitted: (v) {
                  if (v.trim().isNotEmpty) {
                    setState(() {
                      _query = v.trim();
                      _searched = true;
                    });
                  }
                },
                textInputAction: TextInputAction.search,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: () {
                  if (_searchCtrl.text.trim().isNotEmpty) {
                    setState(() {
                      _query = _searchCtrl.text.trim();
                      _searched = true;
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Search', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Results
        if (_query.isNotEmpty)
          Query(
            options: QueryOptions(
              document: gql(kYouTubeSearch),
              variables: {'query': _query, 'maxResults': 8},
              fetchPolicy: FetchPolicy.networkOnly,
            ),
            builder: (result, {fetchMore, refetch}) {
              if (result.isLoading && !_searched) {
                return const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                );
              }

              final videos = ((result.data?['youtubeSearch'] as List?) ?? [])
                  .map((e) => e as Map<String, dynamic>)
                  .toList();

              if (videos.isEmpty && _searched) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text('No videos found. Try a different search.',
                        style: TextStyle(color: DesignTokens.textSecondary)),
                  ),
                );
              }

              return SizedBox(
                height: 200,
                child: ListView.separated(
                  itemCount: videos.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final v = videos[i];
                    final title = v['title']?.toString() ?? '';
                    final channel = v['channelTitle']?.toString() ?? '';
                    final thumb = v['thumbnailUrl']?.toString() ?? '';
                    final url = v['url']?.toString() ?? '';

                    return InkWell(
                      onTap: () {
                        widget.onSelected(url);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Video selected!'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 6),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                thumb,
                                width: 80,
                                height: 52,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 80,
                                  height: 52,
                                  color: DesignTokens.border,
                                  child: const Icon(Icons.videocam_rounded,
                                      size: 24),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                  const SizedBox(height: 2),
                                  Text(channel,
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.6))),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: DesignTokens.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.add_rounded,
                                  size: 16, color: DesignTokens.primary),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
      ],
    );
  }
}
