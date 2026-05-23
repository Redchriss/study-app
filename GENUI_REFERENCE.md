# GenUI Integration Reference — Yaza Study App

Copy-paste this to another AI for brainstorming catalog items and GenUI features.

---

## Stack

- **Frontend:** Flutter with `genui: ^0.9.0` (pub.dev/packages/genui)
- **Backend:** Django + Gemini (`gemini-2.5-flash-lite`) streaming over SSE
- **State:** Riverpod / StateNotifier + go_router
- **GraphQL:** graphql_flutter (for auth, profiles, etc. — NOT for GenUI streaming)

## How GenUI Works (A2UI Protocol)

GenUI = "Generated UI". The AI model returns structured JSON instead of plain text. The Flutter app renders that JSON as interactive widgets.

Flow:

1. User types a message
2. Frontend builds a `PromptBuilder.chat(catalog: catalog)` which generates system instructions listing all available widgets and their JSON schemas
3. Instructions are appended to the payload and sent to the backend SSE endpoint (`/ai/stream/`)
4. Gemini streams back tokens that include special `Surface` directives in A2UI format
5. The `A2uiTransportAdapter` parses these tokens and dispatches events to the `Conversation`
6. `Conversation` surfaces (adds/removes) widget instances via `SurfaceController`
7. The `SurfaceController.contextFor(surfaceId)` is used to render widgets in the Flutter widget tree
8. User interactions (button taps, etc.) dispatch `UserActionEvent` back to the Conversation, which feeds back to the AI

Key classes:
- `Catalog` — registry of allowed widgets
- `CatalogItem` — single widget definition (name + JSON schema + builder)
- `SurfaceController` — manages rendered widget instances
- `Conversation` — orchestrates the back-and-forth
- `A2uiTransportAdapter` — bridges SSE streaming to Conversation events

## Current Catalogs

### AI Tutor (`ai_tutor/presentation/genui/tutor_catalog.dart`)

| Item | Schema | Description |
|------|--------|-------------|
| **QuizDisplay** | component, question (string), options (string[]), answerAction (action) | Multiple choice quiz. User taps an option → dispatches answerAction with selectedIndex |
| **SummaryCard** | component, title (string), points ({heading, details}[]) | Key takeaways card. Read-only, no user action |
| **PlanTimeline** | component, title (string), steps ({timeframe, task, duration?}[]) | Visual study plan with connected steps. Read-only, no user action |

### Kids Mode (`kids_mode/presentation/genui/kids_catalog.dart`)

| Item | Schema | Description |
|------|--------|-------------|
| **EmojiStoryCard** | component, emoji (string), text (string) | Big emoji + short sentence for early readers. Animated entrance. Read-only |
| **InteractiveMatch** | component, question, options ({emoji, label}[]), correctIndex, completeAction (action) | Emoji picker game. Child taps correct emoji → dispatches completeAction. Wrong answer shakes + resets |

## How to Create a New Catalog Item

Every item must follow this exact pattern:

```dart
// 1. JSON Schema (declares what fields Gemini should generate)
final myItemSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['MyItemName']),
    'title': S.string(description: 'What this is'),
    'action': A2uiSchemas.action(
      description: 'What happens on user interaction',
    ),
  },
  required: ['component', 'title'],
);

// 2. Data class (parses JSON from Gemini)
class _MyItemData {
  final String title;
  final String actionName;
  final JsonMap actionContext;

  _MyItemData({required this.title, required this.actionName, required this.actionContext});

  factory _MyItemData.fromJson(Map<String, Object?> json) {
    final action = json['action'] as JsonMap;
    final event = action['event'] as JsonMap;
    return _MyItemData(
      title: json['title'] as String,
      actionName: event['name'] as String,
      actionContext: event['context'] as JsonMap,
    );
  }
}

// 3. Widget (any Flutter widget)
class _MyItemWidget extends StatefulWidget { ... }

// 4. CatalogItem (registers into catalog)
final myItemItem = CatalogItem(
  name: 'MyItemName',  // MUST match enum in schema
  dataSchema: myItemSchema,
  widgetBuilder: (itemContext) {
    final json = itemContext.data as Map<String, Object?>;
    final data = _MyItemData.fromJson(json);
    return _MyItemWidget(
      data: data,
      onAction: () async {
        itemContext.dispatchEvent(
          UserActionEvent(
            name: data.actionName,
            sourceComponentId: itemContext.id,
            context: resolvedContext,
          ),
        );
      },
    );
  },
);
```

