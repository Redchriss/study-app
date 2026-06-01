import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:genui/genui.dart';
import '../../../../core/theme/design_tokens.dart';
import '../providers/ai_tutor_provider.dart';
import '../widgets/ai_tutor_bubbles.dart';
import '../widgets/ai_tutor_empty_state.dart';

class AiTutorMessageList extends StatelessWidget {
  final List<ConversationItem> conversationItems;
  final SurfaceController surfaceController;
  final bool streaming;
  final String streamingText;
  final Animation<double> cursorAnim;
  final Animation<double> breathAnim;
  final bool dark;
  final ScrollController scrollCtrl;
  final List<String> suggestions;
  final ValueChanged<String> onSuggestion;
  final void Function(int, String?)? onFeedback;
  final VoidCallback? onRetry;
  final void Function(String)? onMountSurface;

  const AiTutorMessageList({
    super.key,
    required this.conversationItems,
    required this.surfaceController,
    required this.streaming,
    required this.streamingText,
    required this.cursorAnim,
    required this.breathAnim,
    required this.dark,
    required this.scrollCtrl,
    required this.suggestions,
    required this.onSuggestion,
    this.onFeedback,
    this.onRetry,
    this.onMountSurface,
  });

  @override
  Widget build(BuildContext context) {
    if (conversationItems.isEmpty && !streaming) {
      return AiTutorEmptyState(
        suggestions: suggestions,
        onSuggestion: onSuggestion,
      );
    }
    return ListView.builder(
      controller: scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: conversationItems.length + (streaming ? 1 : 0),
      itemBuilder: (_, i) {
        if (i >= conversationItems.length && streaming) {
          return _StreamingMessage(
            text: streamingText,
            cursorAnim: cursorAnim,
            breathAnim: breathAnim,
            dark: dark,
          );
        }

        final item = conversationItems[i];

        if (item is SurfaceItem) {
          if (!item.mounted) {
            onMountSurface?.call(item.surfaceId);
            return _SurfacePlaceholder();
          }
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Surface(
              surfaceContext: surfaceController.contextFor(item.surfaceId),
            ),
          );
        }

        if (item is TextItem) {
          return Column(
            crossAxisAlignment:
                item.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              item.isUser
                  ? AiUserBubble(text: item.text)
                  : AiAssistantBubble(
                      text: item.text,
                      streaming: false,
                      cursorAnim: cursorAnim,
                      dark: dark,
                      feedback: item.feedback,
                      onFeedback: (value) => onFeedback?.call(i, value),
                      onRetry:
                          i == conversationItems.length - 1 ? onRetry : null,
                    ),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class _StreamingMessage extends StatelessWidget {
  final String text;
  final Animation<double> cursorAnim;
  final Animation<double> breathAnim;
  final bool dark;

  const _StreamingMessage({
    required this.text,
    required this.cursorAnim,
    required this.breathAnim,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.only(right: 8, top: 2),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF7C4DFF), Color(0xFF1B6CA8)]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ScaleTransition(
              scale: breathAnim,
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 14),
            ),
          ),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.78),
              margin: const EdgeInsets.only(bottom: 10, right: 48),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: dark
                    ? DesignTokens.darkSurfaceVariant
                    : DesignTokens.surfaceVariant,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
              ),
              child: Stack(
                children: [
                  MarkdownBody(
                    data: sanitizeStreamingMarkdown(text),
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(fontSize: 14, height: 1.55),
                      code: TextStyle(
                          fontSize: 13,
                          fontFamily: 'monospace',
                          backgroundColor:
                              dark ? Colors.black26 : const Color(0xFFEEF0F2)),
                      codeblockDecoration: BoxDecoration(
                          color: dark
                              ? const Color(0xFF161B22)
                              : const Color(0xFFEEF0F2),
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: ScaleTransition(
                      scale: breathAnim,
                      child: FadeTransition(
                        opacity: cursorAnim,
                        child: Container(
                          width: 8,
                          height: 16,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF7C4DFF),
                                Color(0xFF1B6CA8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SurfacePlaceholder extends StatefulWidget {
  @override
  State<_SurfacePlaceholder> createState() => _SurfacePlaceholderState();
}

class _SurfacePlaceholderState extends State<_SurfacePlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 0.7).animate(_pulseCtrl),
      child: Container(
        height: 120,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? DesignTokens.darkSurfaceVariant
              : DesignTokens.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 10),
              Text('Building interactive widget...',
                  style: TextStyle(
                      fontSize: 12, color: DesignTokens.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

class AiTutorChatHistoryContent extends StatelessWidget {
  final List<Map<String, dynamic>> chatHistory;
  final ValueChanged<String> onRestoreSession;

  const AiTutorChatHistoryContent({
    super.key,
    required this.chatHistory,
    required this.onRestoreSession,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(
              children: [
                const Icon(Icons.history_rounded, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Chat History',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          Expanded(
            child: chatHistory.isEmpty
                ? const Center(
                    child: Text(
                      'No past sessions yet.',
                      style: TextStyle(color: DesignTokens.textSecondary),
                    ),
                  )
                : ListView.builder(
                    controller: scrollCtrl,
                    itemCount: chatHistory.length,
                    itemBuilder: (_, i) {
                      final s = chatHistory[i];
                      final title = s['title']?.toString() ?? 'Chat';
                      final updatedAt = s['updatedAt']?.toString() ?? '';
                      final dateLabel = updatedAt.length >= 10
                          ? updatedAt.substring(0, 10)
                          : updatedAt;
                      return ListTile(
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF7C4DFF),
                                Color(0xFF1B6CA8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        title: Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          dateLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            color: DesignTokens.textSecondary,
                          ),
                        ),
                        onTap: () => onRestoreSession(s['id'].toString()),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
