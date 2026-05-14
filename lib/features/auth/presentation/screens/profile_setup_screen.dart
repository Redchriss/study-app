import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../account/presentation/widgets/education_pickers.dart';
import '../providers/auth_provider.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

/// Onboarding: **Primary / Secondary / Tertiary** (main Yaza account).
/// **Kids mode** is separate — parent creates a child profile from Profile → Kids.
/// Institution / school / programme pickers are shared with [EditProfileScreen] (`education_pickers.dart`).
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});
  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  int _step = 1;
  String? _level;
  int? _standard;
  int? _form;
  String? _universityId;
  String? _universityName;
  String? _programId;
  String? _programName;
  String? _term;
  String? _primarySchoolId;
  String? _primarySchoolName;
  String? _secondarySchoolId;
  String? _secondarySchoolName;

  int get _totalSteps {
    if (_level == null) return 4;
    if (_level == 'tertiary') return 3;
    return 4;
  }

  Future<void> _saveAndFinish() async {
    final client = ref.read(graphqlClientProvider);
    final result = await client.mutate(MutationOptions(
      document: gql(kUpdateProfile),
      variables: {
        'input': {
          'educationLevel': _level,
          if (_standard != null) 'standard': _standard,
          if (_form != null) 'form': _form,
          if (_universityId != null) 'universityId': _universityId,
          if (_programId != null) 'programId': _programId,
          if (_term != null) 'term': _term,
          if (_primarySchoolId != null) 'primarySchoolId': _primarySchoolId,
          if (_secondarySchoolId != null) 'secondarySchoolId': _secondarySchoolId,
        }
      },
    ));
    if (mounted) {
      if (result.hasException || result.data?['updateProfile']?['success'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.hasException
                  ? 'Save failed. Try again.'
                  : (result.data?['updateProfile']?['errors'] as List?)?.first ?? 'Save failed.',
            ),
            backgroundColor: DesignTokens.error,
          ),
        );
        return;
      }
      await ref.read(authProvider.notifier).refreshUser();
      if (!mounted) return;
      context.go('/home');
    }
  }

  Future<void> _openUniversitySheet() async {
    final picked = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => UniversityPickerSheet(selectedId: _universityId),
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

  Future<void> _openProgramSheet() async {
    if (_universityId == null) return;
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
      await _saveAndFinish();
    }
  }

  Future<void> _openSchoolSheet(bool primary) async {
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
    return Scaffold(
      appBar: AppBar(
        leading: _step > 1
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    if (_step == 3 && _level == 'tertiary') {
                      _programId = null;
                      _programName = null;
                    }
                    _step--;
                  });
                },
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Complete your profile', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    _level == null
                        ? 'Choose your school level. Younger learners use Kids mode from Profile after setup.'
                        : _level == 'tertiary'
                            ? 'Pick your college or university, then your programme — same search as Edit profile.'
                            : 'We use this to show the right materials, quizzes, and study circles for Malawi.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: DesignTokens.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: _step / _totalSteps,
                    backgroundColor: DesignTokens.textSecondary.withValues(alpha: 0.2),
                    color: DesignTokens.primary,
                    borderRadius: BorderRadius.circular(4),
                    minHeight: 8,
                  ),
                  const SizedBox(height: 4),
                  Text('Step $_step of $_totalSteps', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: DesignTokens.textSecondary)),
                ],
              ),
            ),
            Expanded(child: _buildStep()),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    if (_step == 1) return _buildLevelStep();
    if (_step == 2 && _level == 'primary') return _buildStandardStep();
    if (_step == 2 && _level == 'secondary') return _buildFormStep();
    if (_step == 2 && _level == 'tertiary') return _buildUniversityStep();
    if (_step == 3 && _level == 'tertiary') return _buildProgramStep();
    if (_step == 3 && _level == 'primary') return _buildPrimarySchoolStep();
    if (_step == 3 && _level == 'secondary') return _buildSecondarySchoolStep();
    if (_step == 4) return _buildTermStep();
    return const SizedBox();
  }

  Widget _buildLevelStep() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      children: [
        Text('What level are you?', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: DesignTokens.info.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: DesignTokens.info.withValues(alpha: 0.25)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.child_care_outlined, color: DesignTokens.info, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Kids (under a parent account with PIN) are not chosen here — after setup, open Profile → Kids mode.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.35, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _LevelCard(
          icon: Icons.child_care,
          title: 'Primary school',
          subtitle: 'Standards 1–8 · PSLCE path',
          onTap: () => setState(() {
            _level = 'primary';
            _step = 2;
          }),
        ),
        const SizedBox(height: 12),
        _LevelCard(
          icon: Icons.school,
          title: 'Secondary school',
          subtitle: 'Forms 1–4 · JCE & MSCE',
          onTap: () => setState(() {
            _level = 'secondary';
            _step = 2;
          }),
        ),
        const SizedBox(height: 12),
        _LevelCard(
          icon: Icons.account_balance,
          title: 'University / college',
          subtitle: 'UNIMA, MUBAS, MUST, TTCs, private colleges…',
          onTap: () => setState(() {
            _level = 'tertiary';
            _step = 2;
          }),
        ),
      ],
    );
  }

  Widget _buildStandardStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Which Standard?', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Materials and topics follow primary progression (Std 1–8).', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: DesignTokens.textSecondary)),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.count(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: List.generate(
                8,
                (i) => ElevatedButton(
                  onPressed: () => setState(() {
                    _standard = i + 1;
                    _step = 3;
                  }),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 0),
                    padding: const EdgeInsets.all(8),
                  ),
                  child: Text('Std ${i + 1}', style: const TextStyle(fontSize: 13)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormStep() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Which Form?', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text('Form 1–2: junior secondary · Form 3–4: senior / MSCE focus.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: DesignTokens.textSecondary)),
        const SizedBox(height: 20),
        ...List.generate(
          4,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _LevelCard(
              icon: Icons.class_,
              title: 'Form ${i + 1}',
              subtitle: i < 2 ? 'Junior secondary' : 'Senior secondary',
              onTap: () => setState(() {
                _form = i + 1;
                _step = 3;
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUniversityStep() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Institution', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'Search public and private colleges and universities (same sheet as Edit profile).',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: DesignTokens.textSecondary),
        ),
        const SizedBox(height: 20),
        Material(
          color: DesignTokens.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          child: ListTile(
            leading: const Icon(Icons.account_balance),
            title: Text(_universityName ?? 'Tap to choose your institution'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _openUniversitySheet,
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _universityId == null ? null : () => setState(() => _step = 3),
          child: const Text('Continue to programme'),
        ),
      ],
    );
  }

  Widget _buildProgramStep() {
    if (_universityId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Select an institution first'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => setState(() => _step = 2), child: const Text('Back')),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Your programme', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (_universityName != null)
          Text('Institution: $_universityName', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: DesignTokens.textSecondary)),
        const SizedBox(height: 16),
        Material(
          color: DesignTokens.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          child: ListTile(
            leading: const Icon(Icons.menu_book),
            title: Text(_programName ?? 'Tap to choose your programme'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _openProgramSheet,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Choosing a programme saves your profile and finishes setup.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: DesignTokens.textSecondary),
        ),
      ],
    );
  }

  Widget _buildPrimarySchoolStep() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Your primary school', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'Optional — helps with local circles. Same school search as Edit profile.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: DesignTokens.textSecondary),
        ),
        const SizedBox(height: 20),
        Material(
          color: DesignTokens.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          child: ListTile(
            leading: const Icon(Icons.school),
            title: Text(_primarySchoolName ?? 'Tap to search for your school'),
            subtitle: _primarySchoolId != null ? const Text('Selected') : null,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openSchoolSheet(true),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => setState(() {
            _primarySchoolId = null;
            _primarySchoolName = null;
            _step = 4;
          }),
          child: const Text('Skip for now'),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () => setState(() => _step = 4),
          child: const Text('Continue to term'),
        ),
      ],
    );
  }

  Widget _buildSecondarySchoolStep() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Your secondary school', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'Optional. Search by school name (same sheet as Edit profile).',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: DesignTokens.textSecondary),
        ),
        const SizedBox(height: 20),
        Material(
          color: DesignTokens.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          child: ListTile(
            leading: const Icon(Icons.school),
            title: Text(_secondarySchoolName ?? 'Tap to search for your school'),
            subtitle: _secondarySchoolId != null ? const Text('Selected') : null,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openSchoolSheet(false),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => setState(() {
            _secondarySchoolId = null;
            _secondarySchoolName = null;
            _step = 4;
          }),
          child: const Text('Skip for now'),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () => setState(() => _step = 4),
          child: const Text('Continue to term'),
        ),
      ],
    );
  }

  Widget _buildTermStep() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Which term?', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text('Used for seasonal materials where relevant.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: DesignTokens.textSecondary)),
        const SizedBox(height: 20),
        ...['1', '2', '3'].map(
          (t) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _LevelCard(
              icon: Icons.calendar_today,
              title: 'Term $t',
              subtitle: '',
              onTap: () {
                setState(() => _term = t);
                _saveAndFinish();
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _LevelCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _LevelCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPress(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: DesignTokens.primary.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: DesignTokens.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: DesignTokens.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  if (subtitle.isNotEmpty)
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: DesignTokens.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: DesignTokens.textSecondary),
          ],
        ),
      ),
    );
  }
}
