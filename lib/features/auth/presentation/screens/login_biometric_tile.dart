import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/theme/design_tokens.dart';

class LoginBiometricTile extends ConsumerStatefulWidget {
  const LoginBiometricTile({super.key});

  @override
  ConsumerState<LoginBiometricTile> createState() => _LoginBiometricTileState();
}

class _LoginBiometricTileState extends ConsumerState<LoginBiometricTile> {
  bool _available = false;
  bool _enabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bio = BiometricService();
    final available = await bio.isAvailable();
    final enabled = await bio.isEnabled();
    if (mounted) {
      setState(() {
        _available = available;
        _enabled = enabled;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || !_available) return const SizedBox.shrink();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await BiometricService().setEnabled(!_enabled);
          if (mounted) setState(() => _enabled = !_enabled);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              Icon(
                Icons.fingerprint_rounded,
                size: 22,
                color:
                    _enabled ? DesignTokens.primary : DesignTokens.textTertiary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Unlock on this phone',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _enabled
                            ? DesignTokens.textPrimary
                            : DesignTokens.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Use Face ID or fingerprint after login',
                      style: TextStyle(
                        fontSize: 12,
                        color: DesignTokens.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _enabled,
                onChanged: (v) async {
                  await BiometricService().setEnabled(v);
                  if (mounted) setState(() => _enabled = v);
                },
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
