import 'package:genui/genui.dart';
import 'flash_card.dart';
import 'step_solver.dart';
import 'past_paper_question.dart';
import 'definition_card.dart';
import 'confidence_slider.dart';
import 'essay_outline.dart';
import 'formula_card.dart';
import 'motivation_card.dart';

Catalog buildSecondaryCatalog() {
  return BasicCatalogItems.asCatalog().copyWith(
    newItems: [
      flashCardItem,
      stepSolverItem,
      pastPaperQuestionItem,
      definitionCardItem,
      confidenceSliderItem,
      essayOutlineItem,
      formulaCardItem,
      motivationCardItem,
    ],
  );
}
