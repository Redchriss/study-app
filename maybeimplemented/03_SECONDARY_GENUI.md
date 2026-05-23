# Yaza Secondary Level — GenUI Catalog Specification

## Context

Secondary level targets Form 1–4 students aged 14–18, with a heavy focus on
MSCE (Malawi School Certificate of Education) examination preparation. Subjects
include Mathematics, English, Biology, Chemistry, Physics, History, Geography,
Agriculture, and Chichewa.

**Study modes**: `secondary_coach`, `secondary_revise`, `secondary_plan`
**Gemini model**: `gemini-2.5-flash-lite`
**Catalog file**: `lib/features/secondary/presentation/genui/secondary_catalog.dart`
**Visual theme**: Material 3 — `Theme.of(context).colorScheme.*`
**Tone**: Focused, respectful, exam-aware. The AI speaks like a knowledgeable
senior student who wants you to pass.

---

## Design Principles for Secondary Level

- **Exam-first mindset.** Every widget is implicitly linked to MSCE preparation.
  The AI should regularly frame learning in terms of "this is what the examiner
  expects."
- **Spaced repetition signals.** The `ConfidenceSlider` and `FlashCard` together
  create a lightweight spaced repetition loop. This is the engine of effective
  secondary revision.
- **Step-by-step beats explanation.** For Mathematics, Chemistry, and Physics,
  a `StepSolver` that walks through a worked example is worth more than a
  paragraph of explanation. Always prefer structured steps.
- **Past paper is sacred.** The `PastPaperQuestion` widget should feel like the
  actual exam. Format, marks allocation, and AI-graded feedback all contribute.
- **Motivation without condescension.** Form 4 students under exam pressure are
  stressed. `MotivationCard` content must be respectful and brief — not cheerful
  kindergarten praise.

---

## Catalog Items

### 1. FlashCard (PRIORITY — build first)

**Purpose**: Front/back flip card for spaced repetition. The AI generates both
sides. Student flips, rates their recall, and the AI uses the rating to decide
whether to resurface the card later in the session.

**Interaction**: Tap card → 3D flip animation → student sees answer → taps one
of three recall buttons: "Got it ✓", "Almost", "Missed ✗" → `recallAction`
dispatched with rating.

**Visual**: Card fills most of the width. Front: question/term in 18sp bold, subtle
icon. Back: answer/definition in 16sp, with optional example. Recall buttons at
bottom in a `Row` with semantic colours (green / amber / red).

```dart
final flashCardSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['FlashCard']),
    'front_text': S.string(description: 'Term, question, or concept to recall'),
    'back_text': S.string(description: 'Definition, answer, or explanation'),
    'subject_tag': S.string(
      description: 'Subject abbreviation e.g. BIO, CHE, PHY, MATH, HIS, GEO',
    ),
    'example': S.string(description: 'Optional worked example or usage sentence'),
    'recallAction': A2uiSchemas.action(
      description: 'Dispatched after student rates recall: context includes rating (got_it, almost, missed)',
    ),
  },
  required: ['component', 'front_text', 'back_text', 'recallAction'],
);
```

**Notes for agent**:
- Use `AnimationController` with `TweenSequence` for the 3D flip — `Transform`
  with `Matrix4.rotationY`
- Subject tag renders as a small coloured chip in top-right corner
- After `missed` rating: AI should resurface the same FlashCard later

---

### 2. StepSolver (PRIORITY — build second)

**Purpose**: A mathematics or science problem shown with steps revealed one at a
time. Student sees step N, predicts what step N+1 is (mentally), then taps
"Show next step" to reveal. This active prediction makes learning stick.

**Interaction**: Each "Show next step" tap reveals the next step with a slide-in
animation. After final step, `solverCompleteAction` dispatched. Student can tap
"Explain this step" at any step to trigger AI to explain in plain text.

**Visual**: Problem statement at top in a coloured card. Steps listed below,
each in its own bordered container. Unrevealed steps show as "Step N — [tap to reveal]"
greyed out. Revealed steps show full content.

```dart
final stepSolverSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['StepSolver']),
    'problem_statement': S.string(description: 'The full question or problem to solve'),
    'subject': S.string(
      enumValues: ['Mathematics', 'Physics', 'Chemistry', 'Biology', 'Other'],
    ),
    'steps': S.array(
      items: S.object(properties: {
        'step_number': S.integer(description: 'Step number starting from 1'),
        'action': S.string(description: 'What is done in this step, e.g. "Expand the brackets"'),
        'working': S.string(description: 'The actual mathematical or scientific working'),
        'explanation': S.string(description: 'Plain English explanation of why this step is taken'),
      }),
      description: 'Between 3 and 7 steps',
    ),
    'final_answer': S.string(description: 'The final answer clearly stated'),
    'solverCompleteAction': A2uiSchemas.action(
      description: 'Dispatched when student reaches the final step',
    ),
  },
  required: ['component', 'problem_statement', 'steps', 'final_answer', 'solverCompleteAction'],
);
```

