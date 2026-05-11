import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/config/theme/app_colors.dart';

class MaterialsScreen extends StatefulWidget {
  const MaterialsScreen({super.key});
  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';
  String? _contentType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Study Materials')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search materials...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() { _searchCtrl.clear(); _search = ''; }))
                    : null,
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [null, 'pdf', 'video', 'text', 'image'].map((t) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(t ?? 'All'),
                  selected: _contentType == t,
                  onSelected: (_) => setState(() => _contentType = t),
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Query(
              options: QueryOptions(
                document: gql(kMaterials),
                variables: {
                  if (_search.isNotEmpty) 'search': _search,
                  if (_contentType != null) 'contentType': _contentType,
                  'limit': 30,
                },
              ),
              builder: (result, {fetchMore, refetch}) {
                if (result.isLoading) return const Center(child: CircularProgressIndicator());
                final materials = (result.data?['materials'] as List?) ?? [];
                if (materials.isEmpty) {
                  return const Center(child: Text('No materials found.'));
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.85,
                  ),
                  itemCount: materials.length,
                  itemBuilder: (_, i) => _MaterialGridCard(material: materials[i]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.upload),
      ),
    );
  }
}

class _MaterialGridCard extends StatelessWidget {
  final Map material;
  const _MaterialGridCard({required this.material});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/materials/${material['slug']}'),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_icon(material['contentType']), color: AppColors.primary, size: 20),
                  const Spacer(),
                  if (material['isBookmarked'] == true)
                    const Icon(Icons.bookmark, color: AppColors.secondary, size: 18),
                ],
              ),
              const SizedBox(height: 8),
              Text(material['title'], maxLines: 3, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const Spacer(),
              Text(material['subject']?['name'] ?? '',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  IconData _icon(String? t) {
    switch (t) {
      case 'pdf': return Icons.picture_as_pdf;
      case 'video': return Icons.play_circle_outline;
      case 'image': return Icons.image_outlined;
      default: return Icons.article_outlined;
    }
  }
}
