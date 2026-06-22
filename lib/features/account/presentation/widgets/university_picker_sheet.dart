import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import 'picker_sheet_widgets.dart';

class UniversityPickerSheet extends StatefulWidget {
  const UniversityPickerSheet({super.key, this.selectedId});

  final String? selectedId;

  @override
  State<UniversityPickerSheet> createState() => _UniversityPickerSheetState();
}

class _UniversityPickerSheetState extends State<UniversityPickerSheet> {
  final _searchCtrl = TextEditingController();
  String _appliedQuery = '';
  String? _typeFilter;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PickerSheetShell(
      title: 'Choose institution',
      subtitle: 'Search public and private colleges and universities.',
      heightFactor: 0.9,
      search: PickerSearchField(
        controller: _searchCtrl,
        hint: 'Search name, city, acronym…',
        onChanged: (value) => setState(() => _appliedQuery = value.trim()),
        onSubmit: (_) =>
            setState(() => _appliedQuery = _searchCtrl.text.trim()),
      ),
      filters: Row(
        children: [
          _TypeChip(
            label: 'All',
            selected: _typeFilter == null,
            onTap: () => setState(() => _typeFilter = null),
          ),
          const SizedBox(width: 8),
          _TypeChip(
            label: 'Public',
            selected: _typeFilter == 'public',
            onTap: () => setState(() => _typeFilter = 'public'),
          ),
          const SizedBox(width: 8),
          _TypeChip(
            label: 'Private',
            selected: _typeFilter == 'private',
            onTap: () => setState(() => _typeFilter = 'private'),
          ),
        ],
      ),
      child: Query(
        options: QueryOptions(
          document: gql(kUniversities),
          variables: {
            if (_appliedQuery.isNotEmpty) 'search': _appliedQuery,
            if (_typeFilter != null) 'universityType': _typeFilter,
          },
        ),
        builder: (result, {fetchMore, refetch}) {
          if (result.isLoading) return const LoadingWidget();
          if (result.hasException) {
            return ErrorState(
              message: graphQLErrorMessage(
                  result.exception, 'Could not load institutions.'),
              onRetry: () => refetch?.call(),
            );
          }
          final list = (result.data?['universities'] as List?) ?? [];
          if (list.isEmpty) {
            return const PickerEmptyHint(
              icon: Icons.school_outlined,
              message: 'No results. Try different words.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final u = list[i] as Map<String, dynamic>;
              final id = u['id'] as String?;
              final name = u['name'] as String? ?? '';
              final loc = u['location'] as String? ?? '';
              final typ = u['universityType'] as String? ?? '';
              final desc = (u['description'] as String?)?.trim() ?? '';
              final short = u['shortName'] as String? ?? '';
              return PickerResultTile(
                icon: Icons.account_balance_rounded,
                title: name,
                subtitle: [if (short.isNotEmpty) short, loc, typ]
                    .where((e) => e.isNotEmpty)
                    .join(' · '),
                selected: id == widget.selectedId,
                onTap: () => Navigator.pop(context, {'id': id, 'name': name}),
                trailing: desc.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.info_outline, size: 20),
                        color: DesignTokens.textSecondary,
                        onPressed: () => showDialog<void>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(name),
                            content: SingleChildScrollView(
                                child: Text(desc.isEmpty ? '—' : desc)),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('OK'))
                            ],
                          ),
                        ),
                      ),
              );
            },
          );
        },
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: DesignTokens.durFast,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? DesignTokens.primary
              : (dark ? DesignTokens.darkSurface : DesignTokens.surface),
          borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
          border: Border.all(
            color: selected
                ? DesignTokens.primary
                : (dark ? DesignTokens.darkBorder : DesignTokens.border),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: selected
                    ? DesignTokens.textOnPrimary
                    : DesignTokens.textSecondary,
              ),
        ),
      ),
    );
  }
}
