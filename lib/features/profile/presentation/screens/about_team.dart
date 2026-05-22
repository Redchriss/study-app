import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import 'about_cards.dart';
import 'about_widgets.dart';

class TeamMemberCard extends StatelessWidget {
  final String name;
  final String role;
  final String bio;
  final String? photoUrl;
  final bool dark;

  const TeamMemberCard({
    super.key,
    required this.name,
    required this.role,
    required this.bio,
    required this.photoUrl,
    required this.dark,
  });

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2)
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: dark ? DesignTokens.darkSurface : DesignTokens.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        border: Border.all(
            color: dark ? DesignTokens.darkBorder : DesignTokens.border),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: DesignTokens.accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              image: photoUrl != null && photoUrl!.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(photoUrl!), fit: BoxFit.cover)
                  : null,
            ),
            child: photoUrl == null || photoUrl!.isEmpty
                ? Center(
                    child: Text(_initials,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: DesignTokens.accent)),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: dark
                          ? DesignTokens.darkTextPrimary
                          : DesignTokens.textPrimary),
                ),
                const SizedBox(height: 3),
                Text(role,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: DesignTokens.accent)),
                if (bio.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(bio,
                      style: const TextStyle(
                          fontSize: 12,
                          color: DesignTokens.textSecondary,
                          height: 1.4)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StaticTeamSection extends StatelessWidget {
  const StaticTeamSection({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        FounderCard(
          name: 'Redson Ngwira',
          role: 'Founder & Developer',
          bio:
              'Building Yaza to help every Malawian student access quality education '
              'through AI — from MSCE revision to early childhood learning.',
          photoUrl: null,
          twitter: 'RedsonNgwira',
          linkedin: '',
          dark: dark,
        ),
        const SizedBox(height: 10),
        TeamMemberCard(
          name: 'Yankho Mtewa',
          role: 'Co-Founder',
          bio:
              'Working to make education accessible and affordable for all Malawians.',
          photoUrl: null,
          dark: dark,
        ),
      ],
    );
  }
}

class TeamSection extends StatelessWidget {
  final bool dark;
  const TeamSection({super.key, required this.dark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Meet the Team'),
        const SizedBox(height: 10),
        Query(
          options: QueryOptions(
            document: gql(kTeamMembers),
            fetchPolicy: FetchPolicy.cacheAndNetwork,
          ),
          builder: (result, {fetchMore, refetch}) {
            if (result.hasException && result.data?['teamMembers'] == null)
              return ErrorState(
                message: result.exception?.graphqlErrors.firstOrNull?.message ??
                    'Failed to load team',
                onRetry: () => refetch?.call(),
              );
            final members = (result.data?['teamMembers'] as List?) ?? [];
            if (result.isLoading && members.isEmpty) {
              return Column(
                children: List.generate(
                    2,
                    (i) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: ShimmerBox(
                              height: 120, radius: DesignTokens.radiusXl),
                        )),
              );
            }
            if (members.isEmpty) return const StaticTeamSection();
            return Column(
              children: members.asMap().entries.map((e) {
                final m = e.value as Map<String, dynamic>;
                final isFirst = e.key == 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: isFirst
                      ? FounderCard(
                          name: m['name'] as String? ?? '',
                          role: m['role'] as String? ?? '',
                          bio: m['bio'] as String? ?? '',
                          photoUrl: m['photoUrl'] as String?,
                          twitter: m['twitter'] as String? ?? '',
                          linkedin: m['linkedin'] as String? ?? '',
                          dark: dark,
                        )
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: 0.05, end: 0)
                      : TeamMemberCard(
                          name: m['name'] as String? ?? '',
                          role: m['role'] as String? ?? '',
                          bio: m['bio'] as String? ?? '',
                          photoUrl: m['photoUrl'] as String?,
                          dark: dark,
                        )
                          .animate(delay: (e.key * 80).ms)
                          .fadeIn(duration: 350.ms),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
