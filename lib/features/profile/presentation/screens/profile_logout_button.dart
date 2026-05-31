import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfileLogoutButton extends ConsumerWidget {
  const ProfileLogoutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: () => showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusXl)),
            title: const Text('Log out?',
                style: TextStyle(fontWeight: FontWeight.w800)),
            content: const Text(
                'You will need to log in again to access your study data.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel')),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ref.read(authProvider.notifier).logout();
                },
                child: const Text('Log out',
                    style: TextStyle(color: DesignTokens.error)),
              ),
            ],
          ),
        ),
        icon: const Icon(Icons.logout, size: 18),
        label: const Text('Log Out'),
        style: OutlinedButton.styleFrom(
          foregroundColor: DesignTokens.error,
          side: const BorderSide(color: DesignTokens.error),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusLg)),
        ),
      ),
    );
  }
}
