# Yaza Kids Mode — GenUI Catalog Specification

## Context

Kids Mode is a self-contained app-within-the-app targeting children aged 4–9
(pre-primary through lower primary). All content is AI-generated in real time.
The tutor speaks directly to the child. Every UI interaction must feel like play.

**Study mode**: `kids_lesson`
**Gemini model**: `gemini-2.5-flash-lite`
**Catalog file**: `lib/features/kids_mode/presentation/genui/kids_catalog.dart`
**Visual theme**: `KidsVisualTheme` (do NOT use Material 3 colorScheme here —
use the kids theme tokens which have high-contrast, playful colors)

---

## Design Principles for Kids Mode

- **Big targets.** Every tappable element must be at minimum 56×56dp. Children
  have lower touch precision.
- **Instant feedback.** Every tap must produce a visual response within 100ms.
  No loading states visible to the child.
- **Sound hooks.** Every correct action should trigger a cheerful sound (use
  `audioplayers` which is already a dependency of `genui`).
- **No failure shame.** Wrong answers shake and reset — they never show a red X
  or negative message. The AI reframes.
- **Animated entrances always.** Every widget slides or scales in. Nothing appears
  instantly.
- **Max 3 choices per question.** Cognitive load for this age group caps here.

---

## Existing Catalog Items (keep and enhance)

### EmojiStoryCard (existing — enhance)

**Purpose**: Big emoji + short sentence for early readers. Animated entrance.
Read-only. The AI generates a micro-story one sentence at a time.

**Enhancement**: Add a text-to-speech trigger button (speaker icon). When tapped,
use Flutter TTS to read the sentence aloud. This is critical for pre-readers.

```dart
// Schema (existing — add tts_text field)
final emojiStoryCardSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['EmojiStoryCard']),
    'emoji': S.string(description: 'Single large emoji representing the story'),
    'text': S.string(description: 'One short sentence, max 8 words, simple language'),
    'tts_text': S.string(description: 'Same sentence optimised for text-to-speech reading'),
  },
  required: ['component', 'emoji', 'text'],
);
```

### InteractiveMatch (existing — keep as-is)

Child taps correct emoji from options. Wrong answer shakes + resets.
`completeAction` fires on correct answer.

---

## New Catalog Items to Build

### 1. TapAndLearn

**Purpose**: Full-screen object with its name. Child taps the object and it
animates + the name is spoken aloud. Pure vocabulary building. Perfect for
Standard 1 first sessions.

**Interaction**: Tap anywhere on the card → `ScaleTransition` bounce animation
→ TTS reads the word → `learnAction` dispatched to AI

**Visual**: Large centred emoji (or image), word displayed below in 36sp bold,
bright background from `KidsVisualTheme.cardColors` cycling per surface.

```dart
final tapAndLearnSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['TapAndLearn']),
    'emoji': S.string(description: 'Emoji representing the object to learn'),
    'word': S.string(description: 'The word to teach, max 2 syllables for youngest'),
    'word_in_chichewa': S.string(description: 'Chichewa translation of the word'),
    'learnAction': A2uiSchemas.action(description: 'Fired after child taps and hears the word'),
  },
  required: ['component', 'emoji', 'word', 'learnAction'],
);
```

**Notes for agent**:
- Show both English and Chichewa word if `word_in_chichewa` is provided
- Alternate language shown can be toggled by parent settings flag
- Animation sequence: tap → scale to 1.3 → bounce back → TTS fires

---

### 2. WordBubble

**Purpose**: A word appears inside a floating bubble. Child taps it to "pop" it.
Used for phonics — child hears the letter sound when they pop. Chain of bubbles
teaches letter recognition without it feeling like work.

**Interaction**: Tap bubble → pop animation → sound plays → `popAction` dispatched

**Visual**: Circular coloured bubble, word/letter centred, bubbles float upward
slightly using a looping `AnimationController` with sine wave offset.

```dart
final wordBubbleSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['WordBubble']),
    'bubbles': S.array(
      items: S.object(properties: {
        'letter_or_word': S.string(description: 'Single letter or short word in the bubble'),
        'sound_hint': S.string(description: 'How it sounds, e.g. "sounds like aah"'),
      }),
      description: 'List of 3–5 bubbles to display',
    ),
    'popAction': A2uiSchemas.action(description: 'Fired each time a bubble is popped'),
  },
  required: ['component', 'bubbles', 'popAction'],
);
```

**Notes for agent**:
- Each bubble gets a random colour from `KidsVisualTheme.bubbleColors`
- Bubbles animate in staggered (100ms delay each)
- When all bubbles are popped, surface auto-completes via `popAction`

---

### 3. CountingBoard

**Purpose**: A grid of fun emoji objects. The AI sets how many are shown. Child
counts them and taps the correct number from three choices below. Grounds maths
in visual, concrete objects (mangoes, goats, stars — Malawi-relevant).

**Interaction**: Child taps number choice → correct: `RewardBurst` surfaces next +
`countAction` dispatched with `{selectedCount, correct: true}` → incorrect: shake
animation on wrong choice, item stays, child tries again.

```dart
final countingBoardSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['CountingBoard']),
    'emoji': S.string(description: 'Single emoji to repeat, e.g. 🥭 or 🐐'),
    'count': S.integer(description: 'How many emoji objects to show, between 1 and 10'),
    'choices': S.array(
      items: S.integer(),
      description: 'Exactly 3 number choices, one of which must equal count',
    ),
    'countAction': A2uiSchemas.action(
      description: 'Dispatched when child selects an answer, context includes selectedCount and isCorrect',
    ),
  },
  required: ['component', 'emoji', 'count', 'choices', 'countAction'],
);
```

