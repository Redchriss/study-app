import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/widgets.dart';

class SchoolPickerSheet extends StatefulWidget {
  const SchoolPickerSheet({super.key, required this.isPrimary, this.selectedId});

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
    final h = MediaQuery.sizeOf(context).height * 0.75;
    final doc = widget.isPrimary ? kPrimarySchools : kSecondarySchools;
    final key = widget.isPrimary ? 'primarySchools' : 'secondarySchools';
    final title = widget.isPrimary ? 'Primary school' : 'Secondary school';

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
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'School name…',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        isDense: true,
                      ),
                      onChanged: (value) => setState(() => _applied = value.trim()),
                      onSubmitted: (_) => setState(() => _applied = _searchCtrl.text.trim()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonal(onPressed: () => setState(() => _applied = _searchCtrl.text.trim()), child: const Text('Go')),
                ],
              ),
            ),
            Expanded(
              child: Query(
                options: QueryOptions(
                  document: gql(doc),
                  variables: {if (_applied.isNotEmpty) 'search': _applied},
                ),
                builder: (result, {fetchMore, refetch}) {
                  if (result.isLoading) return const LoadingWidget();
                  if (result.hasException) {
                    return ErrorState(
                      message: graphQLErrorMessage(result.exception, 'Could not load schools.'),
                      onRetry: () => refetch?.call(),
                    );
                  }
                  final schools = (result.data?[key] as List?) ?? [];
                  if (schools.isEmpty) {
                    return Center(
                      child: Text(
                        _applied.isEmpty ? 'Type a name and tap Go.' : 'No match. Try other spelling.',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: schools.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (_, i) {
                      final s = schools[i] as Map<String, dynamic>;
                      final id = s['id'] as String?;
                      final name = s['name'] as String? ?? '';
                      final sub = '${s['district'] ?? ''} · ${s['region'] ?? ''}';
                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: DesignTokens.border),
                        ),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(sub),
                        selected: id == widget.selectedId,
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
