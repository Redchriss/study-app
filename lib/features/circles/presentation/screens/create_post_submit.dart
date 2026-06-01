import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

Future<void> submitPost({
  required WidgetRef ref,
  required BuildContext context,
  required String? communitySlug,
  required String title,
  required String body,
  required String postType,
  required String? url,
  required String? imageBase64,
  required String? videoBase64,
  required bool isOc,
  required bool isSpoiler,
  required String? flairId,
  required List<String> pollOptions,
  required int pollDurationHours,
  required List<({String base64, String caption})> galleryItems,
  required Map<String, dynamic>? crosspostOf,
  required void Function(String) onError,
  required VoidCallback onSuccess,
}) async {
  final client = ref.read(graphqlClientProvider);

  if (postType == 'crosspost' && crosspostOf != null) {
    final result = await client.mutate(MutationOptions(
      document: gql(kCrosspost),
      variables: {
        'originalPostId': crosspostOf['id'],
        'communitySlug': communitySlug,
        'title': title,
      },
    ));
    if (result.hasException) {
      onError(graphQLErrorMessage(result.exception, 'Could not crosspost'));
      return;
    }
    final payload = result.data?['crosspost'];
    final errors = (payload?['errors'] as List?)?.join(', ');
    if (errors != null && errors.isNotEmpty) {
      onError(errors);
      return;
    }
    onSuccess();
    return;
  }

  final vars = {
    'communitySlug': communitySlug,
    'title': title,
    'body': body,
    'postType': postType.toUpperCase(),
    if (postType == 'link') 'url': url,
    if (postType == 'image') 'imageBase64': imageBase64,
    if (postType == 'video') 'videoBase64': videoBase64,
    if (postType == 'gallery')
      'galleryItems': galleryItems
          .map((g) => {'imageBase64': g.base64, 'caption': g.caption})
          .toList(),
    if (postType == 'poll')
      'pollOptions': pollOptions.where((s) => s.isNotEmpty).toList(),
    if (postType == 'poll') 'pollDurationHours': pollDurationHours,
    'isOc': isOc,
    'isSpoiler': isSpoiler,
    if (flairId != null) 'flairId': flairId,
  };

  final result = await client.mutate(MutationOptions(
    document: gql(kCreatePost),
    variables: vars,
  ));

  if (result.hasException) {
    onError(graphQLErrorMessage(result.exception, 'Could not create post'));
    return;
  }
  final payload = result.data?['createPost'];
  final errors = (payload?['errors'] as List?)?.join(', ');
  if (errors != null && errors.isNotEmpty) {
    onError(errors);
    return;
  }
  onSuccess();
}

({String title, String description})? parseLinkPreview(String url) {
  final parsed = Uri.tryParse(url.trim());
  if (parsed != null && parsed.host.isNotEmpty) {
    return (
      title: parsed.host.replaceFirst('www.', ''),
      description: 'Loading preview...',
    );
  }
  return null;
}

Timer? createLinkPreviewDebounce(String url, String postType,
    {required void Function(String?, String?) onPreview,
    required VoidCallback onClear}) {
  if (url.trim().isEmpty || postType != 'link') {
    onClear();
    return null;
  }
  return Timer(const Duration(milliseconds: 500), () {
    final preview = parseLinkPreview(url);
    onPreview(preview?.title, preview?.description);
  });
}
