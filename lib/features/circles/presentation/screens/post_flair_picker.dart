import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../domain/circles_domain.dart';
import '../providers/circles_providers.dart';

/// Opens a bottom sheet that lets the author/mod pick a flair for a post.
/// Loads the community's flair templates and applies the chosen one (or
/// clears it) via [CirclesRepository.setPostFlair]. Returns true if changed.
Future<bool> showPostFlairPicker(
  BuildContext context, {
  required String communitySlug,
  required String postId,
}) async {
  final changed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _PostFlairSheet(
      communitySlug: communitySlug,
      postId: postId,
    ),
  );
  return changed ?? false;
}

class _PostFlairSheet extends ConsumerStatefulWidget {
  final String communitySlug;
  final String postId;

  const _PostFlairSheet({required this.communitySlug, required this.postId});

  @override
  ConsumerState<_PostFlairSheet> createState() => _PostFlairSheetState();
}

class _PostFlairSheetState extends ConsumerState<_PostFlairSheet> {
  late Future<List<CirclePostFlair>> _future;
  bool _applying = false;

  @override
  void initState() {
    super.initState();
    _future = ref
        .read(circlesRepositoryProvider)
        .communityFlairs(widget.communitySlug);
  }

  Future<void> _apply(String? flairId) async {
    setState(() => _applying = true);
    try {
      await ref
          .read(circlesRepositoryProvider)
          .setPostFlair(postId: widget.postId, flairId: flairId);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
        setState(() => _applying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose flair',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Flexible(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return FutureBuilder<List<CirclePostFlair>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: LoadingWidget()),
          );
        }
        if (snapshot.hasError) {
          return ErrorState(
            message: 'Could not load flairs',
            onRetry: () => setState(() {
              _future = ref
                  .read(circlesRepositoryProvider)
                  .communityFlairs(widget.communitySlug);
            }),
          );
        }
        final flairs = snapshot.data ?? const <CirclePostFlair>[];
        if (flairs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('This community has no flairs yet.',
                style: TextStyle(color: DesignTokens.textSecondary)),
          );
        }
        return ListView(
          shrinkWrap: true,
          children: [
            for (final flair in flairs) _flairTile(flair),
            const Divider(height: 24),
            ListTile(
              enabled: !_applying,
              leading: const Icon(Icons.clear, color: DesignTokens.textTertiary),
              title: const Text('Clear flair'),
              onTap: _applying ? null : () => _apply(null),
            ),
          ],
        );
      },
    );
  }

  Widget _flairTile(CirclePostFlair flair) {
    final color = _parseColor(flair.color) ?? DesignTokens.primary;
    return ListTile(
      enabled: !_applying,
      leading: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      title: Text('${flair.emoji ?? ''} ${flair.text}'.trim()),
      trailing: flair.modOnly
          ? const Icon(Icons.shield_outlined,
              size: 16, color: DesignTokens.textTertiary)
          : null,
      onTap: _applying ? null : () => _apply(flair.id),
    );
  }

  Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    var value = hex.replaceFirst('#', '');
    if (value.length == 6) value = 'FF$value';
    final parsed = int.tryParse(value, radix: 16);
    return parsed == null ? null : Color(parsed);
  }
}
