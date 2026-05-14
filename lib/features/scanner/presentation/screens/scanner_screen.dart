import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});
  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  File? _image;
  String _educationLevel = 'secondary';
  String _subject = '';
  String _examType = '';
  String _year = '';
  bool _solving = false;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: source, maxWidth: 2048, maxHeight: 2048);
    if (x != null) setState(() => _image = File(x.path));
  }

  Future<void> _submit() async {
    if (_image == null) return;
    setState(() => _solving = true);
    try {
      final client = ref.read(graphqlClientProvider);
      final bytes = await _image!.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image too large. Choose a smaller file.'), backgroundColor: DesignTokens.error),
          );
          setState(() => _solving = false);
        }
        return;
      }
      final b64 = base64Encode(bytes);
      final result = await client.mutate(MutationOptions(
        document: gql(kSubmitScanSession),
        variables: {
          'imageBase64': b64,
          'fileName': _image!.path.split('/').last,
          'subject': _subject.trim(),
          'educationLevel': _educationLevel,
          'examType': _examType.trim(),
          'year': int.tryParse(_year),
        },
      ));
      if (!mounted) return;
      setState(() => _solving = false);
      if (result.hasException || result.data?['submitScanSession'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.exception?.graphqlErrors.firstOrNull?.message ?? 'Failed to solve paper'),
            backgroundColor: DesignTokens.error,
          ),
        );
        return;
      }
      final data = result.data!['submitScanSession'];
      if (data['success'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text((data['errors'] as List?)?.firstOrNull?.toString() ?? 'Failed'),
            backgroundColor: DesignTokens.error,
          ),
        );
        return;
      }
      context.push('/scanner/results', extra: {'solutions': data['session']?['solutions'] ?? []});
    } catch (e) {
      if (!mounted) return;
      setState(() => _solving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to solve paper: $e'), backgroundColor: DesignTokens.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text('Magic Scanner', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.spMd),
        child: Column(
          children: [
            GlassCard(
              child: Column(
                children: [
                  if (_image != null)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                          child: Image.file(_image!, height: 250, width: double.infinity, fit: BoxFit.contain),
                        ),
                        Positioned(
                          top: 8, right: 8,
                          child: GestureDetector(
                            onTap: () => _pickImage(ImageSource.camera),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                              ),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    GestureDetector(
                      onTap: () => showModalBottomSheet(
                        context: context,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusXl)),
                        ),
                        builder: (_) => SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(DesignTokens.spMd),
                            child: Column(mainAxisSize: MainAxisSize.min, children: [
                              ListTile(
                                leading: Container(
                                  width: 48, height: 48,
                                  decoration: BoxDecoration(color: DesignTokens.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(DesignTokens.radiusMd)),
                                  child: const Icon(Icons.camera_alt, color: DesignTokens.primary),
                                ),
                                title: const Text('Take a photo'),
                                onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
                              ),
                              ListTile(
                                leading: Container(
                                  width: 48, height: 48,
                                  decoration: BoxDecoration(color: DesignTokens.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(DesignTokens.radiusMd)),
                                  child: const Icon(Icons.photo_library, color: DesignTokens.accent),
                                ),
                                title: const Text('Choose from gallery'),
                                onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
                              ),
                            ]),
                          ),
                        ),
                      ),
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                          border: Border.all(color: (dark ? DesignTokens.darkBorder : DesignTokens.border).withValues(alpha: 0.5), width: 2),
                        ),
                        child: Center(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Container(
                              width: 72, height: 72,
                              decoration: BoxDecoration(color: DesignTokens.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                              child: const Icon(Icons.document_scanner, size: 36, color: DesignTokens.primary),
                            ),
                            const SizedBox(height: DesignTokens.spMd),
                            const Text('Upload a past paper photo', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                            const SizedBox(height: 4),
                            const Text('PDF, JPG, or PNG', style: TextStyle(color: DesignTokens.textSecondary, fontSize: 13)),
                          ]),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.spMd),
            GlassCard(
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(labelText: 'Subject', hintText: 'e.g. Mathematics'),
                    onChanged: (v) => _subject = v,
                  ),
                  const SizedBox(height: DesignTokens.spSm),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Exam type (optional)', hintText: 'e.g. MSCE, Final'),
                    onChanged: (v) => _examType = v,
                  ),
                  const SizedBox(height: DesignTokens.spSm),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          key: ValueKey(_educationLevel),
                          initialValue: _educationLevel,
                          decoration: const InputDecoration(labelText: 'Level'),
                          items: 'primary|secondary|tertiary'
                              .split('|')
                              .map((l) => DropdownMenuItem(value: l, child: Text(l[0].toUpperCase() + l.substring(1))))
                              .toList(),
                          onChanged: (v) => setState(() => _educationLevel = v!),
                        ),
                      ),
                      const SizedBox(width: DesignTokens.spSm),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(labelText: 'Year'),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => _year = v,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.spLg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_image != null && !_solving) ? _submit : null,
                icon: _solving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.auto_awesome),
                label: Text(_solving ? 'Solving...' : 'Solve Paper'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
