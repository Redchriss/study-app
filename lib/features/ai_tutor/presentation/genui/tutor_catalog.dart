import 'package:genui/genui.dart';
import 'quiz_display.dart';
import 'summary_card.dart';
import 'plan_timeline.dart';

Catalog buildTutorCatalog() {
  return BasicCatalogItems.asCatalog().copyWith(
    newItems: [
      quizDisplayItem,
      summaryCardItem,
      planTimelineItem,
    ],
  );
}
