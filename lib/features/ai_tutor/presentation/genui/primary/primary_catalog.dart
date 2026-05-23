import 'package:genui/genui.dart';
import 'simple_quiz.dart';
import 'fill_blank_card.dart';
import 'word_match_pair.dart';
import 'picture_quiz.dart';
import 'chichewa_word_card.dart';
import 'math_visual_board.dart';
import 'story_comprehension.dart';
import 'hint_reveal.dart';

Catalog buildPrimaryCatalog() {
  return BasicCatalogItems.asCatalog().copyWith(
    newItems: [
      simpleQuizItem,
      fillBlankCardItem,
      wordMatchPairItem,
      pictureQuizItem,
      chichewaWordCardItem,
      mathVisualBoardItem,
      storyComprehensionItem,
      hintRevealItem,
    ],
  );
}
