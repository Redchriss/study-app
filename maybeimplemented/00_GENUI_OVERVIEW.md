# Yaza GenUI — Master Architecture Overview

## What GenUI Is (and Why Yaza Uses It)

GenUI is Flutter's official SDK (`genui: ^0.9.0`, published by `labs.flutter.dev`) for
building AI-driven interfaces where the LLM returns structured JSON that renders as
real native Flutter widgets — not plain text, not HTML, not generated Dart code.

The difference for Yaza students:
- **Without GenUI**: student asks a question → wall of text → student scrolls, loses focus
- **With GenUI**: student asks a question → AI surfaces an interactive quiz, a step-by-step
  solver, a visual flashcard, a reward badge — all rendered natively, all bidirectional

This is what makes Yaza feel fundamentally different from ChatGPT or any other AI chat tool.
The AI is not answering — it is *teaching through interactive UI*.

---

## Core GenUI Concepts the Agent Must Understand

### The A2UI Protocol

The AI communicates with Flutter using the A2UI v0.9 protocol. Instead of returning
prose, Gemini returns structured directives:

- `createSurface` — create a new UI surface (a widget instance)
- `updateComponents` — update an existing surface's data
- `updateDataModel` — update shared reactive state
- `deleteSurface` — remove a surface

The `A2uiTransportAdapter` parses raw SSE token chunks into these directives.

### The Catalog Pattern

Every level in Yaza has its own `Catalog`. A `Catalog` is the contract between the app
and the AI — it defines the *exact set of widgets* the AI is allowed to render.

```dart
Catalog buildSecondaryCatalog() {
  return BasicCatalogItems.asCatalog().copyWith(
    newItems: [
      flashCardItem,
      stepSolverItem,
      pastPaperQuestionItem,
      // etc.
    ],
  );
}
```

The AI cannot hallucinate widgets outside the catalog. This is a hard constraint.

### CatalogItem Structure (every item follows this exact pattern)

```dart
// 1. JSON Schema — tells Gemini what fields to generate
final myItemSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['MyItemName']),
    'someField': S.string(description: 'Clear description for Gemini'),
    'action': A2uiSchemas.action(description: 'What happens on tap'),
  },
  required: ['component', 'someField'],
);

// 2. Data class — parses the JSON Gemini returns
class _MyItemData {
  final String someField;
  _MyItemData({required this.someField});

  factory _MyItemData.fromJson(Map<String, Object?> json) {
    return _MyItemData(someField: json['someField'] as String);
  }
}

// 3. Widget — any StatefulWidget
class _MyItemWidget extends StatefulWidget { ... }

// 4. CatalogItem — registers into the catalog
final myItemItem = CatalogItem(
  name: 'MyItemName',         // MUST match enumValues above
  dataSchema: myItemSchema,
  widgetBuilder: (itemContext) {
    final data = _MyItemData.fromJson(itemContext.data as Map<String, Object?>);
    return _MyItemWidget(data: data, onAction: () async {
      itemContext.dispatchEvent(UserActionEvent(
        name: data.actionName,
        sourceComponentId: itemContext.id,
        context: {},
      ));
    });
  },
);
```

### The Conversation + SurfaceController Loop

```
User types → conversation.sendRequest()
          → A2uiTransportAdapter.onSend fires
          → POST to /ai/stream/ with clientInstructions (catalog system prompt)
          → Gemini streams A2UI JSON tokens
          → A2uiTransportAdapter.addChunk() parses each chunk
          → SurfaceController updates DataModel
          → Surface widgets rebuild
          → User taps/interacts → UserActionEvent dispatched
          → SurfaceController emits onSubmit
          → Conversation loops back to Gemini with interaction context
```

---

## Yaza Level Architecture

Yaza has four separate GenUI contexts. Each has its own catalog, its own visual
theme, and its own study modes:

| Context       | File prefix         | Study Modes                  | Target Age     |
|---------------|---------------------|------------------------------|----------------|
| Kids Mode     | `kids_`             | `kids_lesson`                | 4–9            |
| Primary       | `primary_`          | `coach`, `revise`, `explore` | 7–14 (Std 1–8) |
| Secondary     | `secondary_`        | `coach`, `revise`, `plan`    | 14–18 (F1–F4)  |
| Tertiary      | `tertiary_`         | `coach`, `research`, `plan`  | 18+            |

---

## File Structure the Agent Must Create

