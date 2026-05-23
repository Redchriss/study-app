# Yaza Primary Level — GenUI Catalog Specification

## Context

Primary level targets Standard 1–8 students aged 7–14 in the Malawian primary
school curriculum. Topics span English, Chichewa, Mathematics, Environmental
Science, Social Studies, and Expressive Arts.

**Study modes**: `primary_coach`, `primary_revise`, `primary_explore`
**Gemini model**: `gemini-2.5-flash-lite`
**Catalog file**: `lib/features/primary/presentation/genui/primary_catalog.dart`
**Visual theme**: Material 3 — `Theme.of(context).colorScheme.*`
**Tone**: Warm, encouraging, patient. The AI speaks like a good teacher.

---

## Design Principles for Primary Level

- **Concrete before abstract.** Always ground concepts in real-world Malawian
  examples (local foods, animals, geography, currency) before abstract explanation.
- **Language awareness.** Many primary students think in Chichewa first. Widgets
  support bilingual display where relevant.
- **Short text bursts.** No widget should contain more than 4 sentences. If more
  explanation is needed, surface multiple widgets in sequence.
- **Visual anchors.** Every concept card should have an emoji or icon anchor.
  Abstract text alone does not hold attention at this age.
- **Positive progression.** Always show the student moving forward. `ProgressRing`
  should be visible in most sessions.
- **Touch-friendly sizing.** Tap targets minimum 48dp. Students may be using
  shared family phones with worn screens.

---

## Catalog Items

### 1. SimpleQuiz

**Purpose**: Multiple choice question with 3–4 options. The primary-school version
of the AI Tutor `QuizDisplay` — simpler language, emoji anchors on options,
immediate visual feedback.

**Interaction**: Tap option → if correct: option turns green + `answerAction`
dispatched with `{isCorrect: true, selectedIndex}` → if wrong: option turns red,
shakes, resets after 1.5s.

```dart
final simpleQuizSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['SimpleQuiz']),
    'question': S.string(description: 'Question in simple English or Chichewa, max 20 words'),
    'options': S.array(
      items: S.object(properties: {
        'emoji': S.string(description: 'Emoji that anchors this option visually'),
        'label': S.string(description: 'Option text, max 5 words'),
      }),
      description: '3 or 4 answer options',
    ),
    'correct_index': S.integer(description: 'Zero-based index of the correct option'),
    'answerAction': A2uiSchemas.action(
      description: 'Dispatched after answer is selected, includes isCorrect and selectedIndex',
    ),
  },
  required: ['component', 'question', 'options', 'correct_index', 'answerAction'],
);
```

**Notes for agent**:
- Show options in a `GridView` 2×2 layout, not a list — more visual, easier to tap
- Correct option: `Colors.green.shade100` background + ✓ icon
- Wrong option: `Colors.red.shade100` + shake `AnimationController` + auto-reset

---

### 2. FillBlankCard

**Purpose**: A sentence with one word blanked out. 3–4 word chips below that the
student drags or taps to fill the blank. Core for English grammar, Chichewa
vocabulary, and Science terminology.

**Interaction**: Tap a word chip → it flies up and fills the blank (animate with
`TweenAnimationBuilder`) → `fillAction` dispatched with `{selectedWord, isCorrect}`

```dart
final fillBlankCardSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['FillBlankCard']),
    'sentence_before': S.string(description: 'Text before the blank'),
    'sentence_after': S.string(description: 'Text after the blank (can be empty string)'),
    'correct_word': S.string(description: 'The correct word that fills the blank'),
    'distractor_words': S.array(
      items: S.string(),
      description: 'Two or three plausible but wrong words',
    ),
    'fillAction': A2uiSchemas.action(
      description: 'Dispatched when student taps a word chip',
    ),
  },
  required: ['component', 'sentence_before', 'correct_word', 'distractor_words', 'fillAction'],
);
```

**Notes for agent**:
- Shuffle correct_word and distractors together before display
- The blank renders as `_______` with a dashed underline using `BoxDecoration`
- Word chips are `FilterChip` widgets with `labelStyle` 16sp bold

---

### 3. WordMatchPair

