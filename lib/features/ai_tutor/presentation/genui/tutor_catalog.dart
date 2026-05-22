import 'package:genui/genui.dart';
import 'quiz_display.dart';

Catalog buildTutorCatalog() {
  return BasicCatalogItems.asCatalog().copyWith(
    newItems: [
      quizDisplayItem,
    ],
  );
}
