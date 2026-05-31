import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'step_solver_data.dart';
import 'step_solver_widget.dart';

final stepSolverSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['StepSolver']),
    'problem_statement':
        S.string(description: 'The full question or problem to solve'),
    'subject': S.string(
      enumValues: ['Mathematics', 'Physics', 'Chemistry', 'Biology', 'Other'],
    ),
    'steps': S.list(
      description: 'Between 3 and 7 steps',
      items: S.object(properties: {
        'step_number': S.integer(description: 'Step number starting from 1'),
        'action': S.string(description: 'What is done in this step'),
        'working': S.string(
          description: 'The actual working (equations, logic)',
        ),
        'explanation': S.string(
          description: 'Why this step is taken',
        ),
      }),
    ),
    'final_answer': S.string(description: 'The final answer'),
    'solverCompleteAction': A2uiSchemas.action(
      description: 'Dispatched when student reaches the final step',
    ),
  },
  required: [
    'component',
    'problem_statement',
    'steps',
    'final_answer',
    'solverCompleteAction',
  ],
);

final stepSolverItem = CatalogItem(
  name: 'StepSolver',
  dataSchema: stepSolverSchema,
  widgetBuilder: (itemContext) {
    final json = itemContext.data as Map<String, Object?>;
    final data = StepSolverData.fromJson(json);
    return StepSolverWidget(
      data: data,
      onComplete: () async {
        final resolvedContext = await resolveContext(
          itemContext.dataContext,
          data.actionContext,
        );
        itemContext.dispatchEvent(
          UserActionEvent(
            name: data.actionName,
            sourceComponentId: itemContext.id,
            context: resolvedContext,
          ),
        );
      },
      onExplainStep: (stepNumber) {
        itemContext.dispatchEvent(
          UserActionEvent(
            name: 'explain_step',
            sourceComponentId: itemContext.id,
            context: {'stepNumber': stepNumber},
          ),
        );
      },
    );
  },
);