**Purpose**: Two columns — left column has words, right column has definitions or
images. Student taps one from each column to create a match. Lines draw between
matched pairs using `CustomPainter`. Used for vocabulary, number-word matching,
science terms.

**Interaction**: Tap left item (highlights) → tap right item → if correct: line
draws and pair locks with colour → if wrong: both items shake and deselect →
when all pairs matched: `matchCompleteAction` dispatched.

```dart
final wordMatchPairSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['WordMatchPair']),
    'pairs': S.array(
      items: S.object(properties: {
        'left': S.string(description: 'Word or phrase on the left side'),
        'right': S.string(description: 'Matching definition, translation, or value on the right'),
      }),
      description: 'Exactly 3 or 4 pairs',
    ),
    'matchCompleteAction': A2uiSchemas.action(
      description: 'Dispatched when all pairs are correctly matched',
    ),
  },
  required: ['component', 'pairs', 'matchCompleteAction'],
);
```

**Notes for agent**:
- Shuffle left and right columns independently so they don't align visually
- Each matched pair gets a unique colour from a palette of 4
- Use `GlobalKey` on each item to get `RenderBox` positions for `CustomPainter` lines

---

### 4. PictureQuiz

**Purpose**: A large emoji or icon displayed prominently, then a question about it
with multiple choice answers. Grounds abstract concepts in visual context. Works
extremely well for Environmental Science (animals, plants, weather) and Geography.

```dart
final pictureQuizSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['PictureQuiz']),
    'picture_emoji': S.string(description: 'Large emoji representing the subject'),
    'picture_label': S.string(description: 'Name of what is shown, displayed under emoji'),
    'question': S.string(description: 'Question about the picture, max 15 words'),
    'options': S.array(
      items: S.string(),
      description: '3 answer options as plain strings',
    ),
    'correct_index': S.integer(description: 'Zero-based index of the correct answer'),
    'answerAction': A2uiSchemas.action(description: 'Dispatched after answer selected'),
  },
  required: ['component', 'picture_emoji', 'question', 'options', 'correct_index', 'answerAction'],
);
```

---

### 5. ChichewaWordCard

**Purpose**: Bilingual vocabulary card — Chichewa word on one side, English
translation on the other. Tappable to flip. Used in Chichewa lessons and in
any subject where bilingual reinforcement helps comprehension.

**Interaction**: Tap card → 3D flip animation (`Transform` with perspective) →
shows the other side → `flipAction` dispatched → after 2 flips, `learnedAction`
dispatched

```dart
final chichewaWordCardSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['ChichewaWordCard']),
    'chichewa_word': S.string(description: 'The Chichewa word or phrase'),
    'english_translation': S.string(description: 'English equivalent'),
    'example_sentence_chichewa': S.string(
      description: 'Short example sentence using the word in Chichewa, max 8 words',
    ),
    'example_sentence_english': S.string(
      description: 'English translation of the example sentence',
    ),
    'emoji': S.string(description: 'Emoji that visually represents the word meaning'),
    'flipAction': A2uiSchemas.action(description: 'Fired each time card is flipped'),
  },
  required: ['component', 'chichewa_word', 'english_translation', 'emoji', 'flipAction'],
);
```

---

### 6. MathVisualBoard

**Purpose**: Visual maths for Standards 1–5. Shows a maths problem anchored in
real objects (emoji arrays). Student sees 3 mangoes + 4 mangoes = ? and counts
or selects the answer. Bridges the gap between concrete counting and abstract
arithmetic.

```dart
final mathVisualBoardSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['MathVisualBoard']),
    'emoji': S.string(description: 'Emoji object to use for visual counting'),
    'operand_a': S.integer(description: 'First number (shown as emoji array)'),
    'operator': S.string(enumValues: ['+', '-'], description: 'Operation to perform'),
    'operand_b': S.integer(description: 'Second number'),
    'answer_choices': S.array(
      items: S.integer(),
      description: 'Three integer choices, one being the correct answer',
    ),
    'answerAction': A2uiSchemas.action(description: 'Dispatched when student selects answer'),
  },
  required: ['component', 'emoji', 'operand_a', 'operator', 'operand_b', 'answer_choices', 'answerAction'],
);
```

