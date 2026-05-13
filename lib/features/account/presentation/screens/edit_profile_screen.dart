import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});
  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _firstNameCtrl.text = user?['firstName'] as String? ?? '';
    _lastNameCtrl.text = user?['lastName'] as String? ?? '';
    _emailCtrl.text = user?['email'] as String? ?? '';
    _phoneCtrl.text = user?['phone'] as String? ?? '';
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final client = ref.read(graphqlClientProvider);
    final result = await client.mutate(MutationOptions(
      document: gql(kUpdateProfile),
      variables: {
        'input': {
          'firstName': _firstNameCtrl.text,
          'lastName': _lastNameCtrl.text,
          if (_emailCtrl.text.isNotEmpty) 'email': _emailCtrl.text,
          if (_phoneCtrl.text.isNotEmpty) 'phone': _phoneCtrl.text,
        }
      },
    ));
    if (mounted) {
      setState(() => _saving = false);
      if (result.hasException) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed'), backgroundColor: DesignTokens.error));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile updated'), backgroundColor: DesignTokens.success));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.read(authProvider).user;
    return Scaffold(
      appBar: AppBar(title: Text('Edit Profile', style: theme.textTheme.titleLarge)),
      body: ListView(
        padding: const EdgeInsets.all(DesignTokens.spMd),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: DesignTokens.primary,
                  child: Text(user?['username']?.toString().substring(0, 1).toUpperCase() ?? '?',
                    style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.w700)),
                ),
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: DesignTokens.primary),
                    child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextField(controller: _firstNameCtrl, decoration: const InputDecoration(labelText: 'First Name'), textInputAction: TextInputAction.next),
          const SizedBox(height: 16),
          TextField(controller: _lastNameCtrl, decoration: const InputDecoration(labelText: 'Last Name'), textInputAction: TextInputAction.next),
          const SizedBox(height: 16),
          TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next),
          const SizedBox(height: 16),
          TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Phone'), keyboardType: TextInputType.phone, textInputAction: TextInputAction.done),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save Changes'),
            ),
          ),
        ],
      ),
    );
  }
}
