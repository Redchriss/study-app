import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../account/presentation/widgets/education_pickers.dart';
import '../providers/auth_provider.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/services/app_preferences_service.dart';
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
  final _preferences = AppPreferencesService();
  int _step = 1;
  bool _saving = false;
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

  @override
  void initState() {
    super.initState();
    _bootstrapPreferences();
  }

  Future<void> _bootstrapPreferences() async {
    final preferredLevel = await _preferences.preferredLevel();
    if (!mounted || preferredLevel == null) return;
    setState(() {
      _level = preferredLevel;
      _step = 2;
    });
  }

  int get _totalSteps {
    if (_level == null) return 4;
    if (_level == 'tertiary') return 3;
    return 4;
  }

  Future<void> _saveAndFinish() async {
    if (_saving) return;
    setState(() => _saving = true);
    final client = ref.read(graphqlClientProvider);
    try {
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
      if (!mounted) return;
      final payload = result.data?['updateProfile'] as Map<String, dynamic>?;
      final payloadErrors = ((payload?['errors'] as List?) ?? const [])
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList();
      final graphQLError = result.exception?.graphqlErrors.firstOrNull?.message;
      final linkError = result.exception?.linkException?.toString();
      if (result.hasException || payload?['success'] != true) {
        final message = payloadErrors.firstOrNull ?? graphQLError ?? linkError ?? 'Save failed. Try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: DesignTokens.error),
        );
        return;
      }
      await ref.read(authProvider.notifier).refreshUser();
      // Router redirect handles navigation once onboardingComplete=true is set.
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
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
    final dark = Theme.of(context).brightness == Brightness.dark;
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
        const SizedBox(height: 24),
        _VisualLevelCard(
          icon: Icons.child_care_rounded,
          title: 'Primary school',
          subtitle: 'Standards 1–8 · PSLCE path',
          color: const Color(0xFFE87E5E),
          dark: dark,
          onTap: () => setState(() {
            _level = 'primary';
            _step = 2;
          }),
        ),
        const SizedBox(height: 16),
        _VisualLevelCard(
          icon: Icons.menu_book_rounded,
          title: 'Secondary school',
          subtitle: 'Forms 1–4 · JCE & MSCE',
          color: const Color(0xFF389E75),
          dark: dark,
          onTap: () => setState(() {
            _level = 'secondary';
            _step = 2;
          }),
        ),
        const SizedBox(height: 16),
        _VisualLevelCard(
          icon: Icons.account_balance_rounded,
          title: 'University / college',
          subtitle: 'UNIMA, MUBAS, MUST, TTCs, private colleges…',
          color: const Color(0xFF5A6BB2),
          dark: dark,
          onTap: () => setState(() {
            _level = 'tertiary';
            _step = 2;
          }),
        ),
      ],
    );
  }

  Widget _buildStandardStep() {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Which Standard?', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Materials and topics follow primary progression (Std 1–8).', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: DesignTokens.textSecondary)),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.3,
              children: List.generate(
                8,
                (i) => _NumberCard(
                  number: i + 1,
                  label: 'Standard',
                  color: const Color(0xFFE87E5E),
                  dark: dark,
                  onTap: () => setState(() {
                    _standard = i + 1;
                    _step = 3;
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormStep() {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Which Form?', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Form 1–2: junior secondary · Form 3–4: senior / MSCE focus.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: DesignTokens.textSecondary)),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.3,
              children: List.generate(
                4,
                (i) => _NumberCard(
                  number: i + 1,
                  label: 'Form',
                  color: const Color(0xFF389E75),
                  dark: dark,
                  subtitle: i < 2 ? 'JCE' : 'MSCE',
                  onTap: () => setState(() {
                    _form = i + 1;
                    _step = 3;
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
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
          'Choose your programme, then finish setup.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: DesignTokens.textSecondary),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: (_programId == null || _saving) ? null : _saveAndFinish,
          child: _saving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Finish setup'),
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Which term?', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Used for seasonal materials where relevant.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: DesignTokens.textSecondary)),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.3,
              children: List.generate(
                3,
                (i) => _NumberCard(
                  number: i + 1,
                  label: 'Term',
                  color: const Color(0xFF6A8EAE),
                  dark: dark,
                  onTap: () {
                    setState(() => _term = (i + 1).toString());
                    _saveAndFinish();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VisualLevelCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool dark;
  final VoidCallback onTap;

  const _VisualLevelCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.dark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPress(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: dark ? DesignTokens.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color.withValues(alpha: 0.8), color],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 4)),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: DesignTokens.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
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

class _NumberCard extends StatelessWidget {
  final int number;
  final String label;
  final String? subtitle;
  final Color color;
  final bool dark;
  final VoidCallback onTap;

  const _NumberCard({
    required this.number,
    required this.label,
    this.subtitle,
    required this.color,
    required this.dark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPress(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: dark ? DesignTokens.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              number.toString(),
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: color,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: DesignTokens.textSecondary,
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
