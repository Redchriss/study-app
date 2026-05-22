import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/education_pickers.dart';

class EditProfileManager {
  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  bool saving = false;

  String? educationLevel;
  int? standard;
  int? form;
  String? term;
  String? universityId;
  String? universityName;
  String? programId;
  String? programName;
  String? primarySchoolId;
  String? primarySchoolName;
  String? secondarySchoolId;
  String? secondarySchoolName;

  late void Function(VoidCallback) updateState;
  late BuildContext _context;
  late WidgetRef _ref;

  void attach(
      {required WidgetRef ref,
      required BuildContext context,
      required void Function(VoidCallback) setState}) {
    _ref = ref;
    _context = context;
    updateState = setState;
  }

  void loadEducationFromUser(Map<String, dynamic>? user) {
    final p = user?['profile'] as Map<String, dynamic>?;
    if (p == null) return;
    educationLevel = p['educationLevel'] as String?;
    standard = (p['standard'] as num?)?.toInt();
    form = (p['form'] as num?)?.toInt();
    term = p['term'] as String?;
    final uni = p['university'] as Map<String, dynamic>?;
    if (uni != null) {
      universityId = uni['id'] as String?;
      universityName = uni['name'] as String?;
    }
    final prog = p['program'] as Map<String, dynamic>?;
    if (prog != null) {
      programId = prog['id'] as String?;
      programName = prog['name'] as String?;
    }
    final ps = p['primarySchool'] as Map<String, dynamic>?;
    if (ps != null) {
      primarySchoolId = ps['id'] as String?;
      primarySchoolName = ps['name'] as String?;
    }
    final ss = p['secondarySchool'] as Map<String, dynamic>?;
    if (ss != null) {
      secondarySchoolId = ss['id'] as String?;
      secondarySchoolName = ss['name'] as String?;
    }
  }

  void initFromUser(Map<String, dynamic>? user) {
    firstNameCtrl.text = user?['firstName'] as String? ?? '';
    lastNameCtrl.text = user?['lastName'] as String? ?? '';
    emailCtrl.text = user?['email'] as String? ?? '';
    phoneCtrl.text = user?['phone'] as String? ?? '';
    loadEducationFromUser(user);
  }

  void dispose() {
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
  }

  Map<String, dynamic> educationInput() {
    final m = <String, dynamic>{};
    if (educationLevel == null || educationLevel!.isEmpty) return m;
    m['educationLevel'] = educationLevel;
    switch (educationLevel) {
      case 'primary':
        if (standard != null) m['standard'] = standard;
        if (term != null && term!.isNotEmpty) m['term'] = term;
        if (primarySchoolId != null) m['primarySchoolId'] = primarySchoolId;
        break;
      case 'secondary':
        if (form != null) m['form'] = form;
        if (term != null && term!.isNotEmpty) m['term'] = term;
        if (secondarySchoolId != null)
          m['secondarySchoolId'] = secondarySchoolId;
        break;
      case 'tertiary':
        if (universityId != null) m['universityId'] = universityId;
        if (programId != null) m['programId'] = programId;
        break;
    }
    return m;
  }

  Future<void> save() async {
    updateState(() => saving = true);
    final client = _ref.read(graphqlClientProvider);
    final input = <String, dynamic>{
      'firstName': firstNameCtrl.text.trim(),
      'lastName': lastNameCtrl.text.trim(),
      if (emailCtrl.text.trim().isNotEmpty) 'email': emailCtrl.text.trim(),
      if (phoneCtrl.text.trim().isNotEmpty) 'phone': phoneCtrl.text.trim(),
      ...educationInput(),
    };
    final result = await client.mutate(MutationOptions(
      document: gql(kUpdateProfile),
      variables: {'input': input},
    ));
    if (!_checkMounted()) return;
    updateState(() => saving = false);
    if (result.hasException ||
        result.data?['updateProfile']?['success'] != true) {
      final err = result.hasException
          ? 'Save failed'
          : (result.data?['updateProfile']?['errors'] as List?)?.first ??
              'Save failed';
      if (_checkMounted())
        ScaffoldMessenger.of(_context).showSnackBar(SnackBar(
            content: Text('$err'), backgroundColor: DesignTokens.error));
      return;
    }
    await _ref.read(authProvider.notifier).refreshUser();
    if (!_checkMounted()) return;
    loadEducationFromUser(_ref.read(authProvider).user);
    updateState(() {});
    if (_checkMounted())
      ScaffoldMessenger.of(_context).showSnackBar(const SnackBar(
          content: Text('Profile updated'),
          backgroundColor: DesignTokens.success));
  }

  Future<void> openUniversityPicker() async {
    final picked = await showModalBottomSheet<Map<String, dynamic>>(
      context: _context,
      isScrollControlled: true,
      builder: (_) => const UniversityPickerSheet(),
    );
    if (picked != null && _checkMounted()) {
      updateState(() {
        universityId = picked['id'] as String?;
        universityName = picked['name'] as String?;
        programId = null;
        programName = null;
      });
    }
  }

  Future<void> openProgramPicker() async {
    if (universityId == null) {
      if (_checkMounted())
        ScaffoldMessenger.of(_context).showSnackBar(
            const SnackBar(content: Text('Choose an institution first')));
      return;
    }
    final picked = await showModalBottomSheet<Map<String, dynamic>>(
      context: _context,
      isScrollControlled: true,
      builder: (_) => ProgramPickerSheet(
          universityId: universityId!, selectedProgramId: programId),
    );
    if (picked != null && _checkMounted()) {
      updateState(() {
        programId = picked['id'] as String?;
        programName = picked['name'] as String?;
      });
    }
  }

  Future<void> openSchoolPicker(bool primary) async {
    final picked = await showModalBottomSheet<Map<String, dynamic>>(
      context: _context,
      isScrollControlled: true,
      builder: (_) => SchoolPickerSheet(
          isPrimary: primary,
          selectedId: primary ? primarySchoolId : secondarySchoolId),
    );
    if (picked != null && _checkMounted()) {
      updateState(() {
        if (primary) {
          primarySchoolId = picked['id'] as String?;
          primarySchoolName = picked['name'] as String?;
        } else {
          secondarySchoolId = picked['id'] as String?;
          secondarySchoolName = picked['name'] as String?;
        }
      });
    }
  }

  bool _checkMounted() {
    if (!_context.mounted) return false;
    return true;
  }
}