**Notes for agent**:
- For `+`: show two `Wrap` groups of emoji with a `+` between them
- For `-`: show one group of emoji, then animate removing some when student views
- Enforce: operand_a ≤ 10, operand_b ≤ 10 in `fromJson`

---

### 7. StoryComprehension

**Purpose**: A short story (3–5 sentences) followed by a comprehension question.
The core of English and Chichewa reading lessons. The story uses locally relevant
names and settings (Chisomo, Blantyre, Lake Malawi, maize fields).

```dart
final storyComprehensionSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['StoryComprehension']),
    'story_title': S.string(description: 'Short story title, max 5 words'),
    'story_text': S.string(
      description: 'Story body, 3-5 sentences, simple vocabulary, Malawian names and settings',
    ),
    'question': S.string(description: 'Comprehension question about the story'),
    'options': S.array(
      items: S.string(),
      description: '3 answer options, all plausible from the story',
    ),
    'correct_index': S.integer(description: 'Index of the correct answer'),
    'answerAction': A2uiSchemas.action(description: 'Dispatched after answer selected'),
  },
  required: ['component', 'story_title', 'story_text', 'question', 'options', 'correct_index', 'answerAction'],
);
```

---

### 8. HintReveal

**Purpose**: A collapsed hint card. Student taps to reveal a hint when stuck.
Used after a wrong answer or when the AI detects struggle (2+ wrong answers on
same concept). Teaches students to use hints before giving up.

**Interaction**: Tap "Show hint" → `ExpansionTile`-style reveal animation →
`hintRevealAction` dispatched (so AI knows hint was needed)

```dart
final hintRevealSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['HintReveal']),
    'hint_text': S.string(description: 'The hint, 1-2 sentences, guides without giving the answer'),
    'hint_emoji': S.string(description: 'Emoji that hints at the concept visually'),
    'hintRevealAction': A2uiSchemas.action(description: 'Fired when student taps to reveal hint'),
  },
  required: ['component', 'hint_text', 'hint_emoji', 'hintRevealAction'],
);
```

---

## Complete Primary Catalog Builder

```dart
// lib/features/primary/presentation/genui/primary_catalog.dart

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
```

---

## Primary AI Tutor System Prompt Addendum

```
You are Yaza, a patient and warm AI tutor for Malawian primary school students
(Standards 1-8, ages 7-14). You teach English, Chichewa, Mathematics, Environmental
Science, and Social Studies according to the Malawian primary curriculum.

Rules:
- Always use locally relevant examples: Lake Malawi, maize, nsima, Lilongwe,
  Blantyre, Chisomo, Tadala, Mphatso as character names.
- For Chichewa subjects, surface ChichewaWordCard to introduce new vocabulary.
- For maths Standards 1-4, always use MathVisualBoard before abstract equations.
- After any 2 wrong answers on the same question, surface HintReveal automatically.
- Sequence: concept introduction (read-only card) → practice quiz → feedback
- Always acknowledge correct answers with positive text before the next question.
- Keep all question text under 20 words.
- For Standards 1-3: prefer SimpleQuiz and FillBlankCard (simpler interaction).
- For Standards 4-8: introduce WordMatchPair and StoryComprehension.
```

---

## Primary Session Flow by Study Mode

### primary_revise
```
Topic identified (from student message)
    └─► PictureQuiz OR StoryComprehension (assess prior knowledge)
        ├─► Correct → next topic
        └─► Wrong → ChichewaWordCard / FillBlankCard (reteach)
            └─► SimpleQuiz (re-assess)
                └─► HintReveal if wrong again
```

### primary_coach
```
Student expresses confusion
    └─► Read-only explanation (plain text from AI)
        └─► MathVisualBoard OR PictureQuiz (concrete grounding)
            └─► FillBlankCard (guided practice)
                └─► SimpleQuiz (independent practice)
```

### primary_explore
```
Student picks a topic freely
    └─► StoryComprehension (engage through narrative)
        └─► WordMatchPair (vocabulary from the story)
            └─► PictureQuiz (visual extension)
```
