import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';

/// Bottom-sheet: search + public/private filter, pick one university/college.
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
                  if (result.isLoading) return const Center(child: CircularProgressIndicator());
                  if (result.hasException) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          result.exception?.graphqlErrors.firstOrNull?.message ?? 'Could not load institutions.',
                          textAlign: TextAlign.center,
                        ),
                      ),
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

/// Bottom-sheet: search primary or secondary schools.
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
                  if (result.isLoading) return const Center(child: CircularProgressIndicator());
                  if (result.hasException) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          result.exception?.graphqlErrors.firstOrNull?.message ?? 'Could not load schools.',
                          textAlign: TextAlign.center,
                        ),
                      ),
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
                          side: BorderSide(color: DesignTokens.border),
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

/// Bottom-sheet: programmes for one university with text filter.
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
                  if (result.isLoading) return const Center(child: CircularProgressIndicator());
                  if (result.hasException) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          result.exception?.graphqlErrors.firstOrNull?.message ?? 'Could not load programmes.',
                          textAlign: TextAlign.center,
                        ),
                      ),
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
