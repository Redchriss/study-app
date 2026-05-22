import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/scanner_subjects_provider.dart';
import 'scanner_shared_widgets.dart';
import 'scanner_submit_service.dart';

class ScannerDetailsForm extends ConsumerStatefulWidget {
  final File image;
  final ValueChanged<bool> onSolvingChanged;

  const ScannerDetailsForm({
    super.key,
    required this.image,
    required this.onSolvingChanged,
  });

  @override
  ConsumerState<ScannerDetailsForm> createState() => _ScannerDetailsFormState();
}

class _ScannerDetailsFormState extends ConsumerState<ScannerDetailsForm> {
  String? _educationLevel;
  String? _subject;
  String _examType = '';
  String _year = '';
  bool _solving = false;
  late final TextEditingController _examTypeCtrl;

  @override
  void initState() {
    super.initState();
    _examTypeCtrl = TextEditingController();
    final auth = ref.read(authProvider);
    _educationLevel =
        auth.user?['profile']?['educationLevel']?.toString() ?? 'secondary';
    _examType = _examTypeDefault();
    _examTypeCtrl.text = _examTypeDefault();
    ref.read(scannerSubjectsProvider.notifier).load(level: _educationLevel!);
  }

  @override
  void dispose() {
    _examTypeCtrl.dispose();
    super.dispose();
  }

  String _examTypeHint() {
    switch (_educationLevel) {
      case 'primary':
        return 'e.g. PSLCE';
      case 'tertiary':
        return 'e.g. End of Semester';
      default:
        return 'e.g. MSCE, JCE';
    }
  }

  String _examTypeDefault() {
    switch (_educationLevel) {
      case 'primary':
        return 'PSLCE';
      case 'tertiary':
        return 'End of Semester';
      default:
        return 'MSCE';
    }
  }

  Future<void> _submit() async {
    if (_solving) return;
    setState(() => _solving = true);
    widget.onSolvingChanged(true);
    await ScannerSubmitService.submit(
      ref: ref,
      image: widget.image,
      subject: _subject,
      educationLevel: _educationLevel,
      examType: _examType,
      year: _year,
      context: context,
      onSolvingStart: () {},
      onSolvingEnd: () {
        if (mounted) {
          setState(() => _solving = false);
          widget.onSolvingChanged(false);
        }
      },
    );
  }

  Row _buildLevelChips() {
    return Row(
      children: [
        LevelChip(
            label: 'Primary',
            icon: Icons.child_care_rounded,
            selected: _educationLevel == 'primary',
            onTap: () {
              setState(() {
                _educationLevel = 'primary';
                _subject = null;
                _examType = _examTypeDefault();
                _examTypeCtrl.text = _examTypeDefault();
              });
              ref.read(scannerSubjectsProvider.notifier).load(level: 'primary');
            }),
        const SizedBox(width: 8),
        LevelChip(
            label: 'Secondary',
            icon: Icons.menu_book_rounded,
            selected: _educationLevel == 'secondary',
            onTap: () {
              setState(() {
                _educationLevel = 'secondary';
                _subject = null;
                _examType = _examTypeDefault();
                _examTypeCtrl.text = _examTypeDefault();
              });
              ref
                  .read(scannerSubjectsProvider.notifier)
                  .load(level: 'secondary');
            }),
        const SizedBox(width: 8),
        LevelChip(
            label: 'Tertiary',
            icon: Icons.account_balance_rounded,
            selected: _educationLevel == 'tertiary',
            onTap: () {
              setState(() {
                _educationLevel = 'tertiary';
                _subject = null;
                _examType = _examTypeDefault();
                _examTypeCtrl.text = _examTypeDefault();
              });
              ref
                  .read(scannerSubjectsProvider.notifier)
                  .load(level: 'tertiary');
            }),
      ],
    );
  }

  Widget _buildSubjectField() {
    final subjectsState = ref.watch(scannerSubjectsProvider);
    if (subjectsState.loading) return const LoadingWidget();
    final dark = Theme.of(context).brightness == Brightness.dark;
    final subjects = subjectsState.subjects;
    return DropdownButtonFormField<String>(
      key: ValueKey('scanner_subject_${subjects.length}_$_subject'),
      initialValue: _subject,
      decoration: InputDecoration(
        labelText: 'Subject',
        filled: true,
        fillColor:
            dark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
        prefixIcon: const Icon(Icons.book_outlined),
      ),
      items: subjects
          .map((s) => DropdownMenuItem<String>(
                value: s['name']?.toString(),
                child: Text(s['name']?.toString() ?? ''),
              ))
          .toList(),
      onChanged: (v) => setState(() => _subject = v),
    );
  }

  Widget _buildExamTypeYearFields() {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Expanded(
            flex: 2,
            child: TextField(
              controller: _examTypeCtrl,
              decoration: InputDecoration(
                labelText: 'Exam type',
                hintText: _examTypeHint(),
                filled: true,
                fillColor: dark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.shade50,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none),
              ),
              onChanged: (v) => _examType = v,
            )),
        const SizedBox(width: 12),
        Expanded(
            child: TextField(
          decoration: InputDecoration(
            labelText: 'Year',
            filled: true,
            fillColor: dark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.shade50,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none),
          ),
          keyboardType: TextInputType.number,
          onChanged: (v) => _year = v,
        )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Paper Details',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text('Help the AI understand what it is looking at.',
            style: TextStyle(color: DesignTokens.textSecondary, fontSize: 13)),
        const SizedBox(height: 20),
        _buildLevelChips(),
        const SizedBox(height: 20),
        _buildSubjectField(),
        const SizedBox(height: 16),
        _buildExamTypeYearFields(),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton.icon(
            onPressed: _solving ? null : _submit,
            icon: _solving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.auto_awesome_rounded),
            label: Text(_solving ? 'Solving...' : 'Solve This Paper',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }
}
