import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/widgets.dart';
import 'picker_sheet_widgets.dart';

class ProgramPickerSheet extends StatefulWidget {
  const ProgramPickerSheet(
      {super.key, required this.universityId, this.selectedProgramId});

  final String universityId;
  final String? selectedProgramId;

  @override
  State<ProgramPickerSheet> createState() => _ProgramPickerSheetState();
}

class _ProgramPickerSheetState extends State<ProgramPickerSheet> {
  final _filterCtrl = TextEditingController();

  @override
  void dispose() {
    _filterCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PickerSheetShell(
      title: 'Choose programme',
      subtitle: 'Filter by programme name or faculty.',
      heightFactor: 0.82,
      search: PickerSearchField(
        controller: _filterCtrl,
        hint: 'Filter by name or faculty…',
        icon: Icons.filter_list_rounded,
        onChanged: (_) => setState(() {}),
      ),
      child: Query(
        options: QueryOptions(
            document: gql(kPrograms),
            variables: {'universityId': widget.universityId}),
        builder: (result, {fetchMore, refetch}) {
          if (result.isLoading) return const LoadingWidget();
          if (result.hasException) {
            return ErrorState(
              message: graphQLErrorMessage(
                  result.exception, 'Could not load programmes.'),
              onRetry: () => refetch?.call(),
            );
          }
          final programs = (result.data?['programs'] as List?) ?? [];
          final q = _filterCtrl.text.trim().toLowerCase();
          final filtered = q.isEmpty
              ? programs
              : programs.where((p) {
                  final m = p as Map<String, dynamic>;
                  final n = (m['name'] as String? ?? '').toLowerCase();
                  final f = (m['faculty'] as String? ?? '').toLowerCase();
                  return n.contains(q) || f.contains(q);
                }).toList();
          if (filtered.isEmpty) {
            return const PickerEmptyHint(
              icon: Icons.menu_book_outlined,
              message: 'No programmes match.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final p = filtered[i] as Map<String, dynamic>;
              final id = p['id'] as String?;
              final name = p['name'] as String? ?? '';
              final fac = p['faculty'] as String? ?? '';
              final years = p['durationYears'];
              return PickerResultTile(
                icon: Icons.menu_book_rounded,
                title: name,
                subtitle: [fac, if (years != null) '$years years']
                    .where((e) => e.toString().isNotEmpty)
                    .join(' · '),
                selected: id == widget.selectedProgramId,
                onTap: () => Navigator.pop(context, {'id': id, 'name': name}),
              );
            },
          );
        },
      ),
    );
  }
}
