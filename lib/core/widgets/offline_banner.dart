import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import '../services/app_preferences_service.dart';
import '../services/connectivity_service.dart';
import '../services/hive_service.dart';

class OfflineBanner extends StatefulWidget {
  final Widget child;

  const OfflineBanner({super.key, required this.child});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  final _preferences = AppPreferencesService();
  bool _isOffline = false;
  bool _lowDataMode = false;
  bool _hasPending = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _loadPreferences();
    _checkPending();
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
    if (!offline) _checkPending();
  }

  void _checkPending() {
    try {
      if (!HiveService.isInitialized) return;
      final pending = HiveService.hasAnyPending();
      if (mounted) setState(() => _hasPending = pending);
    } catch (_) {
      // Hive not yet initialized — skip pending check
    }
  }

  Future<void> _loadPreferences() async {
    final lowDataMode = await _preferences.isLowDataMode();
    if (mounted) {
      setState(() => _lowDataMode = lowDataMode);
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
        if (_isOffline || _lowDataMode)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Material(
              elevation: 2,
              color: _isOffline ? DesignTokens.warning : DesignTokens.info,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spMd,
                    vertical: DesignTokens.spSm,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isOffline
                            ? Icons.wifi_off
                            : Icons.data_saver_on_outlined,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: DesignTokens.spSm),
                      Expanded(
                        child: Text(
                          _isOffline
                              ? 'You\'re offline. Cached study materials remain available.'
                              : 'Low-data mode is on. Heavy previews are reduced to save bandwidth.',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (!_isOffline && _hasPending)
          Positioned(
            top: _isOffline || _lowDataMode ? 40 : 0,
            left: 0,
            right: 0,
            child: Material(
              elevation: 2,
              color: DesignTokens.info,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spMd,
                    vertical: DesignTokens.spSm,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_upload_outlined,
                          color: Colors.white, size: 16),
                      const SizedBox(width: DesignTokens.spSm),
                      Expanded(
                        child: Text(
                          '${HiveService.totalPendingCount()} pending submission${HiveService.totalPendingCount() == 1 ? '' : 's'} — retrying automatically.',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
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
