class VariableData {
  final String symbol;
  final String meaning;
  final String unit;

  VariableData({
    required this.symbol,
    required this.meaning,
    required this.unit,
  });

  factory VariableData.fromJson(Map<String, Object?> json) {
    return VariableData(
      symbol: (json['symbol'] as String?) ?? '',
      meaning: (json['meaning'] as String?) ?? '',
      unit: (json['unit'] as String?) ?? '',
    );
  }
}

class FormulaCardData {
  final String formulaName;
  final String formula;
  final List<VariableData> variables;
  final String workedExample;
  final String? msceTip;

  FormulaCardData({
    required this.formulaName,
    required this.formula,
    required this.variables,
    required this.workedExample,
    this.msceTip,
  });

  factory FormulaCardData.fromJson(Map<String, Object?> json) {
    final varsRaw = json['variables'] as List<dynamic>?;
    return FormulaCardData(
      formulaName: (json['formula_name'] as String?) ?? '',
      formula: (json['formula'] as String?) ?? '',
      variables: varsRaw
              ?.map((e) => VariableData.fromJson(e as Map<String, Object?>))
              .toList() ??
          [],
      workedExample: (json['worked_example'] as String?) ?? '',
      msceTip: json['msce_tip'] as String?,
    );
  }
}
