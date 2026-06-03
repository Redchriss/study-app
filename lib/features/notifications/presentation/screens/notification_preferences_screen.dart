import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/errors/app_exception.dart';
import 'preference_section_header.dart';
import 'preference_switch_tile.dart';

class NotificationPreferencesScreen extends ConsumerStatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  ConsumerState<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends ConsumerState<NotificationPreferencesScreen> {
  bool _pushEnabled = true;
  bool _soundEnabled = true;
  bool _postReply = true;
  bool _commentReply = true;
  bool _postMention = true;
  bool _upvoteMilestone = false;
  bool _award = true;
  bool _modAction = true;
  bool _modmail = true;
  bool _loaded = false;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Query(
      options: QueryOptions(
        document: gql(kProfileNotificationPreferences),
        fetchPolicy: FetchPolicy.networkOnly,
      ),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading && !_loaded) {
          return Scaffold(
            appBar: AppBar(
                title: const Text('Notification preferences',
                    style: TextStyle(fontWeight: FontWeight.w800))),
            body: const LoadingWidget(),
          );
        }
        if (!_loaded && result.data != null) {
          final prefs =
              result.data?['notificationPreferences'] as Map<String, dynamic>?;
          if (prefs != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() {
                _pushEnabled = prefs['pushEnabled'] as bool? ?? true;
                _postReply = prefs['communityReplies'] as bool? ?? true;
                _modmail = prefs['mentorshipUpdates'] as bool? ?? true;
                _loaded = true;
              });
            });
          } else {
            _loaded = true;
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Notification preferences',
                style: TextStyle(fontWeight: FontWeight.w800)),
            actions: [
              if (_saving)
                const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2)))
              else
                TextButton(
                  onPressed: _save,
                  child: const Text('Save',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              PreferenceSectionHeader(title: 'Push & Sound'),
              const SizedBox(height: 8),
              PreferenceSwitchTile(
                dark: dark,
                icon: Icons.notifications_active_rounded,
                title: 'Push notifications',
                subtitle: 'Receive push notifications on this device',
                value: _pushEnabled,
                onChanged: (v) => setState(() => _pushEnabled = v),
              ),
              PreferenceSwitchTile(
                dark: dark,
                icon: Icons.volume_up_rounded,
                title: 'Sound',
                subtitle: 'Play a sound for notifications',
                value: _soundEnabled,
                onChanged: (v) => setState(() => _soundEnabled = v),
              ),
              const SizedBox(height: 24),
              PreferenceSectionHeader(title: 'Activity'),
              const SizedBox(height: 8),
              PreferenceSwitchTile(
                dark: dark,
                icon: Icons.reply_rounded,
                title: 'Post replies',
                subtitle: 'Someone replies to your post',
                value: _postReply,
                onChanged: (v) => setState(() => _postReply = v),
              ),
              PreferenceSwitchTile(
                dark: dark,
                icon: Icons.reply_all_rounded,
                title: 'Comment replies',
                subtitle: 'Someone replies to your comment',
                value: _commentReply,
                onChanged: (v) => setState(() => _commentReply = v),
              ),
              PreferenceSwitchTile(
                dark: dark,
                icon: Icons.alternate_email_rounded,
                title: 'Mentions',
                subtitle: 'Someone mentions you with @username',
                value: _postMention,
                onChanged: (v) => setState(() => _postMention = v),
              ),
              PreferenceSwitchTile(
                dark: dark,
                icon: Icons.trending_up_rounded,
                title: 'Upvote milestones',
                subtitle: 'Your post reaches 10, 100, or 1 000 upvotes',
                value: _upvoteMilestone,
                onChanged: (v) => setState(() => _upvoteMilestone = v),
              ),
              PreferenceSwitchTile(
                dark: dark,
                icon: Icons.auto_awesome_rounded,
                title: 'Awards',
                subtitle: 'Someone gives you an award',
                value: _award,
                onChanged: (v) => setState(() => _award = v),
              ),
              PreferenceSwitchTile(
                dark: dark,
                icon: Icons.shield_rounded,
                title: 'Mod actions',
                subtitle: 'Your content is removed or you are banned',
                value: _modAction,
                onChanged: (v) => setState(() => _modAction = v),
              ),
              PreferenceSwitchTile(
                dark: dark,
                icon: Icons.mail_outline_rounded,
                title: 'Modmail',
                subtitle: 'New messages in moderation threads',
                value: _modmail,
                onChanged: (v) => setState(() => _modmail = v),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final client = GraphQLProvider.of(context).value;
      final result = await client.mutate(MutationOptions(
        document: gql(kUpdateProfileNotificationPreferences),
        variables: {
          'input': {
            'pushEnabled': _pushEnabled,
            'emailEnabled': false,
            'studyReminders': _postReply,
            'communityReplies': _postReply,
            'mentorshipUpdates': _modmail,
            'marketingEmails': false,
          },
        },
      ));
      if (!mounted) return;
      if (result.hasException) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(graphQLErrorMessage(
              result.exception, 'Could not save preferences.')),
          backgroundColor: DesignTokens.error,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Preferences saved'),
          backgroundColor: DesignTokens.success,
          duration: Duration(seconds: 2),
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
