# Yaza GenUI — Agent Implementation Guide

This document is specifically for the AI coding agent executing the GenUI
implementation. Read this before touching any catalog file.

---

## Build Order (strict — do not skip steps)

```
Phase 1: Kids Mode (simplest schemas, validates the pattern)
  1. kids_catalog.dart — scaffold with existing items only
  2. tap_and_learn.dart
  3. counting_board.dart
  4. reward_burst.dart
  5. word_bubble.dart
  6. story_choice_card.dart
  7. daily_streak_card.dart
  8. kids_catalog.dart — add all new items, test build

Phase 2: Secondary (highest priority for Yaza's core users)
  1. secondary_catalog.dart — scaffold
  2. flash_card.dart
  3. step_solver.dart
  4. confidence_slider.dart
  5. definition_card.dart
  6. formula_card.dart
  7. past_paper_question.dart
  8. essay_outline.dart
  9. motivation_card.dart
  10. secondary_catalog.dart — add all, test build

Phase 3: Primary
  1. primary_catalog.dart — scaffold
  2. simple_quiz.dart
  3. fill_blank_card.dart
  4. math_visual_board.dart
  5. chichewa_word_card.dart
  6. word_match_pair.dart
  7. picture_quiz.dart
  8. story_comprehension.dart
  9. hint_reveal.dart
  10. primary_catalog.dart — add all, test build

Phase 4: Tertiary (most complex schemas)
  1. tertiary_catalog.dart — scaffold
  2. progress_ring.dart
  3. code_snippet_card.dart
  4. research_summary.dart
  5. argument_builder.dart
  6. debate_card.dart
  7. concept_map.dart  ← do this last, most complex CustomPainter
  8. tertiary_catalog.dart — add all, test build
```

---

## Template: Minimal CatalogItem File

Every new catalog item file follows this exact structure:

```dart
// lib/features/{level}/presentation/genui/{widget_name}.dart
// Max 250 lines. Split if needed.

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

// ─── 1. Schema ────────────────────────────────────────────────────────────────

final _widgetNameSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['WidgetName']),
    // ... fields
  },
  required: ['component', /* required fields */],
);

// ─── 2. Data class ────────────────────────────────────────────────────────────

class _WidgetNameData {
  final String field1;
  // ...

  _WidgetNameData({required this.field1});

  factory _WidgetNameData.fromJson(Map<String, Object?> json) {
    return _WidgetNameData(
      // Always null-safe with fallbacks:
      field1: (json['field1'] as String?) ?? 'Default value',
    );
  }
}

// ─── 3. Widget ────────────────────────────────────────────────────────────────

class _WidgetNameWidget extends StatefulWidget {
  const _WidgetNameWidget({required this.data, required this.onAction});
  final _WidgetNameData data;
  final VoidCallback onAction;

  @override
  State<_WidgetNameWidget> createState() => _WidgetNameWidgetState();
}

class _WidgetNameWidgetState extends State<_WidgetNameWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    // Actual widget UI here
    return Container();
  }
}

// ─── 4. CatalogItem ───────────────────────────────────────────────────────────

final widgetNameItem = CatalogItem(
  name: 'WidgetName',         // MUST match enumValues in schema exactly
  dataSchema: _widgetNameSchema,
  widgetBuilder: (itemContext) {
    final data = _WidgetNameData.fromJson(
      itemContext.data as Map<String, Object?>,
    );
    return _WidgetNameWidget(
      data: data,
      onAction: () async {
        itemContext.dispatchEvent(
          UserActionEvent(
            name: data.actionName,
            sourceComponentId: itemContext.id,
            context: {'field': data.field1},
          ),
        );
      },
    );
  },
);
```

---

## Critical Rules (repeat from overview — follow without exception)

### Rule 1: fromJson must never throw

```dart
// WRONG — will crash if Gemini omits or misspells the field
field1: json['field1'] as String,

// CORRECT — always null-safe
field1: (json['field1'] as String?) ?? 'Default',
correctIndex: (json['correct_index'] as int?) ?? 0,
count: ((json['count'] as int?) ?? 5).clamp(1, 10),
```

### Rule 2: Every widget has an animated entrance

No widget appears without animation. The template above shows the standard
`FadeTransition` + `SlideTransition` entrance. All items must implement this.
Kids Mode items use `ScaleTransition` with `ElasticOutCurve` instead.

