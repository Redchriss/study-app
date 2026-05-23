import 'package:genui/genui.dart';
import 'emoji_story_card.dart';
import 'interactive_match.dart';
import 'daily_streak_card.dart';
import 'tap_and_learn.dart';
import 'counting_board.dart';
import 'story_choice_card.dart';
import 'word_bubble.dart';
import 'reward_burst.dart';

Catalog buildKidsCatalog() {
  return BasicCatalogItems.asCatalog().copyWith(
    newItems: [
      dailyStreakCardItem,
      emojiStoryCardItem,
      tapAndLearnItem,
      interactiveMatchItem,
      countingBoardItem,
      storyChoiceCardItem,
      wordBubbleItem,
      rewardBurstItem,
    ],
  );
}