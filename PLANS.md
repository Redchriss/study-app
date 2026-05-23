# PLANS.md — Yaza Flutter App Roadmap

## GenUI Integration Vision

Adopt Flutter's `genui` package (v0.9.0+) to replace static/content-driven UIs with AI-generated interactive surfaces. Instead of walls of text, the AI composes real Flutter widgets at runtime within a defined widget catalog.

---

## Kids Mode — AI-Generated Lessons

**Current:** Static `chunks_json` lessons (emoji + text format). Content is pre-authored. BUG-012 (silent failure on load) exists.

**Target:** Remove static lessons entirely. Kid picks a topic → AI generates a unique interactive lesson every time.

**GenUI Surfaces:**
- **Lesson Cards** — AI composes tap-to-reveal cards with emoji, short text, and sound cues
- **Minigames** — AI generates simple matching/quiz widgets inline
- **Progress Badges** — earned interactively as the kid completes AI-generated steps
- **Companion Dialog** — Sprout/Flame characters rendered as GenUI widgets with dynamic speech

**Benefits:**
- Infinite unique content — no authoring bottleneck
- BUG-012 becomes irrelevant (no pre-loaded lesson to fail on)
- Adapts difficulty per kid based on interaction history

---

## AI Tutor — Mode-Specific Interfaces

**Current:** Single chat UI for all 5 modes. Modes only change placeholder text and prompt prefix. BUG-011 (back exits app) is a separate concern.

**Target:** Each mode gets its own GenUI surface with mode-specific widgets, while falling back to chat for open-ended Q&A.

### Coach
- Chat surface with rich widget responses (not just text)
- AI embeds diagrams, formulas, step-by-step cards inline

### Quiz Me
- Question cards — tap to reveal answer
- Score counter and progress dots
- Multiple choice / fill-in / true-false widgets
- AI generates fresh questions each session

### Revise
- Bullet summary cards with expandable sections
- Key points rendered as compact widgets
- AI compresses any topic on demand

### Memorize
- Flip cards (spaced-repetition style)
- Mnemonic display cards
- AI generates memory hooks per topic

### Plan
- Timeline/checklist layout
- Progress bars
- AI builds adaptive study schedules

**Backend:** No changes needed. The backend already returns text. GenUI replaces the Flutter rendering layer — instead of displaying text in a chat bubble, the app parses A2UI JSONL from the same response stream and renders interactive widgets.

---

## Architecture Approach

```
lib/features/ai_tutor/
└── presentation/
    ├── surfaces/           # One GenUI Surface per mode
    │   ├── coach_surface.dart
    │   ├── quiz_surface.dart
    │   ├── revise_surface.dart
    │   ├── memorize_surface.dart
    │   └── plan_surface.dart
    ├── catalog/            # Custom widgets the AI can use
    │   ├── tutor_catalog.dart       # Combined catalog builder
    │   ├── quiz_card.dart
    │   ├── flip_card.dart
    │   ├── summary_card.dart
    │   └── plan_timeline.dart
    └── screens/
        └── ai_tutor_screen.dart  # Switches body by mode → GenUI surface or chat

lib/features/kids_mode/
└── presentation/
    ├── surfaces/
    │   ├── lesson_surface.dart
    │   └── minigame_surface.dart
    ├── catalog/
    │   ├── kids_catalog.dart
    │   ├── lesson_card.dart
    │   ├── emoji_reveal.dart
    │   └── badge_widget.dart
    └── widgets/
        └── ...
```

**Key principle:** The existing `AiTutorNotifier` and backend remain untouched. GenUI only changes how responses are **rendered** on the client.

---

## Risks & Mitigations

| Risk | Mitigation |
|---|---|
| GenUI still experimental (alpha) | Start with one mode (Quiz Me) as proof of concept. Keep chat fallback. |
| Token costs increase | Cache common responses. Use PromptBuilder discipline. |
| AI generates broken UI | Widget catalog is constrained — AI only composes from approved items. |
| Latency | Use GenUI streaming (supports progressive rendering). |
| Kids content safety | Catalog limits widget types. System prompt enforces age-appropriate rules. |

---

## Next Steps

1. Add `genui` and `genai_primitives` to `pubspec.yaml`
2. Build a `TutorCatalog` with 1–2 custom widgets (e.g., `QuizCard`)
3. Wire GenUI surface into **Quiz Me** mode as POC
4. If stable, expand to remaining modes and Kids Mode
5. Run `flutter analyze` and test on device after each step
