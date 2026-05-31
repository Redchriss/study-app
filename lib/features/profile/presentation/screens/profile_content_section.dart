import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/widgets.dart';
import 'profile_list_widgets.dart';

class ProfileContentSection extends ConsumerWidget {
  const ProfileContentSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const SectionLabel(label: 'STUDY CONTENT'),
        const SizedBox(height: 10),
        GlassCard(
          child: Column(
            children: [
              NavRow(
                  icon: Icons.upload_file_outlined,
                  label: 'Upload Material',
                  onTap: () => context.push('/upload-material')),
              const SectionDivider(),
              NavRow(
                  icon: Icons.folder_special_outlined,
                  label: 'My Uploads',
                  onTap: () => context.push('/my-uploads')),
              const SectionDivider(),
              NavRow(
                  icon: Icons.article_outlined,
                  label: 'Past Papers',
                  onTap: () => context.push('/past-papers')),
              const SectionDivider(),
              NavRow(
                  icon: Icons.library_books_outlined,
                  label: 'Paper Library',
                  onTap: () => context.push('/paper-library')),
              const SectionDivider(),
              NavRow(
                  icon: Icons.bookmark_outline,
                  label: 'Bookmarks',
                  onTap: () => context.push('/bookmarks')),
            ],
          ),
        ),
      ],
    );
  }
}
