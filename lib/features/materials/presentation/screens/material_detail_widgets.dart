import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

class MaterialDetailAiBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final int cost;
  final bool loading;
  final VoidCallback? onTap;

  const MaterialDetailAiBtn(
      {super.key,
      required this.label,
      required this.icon,
      required this.cost,
      this.loading = false,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedPress(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: DesignTokens.spSm),
          decoration: BoxDecoration(
            color: DesignTokens.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            border:
                Border.all(color: DesignTokens.primary.withValues(alpha: 0.15)),
          ),
          child: Column(children: [
            loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(icon, color: DesignTokens.primary, size: 20),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.primary)),
            Text('−$cost 💎',
                style: const TextStyle(
                    fontSize: 10, color: DesignTokens.textTertiary)),
          ]),
        ),
      ),
    );
  }
}

class MaterialDetailYoutubePlayer extends StatefulWidget {
  final String url;
  final ValueChanged<YoutubePlayerController> onControllerReady;
  const MaterialDetailYoutubePlayer(
      {super.key, required this.url, required this.onControllerReady});
  @override
  State<MaterialDetailYoutubePlayer> createState() =>
      _MaterialDetailYoutubePlayerState();
}

class _MaterialDetailYoutubePlayerState
    extends State<MaterialDetailYoutubePlayer> {
  late final YoutubePlayerController _ctrl;

  String _extractVideoId(String url) {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      final fromQuery = uri.queryParameters['v'];
      if (fromQuery != null && fromQuery.isNotEmpty) return fromQuery;
      final segments =
          uri.pathSegments.where((segment) => segment.isNotEmpty).toList();
      if (uri.host.contains('youtu.be') && segments.isNotEmpty)
        return segments.first;
      if (segments.length >= 2 && segments.first == 'embed') return segments[1];
      if (segments.isNotEmpty) return segments.last;
    }
    final parts = url.split('/');
    return parts.last.split('?').first;
  }

  @override
  void initState() {
    super.initState();
    _ctrl = YoutubePlayerController.fromVideoId(
      videoId: _extractVideoId(widget.url),
      autoPlay: false,
      params: const YoutubePlayerParams(showFullscreenButton: true),
    );
    widget.onControllerReady(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        child: YoutubePlayer(controller: _ctrl, aspectRatio: 16 / 9),
      ),
    );
  }
}
