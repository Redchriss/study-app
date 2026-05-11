import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../providers/auth_provider.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/config/theme/app_colors.dart';

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
  String? _programId;
  String? _term;
  bool _loading = false;

  Future<void> _saveAndFinish() async {
    setState(() => _loading = true);
    final client = await ref.read(graphqlClientProvider.future);
    await client.mutate(MutationOptions(
      document: gql(kUpdateProfile),
      variables: {
        'input': {
          'educationLevel': _level,
          if (_standard != null) 'standard': _standard,
          if (_form != null) 'form': _form,
          if (_universityId != null) 'universityId': _universityId,
          if (_programId != null) 'programId': _programId,
          if (_term != null) 'term': _term,
        }
      },
    ));
    if (mounted) {
      setState(() => _loading = false);
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalSteps = _level == 'tertiary' ? 3 : (_level != null ? 4 : 3);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Complete Your Profile', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: _step / totalSteps,
                    backgroundColor: AppColors.textSecondary.withOpacity(0.2),
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                    minHeight: 8,
                  ),
                  const SizedBox(height: 4),
                  Text('Step $_step of $totalSteps', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
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
    if (_step == 3 || _step == 4) return _buildTermStep();
    return const SizedBox();
  }

  Widget _buildLevelStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What level are you?', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),
          _LevelCard(
            icon: Icons.child_care,
            title: 'Primary School',
            subtitle: 'Standards 1–8 (PSLCE)',
            onTap: () => setState(() { _level = 'primary'; _step = 2; }),
          ),
          const SizedBox(height: 12),
          _LevelCard(
            icon: Icons.school,
            title: 'Secondary School',
            subtitle: 'Forms 1–4 (JCE & MSCE)',
            onTap: () => setState(() { _level = 'secondary'; _step = 2; }),
          ),
          const SizedBox(height: 12),
          _LevelCard(
            icon: Icons.account_balance,
            title: 'University / College',
            subtitle: 'Undergraduate & Diploma',
            onTap: () => setState(() { _level = 'tertiary'; _step = 2; }),
          ),
        ],
      ),
    );
  }

  Widget _buildStandardStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Which Standard?', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: List.generate(8, (i) => ElevatedButton(
              onPressed: () => setState(() { _standard = i + 1; _step = 4; }),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 0),
                padding: const EdgeInsets.all(8),
              ),
              child: Text('Std ${i + 1}', style: const TextStyle(fontSize: 13)),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildFormStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Which Form?', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),
          ...List.generate(4, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _LevelCard(
              icon: Icons.class_,
              title: 'Form ${i + 1}',
              subtitle: i < 2 ? 'Junior Secondary' : 'Senior Secondary',
              onTap: () => setState(() { _form = i + 1; _step = 4; }),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildUniversityStep() {
    return Query(
      options: QueryOptions(document: gql(kUniversities)),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) return const Center(child: CircularProgressIndicator());
        final unis = (result.data?['universities'] as List?) ?? [];
        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: unis.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            if (i == 0) return Text('Select your University', style: Theme.of(context).textTheme.titleLarge);
            final uni = unis[i - 1];
            return _LevelCard(
              icon: Icons.account_balance,
              title: uni['name'],
              subtitle: '${uni['location']} · ${uni['universityType']}',
              onTap: () => setState(() { _universityId = uni['id']; _step = 3; }),
            );
          },
        );
      },
    );
  }

  Widget _buildProgramStep() {
    return Query(
      options: QueryOptions(document: gql(kPrograms), variables: {'universityId': _universityId}),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) return const Center(child: CircularProgressIndicator());
        final programs = (result.data?['programs'] as List?) ?? [];
        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: programs.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            if (i == 0) return Text('Select your Programme', style: Theme.of(context).textTheme.titleLarge);
            final p = programs[i - 1];
            return _LevelCard(
              icon: Icons.menu_book,
              title: p['name'],
              subtitle: '${p['faculty']} · ${p['durationYears']} years',
              onTap: () { setState(() => _programId = p['id']); _saveAndFinish(); },
            );
          },
        );
      },
    );
  }

  Widget _buildTermStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Which Term?', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),
          ...['1', '2', '3'].map((t) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _LevelCard(
              icon: Icons.calendar_today,
              title: 'Term $t',
              subtitle: '',
              onTap: () { setState(() => _term = t); _saveAndFinish(); },
            ),
          )),
        ],
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _LevelCard({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  if (subtitle.isNotEmpty)
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
