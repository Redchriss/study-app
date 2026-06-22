import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../account/presentation/widgets/education_pickers.dart';
import '../providers/auth_provider.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/services/app_preferences_service.dart';
import '../../../../core/theme/design_tokens.dart';
import 'kids_mode_suggestion_dialog.dart';

class ProfileSetupManager {
  final _preferences = AppPreferencesService();
  late WidgetRef _ref;
  late void Function(VoidCallback) _setState;
  late BuildContext _context;
  late bool Function() _isMounted;

  int step = 1;
  bool saving = false;
  String? level;
  int? standard;
  int? form;
  String? universityId;
  String? universityName;
  String? programId;
  String? programName;
  String? term;
  String? primarySchoolId;
  String? primarySchoolName;
  String? secondarySchoolId;
  String? secondarySchoolName;

  void attach({
    required WidgetRef ref,
    required void Function(VoidCallback) setState,
    required BuildContext context,
    required bool Function() isMounted,
  }) {
    _ref = ref;
    _setState = setState;
    _context = context;
    _isMounted = isMounted;
  }

  int get totalSteps {
    if (level == null) return 4;
    if (level == 'tertiary') return 3;
    return 4;
  }

  Future<void> bootstrapPreferences() async {
    final preferredLevel = await _preferences.preferredLevel();
    if (!_isMounted() || preferredLevel == null) return;
    _setState(() {
      level = preferredLevel;
      step = 2;
    });
  }

  void selectLevel(String value) {
    _setState(() {
      level = value;
      step = 2;
    });
  }

  void selectStandard(int value) {
    _setState(() {
      standard = value;
      step = 3;
    });
  }

  void selectForm(int value) {
    _setState(() {
      form = value;
      step = 3;
    });
  }

  void selectTerm(int value) {
    _setState(() => term = value.toString());
    saveAndFinish();
  }

  void back() {
    _setState(() {
      if (step == 3 && level == 'tertiary') {
        programId = null;
        programName = null;
      }
      step--;
    });
  }

  void goToStep(int s) {
    _setState(() => step = s);
  }

  void skipPrimarySchool() {
    _setState(() {
      primarySchoolId = null;
      primarySchoolName = null;
      step = 4;
    });
  }

  void skipSecondarySchool() {
    _setState(() {
      secondarySchoolId = null;
      secondarySchoolName = null;
      step = 4;
    });
  }

  Future<void> saveAndFinish() async {
    if (saving) return;
    _setState(() => saving = true);
    final client = _ref.read(graphqlClientProvider);
    try {
      // NOTE: do NOT send `onboardingComplete` here — it is not a field on the
      // backend `ProfileInput` and including it makes the whole mutation fail
      // (so the final step silently "does nothing"). The server marks
      // onboarding complete automatically once term (primary/secondary) or
      // programme (tertiary) is saved.
      final result = await client
          .mutate(MutationOptions(
            document: gql(kUpdateProfile),
            variables: {
              'input': {
                'educationLevel': level,
                if (standard != null) 'standard': standard,
                if (form != null) 'form': form,
                if (universityId != null) 'universityId': universityId,
                if (programId != null) 'programId': programId,
                if (term != null) 'term': term,
                if (primarySchoolId != null) 'primarySchoolId': primarySchoolId,
                if (secondarySchoolId != null)
                  'secondarySchoolId': secondarySchoolId,
              }
            },
          ))
          .timeout(const Duration(seconds: 30));
      if (!_isMounted()) return;
      final payload = result.data?['updateProfile'] as Map<String, dynamic>?;
      final payloadErrors = ((payload?['errors'] as List?) ?? const [])
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList();
      if (result.hasException || payload?['success'] != true) {
        final message = payloadErrors.firstOrNull ??
            graphQLErrorMessage(result.exception, 'Save failed. Try again.');
        if (!_context.mounted) return;
        ScaffoldMessenger.of(_context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: DesignTokens.error,
          ),
        );
        return;
      }
      await _ref.read(authProvider.notifier).refreshUser();
      if (!_context.mounted) return;
      if (level == 'primary' && _context.mounted) {
        final goKids = await _suggestKidsMode();
        if (!_context.mounted) return;
        if (goKids) {
          GoRouter.of(_context).go('/kids');
          return;
        }
      }
      GoRouter.of(_context).go('/home');
    } on TimeoutException {
      if (!_context.mounted) return;
      ScaffoldMessenger.of(_context).showSnackBar(
        const SnackBar(
          content: Text(
              'This is taking too long. Check your connection and try again.'),
          backgroundColor: DesignTokens.error,
        ),
      );
    } catch (e) {
      debugPrint('saveAndFinish failed: $e');
      if (!_context.mounted) return;
      ScaffoldMessenger.of(_context).showSnackBar(
        const SnackBar(
          content: Text('Could not save your profile. Please try again.'),
          backgroundColor: DesignTokens.error,
        ),
      );
    } finally {
      if (_isMounted()) _setState(() => saving = false);
    }
  }

  Future<bool> _suggestKidsMode() async {
    final goKids = await showDialog<bool>(
      context: _context,
      barrierDismissible: false,
      builder: (_) => const KidsModeSuggestionDialog(),
    );
    return goKids == true;
  }

  Future<void> openUniversitySheet() async {
    final picked = await showModalBottomSheet<Map<String, dynamic>>(
      context: _context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UniversityPickerSheet(selectedId: universityId),
    );
    if (picked != null && _isMounted()) {
      _setState(() {
        universityId = picked['id'] as String?;
        universityName = picked['name'] as String?;
        programId = null;
        programName = null;
      });
    }
  }

  Future<void> openProgramSheet() async {
    if (universityId == null) return;
    final picked = await showModalBottomSheet<Map<String, dynamic>>(
      context: _context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProgramPickerSheet(
        universityId: universityId!,
        selectedProgramId: programId,
      ),
    );
    if (picked != null && _isMounted()) {
      _setState(() {
        programId = picked['id'] as String?;
        programName = picked['name'] as String?;
      });
    }
  }

  Future<void> openSchoolSheet(bool primary) async {
    final picked = await showModalBottomSheet<Map<String, dynamic>>(
      context: _context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SchoolPickerSheet(
        isPrimary: primary,
        selectedId: primary ? primarySchoolId : secondarySchoolId,
      ),
    );
    if (picked != null && _isMounted()) {
      _setState(() {
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
}
