import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

class LogoutDialog extends StatelessWidget {
  final VoidCallback onLogout;
  const LogoutDialog({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusXl)),
      title: const Row(
        children: [
          Icon(Icons.logout, size: 20, color: DesignTokens.error),
          SizedBox(width: 8),
          Text('Log out?', style: TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
      content: const Text(
          'You will need to log in again to access your study data.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onLogout();
          },
          child: const Text('Log out',
              style: TextStyle(color: DesignTokens.error)),
        ),
      ],
    );
  }
}

class DeleteAccountDialog extends StatefulWidget {
  final void Function(String password) onDelete;
  const DeleteAccountDialog({super.key, required this.onDelete});

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final _pwdCtrl = TextEditingController();

  @override
  void dispose() {
    _pwdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusXl)),
      title: const Row(
        children: [
          Icon(Icons.warning_rounded, size: 20, color: DesignTokens.error),
          SizedBox(width: 8),
          Text('Delete Account', style: TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('This will permanently delete your account, '
              'study history, progress, and all associated data. '
              'This action cannot be undone.'),
          const SizedBox(height: 16),
          TextField(
            controller: _pwdCtrl,
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            final password = _pwdCtrl.text.trim();
            if (password.isEmpty) return;
            widget.onDelete(password);
          },
          child: const Text('Delete Account',
              style: TextStyle(color: DesignTokens.error)),
        ),
      ],
    );
  }
}

class DeleteAccountErrorDialog extends StatelessWidget {
  final String error;
  const DeleteAccountErrorDialog({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusXl)),
      title: const Text('Error', style: TextStyle(color: DesignTokens.error)),
      content: Text(error),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('OK')),
      ],
    );
  }
}
