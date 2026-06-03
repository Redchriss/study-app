import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../core/theme/design_tokens.dart';
import 'post_detail_header_info.dart';
import 'post_detail_media_widgets.dart';

class PostDetailHeader extends StatefulWidget {
  final Map<String, dynamic> post;
  final bool dark;
  const PostDetailHeader({super.key, required this.post, required this.dark});

  @override
  State<PostDetailHeader> createState() => _PostDetailHeaderState();
}

class _PostDetailHeaderState extends State<PostDetailHeader> {
  bool _spoilerRevealed = false;
  bool _nsfwRevealed = false;

  bool get _isBlurred =>
      (widget.post['isSpoiler'] == true && !_spoilerRevealed) ||
      (widget.post['isNsfw'] == true && !_nsfwRevealed);

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PostHeaderInfo(post: post),
        if (post['bodyHtml'] != null && post['bodyHtml'].toString().isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _isBlurred
                ? SpoilerBlurOverlay(
                    isSpoiler: post['isSpoiler'] == true,
                    isNsfw: post['isNsfw'] == true,
                    onReveal: () => setState(() {
                      if (post['isSpoiler'] == true) _spoilerRevealed = true;
                      if (post['isNsfw'] == true) _nsfwRevealed = true;
                    }),
                    child:
                        PostMarkdownBody(bodyHtml: post['bodyHtml'].toString()),
                  )
                : PostMarkdownBody(bodyHtml: post['bodyHtml'].toString()),
          ),
        PostMediaSection(
          post: post,
          dark: widget.dark,
          isBlurred: _isBlurred,
          onReveal: () => setState(() {
            if (post['isSpoiler'] == true) _spoilerRevealed = true;
            if (post['isNsfw'] == true) _nsfwRevealed = true;
          }),
        ),
        if (post['isSpoiler'] == true && _spoilerRevealed)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SpoilerRevealedChip(),
          ),
      ],
    );
  }
}

class PostMarkdownBody extends StatelessWidget {
  final String bodyHtml;
  const PostMarkdownBody({super.key, required this.bodyHtml});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        dark ? DesignTokens.darkSurfaceVariant : DesignTokens.surfaceVariant;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Markdown(
        data: bodyHtml,
        styleSheet: MarkdownStyleSheet(
          p: const TextStyle(
              fontSize: 14, height: 1.5, color: DesignTokens.textPrimary),
          strong: const TextStyle(fontWeight: FontWeight.w700),
          em: const TextStyle(fontStyle: FontStyle.italic),
          code: TextStyle(
            fontSize: 13,
            backgroundColor: surfaceColor,
            color: DesignTokens.primary,
          ),
          codeblockDecoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(8),
          ),
          blockquoteDecoration: BoxDecoration(
            border:
                Border(left: BorderSide(color: DesignTokens.primary, width: 3)),
            color: surfaceColor.withValues(alpha: 0.5),
          ),
          listBullet:
              const TextStyle(fontSize: 14, color: DesignTokens.textPrimary),
          h1: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          h2: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          h3: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class SpoilerRevealedChip extends StatelessWidget {
  const SpoilerRevealedChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: DesignTokens.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text('SPOILER',
          style: TextStyle(
              fontSize: 9,
              color: DesignTokens.warning,
              fontWeight: FontWeight.w700)),
    );
  }
}
