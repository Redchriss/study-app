import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

/// Shared, polished chrome for the institution / school / programme picker
/// bottom sheets so they stop looking like raw default Material lists.
///
/// Provides a rounded sheet surface with a drag handle, a clean header, a
/// pill-shaped search field and card-style result rows with a clear selected
/// state — all dark-mode aware via [DesignTokens].
class PickerSheetShell extends StatelessWidget {
  const PickerSheetShell({
    super.key,
    required this.title,
    this.subtitle,
    this.heightFactor = 0.85,
    required this.search,
    this.filters,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final double heightFactor;
  final Widget search;
  final Widget? filters;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final height = MediaQuery.sizeOf(context).height * heightFactor;
    return SafeArea(
      top: false,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: dark ? DesignTokens.darkBackground : DesignTokens.background,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(DesignTokens.radiusXxl),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: (dark ? DesignTokens.darkBorder : DesignTokens.border),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: DesignTokens.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: dark
                          ? DesignTokens.darkSurfaceVariant
                          : DesignTokens.surfaceVariant,
                    ),
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: search,
            ),
            if (filters != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: filters!,
              ),
            const SizedBox(height: 8),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

/// A rounded, filled search field used inside the picker sheets.
class PickerSearchField extends StatelessWidget {
  const PickerSearchField({
    super.key,
    required this.controller,
    required this.hint,
    this.icon = Icons.search,
    required this.onChanged,
    this.onSubmit,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmit;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fill = dark ? DesignTokens.darkSurfaceVariant : DesignTokens.surface;
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      onChanged: onChanged,
      onSubmitted: onSubmit,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: DesignTokens.textSecondary),
        filled: true,
        fillColor: fill,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          borderSide: BorderSide(
            color: dark ? DesignTokens.darkBorder : DesignTokens.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: DesignTokens.primaryLight, width: 1.5),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

/// A card-style row used to display a single pickable result.
class PickerResultTile extends StatelessWidget {
  const PickerResultTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark ? DesignTokens.darkSurface : DesignTokens.surface;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        child: AnimatedContainer(
          duration: DesignTokens.durFast,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? DesignTokens.primaryLight
                    .withValues(alpha: dark ? 0.16 : 0.08)
                : surface,
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            border: Border.all(
              color: selected
                  ? DesignTokens.primaryLight
                  : (dark ? DesignTokens.darkBorder : DesignTokens.border),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: DesignTokens.primary
                      .withValues(alpha: dark ? 0.22 : 0.08),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                ),
                child: Icon(icon,
                    size: 20,
                    color: dark
                        ? DesignTokens.primaryLight
                        : DesignTokens.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: DesignTokens.textSecondary,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (trailing != null)
                trailing!
              else
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.chevron_right_rounded,
                  color: selected
                      ? DesignTokens.primaryLight
                      : DesignTokens.textTertiary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A simple centered hint/empty message styled for the picker sheets.
class PickerEmptyHint extends StatelessWidget {
  const PickerEmptyHint({super.key, required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: DesignTokens.textTertiary),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: DesignTokens.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
