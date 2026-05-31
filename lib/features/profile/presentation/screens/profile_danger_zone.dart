import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'profile_list_widgets.dart';

class ProfileDangerZone extends ConsumerWidget {
  const ProfileDangerZone({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const SectionLabel(label: 'DANGER ZONE'),
        const SizedBox(height: 10),
        GlassCard(
          child: Column(
            children: [
              _DangerRow(
                icon: Icons.logout,
                label: 'Log Out',
                onTap: () => _confirmLogout(context, ref),
              ),
              const SectionDivider(),
              _DangerRow(
                icon: Icons.delete_forever_outlined,
                label: 'Delete Account',
                onTap: () => _confirmDeleteAccount(context, ref),
                isDestructive: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

void _confirmLogout(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusXl)),
      title: const Row(
        children: [
          Icon(Icons.logout, size: 20, color: DesignTokens.error),
          SizedBox(width: 8),
          Text('Log out?',
              style: TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
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
  );
}

void _confirmDeleteAccount(BuildContext context, WidgetRef ref) {
  final pwdCtrl = TextEditingController();
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusXl)),
      title: const Row(
        children: [
          Icon(Icons.warning_rounded,
              size: 20, color: DesignTokens.error),
          SizedBox(width: 8),
          Text('Delete Account',
              style: TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This will permanently delete your account, study history, '
            'progress, and all associated data. This action cannot be undone.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: pwdCtrl,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Enter your password to confirm',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            final password = pwdCtrl.text.trim();
            if (password.isEmpty) return;
            Navigator.pop(ctx);
            _performDelete(context, ref, password);
          },
          child: const Text('Delete Account',
              style: TextStyle(color: DesignTokens.error)),
        ),
      ],
    ),
  );
}

Future<void> _performDelete(
    BuildContext context, WidgetRef ref, String password) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  final error = await ref.read(authProvider.notifier).deleteAccount(password);
  if (!context.mounted) return;
  Navigator.pop(context);

  if (error != null) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusXl)),
        title: const Text('Error',
            style: TextStyle(color: DesignTokens.error)),
        content: Text(error),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK')),
        ],
      ),
    );
  }
}

class _DangerRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _DangerRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: DesignTokens.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                ),
                child: Icon(icon, size: 16, color: DesignTokens.error),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDestructive
                          ? DesignTokens.error
                          : DesignTokens.error,
                    )),
              ),
              const Icon(Icons.chevron_right,
                  size: 16, color: DesignTokens.error),
            ],
          ),
        ),
      ),
    );
  }
}
