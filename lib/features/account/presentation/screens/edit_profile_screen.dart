import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/education_pickers.dart';

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

  String? _educationLevel;
  int? _standard;
  int? _form;
  String? _term;
  String? _universityId;
  String? _universityName;
  String? _programId;
  String? _programName;
  String? _primarySchoolId;
  String? _primarySchoolName;
  String? _secondarySchoolId;
  String? _secondarySchoolName;

  void _loadEducationFromUser(Map<String, dynamic>? user) {
    final p = user?['profile'] as Map<String, dynamic>?;
    if (p == null) return;
    _educationLevel = p['educationLevel'] as String?;
    _standard = (p['standard'] as num?)?.toInt();
    _form = (p['form'] as num?)?.toInt();
    _term = p['term'] as String?;
    final uni = p['university'] as Map<String, dynamic>?;
    if (uni != null) {
      _universityId = uni['id'] as String?;
      _universityName = uni['name'] as String?;
    }
    final prog = p['program'] as Map<String, dynamic>?;
    if (prog != null) {
      _programId = prog['id'] as String?;
      _programName = prog['name'] as String?;
    }
    final ps = p['primarySchool'] as Map<String, dynamic>?;
    if (ps != null) {
      _primarySchoolId = ps['id'] as String?;
      _primarySchoolName = ps['name'] as String?;
    }
    final ss = p['secondarySchool'] as Map<String, dynamic>?;
    if (ss != null) {
      _secondarySchoolId = ss['id'] as String?;
      _secondarySchoolName = ss['name'] as String?;
    }
  }

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _firstNameCtrl.text = user?['firstName'] as String? ?? '';
    _lastNameCtrl.text = user?['lastName'] as String? ?? '';
    _emailCtrl.text = user?['email'] as String? ?? '';
    _phoneCtrl.text = user?['phone'] as String? ?? '';
    _loadEducationFromUser(user);
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> _educationInput() {
    final m = <String, dynamic>{};
    if (_educationLevel == null || _educationLevel!.isEmpty) return m;
    m['educationLevel'] = _educationLevel;
    switch (_educationLevel) {
      case 'primary':
        if (_standard != null) m['standard'] = _standard;
        if (_term != null && _term!.isNotEmpty) m['term'] = _term;
        if (_primarySchoolId != null) m['primarySchoolId'] = _primarySchoolId;
        break;
      case 'secondary':
        if (_form != null) m['form'] = _form;
        if (_term != null && _term!.isNotEmpty) m['term'] = _term;
        if (_secondarySchoolId != null) m['secondarySchoolId'] = _secondarySchoolId;
        break;
      case 'tertiary':
        if (_universityId != null) m['universityId'] = _universityId;
        if (_programId != null) m['programId'] = _programId;
        break;
    }
    return m;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final client = ref.read(graphqlClientProvider);
    final input = <String, dynamic>{
      'firstName': _firstNameCtrl.text.trim(),
      'lastName': _lastNameCtrl.text.trim(),
      if (_emailCtrl.text.trim().isNotEmpty) 'email': _emailCtrl.text.trim(),
      if (_phoneCtrl.text.trim().isNotEmpty) 'phone': _phoneCtrl.text.trim(),
      ..._educationInput(),
    };
    final result = await client.mutate(MutationOptions(
      document: gql(kUpdateProfile),
      variables: {'input': input},
    ));
    if (!mounted) return;
    setState(() => _saving = false);
    if (result.hasException || result.data?['updateProfile']?['success'] != true) {
      final err = result.hasException
          ? 'Save failed'
          : (result.data?['updateProfile']?['errors'] as List?)?.first ?? 'Save failed';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$err'), backgroundColor: DesignTokens.error));
      return;
    }
    await ref.read(authProvider.notifier).refreshUser();
    if (!mounted) return;
    _loadEducationFromUser(ref.read(authProvider).user);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated'), backgroundColor: DesignTokens.success));
  }

  Future<void> _openUniversityPicker() async {
    final picked = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const UniversityPickerSheet(),
    );
    if (picked != null && mounted) {
      setState(() {
        _universityId = picked['id'] as String?;
        _universityName = picked['name'] as String?;
        _programId = null;
        _programName = null;
      });
    }
  }

  Future<void> _openProgramPicker() async {
    if (_universityId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choose an institution first')));
      return;
    }
    final picked = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ProgramPickerSheet(universityId: _universityId!, selectedProgramId: _programId),
    );
    if (picked != null && mounted) {
      setState(() {
        _programId = picked['id'] as String?;
        _programName = picked['name'] as String?;
      });
    }
  }

  Future<void> _openSchoolPicker(bool primary) async {
    final picked = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SchoolPickerSheet(
        isPrimary: primary,
        selectedId: primary ? _primarySchoolId : _secondarySchoolId,
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        if (primary) {
          _primarySchoolId = picked['id'] as String?;
          _primarySchoolName = picked['name'] as String?;
        } else {
          _secondarySchoolId = picked['id'] as String?;
          _secondarySchoolName = picked['name'] as String?;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final user = ref.watch(authProvider).user;
    final prof = user?['profile'];
    final level = _educationLevel ?? (prof is Map<String, dynamic> ? prof['educationLevel'] as String? : null);

    return Scaffold(
      appBar: AppBar(title: Text('Edit profile', style: theme.textTheme.titleLarge)),
      body: ListView(
        padding: const EdgeInsets.all(DesignTokens.spLg),
        children: [
          Center(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: DesignTokens.primary.withValues(alpha: 0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 56,
                    backgroundColor: DesignTokens.primary,
                    child: Text(
                      user?['username']?.toString().substring(0, 1).toUpperCase() ?? '?',
                      style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle, 
                      color: dark ? DesignTokens.darkSurface : Colors.white,
                      boxShadow: DesignTokens.shadowSm(dark),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, size: 20, color: DesignTokens.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text('Personal details', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: dark ? DesignTokens.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: DesignTokens.shadowSm(dark),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildModernTextField(
                  controller: _firstNameCtrl,
                  label: 'First name',
                  dark: dark,
                  action: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                _buildModernTextField(
                  controller: _lastNameCtrl,
                  label: 'Last name',
                  dark: dark,
                  action: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                _buildModernTextField(
                  controller: _emailCtrl,
                  label: 'Email',
                  dark: dark,
                  keyboard: TextInputType.emailAddress,
                  action: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                _buildModernTextField(
                  controller: _phoneCtrl,
                  label: 'Phone number',
                  dark: dark,
                  keyboard: TextInputType.phone,
                  action: TextInputAction.done,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text('School & studies', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            'Search universities (public/private), pick a programme, or set your school — same as setup. Kids: Profile → Kids mode.',
            style: theme.textTheme.bodySmall?.copyWith(color: DesignTokens.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 16),
          if (level == null || level.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DesignTokens.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Complete onboarding first to set your education level.',
                style: TextStyle(color: DesignTokens.warning, fontWeight: FontWeight.w600),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: dark ? DesignTokens.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: DesignTokens.shadowSm(dark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: dark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your level', style: TextStyle(fontSize: 12, color: DesignTokens.textSecondary, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(
                          level == 'primary'
                              ? 'Primary'
                              : level == 'secondary'
                                  ? 'Secondary'
                                  : 'University / college',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (level == 'primary') ...[
                    _buildModernDropdown<int>(
                      key: ValueKey('std_${_standard ?? 0}'),
                      label: 'Standard',
                      value: _standard,
                      items: List.generate(8, (i) => DropdownMenuItem(value: i + 1, child: Text('Standard ${i + 1}'))),
                      onChanged: (v) => setState(() => _standard = v),
                      dark: dark,
                    ),
                    const SizedBox(height: 16),
                    _buildModernDropdown<String>(
                      key: ValueKey('term_${_term ?? 'x'}'),
                      label: 'Term',
                      value: _term != null && ['1', '2', '3'].contains(_term) ? _term : null,
                      items: const [
                        DropdownMenuItem(value: '1', child: Text('Term 1')),
                        DropdownMenuItem(value: '2', child: Text('Term 2')),
                        DropdownMenuItem(value: '3', child: Text('Term 3')),
                      ],
                      onChanged: (v) => setState(() => _term = v),
                      dark: dark,
                    ),
                    const SizedBox(height: 16),
                    _buildModernListTile(
                      title: 'Primary school',
                      subtitle: _primarySchoolName ?? 'Not set — tap to search',
                      icon: Icons.school_rounded,
                      dark: dark,
                      onTap: () => _openSchoolPicker(true),
                    ),
                  ],
                  if (level == 'secondary') ...[
                    _buildModernDropdown<int>(
                      key: ValueKey('form_${_form ?? 0}'),
                      label: 'Form',
                      value: _form,
                      items: List.generate(4, (i) => DropdownMenuItem(value: i + 1, child: Text('Form ${i + 1}'))),
                      onChanged: (v) => setState(() => _form = v),
                      dark: dark,
                    ),
                    const SizedBox(height: 16),
                    _buildModernDropdown<String>(
                      key: ValueKey('term_${_term ?? 'x'}'),
                      label: 'Term',
                      value: _term != null && ['1', '2', '3'].contains(_term) ? _term : null,
                      items: const [
                        DropdownMenuItem(value: '1', child: Text('Term 1')),
                        DropdownMenuItem(value: '2', child: Text('Term 2')),
                        DropdownMenuItem(value: '3', child: Text('Term 3')),
                      ],
                      onChanged: (v) => setState(() => _term = v),
                      dark: dark,
                    ),
                    const SizedBox(height: 16),
                    _buildModernListTile(
                      title: 'Secondary school',
                      subtitle: _secondarySchoolName ?? 'Not set — tap to search',
                      icon: Icons.school_rounded,
                      dark: dark,
                      onTap: () => _openSchoolPicker(false),
                    ),
                  ],
                  if (level == 'tertiary') ...[
                    _buildModernListTile(
                      title: 'Institution',
                      subtitle: _universityName ?? 'Not set — tap to search',
                      icon: Icons.account_balance_rounded,
                      dark: dark,
                      onTap: _openUniversityPicker,
                    ),
                    const SizedBox(height: 16),
                    _buildModernListTile(
                      title: 'Programme',
                      subtitle: _programName ?? 'Not set — tap to choose',
                      icon: Icons.menu_book_rounded,
                      dark: dark,
                      onTap: _openProgramPicker,
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required bool dark,
    TextInputType? keyboard,
    TextInputAction? action,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      textInputAction: action,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: dark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildModernDropdown<T>({
    required Key key,
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required bool dark,
  }) {
    return DropdownButtonFormField<T>(
      key: key,
      value: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: dark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildModernListTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required bool dark,
  }) {
    return AnimatedPress(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: dark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: DesignTokens.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: DesignTokens.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: DesignTokens.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: DesignTokens.textSecondary),
          ],
        ),
      ),
    );
  }
}
