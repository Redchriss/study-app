import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/widgets.dart';
import 'picker_sheet_widgets.dart';

class SchoolPickerSheet extends StatefulWidget {
  const SchoolPickerSheet(
      {super.key, required this.isPrimary, this.selectedId});

  final bool isPrimary;
  final String? selectedId;

  @override
  State<SchoolPickerSheet> createState() => _SchoolPickerSheetState();
}

class _SchoolPickerSheetState extends State<SchoolPickerSheet> {
  final _searchCtrl = TextEditingController();
  String _applied = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.isPrimary ? kPrimarySchools : kSecondarySchools;
    final key = widget.isPrimary ? 'primarySchools' : 'secondarySchools';
    final title = widget.isPrimary ? 'Primary school' : 'Secondary school';

    return PickerSheetShell(
      title: title,
      subtitle: 'Search by school name.',
      heightFactor: 0.8,
      search: PickerSearchField(
        controller: _searchCtrl,
        hint: 'School name…',
        onChanged: (value) => setState(() => _applied = value.trim()),
        onSubmit: (_) => setState(() => _applied = _searchCtrl.text.trim()),
      ),
      child: Query(
        options: QueryOptions(
          document: gql(doc),
          variables: {if (_applied.isNotEmpty) 'search': _applied},
        ),
        builder: (result, {fetchMore, refetch}) {
          if (result.isLoading) return const LoadingWidget();
          if (result.hasException) {
            return ErrorState(
              message: graphQLErrorMessage(
                  result.exception, 'Could not load schools.'),
              onRetry: () => refetch?.call(),
            );
          }
          final schools = (result.data?[key] as List?) ?? [];
          if (schools.isEmpty) {
            return PickerEmptyHint(
              icon: Icons.search_off_rounded,
              message: _applied.isEmpty
                  ? 'Type a school name to search.'
                  : 'No match. Try another spelling.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            itemCount: schools.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final s = schools[i] as Map<String, dynamic>;
              final id = s['id'] as String?;
              final name = s['name'] as String? ?? '';
              final sub = [s['district'], s['region']]
                  .map((e) => (e ?? '').toString().trim())
                  .where((e) => e.isNotEmpty)
                  .join(' · ');
              return PickerResultTile(
                icon: Icons.school_rounded,
                title: name,
                subtitle: sub,
                selected: id == widget.selectedId,
                onTap: () => Navigator.pop(context, {'id': id, 'name': name}),
              );
            },
          );
        },
      ),
    );
  }
}
