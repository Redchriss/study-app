import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final client = ref.read(graphqlClientProvider);

    return Query(
      options: QueryOptions(
          document: gql(kNotifications),
          variables: const {'unreadOnly': false}),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) {
          return Scaffold(
            appBar: AppBar(
                title: Text('Notifications',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800))),
            body: const LoadingWidget(),
          );
        }
        if (result.hasException) {
          return Scaffold(
            appBar: AppBar(
                title: Text('Notifications',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800))),
            body: ErrorState(
              message: graphQLErrorMessage(
                  result.exception, 'Could not load notifications.'),
              onRetry: () => refetch?.call(),
            ),
          );
        }
        final items = (result.data?['notifications'] as List?) ??
            <Map<String, dynamic>>[];
        final unreadCount =
            result.data?['unreadNotificationCount'] as int? ?? 0;

        return Scaffold(
          appBar: AppBar(
            title: Text('Notifications',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            actions: unreadCount > 0
                ? [
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: TextButton.icon(
                        icon: const Icon(Icons.done_all_rounded, size: 18),
                        label: const Text('Mark all read'),
                        onPressed: () async {
                          final markResult = await client.mutate(
                              MutationOptions(
                                  document: gql(kMarkAllNotificationsRead)));
                          if (!context.mounted) return;
                          if (markResult.hasException) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(graphQLErrorMessage(
                                    markResult.exception,
                                    'Could not mark notifications as read.')),
                                backgroundColor: DesignTokens.error,
                              ),
                            );
                            return;
                          }
                          refetch?.call();
                        },
                      ),
                    ),
                  ]
                : null,
          ),
          body: RefreshIndicator(
            onRefresh: () async => refetch?.call(),
            child: items.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.2),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: DesignTokens.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.notifications_none_rounded,
                            size: 64, color: DesignTokens.primary),
                      ),
                      const SizedBox(height: 24),
                      Text('All caught up!',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      const Text(
                        'When you get replies, upvotes, or quiz results, they\'ll show up right here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: DesignTokens.textSecondary,
                            fontSize: 15,
                            height: 1.4),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final n = items[i];
                      final bool isRead = n['isRead'] == true;
                      final String type =
                          n['notificationType'] as String? ?? '';
                      final IconData icon = _iconForType(type);
                      final Color color = _colorForType(type);

                      return AnimatedPress(
                        onTap: () {
                          // Mark as read if not already, then potentially navigate
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color:
                                dark ? DesignTokens.darkSurface : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: isRead
                                ? null
                                : Border.all(
                                    color: color.withValues(alpha: 0.3)),
                            boxShadow: isRead
                                ? null
                                : [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.08),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isRead
                                      ? (dark
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : Colors.grey.shade100)
                                      : color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  icon,
                                  color: isRead
                                      ? DesignTokens.textTertiary
                                      : color,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      n['message'] ?? '',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: isRead
                                            ? FontWeight.w500
                                            : FontWeight.w700,
                                        color: isRead
                                            ? DesignTokens.textSecondary
                                            : DesignTokens.textPrimary,
                                        height: 1.3,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _timeAgo(n['createdAt'] as String? ?? ''),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isRead
                                            ? DesignTokens.textTertiary
                                            : color.withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isRead) ...[
                                const SizedBox(width: 12),
                                Container(
                                  width: 10,
                                  height: 10,
                                  margin: const EdgeInsets.only(top: 6),
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'reply':
        return Icons.reply_rounded;
      case 'upvote':
        return Icons.arrow_upward_rounded;
      case 'circle_invite':
        return Icons.group_add_rounded;
      case 'quiz_result':
        return Icons.quiz_rounded;
      case 'ai_credits':
        return Icons.auto_awesome_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'reply':
        return const Color(0xFF389E75); // Green
      case 'upvote':
        return const Color(0xFFE87E5E); // Orange
      case 'circle_invite':
        return const Color(0xFF5A6BB2); // Purple/Blue
      case 'quiz_result':
        return const Color(0xFFE5B300); // Gold
      case 'ai_credits':
        return const Color(0xFF6B48FF); // Deep Purple
      default:
        return DesignTokens.primary;
    }
  }

  String _timeAgo(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${(diff.inDays / 7).floor()}w ago';
    } catch (_) {
      return '';
    }
  }
}
