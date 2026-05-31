import 'package:flutter/material.dart';
import 'formula_card_data.dart';
import 'formula_card_parts.dart';
import 'formula_card_variables_table.dart';

class FormulaCardWidget extends StatefulWidget {
  final FormulaCardData data;

  const FormulaCardWidget({super.key, required this.data});

  @override
  State<FormulaCardWidget> createState() => _FormulaCardWidgetState();
}

class _FormulaCardWidgetState extends State<FormulaCardWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _entrance;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _entrance = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _entrance,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FormulaDisplay(data: widget.data, theme: theme, cs: cs),
              const SizedBox(height: 12),
              if (widget.data.variables.isNotEmpty)
                VariablesTable(data: widget.data, theme: theme, cs: cs),
              const SizedBox(height: 12),
              WorkedExampleBox(
                workedExample: widget.data.workedExample,
                theme: theme,
                cs: cs,
              ),
              if (widget.data.msceTip != null) ...[
                const SizedBox(height: 12),
                MsceTipBox(
                  msceTip: widget.data.msceTip!,
                  theme: theme,
                  cs: cs,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
