# Yaza Tertiary Level — GenUI Catalog Specification

## Context

Tertiary level targets university and college students aged 18+ studying at
institutions like MUBAS, UNIMA, Malawi Polytechnic, Kamuzu University of Health
Sciences, and other Malawian higher education institutions. Subjects span
Computer Science, Engineering, Business, Education, Health Sciences, Law,
Agriculture, and Social Sciences.

**Study modes**: `tertiary_coach`, `tertiary_research`, `tertiary_plan`
**Gemini model**: `gemini-2.5-flash-lite`
**Catalog file**: `lib/features/tertiary/presentation/genui/tertiary_catalog.dart`
**Visual theme**: Material 3 — `Theme.of(context).colorScheme.*`
**Tone**: Collegial, intellectually rigorous, peer-level. The AI speaks like a
knowledgeable study partner, not a teacher.

---

## Design Principles for Tertiary Level

- **Critical thinking over recall.** Tertiary students need to synthesise, argue,
  and analyse — not just memorise. Widgets should prompt higher-order thinking.
- **Open-ended interactions.** Unlike primary/secondary, tertiary widgets should
  accept long-form text input and nuanced responses.
- **Concept relationships matter.** University-level understanding is about how
  ideas connect, not isolated facts. `ConceptMap` and `ArgumentBuilder` directly
  serve this.
- **Research-aware.** Tertiary students write papers and do research. Widgets
  like `ResearchSummary` and `SourceCitation` support academic workflow.
- **Discipline-specific depth.** The AI should always know which faculty/course
  the student is in and tailor its widget choices accordingly. A CS student
  needs `CodeSnippetCard`; a law student needs `DebateCard`.
- **Minimal gamification.** No reward bursts, no confetti. Tertiary students
  find this patronising. Progress is shown through `ProgressRing` only.

---

## Catalog Items

### 1. ConceptMap

**Purpose**: A visual graph of nodes and edges showing how concepts relate to
each other. The AI generates the nodes (concepts) and edges (relationships).
The student can tap any node to expand it — firing an AI response that explains
that concept in depth.

**Interaction**: Tap a node → `nodeExpandAction` dispatched with `{nodeId, nodeLabel}`
→ AI responds with a `DefinitionCard` or plain text explanation for that node.

**Visual**: Rendered using `CustomPainter` on a `Canvas`. Nodes are rounded
rectangles, edges are lines with relationship labels. The central concept is
distinguished by size and colour. Student can pan the canvas.

```dart
final conceptMapSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['ConceptMap']),
    'title': S.string(description: 'Title of the concept map topic'),
    'nodes': S.array(
      items: S.object(properties: {
        'id': S.string(description: 'Unique identifier for this node'),
        'label': S.string(description: 'Concept name, max 3 words'),
        'is_central': S.boolean(description: 'True for the main/root concept only'),
      }),
      description: 'Between 5 and 10 concept nodes',
    ),
    'edges': S.array(
      items: S.object(properties: {
        'from_id': S.string(description: 'Source node id'),
        'to_id': S.string(description: 'Target node id'),
        'relationship': S.string(description: 'Relationship label, max 4 words'),
      }),
      description: 'Connections between concepts',
    ),
    'nodeExpandAction': A2uiSchemas.action(
      description: 'Dispatched when student taps a node, context includes nodeId and nodeLabel',
    ),
  },
  required: ['component', 'title', 'nodes', 'edges', 'nodeExpandAction'],
);
```

**Notes for agent**:
- Use a force-directed layout approximation: central node at centre, others
  distributed radially using `math.cos` / `math.sin` based on index
- Node sizes: central = 80×40dp, others = 60×32dp
- Edge relationship labels render in 10sp on a white pill background on the line
- GestureDetector on each node using `contains(Offset)` check against painted bounds
- Pan support via `GestureDetector.onPanUpdate` modifying an `Offset` state variable

---

### 2. ArgumentBuilder

**Purpose**: A scaffolded card for constructing academic arguments. Claim →
Evidence → Counter-argument → Rebuttal. Used for Law, Education, Social
Sciences, Business. The student fills each section; AI provides feedback on
each section when submitted.

**Interaction**: Each section has a text field. Student fills them one by one.
Each section has a "Review this" button → `reviewAction` dispatched with
`{section, content}` → AI responds with plain text feedback inline.

**Visual**: Vertical stack of four bordered sections, each with a coloured
left-border accent (claim: blue, evidence: green, counter: amber, rebuttal: teal).
Section labels in bold caps. Text fields are multi-line.

