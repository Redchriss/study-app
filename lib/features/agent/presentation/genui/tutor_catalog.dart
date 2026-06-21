import 'package:genui/genui.dart';
import 'quiz_display.dart';
import 'summary_card.dart';
import 'plan_timeline.dart';
import 'learning_session.dart';
import 'secondary/secondary_catalog.dart' as secondary;
import 'primary/primary_catalog.dart' as primary;
import 'tertiary/tertiary_catalog.dart' as tertiary;
import 'secondary/flash_card.dart';
import 'secondary/step_solver.dart';
import 'secondary/confidence_slider.dart';

Catalog buildTutorCatalog() {
  return BasicCatalogItems.asCatalog().copyWith(
    newItems: [
      quizDisplayItem,
      summaryCardItem,
      planTimelineItem,
      flashCardItem,
      stepSolverItem,
      confidenceSliderItem,
      learningSessionItem,
    ],
  );
}

Catalog catalogForStudyMode(String mode) {
  if (mode.startsWith('primary_')) {
    return primary.buildPrimaryCatalog();
  } else if (mode.startsWith('secondary_')) {
    return secondary.buildSecondaryCatalog();
  } else if (mode.startsWith('tertiary_')) {
    return tertiary.buildTertiaryCatalog();
  }
  // Coach, quiz, revise, memorize, plan modes all use the full catalog
  return buildTutorCatalog();
}