**Notes for agent**:
- Steps should animate in using `SlideTransition` from bottom
- "Explain this step" button on each revealed step dispatches a `UserActionEvent`
  with `{stepNumber}` — AI responds with plain text explanation in chat
- For Chemistry: working field may contain chemical equations — render in
  `SelectableText` with monospace font

---

### 3. PastPaperQuestion

**Purpose**: A question formatted exactly like an MSCE past paper. Shows the
question, marks allocation, and a text field for the student's answer. When
submitted, AI grades the answer and surfaces feedback inline.

**Interaction**: Student types answer → taps "Submit" → surface updates to show
AI-graded feedback with marks awarded, model answer, and what was missing.

**Visual**: Header shows subject + year + marks. Question in serif-style font to
mimic exam paper feel. Text input field with character count. Submit button.
After submission: green/amber/red band at top showing marks awarded.

```dart
final pastPaperQuestionSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['PastPaperQuestion']),
    'subject': S.string(description: 'Subject name e.g. Biology, Mathematics'),
    'year': S.integer(description: 'MSCE paper year e.g. 2019'),
    'question_number': S.string(description: 'Question reference e.g. "Question 3(b)"'),
    'question_text': S.string(description: 'Full question text as it appears in the paper'),
    'total_marks': S.integer(description: 'Marks allocated to this question'),
    'marking_guide': S.string(
      description: 'Internal marking guide — NOT shown to student, used by AI to grade',
    ),
    'submitAction': A2uiSchemas.action(
      description: 'Fired when student submits answer, context includes studentAnswer string',
    ),
  },
  required: ['component', 'subject', 'question_text', 'total_marks', 'marking_guide', 'submitAction'],
);
```

**Notes for agent**:
- `marking_guide` must NOT be rendered in the widget — it is for AI reference only
  (passed back in `UserActionEvent` context)
- After grading: update the surface's `DataModel` to show feedback state
- Marks awarded render as "X / Y marks" in a banner with semantic colour

---

### 4. DefinitionCard

**Purpose**: Term + definition + example sentence. Compact. Read-only. Used to
introduce vocabulary in Biology (organelles, processes), Geography (terms),
History (events, people), and Chemistry (elements, reactions).

```dart
final definitionCardSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['DefinitionCard']),
    'term': S.string(description: 'The word or concept being defined'),
    'subject_tag': S.string(description: 'Subject abbreviation'),
    'definition': S.string(description: 'Clear definition, max 2 sentences'),
    'example': S.string(description: 'Real-world or exam-relevant example, max 1 sentence'),
    'memory_hook': S.string(
      description: 'Optional mnemonic or memory trick to help recall this term',
    ),
  },
  required: ['component', 'term', 'definition', 'example'],
);
```

---

### 5. ConfidenceSlider

**Purpose**: After any quiz or practice, the AI surfaces this to measure how
confident the student feels about the concept just covered. The AI uses this
rating to decide what to surface next — more practice or move forward.

**Interaction**: Student drags slider from 1–5 → `confidenceAction` dispatched
with `{rating, topic}` → AI decides: rating ≤ 2 = resurface StepSolver with
different example; rating 3 = offer more practice; rating ≥ 4 = move forward.

**Visual**: Horizontal slider with emoji anchors at each end (😕 at 1, 😊 at 5).
Current value shown in large text centre. Brief label describing each level
appears below the slider as it moves (1: "Not sure at all", 3: "Getting there",
5: "I've got this!").

```dart
final confidenceSliderSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['ConfidenceSlider']),
    'topic': S.string(description: 'The topic just covered, used in context of action'),
    'question': S.string(
      description: 'Prompt shown above slider e.g. "How confident do you feel about photosynthesis?"',
    ),
    'confidenceAction': A2uiSchemas.action(
      description: 'Dispatched when student submits rating, context includes rating (1-5) and topic',
    ),
  },
  required: ['component', 'topic', 'question', 'confidenceAction'],
);
```

---

### 6. EssayOutline

**Purpose**: A structured hierarchical card for essay-based subjects (History,
Geography, English Literature, Chichewa). Shows thesis → main points → supporting
evidence. Read-only but sections are collapsible. Helps students understand essay
structure before writing.

```dart
final essayOutlineSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['EssayOutline']),
    'essay_question': S.string(description: 'The essay question this outline addresses'),
    'thesis': S.string(description: 'The central argument or thesis statement'),
    'points': S.array(
      items: S.object(properties: {
        'heading': S.string(description: 'Main point heading'),
        'evidence': S.string(description: 'Supporting evidence or example'),
        'link_back': S.string(description: 'How this point links back to the thesis'),
      }),
      description: 'Between 2 and 4 main points',
    ),
    'conclusion_note': S.string(description: 'What the conclusion should address'),
  },
  required: ['component', 'essay_question', 'thesis', 'points'],
);
```

