import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/widgets.dart';

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
    final h = MediaQuery.sizeOf(context).height * 0.88;
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
                  Text('Choose institution', style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search name, city, acronym…',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  isDense: true,
                ),
                textInputAction: TextInputAction.search,
                onChanged: (value) => setState(() => _appliedQuery = value.trim()),
                onSubmitted: (_) => setState(() => _appliedQuery = _searchCtrl.text.trim()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _typeFilter == null,
                    onSelected: (_) => setState(() => _typeFilter = null),
                  ),
                  FilterChip(
                    label: const Text('Public'),
                    selected: _typeFilter == 'public',
                    onSelected: (_) => setState(() => _typeFilter = 'public'),
                  ),
                  FilterChip(
                    label: const Text('Private'),
                    selected: _typeFilter == 'private',
                    onSelected: (_) => setState(() => _typeFilter = 'private'),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _appliedQuery = _searchCtrl.text.trim()),
                    child: const Text('Search'),
                  ),
                ],
              ),
            ),
            Expanded(
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
                      message: graphQLErrorMessage(result.exception, 'Could not load institutions.'),
                      onRetry: () => refetch?.call(),
                    );
                  }
                  final list = (result.data?['universities'] as List?) ?? [];
                  if (list.isEmpty) {
                    return const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No results. Try different words.')));
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final u = list[i] as Map<String, dynamic>;
                      final id = u['id'] as String?;
                      final name = u['name'] as String? ?? '';
                      final loc = u['location'] as String? ?? '';
                      final typ = u['universityType'] as String? ?? '';
                      final desc = (u['description'] as String?)?.trim() ?? '';
                      final short = u['shortName'] as String? ?? '';
                      final selected = id == widget.selectedId;
                      return ListTile(
                        selected: selected,
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          [if (short.isNotEmpty) short, loc, typ].where((e) => e.isNotEmpty).join(' · '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => Navigator.pop(context, {'id': id, 'name': name}),
                        trailing: desc.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.info_outline, size: 20),
                                onPressed: () => showDialog<void>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text(name),
                                    content: SingleChildScrollView(child: Text(desc.isEmpty ? '—' : desc)),
                                    actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
                                  ),
                                ),
                              ),
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
