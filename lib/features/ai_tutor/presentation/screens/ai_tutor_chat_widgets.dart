import 'package:flutter/material.dart';
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
  final bool dark;
  final ScrollController scrollCtrl;
  final List<String> suggestions;
  final ValueChanged<String> onSuggestion;
  final void Function(int, String?)? onFeedback;

  const AiTutorMessageList({
    super.key,
    required this.conversationItems,
    required this.surfaceController,
    required this.streaming,
    required this.streamingText,
    required this.cursorAnim,
    required this.dark,
    required this.scrollCtrl,
    required this.suggestions,
    required this.onSuggestion,
    this.onFeedback,
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
      itemCount: conversationItems.length,
      itemBuilder: (_, i) {
        final item = conversationItems[i];

        if (item is SurfaceItem) {
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
                      onFeedback: (value) => onFeedback?.call(i, value),
                    ),
            ],
          );
        }

        return const SizedBox.shrink();
      },
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
                          s['title']?.toString() ?? 'Chat',
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
