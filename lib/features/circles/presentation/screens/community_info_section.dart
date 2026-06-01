import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

class CommunityInfoSection extends StatelessWidget {
  final Map<String, dynamic> community;
  final List<Map<String, dynamic>> rules;
  final List<Map<String, dynamic>> moderators;
  final ThemeData theme;
  final String Function(int) formatCount;

  const CommunityInfoSection({
    super.key,
    required this.community,
    this.rules = const [],
    this.moderators = const [],
    required this.theme,
    required this.formatCount,
  });

  @override
  Widget build(BuildContext context) {
    final dark = theme.brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? DesignTokens.darkSurfaceVariant : DesignTokens.surfaceVariant,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(
          color: dark ? DesignTokens.darkBorder : DesignTokens.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('About Community'),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Text(
              community['description']?.toString() ?? 'No description',
              style: TextStyle(
                fontSize: 13,
                color: dark ? DesignTokens.darkTextSecondary : DesignTokens.textSecondary,
                height: 1.4,
              ),
            ),
          ),
          _Divider(dark: dark),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _stat(Icons.people_outline, '${formatCount((community['memberCount'] as num?)?.toInt() ?? 0)} members'),
                const SizedBox(width: 24),
                _stat(Icons.article_outlined, '${formatCount((community['postCount'] as num?)?.toInt() ?? 0)} posts'),
              ],
            ),
          ),
          _Divider(dark: dark),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Created', style: _labelStyle()),
                const SizedBox(height: 2),
                Text(
                  _formatDate(community['createdAt']?.toString()),
                  style: TextStyle(
                    fontSize: 12,
                    color: dark ? DesignTokens.darkTextSecondary : DesignTokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (community['communityType'] != null) ...[
            _Divider(dark: dark),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    community['communityType'] == 'private'
                        ? Icons.lock_rounded
                        : community['communityType'] == 'restricted'
                            ? Icons.verified_user_rounded
                            : Icons.public_rounded,
                    size: 16,
                    color: DesignTokens.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _typeLabel(community['communityType'].toString()),
                    style: const TextStyle(fontSize: 12, color: DesignTokens.textSecondary),
                  ),
                ],
              ),
            ),
          ],
          if (rules.isNotEmpty) ...[
            _Divider(dark: dark),
            _sectionHeader('Rules'),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Column(
                children: rules.asMap().entries.map((e) {
                  final r = e.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${e.key + 1}.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: dark ? DesignTokens.darkTextPrimary : DesignTokens.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r['title']?.toString() ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: dark ? DesignTokens.darkTextPrimary : DesignTokens.textPrimary,
                                ),
                              ),
                              if (r['description'] != null && r['description'].toString().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    r['description'].toString(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: dark ? DesignTokens.darkTextSecondary : DesignTokens.textSecondary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          if (moderators.isNotEmpty) ...[
            _Divider(dark: dark),
            _sectionHeader('Moderators'),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Column(
                children: moderators.map((m) {
                  final user = m['user'] as Map<String, dynamic>?;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.shield_rounded, size: 14, color: DesignTokens.primary),
                        const SizedBox(width: 6),
                        Text(
                          'u/${user?['username'] ?? 'unknown'}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  TextStyle _labelStyle() {
    return TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: theme.brightness == Brightness.dark
          ? DesignTokens.darkTextTertiary
          : DesignTokens.textTertiary,
    );
  }

  Widget _stat(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: DesignTokens.textSecondary),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: DesignTokens.textSecondary)),
      ],
    );
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return 'Unknown';
    try {
      final dt = DateTime.parse(iso);
      return '${dt.month}/${dt.day}/${dt.year}';
    } catch (_) {
      return 'Unknown';
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'public':
        return 'Public community';
      case 'restricted':
        return 'Restricted — approval needed to post';
      case 'private':
        return 'Private — invite only';
      default:
        return type;
    }
  }
}

class _Divider extends StatelessWidget {
  final bool dark;
  const _Divider({required this.dark});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      color: dark ? DesignTokens.darkBorder : DesignTokens.border,
    );
  }
}
