import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/design_tokens.dart';
import 'profile_setup_level_step.dart';
import 'profile_setup_manager.dart';
import 'profile_setup_number_step.dart';
import 'profile_setup_school_step.dart';
import 'profile_setup_tertiary_step.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});
  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _manager = ProfileSetupManager();

  @override
  void initState() {
    super.initState();
    _manager.attach(
      ref: ref,
      setState: setState,
      context: context,
      isMounted: () => mounted,
    );
    _manager.bootstrapPreferences();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _manager.step > 1
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _manager.back,
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildStep()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Complete your profile',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            _manager.level == null
                ? 'Choose your school level. Younger learners use Kids mode from Profile after setup.'
                : _manager.level == 'tertiary'
                    ? 'Pick your college or university, then your programme — same search as Edit profile.'
                    : 'We use this to show the right materials, quizzes, and communities for Malawi.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: DesignTokens.textSecondary,
                ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: _manager.step / _manager.totalSteps,
            backgroundColor: DesignTokens.textSecondary.withValues(alpha: 0.2),
            color: DesignTokens.primary,
            borderRadius: BorderRadius.circular(4),
            minHeight: 8,
          ),
          const SizedBox(height: 4),
          Text(
            'Step ${_manager.step} of ${_manager.totalSteps}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: DesignTokens.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep() {
    if (_manager.step == 1) return _buildLevelStep();
    if (_manager.step == 4) return _buildTermStep();
    if (_manager.step == 2) return _buildStep2();
    return _buildStep3();
  }

  Widget _buildLevelStep() {
    return ProfileLevelStep(
      onSelectPrimary: () => _manager.selectLevel('primary'),
      onSelectSecondary: () => _manager.selectLevel('secondary'),
      onSelectTertiary: () => _manager.selectLevel('tertiary'),
    );
  }

  Widget _buildStep2() {
    if (_manager.level == 'primary') {
      return ProfileNumberStep(
        title: 'Which Standard?',
        subtitle: 'Materials and topics follow primary progression (Std 1–8).',
        label: 'Standard',
        count: 8,
        color: const Color(0xFFE87E5E),
        onSelect: _manager.selectStandard,
      );
    }
    if (_manager.level == 'secondary') {
      return ProfileNumberStep(
        title: 'Which Form?',
        subtitle: 'Form 1–2: junior secondary · Form 3–4: senior / MSCE focus.',
        label: 'Form',
        count: 4,
        color: const Color(0xFF389E75),
        onSelect: _manager.selectForm,
      );
    }
    return ProfileUniversityStep(
      universityName: _manager.universityName,
      universityId: _manager.universityId,
      onPickUniversity: _manager.openUniversitySheet,
      onContinue: () => _manager.goToStep(3),
    );
  }

  Widget _buildStep3() {
    if (_manager.level == 'tertiary') {
      return ProfileProgramStep(
        universityId: _manager.universityId,
        universityName: _manager.universityName,
        programName: _manager.programName,
        programId: _manager.programId,
        saving: _manager.saving,
        onPickProgram: _manager.openProgramSheet,
        onFinish: _manager.saveAndFinish,
        onBack: () => _manager.goToStep(2),
      );
    }
    if (_manager.level == 'primary') {
      return ProfileSchoolStep(
        isPrimary: true,
        schoolName: _manager.primarySchoolName,
        schoolId: _manager.primarySchoolId,
        onPickSchool: () => _manager.openSchoolSheet(true),
        onSkip: _manager.skipPrimarySchool,
        onContinue: () => _manager.goToStep(4),
      );
    }
    return ProfileSchoolStep(
      isPrimary: false,
      schoolName: _manager.secondarySchoolName,
      schoolId: _manager.secondarySchoolId,
      onPickSchool: () => _manager.openSchoolSheet(false),
      onSkip: _manager.skipSecondarySchool,
      onContinue: () => _manager.goToStep(4),
    );
  }

  Widget _buildTermStep() {
    return ProfileNumberStep(
      title: 'Which term?',
      subtitle: 'Used for seasonal materials where relevant.',
      label: 'Term',
      count: 3,
      color: const Color(0xFF6A8EAE),
      onSelect: _manager.selectTerm,
    );
  }
}
