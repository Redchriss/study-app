import 'package:flutter/material.dart';
import 'post_card_card.dart';
import 'post_card_compact.dart';
import 'post_card_classic.dart';

enum PostCardLayout { compact, card, classic }

class PostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final PostCardLayout layout;
  final VoidCallback onTap;

  const PostCard({
    super.key,
    required this.post,
    this.layout = PostCardLayout.card,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    switch (layout) {
      case PostCardLayout.compact:
        return CompactPostCard(post: post, onTap: onTap);
      case PostCardLayout.card:
        return CardPostCard(post: post, onTap: onTap);
      case PostCardLayout.classic:
        return ClassicPostCard(post: post, onTap: onTap);
    }
  }
}
