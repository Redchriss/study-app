import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

final formulaCardSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['FormulaCard']),
    'formula_name': S.string(description: 'Name of the formula or law'),
    'formula': S.string(
      description: 'The formula itself in plain text e.g. "F = ma"',
    ),
    'variables': S.list(
      items: S.object(properties: {
        'symbol': S.string(description: 'Variable symbol'),
        'meaning': S.string(description: 'What the variable represents'),
        'unit': S.string(description: 'SI unit e.g. kg, m/s², N'),
      }),
    ),
    'worked_example': S.string(
      description: 'One concrete worked example using realistic values',
    ),
    'msce_tip': S.string(
      description: 'Common MSCE exam mistake to avoid when using this formula',
    ),
  },
  required: [
    'component',
    'formula_name',
    'formula',
    'variables',
    'worked_example',
  ],
);

class _VariableData {
  final String symbol;
  final String meaning;
  final String unit;

  _VariableData({
    required this.symbol,
    required this.meaning,
    required this.unit,
  });

  factory _VariableData.fromJson(Map<String, Object?> json) {
    return _VariableData(
      symbol: (json['symbol'] as String?) ?? '',
      meaning: (json['meaning'] as String?) ?? '',
      unit: (json['unit'] as String?) ?? '',
    );
  }
}

class _FormulaCardData {
  final String formulaName;
  final String formula;
  final List<_VariableData> variables;
  final String workedExample;
  final String? msceTip;

  _FormulaCardData({
    required this.formulaName,
    required this.formula,
    required this.variables,
    required this.workedExample,
    this.msceTip,
  });

  factory _FormulaCardData.fromJson(Map<String, Object?> json) {
    final varsRaw = json['variables'] as List<dynamic>?;
    return _FormulaCardData(
      formulaName: (json['formula_name'] as String?) ?? '',
      formula: (json['formula'] as String?) ?? '',
      variables: varsRaw
              ?.map((e) => _VariableData.fromJson(e as Map<String, Object?>))
              .toList() ??
          [],
      workedExample: (json['worked_example'] as String?) ?? '',
      msceTip: json['msce_tip'] as String?,
    );
  }
}

class _FormulaCardWidget extends StatefulWidget {
  final _FormulaCardData data;

  const _FormulaCardWidget({required this.data});

  @override
  State<_FormulaCardWidget> createState() => _FormulaCardWidgetState();
}

class _FormulaCardWidgetState extends State<_FormulaCardWidget>
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
              _buildFormulaDisplay(theme, cs),
              const SizedBox(height: 12),
              if (widget.data.variables.isNotEmpty)
                _buildVariablesTable(theme, cs),
              const SizedBox(height: 12),
              _buildWorkedExample(theme, cs),
              if (widget.data.msceTip != null) ...[
                const SizedBox(height: 12),
                _buildMsceTip(theme, cs),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormulaDisplay(ThemeData theme, ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primaryContainer,
            cs.primaryContainer.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            widget.data.formulaName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.data.formula,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVariablesTable(ThemeData theme, ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Variables',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(1),
              1: FlexColumnWidth(3),
              2: FlexColumnWidth(2),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: cs.outlineVariant),
                  ),
                ),
                children: [
                  _buildVarHeader('Symbol', theme, cs),
                  _buildVarHeader('Meaning', theme, cs),
                  _buildVarHeader('Unit', theme, cs),
                ],
              ),
              ...widget.data.variables.map((v) {
                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        v.symbol,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w700,
                          color: cs.primary,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        v.meaning,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        v.unit,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVarHeader(String label, ThemeData theme, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildWorkedExample(ThemeData theme, ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calculate_outlined,
                  size: 16, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                'Worked example',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.data.workedExample,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildMsceTip(ThemeData theme, ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, size: 18, color: cs.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.data.msceTip!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onErrorContainer,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final formulaCardItem = CatalogItem(
  name: 'FormulaCard',
  dataSchema: formulaCardSchema,
  widgetBuilder: (itemContext) {
    final json = itemContext.data as Map<String, Object?>;
    final data = _FormulaCardData.fromJson(json);
    return _FormulaCardWidget(data: data);
  },
);
