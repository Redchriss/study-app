import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/design_tokens.dart';
import '../providers/circles_providers.dart';
import 'create_post_community_widgets.dart';

/// Lets moderators upload a community's icon and banner. Backed by the
/// previously-unreachable `uploadCommunityIcon` / `uploadCommunityBanner`
/// mutations via [CirclesRepository].
class CommunityImageSection extends ConsumerStatefulWidget {
  final String communitySlug;
  final String? icon;
  final String? banner;

  const CommunityImageSection({
    super.key,
    required this.communitySlug,
    this.icon,
    this.banner,
  });

  @override
  ConsumerState<CommunityImageSection> createState() =>
      _CommunityImageSectionState();
}

class _CommunityImageSectionState extends ConsumerState<CommunityImageSection> {
  String? _icon;
  String? _banner;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _icon = widget.icon;
    _banner = widget.banner;
  }

  Future<void> _upload({required bool isIcon}) async {
    final picked = await pickPostImage();
    if (picked == null) return;
    setState(() => _busy = true);
    final repo = ref.read(circlesRepositoryProvider);
    try {
      final url = isIcon
          ? await repo.uploadCommunityIcon(
              slug: widget.communitySlug, imageBase64: picked.base64)
          : await repo.uploadCommunityBanner(
              slug: widget.communitySlug, imageBase64: picked.base64);
      if (!mounted) return;
      setState(() {
        if (isIcon) {
          _icon = url ?? _icon;
        } else {
          _banner = url ?? _banner;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isIcon ? 'Icon updated' : 'Banner updated'),
          backgroundColor: DesignTokens.success));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _bannerPreview(),
        const SizedBox(height: 12),
        Row(
          children: [
            _iconPreview(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => _upload(isIcon: true),
                    icon: const Icon(Icons.account_circle_outlined, size: 18),
                    label: const Text('Change icon'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => _upload(isIcon: false),
                    icon: const Icon(Icons.panorama_outlined, size: 18),
                    label: const Text('Change banner'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _bannerPreview() {
    final hasBanner = (_banner ?? '').isNotEmpty;
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: DesignTokens.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        image: hasBanner
            ? DecorationImage(
                image: NetworkImage(_banner!), fit: BoxFit.cover)
            : null,
      ),
      alignment: Alignment.center,
      child: hasBanner
          ? null
          : const Text('No banner',
              style: TextStyle(color: DesignTokens.textSecondary)),
    );
  }

  Widget _iconPreview() {
    final hasIcon = (_icon ?? '').isNotEmpty;
    return CircleAvatar(
      radius: 28,
      backgroundColor: DesignTokens.primary.withValues(alpha: 0.15),
      backgroundImage: hasIcon ? NetworkImage(_icon!) : null,
      child: hasIcon
          ? null
          : const Icon(Icons.groups_rounded, color: DesignTokens.primary),
    );
  }
}
