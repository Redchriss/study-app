import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/config/theme/app_colors.dart';

class CirclesScreen extends ConsumerWidget {
  const CirclesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Study Circles'), centerTitle: true),
      body: Query(
        options: QueryOptions(document: gql(kMyCircles)),
        builder: (result, {refetch}) {
          if (result.isLoading) return const Center(child: CircularProgressIndicator());
          final circles = (result.data?['myCircles'] as List?) ?? [];
          if (circles.isEmpty) {
            return Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.groups_outlined, size: 80, color: AppColors.textSecondary.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text('No circles yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 18)),
                const SizedBox(height: 8),
                Text('Complete your profile setup to join', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ]),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => refetch?.call(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: circles.length,
              itemBuilder: (_, i) {
                final c = circles[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Icon(Icons.group, color: AppColors.primary, size: 20),
                    ),
                    title: Text(c['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${c['educationLevel'] ?? ''}  ·  ${c['memberCount'] ?? 0} members'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/circles/${c['slug']}'),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