```
lib/features/
├── kids_mode/presentation/genui/
│   ├── kids_catalog.dart
│   ├── emoji_story_card.dart          (existing)
│   ├── interactive_match.dart         (existing)
│   ├── tap_and_learn.dart             (NEW)
│   ├── word_bubble.dart               (NEW)
│   ├── counting_board.dart            (NEW)
│   ├── story_choice_card.dart         (NEW)
│   ├── reward_burst.dart              (NEW)
│   ├── daily_streak_card.dart         (NEW)
│   └── star_collector.dart            (NEW)
│
├── primary/presentation/genui/
│   ├── primary_catalog.dart
│   ├── fill_blank_card.dart
│   ├── word_match_pair.dart
│   ├── picture_quiz.dart
│   ├── simple_quiz.dart
│   ├── story_comprehension.dart
│   ├── chichewa_word_card.dart
│   ├── math_visual_board.dart
│   ├── primary_summary_card.dart
│   └── hint_reveal.dart
│
├── secondary/presentation/genui/
│   ├── secondary_catalog.dart
│   ├── flash_card.dart
│   ├── step_solver.dart
│   ├── past_paper_question.dart
│   ├── definition_card.dart
│   ├── confidence_slider.dart
│   ├── essay_outline.dart
│   ├── formula_card.dart
│   ├── progress_ring.dart
│   ├── motivation_card.dart
│   └── hint_reveal.dart
│
└── tertiary/presentation/genui/
    ├── tertiary_catalog.dart
    ├── concept_map.dart
    ├── argument_builder.dart
    ├── code_snippet_card.dart
    ├── research_summary.dart
    ├── formula_card.dart
    ├── source_citation.dart
    ├── debate_card.dart
    └── progress_ring.dart
```

---

## Critical Implementation Rules

1. **No file > 250 lines.** Split widget + schema + data class if needed.
2. **Component name in schema MUST exactly match CatalogItem.name.** Case-sensitive.
3. **All interactive items use `A2uiSchemas.action()`.** Never raw strings for actions.
4. **Material 3 theming only.** Use `Theme.of(context).colorScheme.*` — no hardcoded
   hex colors except in Kids Mode which uses `KidsVisualTheme`.
5. **Each catalog stays under ~8 items.** The system prompt per catalog is 3,000–5,000
   tokens. Keep catalogs focused to avoid context bloat with `gemini-2.5-flash-lite`.
6. **Every widget must have an animated entrance.** Use `AnimatedOpacity` +
   `SlideTransition` at minimum. Kids Mode needs richer animations (`ScaleTransition`,
   particle bursts).
7. **Read-only widgets return no action.** Only interactive items dispatch `UserActionEvent`.
8. **Error handling is mandatory.** Every `fromJson` must have null-safe parsing with
   fallback values. The AI can occasionally hallucinate missing fields.

---

## Token Budget Strategy

`gemini-2.5-flash-lite` has a tighter context window than full Gemini models.

| Level     | Max catalog items | Why                                          |
|-----------|-------------------|----------------------------------------------|
| Kids      | 6                 | Simpler schemas, lower token cost per item   |
| Primary   | 8                 | Moderate complexity                          |
| Secondary | 8                 | Richer schemas (essay, step solver)          |
| Tertiary  | 7                 | Most complex schemas (concept map, debate)   |

Use `systemPromptFragments` if a catalog starts to feel heavy — pass only the
widgets relevant to the current study mode, not the full catalog.

---

## The Aha Moment Strategy

The goal is not individual widget quality. The goal is *sequences* that feel like
intelligent tutoring:

**Example sequence — Form 3 student, quadratic equations:**
1. Student: "I don't understand quadratic equations"
2. AI surfaces `DefinitionCard` (what it is)
3. AI surfaces `StepSolver` (worked example, step by step)
4. AI surfaces `QuizDisplay` (one practice question)
5. Student answers wrong → AI surfaces `MotivationCard` + `HintReveal`
6. Student answers correctly → AI surfaces `ProgressRing` update + encouraging text
7. AI surfaces `ConfidenceSlider` ("how confident are you now?")
8. If confidence < 3 → AI surfaces another `StepSolver` with different example
9. If confidence ≥ 4 → AI surfaces `FlashCard` for spaced repetition later

That 9-step sequence, driven entirely by AI reading student signals, is what no
text-based tool can replicate. That is the Yaza aha moment.
