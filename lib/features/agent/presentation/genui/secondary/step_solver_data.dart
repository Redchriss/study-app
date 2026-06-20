import 'package:genui/genui.dart';

class StepData {
  final int stepNumber;
  final String action;
  final String working;
  final String explanation;

  StepData({
    required this.stepNumber,
    required this.action,
    required this.working,
    required this.explanation,
  });

  factory StepData.fromJson(Map<String, Object?> json) {
    return StepData(
      stepNumber: (json['step_number'] as num?)?.toInt() ?? 0,
      action: (json['action'] as String?) ?? '',
      working: (json['working'] as String?) ?? '',
      explanation: (json['explanation'] as String?) ?? '',
    );
  }
}

class StepSolverData {
  final String problemStatement;
  final String subject;
  final List<StepData> steps;
  final String finalAnswer;
  final String actionName;
  final JsonMap actionContext;

  StepSolverData({
    required this.problemStatement,
    required this.subject,
    required this.steps,
    required this.finalAnswer,
    required this.actionName,
    required this.actionContext,
  });

  factory StepSolverData.fromJson(Map<String, Object?> json) {
    final action = json['solverCompleteAction'] as JsonMap?;
    final event = action?['event'] as JsonMap?;
    final stepsRaw = json['steps'] as List<dynamic>?;
    return StepSolverData(
      problemStatement: (json['problem_statement'] as String?) ?? '',
      subject: (json['subject'] as String?) ?? 'Mathematics',
      steps: stepsRaw
              ?.map((e) => StepData.fromJson(e as Map<String, Object?>))
              .toList() ??
          [],
      finalAnswer: (json['final_answer'] as String?) ?? '',
      actionName: (event?['name'] as String?) ?? 'solver_complete',
      actionContext: (event?['context'] as JsonMap?) ?? {},
    );
  }
}
