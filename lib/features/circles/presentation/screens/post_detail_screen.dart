import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'post_detail_screen_state.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final String communitySlug;
  final String postSlug;
  final String? commentId;
  const PostDetailScreen({
    super.key,
    required this.communitySlug,
    required this.postSlug,
    this.commentId,
  });

  @override
  ConsumerState<PostDetailScreen> createState() => PostDetailScreenState();
}