**Notes for agent**:
- Lay out emoji in a `Wrap` widget with `spacing: 8`, `runSpacing: 8`
- Number choice buttons are large circles (64dp diameter), bold text
- Max emoji count is 10 — enforce this in `fromJson` with a clamp

---

### 4. StoryChoiceCard

**Purpose**: A short story paragraph (2–3 sentences) with two choice buttons at
the bottom. Child picks what happens next. The AI uses the choice to branch the
story. Builds reading comprehension through narrative engagement.

**Interaction**: Tap choice A or B → `choiceAction` dispatched with
`{choiceIndex: 0 or 1, choiceLabel: string}` → AI generates next story beat

**Visual**: Story text in large readable font (20sp), two large colourful buttons
side by side at bottom. No wrong answer — both choices continue the story.

```dart
final storyChoiceCardSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['StoryChoiceCard']),
    'story_text': S.string(
      description: 'Story paragraph, 2-3 short sentences, simple vocabulary, present tense',
    ),
    'choice_a': S.string(description: 'First story branch option, max 6 words'),
    'choice_b': S.string(description: 'Second story branch option, max 6 words'),
    'choiceAction': A2uiSchemas.action(
      description: 'Dispatched when child taps a choice, includes choiceIndex (0 or 1) and choiceLabel',
    ),
  },
  required: ['component', 'story_text', 'choice_a', 'choice_b', 'choiceAction'],
);
```

---

### 5. RewardBurst

**Purpose**: A full-screen celebration moment. Confetti particles, animated star,
congratulatory message. Surfaces automatically after correct answers. Read-only —
it self-dismisses after 2.5 seconds then `dismissAction` fires.

**Visual**: Confetti using a `CustomPainter` with 40 coloured rectangles falling
from random top positions. Centred star emoji scales in with `ElasticOutCurve`.
Message text in bold kids font.

```dart
final rewardBurstSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['RewardBurst']),
    'message': S.string(
      description: 'Short celebration message, max 5 words, e.g. "Amazing! You got it!"',
    ),
    'stars_earned': S.integer(description: 'Number of stars to show (1, 2, or 3)'),
    'dismissAction': A2uiSchemas.action(description: 'Fires automatically after 2.5 seconds'),
  },
  required: ['component', 'message', 'stars_earned', 'dismissAction'],
);
```

**Notes for agent**:
- Use `Future.delayed(Duration(milliseconds: 2500))` to auto-fire `dismissAction`
- Stars display as row of ⭐ emoji scaling in with staggered delays
- Confetti painter uses `math.Random` seeded by `stars_earned` for consistency

---

### 6. DailyStreakCard

**Purpose**: Shows the child's current learning streak (days in a row). Surfaces
at the start of each session. Even at age 6 this creates habit and gives parents
something to celebrate with the child.

**Visual**: Animated flame emoji (scale pulse loop), large streak number, row of
day dots (filled = completed, empty = future). Read-only, no interaction.

```dart
final dailyStreakCardSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['DailyStreakCard']),
    'streak_days': S.integer(description: 'Current streak in days'),
    'child_name': S.string(description: 'Child first name for personalised message'),
    'message': S.string(description: 'Short encouraging message about the streak'),
  },
  required: ['component', 'streak_days', 'message'],
);
```

---

## Complete Kids Catalog Builder

```dart
// lib/features/kids_mode/presentation/genui/kids_catalog.dart

Catalog buildKidsCatalog() {
  return BasicCatalogItems.asCatalog().copyWith(
    newItems: [
      emojiStoryCardItem,      // enhanced existing
      interactiveMatchItem,    // existing
      tapAndLearnItem,         // NEW
      wordBubbleItem,          // NEW
      countingBoardItem,       // NEW
      storyChoiceCardItem,     // NEW
      rewardBurstItem,         // NEW
      dailyStreakCardItem,      // NEW — surfaces first in every session
    ],
  );
}
```

---

## Kids Mode AI Tutor System Prompt Addendum

Append this to the `clientInstructions` for `kids_lesson` mode:

```
You are Yaza, a warm and playful AI tutor for young children aged 4-9.
Rules:
- ALWAYS start the session by surfacing DailyStreakCard.
- Use EmojiStoryCard to introduce any new concept before quizzing.
- Surface RewardBurst after EVERY correct answer. Children need constant positive reinforcement.
- Never surface more than 2 widgets before asking an interactive question.
- Use CountingBoard for any number concept. Use InteractiveMatch for vocabulary.
- After 5 correct answers, surface DailyStreakCard again with an updated message.
- Keep all text under 10 words per sentence. Use simple vocabulary only.
- Include Chichewa words in TapAndLearn when teaching object vocabulary.
- Never express disappointment. Wrong answers get: shake animation + "Try again! You can do it!"
```

---

## Kids Mode Session Flow (reference for AI)

```
Session Start
    └─► DailyStreakCard (streak + welcome)
        └─► EmojiStoryCard (introduce topic)
            └─► TapAndLearn × 2-3 (vocabulary)
                └─► InteractiveMatch (first quiz)
                    ├─► Correct → RewardBurst → next TapAndLearn
                    └─► Wrong → shake + retry (same widget, no penalty)
                        └─► [after 5 correct] → DailyStreakCard (milestone)
                            └─► StoryChoiceCard (comprehension / engagement)
                                └─► RewardBurst (session complete)
```
