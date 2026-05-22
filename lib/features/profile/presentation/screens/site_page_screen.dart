import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/widgets.dart';

/// Generic screen that fetches and renders any [SitePage] by slug.
/// Used for: terms, privacy, faq, support, community-guidelines, cookies.
class SitePageScreen extends StatelessWidget {
  /// The slug that matches [SitePage.slug] on the backend.
  final String slug;

  /// Shown in the AppBar while loading or if backend has no content yet.
  final String fallbackTitle;

  /// Shown as markdown content if the backend returns nothing.
  final String fallbackContent;

  const SitePageScreen({
    super.key,
    required this.slug,
    required this.fallbackTitle,
    required this.fallbackContent,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Query(
      options: QueryOptions(
        document: gql(kSitePage),
        variables: {'slug': slug},
        fetchPolicy: FetchPolicy.cacheAndNetwork,
      ),
      builder: (result, {fetchMore, refetch}) {
        if (result.hasException && result.data?['sitePage'] == null) {
          return Scaffold(
            body: ErrorState(
              message: graphQLErrorMessage(result.exception, 'Failed to load page'),
              onRetry: () => refetch?.call(),
            ),
          );
        }
        final page = result.data?['sitePage'] as Map<String, dynamic>?;
        final title = page?['title'] as String? ?? fallbackTitle;
        final content = page?['content'] as String? ?? fallbackContent;
        final version = page?['version'] as String?;
        final lastUpdated = page?['lastUpdated'] as String?;
        final isLoading = result.isLoading && page == null;

        return Scaffold(
          backgroundColor: dark ? DesignTokens.darkBackground : DesignTokens.background,
          appBar: AppBar(
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            centerTitle: true,
          ),
          body: isLoading
              ? Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: List.generate(
                      6,
                       (i) => Padding(
                         padding: const EdgeInsets.only(bottom: 12),
                         child: ShimmerBox(
                           height: i == 0 ? 28 : 14,
                           radius: DesignTokens.radiusSm,
                         ),
                       ),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Version / date badge
                      if (version != null || lastUpdated != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: DesignTokens.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                            border: Border.all(color: DesignTokens.primary.withValues(alpha: 0.15)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.info_outline_rounded,
                                  size: 16, color: DesignTokens.primary),
                              const SizedBox(width: 8),
                              Text(
                                [
                                  if (version != null) 'v$version',
                                  if (lastUpdated != null) 'Updated $lastUpdated',
                                ].join(' · '),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: DesignTokens.primary,
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 300.ms),

                      // Markdown content
                      MarkdownBody(
                        data: content,
                        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                          p: TextStyle(
                            fontSize: 14,
                            height: 1.7,
                            color: dark ? DesignTokens.darkTextPrimary : DesignTokens.textPrimary,
                          ),
                          h1: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: dark ? DesignTokens.darkTextPrimary : DesignTokens.textPrimary,
                          ),
                          h2: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: dark ? DesignTokens.darkTextPrimary : DesignTokens.textPrimary,
                          ),
                          h3: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: dark ? DesignTokens.darkTextPrimary : DesignTokens.textPrimary,
                          ),
                          strong: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: dark ? DesignTokens.darkTextPrimary : DesignTokens.textPrimary,
                          ),
                          blockquoteDecoration: BoxDecoration(
                            color: DesignTokens.primary.withValues(alpha: 0.06),
                            border: const Border(
                              left: BorderSide(color: DesignTokens.primary, width: 3),
                            ),
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                          ),
                        ),
                        onTapLink: (text, href, title) async {
                          if (href == null) return;
                          final uri = Uri.parse(href);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.03, end: 0),

                      // Contact CTA for support page
                      if (slug == 'support') ...[
                        const SizedBox(height: 28),
                        _ContactCard(dark: dark),
                      ],
                    ],
                  ),
                ),
        );
      },
    );
  }
}

// ── Contact card shown on the support page ─────────────────────────────────────
class _ContactCard extends StatelessWidget {
  final bool dark;
  const _ContactCard({required this.dark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B6CA8), Color(0xFF2EC4B6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Get in Touch',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const SizedBox(height: 6),
          const Text(
            'We respond to every message within 24 hours.',
            style: TextStyle(fontSize: 13, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () async {
              final uri = Uri.parse('mailto:support@yaza.app');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.mail_rounded, color: DesignTokens.primary, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'support@yaza.app',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: DesignTokens.primary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }
}
