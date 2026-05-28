import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/widgets.dart';
import 'profile_body.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Query(
      options: QueryOptions(document: gql(kMe)),
      builder: (result, {fetchMore, refetch}) {
        final me = result.data?['me'];

        if (result.isLoading && me == null) {
          return Scaffold(
            body: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              children: const [
                SizedBox(height: 120),
                ShimmerBox(height: 160, radius: DesignTokens.radiusXl),
                SizedBox(height: 16),
                ShimmerBox(height: 200, radius: DesignTokens.radiusXl),
                SizedBox(height: 16),
                ShimmerBox(height: 280, radius: DesignTokens.radiusXl),
              ],
            ),
          );
        }

        if (result.hasException && me == null) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Profile',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              centerTitle: true,
            ),
            body: ErrorState(
              message: graphQLErrorMessage(
                  result.exception, 'Could not load profile.'),
              onRetry: () => refetch?.call(),
            ),
          );
        }

        return ProfileBody(me: me, refetch: refetch);
      },
    );
  }
}