### Rule 3: Actions include context

When dispatching `UserActionEvent`, always include relevant context:

```dart
// WRONG
itemContext.dispatchEvent(UserActionEvent(
  name: 'answerSelected',
  sourceComponentId: itemContext.id,
  context: {},  // ← empty context tells the AI nothing
));

// CORRECT
itemContext.dispatchEvent(UserActionEvent(
  name: 'answerSelected',
  sourceComponentId: itemContext.id,
  context: {
    'selectedIndex': selectedIndex,
    'isCorrect': isCorrect,
    'questionText': data.question,
  },
));
```

### Rule 4: Material 3 only (except Kids)

```dart
// WRONG
color: Color(0xFF4CAF50),
backgroundColor: Colors.blue,

// CORRECT
color: Theme.of(context).colorScheme.primary,
backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
```

### Rule 5: Max 250 lines per file

If a widget is getting complex (e.g. `ConceptMap` with `CustomPainter`), split:
- `concept_map.dart` — schema + data class + CatalogItem
- `concept_map_painter.dart` — the CustomPainter class

---

## Testing Each Item After Build

After building each catalog item, verify:

```
□ flutter analyze returns no errors for the new file
□ The catalog builder compiles with the new item added
□ fromJson handles missing optional fields without throwing
□ Animated entrance plays on first render
□ Action dispatches with correct context map
□ Widget respects Material 3 theme colours
□ File is under 250 lines
```

---

## Connecting Catalogs to Study Modes

In `AiTutorStreamService`, the catalog is selected based on `studyMode`:

```dart
Catalog _catalogForMode(String studyMode) {
  return switch (studyMode) {
    'kids_lesson'         => buildKidsCatalog(),
    'primary_coach'       => buildPrimaryCatalog(),
    'primary_revise'      => buildPrimaryCatalog(),
    'primary_explore'     => buildPrimaryCatalog(),
    'secondary_coach'     => buildSecondaryCatalog(),
    'secondary_revise'    => buildSecondaryCatalog(),
    'secondary_plan'      => buildSecondaryCatalog(),
    'tertiary_coach'      => buildTertiaryCatalog(),
    'tertiary_research'   => buildTertiaryCatalog(),
    'tertiary_plan'       => buildTertiaryCatalog(),
    _                     => buildSecondaryCatalog(),   // safe default
  };
}
```

The selected catalog is passed to `PromptBuilder.chat(catalog: catalog)` which
generates the `clientInstructions` system prompt fragment, which is appended
to the payload sent to `/ai/stream/`.

---

## Known GenUI Alpha Gotchas (as of v0.8.0–0.9.0)

1. **API will change.** The package is explicitly alpha. When upgrading, check
   the changelog for breaking changes in `Conversation`, `SurfaceController`,
   and `CatalogItem` APIs.

2. **PromptBuilder token cost is real.** Each catalog item adds ~200–400 tokens
   to the system prompt. With 8 items you're at 1,600–3,200 tokens before the
   user says anything. Keep catalogs lean.

3. **Gemini occasionally ignores the catalog.** If Gemini returns plain text
   instead of A2UI JSON, the `A2uiTransportAdapter` falls back gracefully —
   it emits a `TextEvent` which should be rendered as a chat bubble. Always
   implement a fallback chat bubble renderer alongside Surface widgets.

4. **`SurfaceController` does not persist across app restarts.** All GenUI
   state is in-memory. If the user backgrounds the app and returns, the
   conversation history must be managed separately and replayed.

5. **Multiple surfaces stack.** Each AI turn can `createSurface` a new widget.
   After 5–6 turns, the screen fills up. Implement a scroll view in the chat
   container and consider calling `deleteSurface` on older read-only cards.

---

## Dependencies to Add to pubspec.yaml

```yaml
dependencies:
  genui: ^0.9.0
  json_schema_builder: ^0.1.3
  # These are already dependencies of genui but pin explicitly:
  audioplayers: ^6.6.0    # for Kids Mode sounds
  flutter_markdown_plus: ^1.0.5
```

For Tertiary `CodeSnippetCard`:
```yaml
  flutter_highlight: ^0.7.0  # syntax highlighting
  google_fonts: ^6.2.1       # JetBrains Mono for code display
```
