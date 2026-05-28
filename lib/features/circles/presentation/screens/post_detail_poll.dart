import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';

class PollWidget extends StatelessWidget {
  final Map<String, dynamic> poll;
  final bool dark;
  const PollWidget({super.key, required this.poll, required this.dark});

  String _timeRemaining(String? closesAt) {
    if (closesAt == null) return '';
    try {
      final dt = DateTime.parse(closesAt);
      final diff = dt.difference(DateTime.now());
      if (diff.isNegative) return 'Closed';
      if (diff.inDays > 0)
        return '${diff.inDays}d ${diff.inHours % 24}h remaining';
      if (diff.inHours > 0) return '${diff.inHours}h remaining';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m remaining';
      return 'Closing soon';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = (poll['options'] as List?) ?? [];
    final total = options.fold<int>(
        0, (sum, o) => sum + ((o['voteCount'] as num?)?.toInt() ?? 0));
    final userVote = poll['userVote'] as Map<String, dynamic>?;
    final hasVoted = userVote != null;
    final closesAt = poll['closesAt']?.toString();
    final timeRemaining = _timeRemaining(closesAt);
    final closed = timeRemaining == 'Closed';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark
            ? DesignTokens.darkSurfaceVariant
            : DesignTokens.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Poll${closed ? " (closed)" : ""}',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              if (timeRemaining.isNotEmpty)
                Text(timeRemaining,
                    style: TextStyle(
                      fontSize: 11,
                      color: closed
                          ? DesignTokens.error
                          : DesignTokens.textSecondary,
                      fontWeight: closed ? FontWeight.w600 : FontWeight.normal,
                    )),
            ],
          ),
          const SizedBox(height: 8),
          ...options.map((o) {
            final count = (o['voteCount'] as num?)?.toInt() ?? 0;
            final pct = total > 0 ? count / total : 0.0;
            final isSelected = hasVoted && userVote['id'] == o['id'];
            final pollId = poll['id'].toString();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Mutation(
                options: MutationOptions(document: gql(kVotePoll)),
                builder: (run, _) => GestureDetector(
                  onTap: (hasVoted || closed)
                      ? null
                      : () => run({'pollId': pollId, 'optionId': o['id']}),
                  child: Stack(
                    children: [
                      Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? DesignTokens.primary.withValues(alpha: 0.15)
                              : dark
                                  ? DesignTokens.darkSurface
                                  : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 12),
                            if (hasVoted || closed) ...[
                              Icon(
                                isSelected
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                size: 18,
                                color: isSelected
                                    ? DesignTokens.primary
                                    : DesignTokens.textTertiary,
                              ),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: Text(o['text']?.toString() ?? '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                            ),
                            if (hasVoted || closed)
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Text('${(pct * 100).toInt()}%',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: DesignTokens.textSecondary)),
                              ),
                          ],
                        ),
                      ),
                      if ((hasVoted || closed) && pct > 0)
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: pct,
                              child: Container(
                                color: DesignTokens.primary
                                    .withValues(alpha: 0.08),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (hasVoted || closed)
            Text('$total total votes',
                style: const TextStyle(
                    fontSize: 11, color: DesignTokens.textTertiary)),
        ],
      ),
    );
  }
}
