import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class UploadMaterialScreen extends ConsumerStatefulWidget {
  const UploadMaterialScreen({super.key});
  @override
  ConsumerState<UploadMaterialScreen> createState() => _UploadMaterialScreenState();
}

class _UploadMaterialScreenState extends ConsumerState<UploadMaterialScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _textCtrl = TextEditingController();
  final _youtubeCtrl = TextEditingController();
  String _contentType = 'text';
  String? _subjectId;
  bool _saving = false;
  List? _subjects;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    final client = ref.read(graphqlClientProvider);
    final r = await client.query(QueryOptions(document: gql(kSubjects), fetchPolicy: FetchPolicy.cacheFirst));
    if (mounted) setState(() => _subjects = (r.data?['subjects'] as List?) ?? []);
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty || _subjectId == null) return;
    setState(() => _saving = true);
    final client = ref.read(graphqlClientProvider);
    final result = await client.mutate(MutationOptions(
      document: gql(kUploadMaterial),
      variables: {
        'title': _titleCtrl.text.trim(),
        'subjectId': _subjectId,
        'contentType': _contentType,
        'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'contentText': _textCtrl.text.trim().isEmpty ? null : _textCtrl.text.trim(),
        'youtubeUrl': _youtubeCtrl.text.trim().isEmpty ? null : _youtubeCtrl.text.trim(),
      },
    ));
    if (mounted) {
      setState(() => _saving = false);
      if (result.hasException || result.data?['uploadMaterial']?['success'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Upload failed'), backgroundColor: DesignTokens.error));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Material submitted for review'), backgroundColor: DesignTokens.success));
        context.pop();
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose(); _descCtrl.dispose(); _textCtrl.dispose(); _youtubeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('Upload Material', style: theme.textTheme.titleLarge)),
      body: ListView(
        padding: const EdgeInsets.all(DesignTokens.spMd),
        children: [
          TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Title'), textInputAction: TextInputAction.next),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            key: ValueKey('subject_${_subjects?.length}_$_subjectId'),
            initialValue: _subjectId,
            decoration: const InputDecoration(labelText: 'Subject'),
            items: (_subjects ?? [])
                .map((s) => DropdownMenuItem<String>(
                      value: s['id']?.toString(),
                      child: Text(s['name']?.toString() ?? ''),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _subjectId = v),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            key: ValueKey(_contentType),
            initialValue: _contentType,
            decoration: const InputDecoration(labelText: 'Type'),
            items: 'pdf|text|video|image'.split('|').map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase()))).toList(),
            onChanged: (v) => setState(() => _contentType = v ?? 'text'),
          ),
          const SizedBox(height: 16),
          TextField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3, textInputAction: TextInputAction.next),
          if (_contentType == 'video') ...[
            const SizedBox(height: 16),
            TextField(controller: _youtubeCtrl, decoration: const InputDecoration(labelText: 'YouTube URL'), textInputAction: TextInputAction.next),
          ],
          if (_contentType == 'text') ...[
            const SizedBox(height: 16),
            TextField(controller: _textCtrl, decoration: const InputDecoration(labelText: 'Content'), maxLines: 6),
          ],
          const SizedBox(height: 32),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: _saving ? null : _submit,
            child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Submit'),
          )),
        ],
      ),
    );
  }
}
