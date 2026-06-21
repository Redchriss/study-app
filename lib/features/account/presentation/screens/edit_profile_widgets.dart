import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'edit_profile_manager.dart';

class ModernTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool dark;
  final TextInputType? keyboard;
  final TextInputAction? action;

  const ModernTextField(
      {super.key,
      required this.controller,
      required this.label,
      required this.dark,
      this.keyboard,
      this.action});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      textInputAction: action,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor:
            dark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
      ),
    );
  }
}

class ModernDropdown<T> extends StatelessWidget {
  final Key dropKey;
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final bool dark;

  const ModernDropdown(
      {super.key,
      required this.dropKey,
      required this.label,
      required this.value,
      required this.items,
      required this.onChanged,
      required this.dark});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      key: dropKey,
      value: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor:
            dark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
      ),
    );
  }
}

class ModernListTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool dark;

  const ModernListTile(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.icon,
      required this.onTap,
      required this.dark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
            color: dark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: DesignTokens.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: DesignTokens.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: DesignTokens.textSecondary)),
                  ]),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: DesignTokens.textSecondary),
          ],
        ),
      ),
    );
  }
}

class Avatar extends ConsumerWidget {
  final Map<String, dynamic>? user;
  final bool dark;
  const Avatar({super.key, required this.user, required this.dark});

  Future<void> _pickAndUpload(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (image == null || !context.mounted) return;

    final bytes = await image.readAsBytes();
    final b64 = base64Encode(bytes);

    final client = ref.read(graphqlClientProvider);
    final result = await client.mutate(MutationOptions(
      document: gql(kUpdateProfileAvatar),
      variables: {'imageBase64': b64},
    ));

    if (!context.mounted) return;
    if (result.hasException ||
        result.data?['updateProfileAvatar']?['errors'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Could not update avatar'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
      return;
    }
    await ref.read(authProvider.notifier).refreshUser();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Avatar updated'),
      backgroundColor: Color(0xFF2ECC71),
    ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarUrl = user?['profile']?['avatarUrl']?.toString() ?? '';
    return Center(
      child: GestureDetector(
        onTap: () => _pickAndUpload(context, ref),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [
                BoxShadow(
                    color: DesignTokens.primary.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 8))
              ]),
              child: CircleAvatar(
                radius: 56,
                backgroundColor: DesignTokens.primary,
                backgroundImage:
                    avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                child: avatarUrl.isEmpty
                    ? Text(
                        user?['username']
                                ?.toString()
                                .substring(0, 1)
                                .toUpperCase() ??
                            '?',
                        style: const TextStyle(
                            fontSize: 40,
                            color: Colors.white,
                            fontWeight: FontWeight.w800))
                    : null,
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dark ? DesignTokens.darkSurface : Colors.white,
                    boxShadow: DesignTokens.shadowSm(dark)),
                child: const Icon(Icons.camera_alt_rounded,
                    size: 20, color: DesignTokens.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PersonalDetails extends StatelessWidget {
  final EditProfileManager m;
  final bool dark;
  const PersonalDetails({super.key, required this.m, required this.dark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: dark ? DesignTokens.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: DesignTokens.shadowSm(dark)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ModernTextField(
              controller: m.firstNameCtrl,
              label: 'First name',
              dark: dark,
              action: TextInputAction.next),
          const SizedBox(height: 16),
          ModernTextField(
              controller: m.lastNameCtrl,
              label: 'Last name',
              dark: dark,
              action: TextInputAction.next),
          const SizedBox(height: 16),
          ModernTextField(
              controller: m.emailCtrl,
              label: 'Email',
              dark: dark,
              keyboard: TextInputType.emailAddress,
              action: TextInputAction.next),
          const SizedBox(height: 16),
          ModernTextField(
              controller: m.phoneCtrl,
              label: 'Phone number',
              dark: dark,
              keyboard: TextInputType.phone,
              action: TextInputAction.next),
          const SizedBox(height: 16),
          TextField(
              controller: m.bioCtrl,
              maxLines: 3,
              maxLength: 300,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Bio',
                hintText: 'Tell others about yourself...',
                filled: true,
                fillColor: dark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.shade50,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none),
              )),
        ],
      ),
    );
  }
}

class NoLevelWarning extends StatelessWidget {
  const NoLevelWarning({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: DesignTokens.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16)),
      child: const Text(
          'Complete onboarding first to set your education level.',
          style: TextStyle(
              color: DesignTokens.warning, fontWeight: FontWeight.w600)),
    );
  }
}