---

### 7. FormulaCard

**Purpose**: A physics or chemistry formula displayed prominently with variable
definitions and a worked example. Makes formulas memorable and connected to their
meaning — not just symbols on a page.

```dart
final formulaCardSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['FormulaCard']),
    'formula_name': S.string(description: 'Name of the formula or law'),
    'formula': S.string(description: 'The formula itself in plain text e.g. "F = ma"'),
    'variables': S.array(
      items: S.object(properties: {
        'symbol': S.string(description: 'Variable symbol'),
        'meaning': S.string(description: 'What the variable represents'),
        'unit': S.string(description: 'SI unit e.g. kg, m/s², N'),
      }),
    ),
    'worked_example': S.string(
      description: 'One concrete worked example using realistic values',
    ),
    'msce_tip': S.string(
      description: 'Common MSCE exam mistake to avoid when using this formula',
    ),
  },
  required: ['component', 'formula_name', 'formula', 'variables', 'worked_example'],
);
```

**Notes for agent**:
- Formula renders in a monospace font at 24sp, inside a distinct coloured box
- MSCE tip renders with a ⚠️ icon prefix

---

### 8. MotivationCard

**Purpose**: A short, respectful encouragement card. The AI surfaces this when
it detects struggle signals: 3+ wrong answers on the same concept, long gaps
between responses, or explicit expressions of frustration. Read-only.

```dart
final motivationCardSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['MotivationCard']),
    'message': S.string(
      description: 'Encouraging message, max 2 sentences. Respectful, not childish. Acknowledges difficulty.',
    ),
    'reframe': S.string(
      description: 'One sentence that reframes the difficult concept as approachable',
    ),
    'action_prompt': S.string(
      description: 'What the student should try next, e.g. "Let\'s try a different example."',
    ),
  },
  required: ['component', 'message', 'reframe'],
);
```

---

## Complete Secondary Catalog Builder

```dart
// lib/features/secondary/presentation/genui/secondary_catalog.dart

Catalog buildSecondaryCatalog() {
  return BasicCatalogItems.asCatalog().copyWith(
    newItems: [
      flashCardItem,
      stepSolverItem,
      pastPaperQuestionItem,
      definitionCardItem,
      confidenceSliderItem,
      essayOutlineItem,
      formulaCardItem,
      motivationCardItem,
    ],
  );
}
```

---

## Secondary AI Tutor System Prompt Addendum

```
You are Yaza, an AI tutor for Malawian secondary school students preparing for
MSCE examinations (Form 1-4, ages 14-18).

Rules:
- For Mathematics, Physics, Chemistry: ALWAYS use StepSolver for worked examples.
  Never explain a calculation in plain text alone.
- After every StepSolver or PastPaperQuestion, surface ConfidenceSlider.
- For Biology, History, Geography: use DefinitionCard to introduce terms, then
  quiz with the existing QuizDisplay or PastPaperQuestion.
- For English and Chichewa essays: use EssayOutline before asking student to write.
- Surface MotivationCard when: student explicitly says they don't understand,
  student gets same question wrong twice, or student sends a very short frustrated response.
- Reference MSCE directly when relevant: "In the MSCE exam, you would need to..."
- Include the subject_tag field on all widgets that support it.
- Surface FlashCard at the END of every session to cement key terms.
- Never surface MotivationCard and PastPaperQuestion consecutively — give the
  student time to recover confidence first.
```

---

## Secondary Session Flows

### secondary_revise (most common)
```
Student: "Revise photosynthesis with me"
    └─► DefinitionCard (photosynthesis definition + memory hook)
        └─► FormulaCard (light equation if Physics link)
            └─► StepSolver (worked process question)
                └─► ConfidenceSlider
                    ├─► Rating ≥ 4 → PastPaperQuestion (MSCE-style)
                    │               └─► FlashCard (key terms)
                    └─► Rating ≤ 2 → MotivationCard
                                    └─► StepSolver (different example)
                                        └─► ConfidenceSlider
```

### secondary_plan (exam countdown mode)
```
Student: "Help me plan my Biology revision"
    └─► PlanTimeline (existing widget — topic schedule)
        └─► DefinitionCard × 3 (priority terms for first topic)
            └─► FlashCard × 3 (quick self-test)
                └─► ConfidenceSlider (session wrap-up)
```

### secondary_coach (struggle mode)
```
Student: "I don't get quadratic equations"
    └─► MotivationCard (acknowledge difficulty)
        └─► DefinitionCard (what is a quadratic equation)
            └─► StepSolver (fully worked example, step by step)
                └─► StepSolver (second example, student predicts steps)
                    └─► ConfidenceSlider
                        └─► FlashCard (key terms: quadratic, coefficient, root)
```
