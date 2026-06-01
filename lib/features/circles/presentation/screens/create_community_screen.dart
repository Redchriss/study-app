import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

const String kCreateCommunity = r'''mutation CreateCommunity { __typename }''';

class CreateCommunityScreen extends ConsumerStatefulWidget {
  const CreateCommunityScreen({super.key});

  @override
  ConsumerState<CreateCommunityScreen> createState() =>
      _CreateCommunityScreenState();
}

class _CreateCommunityScreenState extends ConsumerState<CreateCommunityScreen> {
  final _nameCtrl = TextEditingController();
  final _displayNameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _type = 'public';
  bool _over18 = false;
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _displayNameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _nameCtrl.text.trim().length >= 3 &&
      _displayNameCtrl.text.trim().isNotEmpty;

  Future<void> _submit() async {
    if (!_isValid || _submitting) return;
    setState(() => _submitting = true);
    try {
      final client = ref.read(graphqlClientProvider);
      final result = await client.mutate(MutationOptions(
        document: gql(kCreateCommunity),
        variables: {
          'name': _nameCtrl.text.trim(),
          'displayName': _displayNameCtrl.text.trim(),
          'description': _descCtrl.text.trim(),
          'communityType': _type,
          'over18': _over18,
        },
      ));
      if (!mounted) return;
      final payload = result.data?['createCommunity'];
      final errors = (payload?['errors'] as List?)?.join(', ');
      if (result.hasException || (errors != null && errors.isNotEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(errors ??
              graphQLErrorMessage(
                  result.exception, 'Could not create community')),
          backgroundColor: DesignTokens.error,
        ));
        return;
      }
      final slug = payload?['community']?['slug']?.toString();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Community created!'),
          backgroundColor: DesignTokens.success,
        ));
        if (slug != null) {
          context.go('/y/$slug');
        } else {
          context.pop();
        }
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Community'),
        actions: [
          TextButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text('Create',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _isValid
                            ? DesignTokens.primary
                            : DesignTokens.textTertiary)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'community_name (no spaces)',
                border: OutlineInputBorder(),
                helperText: '3+ characters, lowercase, no spaces',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _displayNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            Text('Community Type',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(
                    value: 'public', child: Text('Public - Anyone can join')),
                DropdownMenuItem(
                    value: 'restricted',
                    child: Text('Restricted - Approval required')),
                DropdownMenuItem(
                    value: 'private', child: Text('Private - Invite only')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _type = v);
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('18+ / NSFW'),
              value: _over18,
              onChanged: (v) => setState(() => _over18 = v),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}
