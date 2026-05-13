import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../theme/design_tokens.dart';
import '../services/connectivity_service.dart';

class OfflineBanner extends StatefulWidget {
  final Widget child;

  const OfflineBanner({super.key, required this.child});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    ConnectivityService.onConnectivityChanged.listen((_) {
      _checkConnectivity();
    });
  }

  Future<void> _checkConnectivity() async {
    final offline = await ConnectivityService.isOffline();
    if (mounted) {
      setState(() => _isOffline = offline);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_isOffline)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spMd,
              vertical: DesignTokens.spSm,
            ),
            color: DesignTokens.warning,
            child: Row(
              children: [
                const Icon(Icons.wifi_off, color: Colors.white, size: 16),
                const SizedBox(width: DesignTokens.spSm),
                const Text(
                  'You\'re offline. Some features may not work.',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}
