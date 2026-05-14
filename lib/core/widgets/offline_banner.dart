import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
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
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _connectivitySub = ConnectivityService.onConnectivityChanged.listen((_) {
      _checkConnectivity();
    });
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    final offline = await ConnectivityService.isOffline();
    if (mounted) {
      setState(() => _isOffline = offline);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use Stack, not Column+Expanded: wrapping MaterialApp.router in Expanded can
    // break navigator layout and produce a permanent blank screen on some devices.
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_isOffline)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Material(
              elevation: 2,
              color: DesignTokens.warning,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: DesignTokens.spMd,
                    vertical: DesignTokens.spSm,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.wifi_off, color: Colors.white, size: 16),
                      SizedBox(width: DesignTokens.spSm),
                      Expanded(
                        child: Text(
                          'You\'re offline. Some features may not work.',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