Then add it to the catalog:
```dart
Catalog buildTutorCatalog() {
  return BasicCatalogItems.asCatalog().copyWith(
    newItems: [quizDisplayItem, summaryCardItem, planTimelineItem, myItemItem],
  );
}
```

## Constraints

1. **Bounded catalog**: AI can ONLY render widgets in the catalog. No arbitrary UI.
2. **Component name in schema**: Every schema must include `'component': S.string(enumValues: ['ExactName'])` matching the `CatalogItem.name`.
3. **Actions use `A2uiSchemas.action()`**: For interactive items, uses `{event: {name, context}}` format.
4. **No file > 250 lines**: Split if needed.
5. **Material 3 theming**: Use `Theme.of(context).colorScheme.*` not hardcoded colors (except Kids Mode which uses `KidsVisualTheme`).
6. **Two separate catalogs**: AI Tutor and Kids Mode have separate catalogs because they have different visual languages and use cases.

## Backend Integration

- **Endpoint**: `/ai/stream/` SSE
- **Streaming service**: `AiTutorStreamService` (Flutter) sends POST with `{text, sessionId, studyMode, clientInstructions, token}`
- **Client instructions**: Generated by `PromptBuilder.chat(catalog: catalog).systemPromptJoined()` — this tells Gemini what widgets are available and their schemas
- **Gemini model**: `gemini-2.5-flash-lite`
- **Study modes**: `coach`, `revise`, `plan` (tutor); `kids_lesson` (kids mode)

## Where Things Live

```
lib/features/ai_tutor/presentation/genui/
├── tutor_catalog.dart          # Catalog builder (3 items)
├── quiz_display.dart           # QuizDisplay item
├── summary_card.dart           # SummaryCard item
└── plan_timeline.dart          # PlanTimeline item

lib/features/ai_tutor/presentation/screens/
├── ai_tutor_manager.dart       # Conversation + SurfaceController setup
├── ai_tutor_stream_service.dart # SSE streaming client
└── ai_tutor_chat_widgets.dart   # Renders Surface widgets inline

lib/features/kids_mode/presentation/genui/
├── kids_catalog.dart           # Catalog builder (2 items)
├── emoji_story_card.dart       # EmojiStoryCard item
└── interactive_match.dart      # InteractiveMatch item

lib/features/kids_mode/presentation/widgets/
├── kids_home_screen_manager.dart  # Conversation + SurfaceController setup
└── kids_lesson_view_section.dart  # Renders Surface widgets for lessons
```

## Brainstorming Prompts

Give the AI these prompts for ideas:

### For AI Tutor
- "Suggest 5-8 new GenUI catalog items for an AI study tutor. Consider: flashcards, progress bars, concept maps, practice problem generators, essay outline builders, spaced-revision schedule cards, subject-specific tools (math equation solver UI, code snippet runner, diagram annotator). For each: name, purpose, JSON schema, and whether it's read-only or interactive."
- "What interactive widgets would make the AI Tutor feel like a real tutoring session vs. a chat? Think: whiteboard snippets, confidence sliders, 'explain like I'm 5' toggles, step reveal animations."
- "What study-mode-specific catalogs could exist? Coach mode, Revise mode, Plan mode — should each have dedicated widgets?"

### For Kids Mode
- "Suggest 8-12 new GenUI catalog items for a kids' learning app (ages 6-12). Consider: quiz variations (true/false, drag-to-order, fill-in-blank), reward animations, progress badges, mini-games, read-along cards, drawing prompts, memory match grids, sorting activities, fill-in-the-blank, word search, coloring pages, storytelling prompts with choices."
- "What makes Kids Mode feel magical? Think: confetti bursts, character reactions, level-up animations, daily streak visualizers, collectible card reveals."
- "How can we blend education + fun: phonics matching, math bingo, geography pin-drop, science experiment step cards?"

### Cross-cutting
- "What infrastructure improvements would make catalog items easier to build? Shared utilities, animation helpers, testing tools?"
- "How should two catalogs interact? Could Kids Mode have sub-catalogs per subject (math vs. reading)?"
- "What A2UI patterns are missing? Multi-step wizards, conditional rendering, pagination, infinite scroll?"
