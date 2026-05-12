import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import 'animated_press.dart';

/// Bento-style card with optional spanning, glassmorphism, and press animation.
/// Grid children: use columnSpan / rowSpan for asymmetric bento layouts.

class BentoCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final int columnSpan;
  final int rowSpan;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final bool glass;

  const BentoCard({
    super.key,
    required this.child,
    this.onTap,
    this.columnSpan = 1,
    this.rowSpan = 1,
    this.color,
    this.padding,
    this.glass = false,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final content = Container(
      padding: padding ?? const EdgeInsets.all(DesignTokens.spLg),
      decoration: glass
          ? DesignTokens.glassDecoration(dark)
          : BoxDecoration(
              color: color ?? Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
              border: Border.all(
                color: (dark ? DesignTokens.darkBorder : DesignTokens.border)
                    .withValues(alpha: 0.5),
              ),
              boxShadow: DesignTokens.shadowSm(dark),
            ),
      child: child,
    );

    if (onTap != null) {
      return AnimatedPress(onTap: onTap, child: content);
    }
    return content;
  }
}

/// Layout helper — wraps children in a bento grid.
/// Example:
/// ```dart
/// BentoGrid(children: [
///   BentoCard(child: ..., columnSpan: 2),
///   BentoCard(child: ...),
/// ])
/// ```
class BentoGrid extends StatelessWidget {
  final List<BentoCard> children;
  final double spacing;
  final int columns;

  const BentoGrid({
    super.key,
    required this.children,
    this.spacing = DesignTokens.spMd,
    this.columns = 6,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = spacing;
        final colWidth = (constraints.maxWidth - gap * (columns - 1)) / columns;

        // Build rows by placing cards left-to-right
        final rows = <Widget>[];
        int i = 0;
        while (i < children.length) {
          final rowCards = <Widget>[];
          int usedCols = 0;
          while (i < children.length && usedCols < columns) {
            final card = children[i];
            final span = card.columnSpan.clamp(1, columns - usedCols);
            rowCards.add(
              SizedBox(
                width: colWidth * span + gap * (span - 1),
                child: SizedBox(
                  height: 140 * card.rowSpan + gap * (card.rowSpan - 1),
                  child: card,
                ),
              ),
            );
            usedCols += span;
            i++;
          }
          rows.add(Padding(
            padding: EdgeInsets.only(bottom: gap),
            child: Row(
              children: List.generate(rowCards.length * 2 - 1, (j) {
                if (j.isOdd) return SizedBox(width: gap);
                return rowCards[j ~/ 2];
              }),
            ),
          ));
        }
        return Column(children: rows);
      },
    );
  }
}
