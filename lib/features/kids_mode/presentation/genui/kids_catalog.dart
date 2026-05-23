import 'package:genui/genui.dart';
import 'emoji_story_card.dart';
import 'interactive_match.dart';

Catalog buildKidsCatalog() {
  return BasicCatalogItems.asCatalog().copyWith(
    newItems: [
      emojiStoryCardItem,
      interactiveMatchItem,
    ],
  );
}