```dart
final argumentBuilderSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['ArgumentBuilder']),
    'topic': S.string(description: 'The debate or essay topic'),
    'position': S.string(description: 'The stance the student is arguing for'),
    'claim_prompt': S.string(
      description: 'Guiding prompt for the claim section e.g. "State your main argument in one sentence"',
    ),
    'evidence_prompt': S.string(
      description: 'Guiding prompt for evidence e.g. "What data or example supports your claim?"',
    ),
    'counter_prompt': S.string(
      description: 'Guiding prompt for counter-argument e.g. "What would an opponent say?"',
    ),
    'rebuttal_prompt': S.string(
      description: 'Guiding prompt for rebuttal e.g. "How do you address that counter-argument?"',
    ),
    'reviewAction': A2uiSchemas.action(
      description: 'Dispatched when student requests review of a section',
    ),
  },
  required: ['component', 'topic', 'position', 'claim_prompt', 'evidence_prompt',
             'counter_prompt', 'rebuttal_prompt', 'reviewAction'],
);
```

---

### 3. CodeSnippetCard

**Purpose**: A syntax-highlighted code block with line-by-line annotations. For
Computer Science and Engineering students. The AI explains what the code does,
common bugs, and exam-relevant patterns.

**Interaction**: Each annotated line is tappable → `lineExplainAction` dispatched
with `{lineNumber, lineContent}` → AI explains that specific line in chat.
A "Run in head" button challenges the student to predict the output mentally,
then reveals it.

**Visual**: Dark background code block (even in light mode for readability).
Line numbers in muted colour. Annotations appear as inline comments with a
distinct highlight. Output reveal uses `AnimatedSize`.

```dart
final codeSnippetCardSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['CodeSnippetCard']),
    'language': S.string(
      enumValues: ['python', 'java', 'c', 'dart', 'javascript', 'sql', 'other'],
    ),
    'code': S.string(description: 'The code snippet, max 20 lines'),
    'annotations': S.array(
      items: S.object(properties: {
        'line_number': S.integer(description: 'Line number to annotate (1-based)'),
        'note': S.string(description: 'Annotation text, max 10 words'),
      }),
      description: 'Up to 5 line annotations',
    ),
    'expected_output': S.string(
      description: 'What this code outputs or returns when run',
    ),
    'concept_tag': S.string(
      description: 'Core CS concept demonstrated e.g. "recursion", "sorting", "OOP"',
    ),
    'lineExplainAction': A2uiSchemas.action(
      description: 'Dispatched when student taps a line for explanation',
    ),
  },
  required: ['component', 'language', 'code', 'expected_output', 'lineExplainAction'],
);
```

**Notes for agent**:
- Use `flutter_highlight` or manual tokenization for syntax highlighting
- Code renders in `JetBrains Mono` or `Source Code Pro` (Google Fonts)
- "Show output" button reveals `expected_output` with a `SlideTransition`

---

### 4. ResearchSummary

**Purpose**: A structured academic summary card: Background → Methodology →
Findings → Limitations → Implications. Used in Research Methods courses and
when helping students understand academic papers or design their own research.

```dart
final researchSummarySchema = S.object(
  properties: {
    'component': S.string(enumValues: ['ResearchSummary']),
    'paper_title': S.string(description: 'Title or topic of the research being summarised'),
    'background': S.string(description: 'Why this research matters, 1-2 sentences'),
    'methodology': S.string(
      description: 'How the research was done or would be done, 1-2 sentences',
    ),
    'findings': S.string(description: 'Key results or expected results, 2-3 bullet points as a string'),
    'limitations': S.string(description: 'What the research cannot tell us, 1 sentence'),
    'implications': S.string(
      description: 'What this means for the field or for Malawi specifically, 1-2 sentences',
    ),
  },
  required: ['component', 'paper_title', 'background', 'methodology', 'findings'],
);
```

---

### 5. FormulaCard (shared with Secondary — same implementation)

**Purpose**: Engineering and science formula with variable definitions and worked
example. Same schema as secondary — import and reuse the same `CatalogItem`.

```dart
// Import from secondary catalog — do not redefine
// import 'package:yaza/features/secondary/presentation/genui/formula_card.dart';
// Use formulaCardItem directly in tertiary catalog
```

---

### 6. DebateCard

**Purpose**: Two-sided card presenting both sides of a contested academic question
or policy issue. Student reads both sides, then taps which argument they find
stronger, with a brief reasoning field. Used in Law, Political Science, Education,
Business Ethics. Trains intellectual objectivity.

