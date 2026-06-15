import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ai_tutor_provider.dart';

class AiTutorAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final VoidCallback onHistory;
  final VoidCallback onPreferences;

  const AiTutorAppBar({
    super.key,
    required this.onHistory,
    required this.onPreferences,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hasMessages = ref.watch(aiTutorProvider).conversationItems.isNotEmpty;
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C4DFF), Color(0xFF1B6CA8)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.psychology_rounded,
                color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Text('AI Tutor',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.history_rounded, size: 22),
          tooltip: 'Chat history',
          onPressed: onHistory,
        ),
        IconButton(
          icon: const Icon(Icons.tune_rounded, size: 22),
          tooltip: 'Tutor preferences',
          onPressed: onPreferences,
        ),
        hasMessages
            ? IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 22),
                tooltip: 'New conversation',
                onPressed: () => showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Start new conversation?'),
                    content: const Text(
                        'This will clear your current chat history.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          ref.read(aiTutorProvider.notifier).newConversation();
                        },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ],
    );
  }
}
