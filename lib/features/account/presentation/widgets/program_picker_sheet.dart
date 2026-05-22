import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/widgets.dart';

class ProgramPickerSheet extends StatefulWidget {
  const ProgramPickerSheet({super.key, required this.universityId, this.selectedProgramId});

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
    final h = MediaQuery.sizeOf(context).height * 0.78;
    return SafeArea(
      child: SizedBox(
        height: h,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              child: Row(
                children: [
                  Text('Choose programme', style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _filterCtrl,
                decoration: InputDecoration(
                  hintText: 'Filter by name or faculty…',
                  prefixIcon: const Icon(Icons.filter_list),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  isDense: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            Expanded(
              child: Query(
                options: QueryOptions(document: gql(kPrograms), variables: {'universityId': widget.universityId}),
                builder: (result, {fetchMore, refetch}) {
                  if (result.isLoading) return const LoadingWidget();
                  if (result.hasException) {
                    return ErrorState(
                      message: graphQLErrorMessage(result.exception, 'Could not load programmes.'),
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
                    return const Center(child: Text('No programmes match.'));
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final p = filtered[i] as Map<String, dynamic>;
                      final id = p['id'] as String?;
                      final name = p['name'] as String? ?? '';
                      final fac = p['faculty'] as String? ?? '';
                      final years = p['durationYears'];
                      return ListTile(
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text([fac, if (years != null) '$years years'].where((e) => e.toString().isNotEmpty).join(' · ')),
                        selected: id == widget.selectedProgramId,
                        onTap: () => Navigator.pop(context, {'id': id, 'name': name}),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