**Interaction**: Student selects side A or B → reasoning text field appears →
student types 2-3 sentences → `debateAction` dispatched with `{selectedSide,
reasoning}` → AI responds with its own analysis of both sides.

```dart
final debateCardSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['DebateCard']),
    'question': S.string(description: 'The contested question or proposition'),
    'side_a_label': S.string(description: 'Label for position A, max 4 words'),
    'side_a_argument': S.string(
      description: 'Core argument for position A, 2-3 sentences with evidence',
    ),
    'side_b_label': S.string(description: 'Label for position B, max 4 words'),
    'side_b_argument': S.string(
      description: 'Core argument for position B, 2-3 sentences with evidence',
    ),
    'context': S.string(
      description: 'Optional Malawian or African context that makes this debate locally relevant',
    ),
    'debateAction': A2uiSchemas.action(
      description: 'Dispatched when student submits their side selection and reasoning',
    ),
  },
  required: ['component', 'question', 'side_a_label', 'side_a_argument',
             'side_b_label', 'side_b_argument', 'debateAction'],
);
```

---

### 7. ProgressRing

**Purpose**: A circular progress indicator showing session or topic completion.
Surfaces at the start and end of sessions. Tertiary students are self-directed —
they want to see where they are in a topic without gamified badges.

```dart
final progressRingSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['ProgressRing']),
    'topic': S.string(description: 'The topic or course being tracked'),
    'completed_count': S.integer(description: 'Number of subtopics or questions completed'),
    'total_count': S.integer(description: 'Total subtopics or questions in this topic'),
    'session_summary': S.string(
      description: 'One sentence summary of what was covered today',
    ),
  },
  required: ['component', 'topic', 'completed_count', 'total_count'],
);
```

**Visual**: `CustomPaint` circular arc. Percentage in centre in 28sp bold.
Topic name below. Session summary in muted text below the ring. Animates from
0 to percentage on entrance using `AnimationController`.

---

## Complete Tertiary Catalog Builder

```dart
// lib/features/tertiary/presentation/genui/tertiary_catalog.dart

Catalog buildTertiaryCatalog() {
  return BasicCatalogItems.asCatalog().copyWith(
    newItems: [
      conceptMapItem,
      argumentBuilderItem,
      codeSnippetCardItem,
      researchSummaryItem,
      formulaCardItem,          // reused from secondary
      debateCardItem,
      progressRingItem,
    ],
  );
}
```

---

## Tertiary AI Tutor System Prompt Addendum

```
You are Yaza, an AI study partner for university and college students in Malawi.
You operate at a peer level — intellectually rigorous, direct, and respectful.

Rules:
- ALWAYS open a session with ProgressRing showing current topic progress.
- For CS/Engineering topics: use CodeSnippetCard for any code discussion.
  Never explain code only in plain text.
- For essay/argument topics (Law, Education, Business): use ArgumentBuilder
  before asking the student to write anything.
- For contested topics: use DebateCard to force the student to engage critically
  with both sides before you give your analysis.
- For any topic with 6+ concepts: use ConceptMap to establish the landscape
  before drilling into specifics.
- For research methods courses: always use ResearchSummary to model what good
  academic structure looks like.
- Surface ProgressRing at the END of every session.
- Do NOT surface ProgressRing more than twice per session.
- Localise examples where possible: reference MUBAS, UNIMA, Malawi's economy,
  Malawi's health system, Lilongwe, African Union context.
- Do not use childlike language. Speak as a knowledgeable peer.
```

---

## Tertiary Session Flows

### tertiary_coach (concept mastery)
```
Student: "Help me understand database normalisation"
    └─► ConceptMap (1NF, 2NF, 3NF and their relationships)
        └─► CodeSnippetCard (SQL example of unnormalised vs 3NF table)
            └─► DebateCard ("Is 3NF always worth the complexity cost?")
                └─► ProgressRing (session wrap)
```

### tertiary_research (academic writing)
```
Student: "Help me write my research proposal methodology"
    └─► ResearchSummary (AI drafts a sample structure for their topic)
        └─► ArgumentBuilder (student articulates their research rationale)
            └─► ProgressRing (proposal section tracker)
```

### tertiary_plan (exam/assignment prep)
```
Student: "My Business Ethics exam is in 2 weeks"
    └─► ProgressRing (topics covered vs remaining)
        └─► ConceptMap (key theories: utilitarianism, deontology, virtue ethics)
            └─► DebateCard (contested CSR question)
                └─► ArgumentBuilder (practice essay argument)
                    └─► ProgressRing (updated — session complete)
```
