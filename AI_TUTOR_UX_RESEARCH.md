# AI Tutoring UX Research Report
**Date:** May 2026  
**Scope:** Streaming response UI, interactive learning widgets, accessibility, conversation management, error recovery, competitor analysis (Khanmigo, Duolingo Max, Synthesis, BoardyBoo)

---

## 1. Top 5 User Complaints About AI Tutoring UIs

### 1.1 "Pull-based" chatbots fail — students don't know what to ask
Khan Academy's own data: only ~15% of students who have access to Khanmigo engage with it. Sal Khan admitted publicly that "for most students, it was a non-event." Students don't seek out help because they don't know what they don't know. A chatbot waiting silently in a sidebar cannot help a student who doesn't formulate the right question.

Dan Meyer's "5 Percent Problem": Khanmigo's strongest results came from excluding 95% of study participants. The students who *would* seek out an AI tutor are already self-motivated high-performers.

**Source:** Khan Academy blog, Chalkbeat interview (April 2026), AgentConn analysis

### 1.2 Math hallucinations and factual unreliability
Khanmigo accepted 272 − 172 = 430, marked 10,332 ÷ 4 wrong three times before agreeing, miscalculated 343 − 17. Students lose trust instantly when an AI tutor gives wrong answers on basic arithmetic. This is GPT-4 base behavior — it persists across models.

**Source:** IBL News audit, AgentConn blog (May 2026)

### 1.3 Pure Socratic dialogue frustrates most learners
Khanmigo's "never give the answer" approach — asking guiding questions for every single interaction — creates frustration, especially for K-5 students who just want help. The strongest user complaint across products is exactly this: kids who want help get more questions. Synthesis succeeds because its game loop *disguises* the Socratic structure. Khanmigo struggles because the "naked Socratic dialogue" UI is transparently a question-generator.

**Source:** AgentConn blog, Playground Post (April 2026)

### 1.4 Slow response latency kills engagement
Khan Academy's own experiments: reducing response time by 0.3 seconds across 1.35M tutoring threads measurably improved engagement. Every 100ms of latency the user *waits staring at a blank screen* erodes the feeling of natural conversation. Students start tab-switching.

**Source:** Khan Academy blog (May 2026) — six months of latency experiments

### 1.5 Interface feels like a help desk, not a learning environment
Khanmigo's chat UI was described as looking like "a help desk." No gamification. No visual variety. No character personality. Flat text in a box. By contrast, Synthesis looks like a game, Duolingo Max has character-driven roleplay with Lily, and BoardyBoo has a live whiteboard. The "chat-only" aesthetic signals "answer machine" rather than "tutor."

**Source:** AgentConn, Playground Post, student feedback in Stanford CEPA studies

---

## 2. Top 5 Best Practices (with Examples)

### 2.1 Stream responses with < 500ms time-to-first-token
**What:** Streaming via SSE reduces *perceived* latency by 60-80% even when total generation time is identical. Users start reading while the model finishes generating.

**Implementation:**
- SSE is simpler than WebSockets for one-way streaming
- Time-to-first-token (TTFT) is the metric that matters — aim for < 500ms
- Show a "typing indicator" or cursor pulse during the 200-500ms pre-token window
- Batch DOM updates every 50-100ms (not per-token re-renders)
- Never re-parse/re-render the entire message on each chunk

**Sources:** Chrome Developers guide (2025), Athenic blog, Maisum Hashim (April 2026)
**Used by:** ChatGPT, Claude, Gemini, all production AI apps

### 2.2 Push-based AI integrated into the learning workflow
**What:** Don't make the student open a separate chat. Embed AI help *at the point of struggle* — next to the practice problem, inside the lesson, overlaid on the video.

**Implementation:**
- Khanmigo's 2026 overhaul: embedded directly into practice problems, auto-activates without requiring student invitation
- StudyMate (LearnMate2 research): context-aware Q&A inside the study material, "feels like having an instructor next to me"
- Push notifications calibrated by spaced-repetition schedule (not daily spam)

**Sources:** Khan Academy blog, LearnMate2 paper (arXiv 2605.06257), ForaSoft guide (May 2026)

### 2.3 Streaming markdown with a pre-processor for partial content
**What:** Don't feed incomplete markdown to a standard parser. Use a streaming parser that auto-closes unterminated structures for rendering, then re-parses cleanly when the stream completes.

**Implementation:**
```js
// Pre-processor: close obviously-unfinished structures
function closePartialMarkdown(text) {
  // Close unclosed code fences
  if (text.split('```').length % 2 === 0) text += '\n```';
  // Close unclosed bold/italic markers
  // (heuristic, not a parser — eliminates 95% of visible jank)
  return text;
}
```
- Use streaming parsers like `streaming-markdown` (uses `appendChild`, not `innerHTML`)
- Sanitize with DOMPurify — treat LLM output as untrusted user content
- Memoize the pre-processor output to avoid re-running regex on every chunk

**Sources:** Chrome Developers (Jan 2025), Vadim Alakhverdov (May 2026), Tiger Abrodi (March 2026)
**Used by:** shadcn AI blocks, production React streaming implementations

### 2.4 Interactive widgets using two-phase architecture
**What:** AI-generated interactive widgets (graphs, quizzes, simulations) embedded in chat. The key insight: register placeholders during streaming, mount widgets *after* streaming completes.

**Implementation pattern (from AimiChat):**
1. **Phase 1 (streaming):** AI generates `interactive-*` fenced code blocks with JSON config. Parser extracts config, assigns content-addressed hash ID, inserts a placeholder `<div>` with loading spinner. No mounting during streaming.
2. **Phase 2 (post-stream):** Walk all placeholders, mount widgets (Canvas, sliders, quizzes, etc.) into stable DOM nodes. Content-addressed IDs survive DOM resets because they're deterministic.
3. **Safety:** Use recursive descent parser for math expressions (not `eval()`). IntersectionObserver to pause off-screen animation loops.

**Sources:** AimiChat blog (DEV.to, April 2026), shadcn AI blocks, BoardyBoo (Excalidraw + Framer Motion)

### 2.5 Multi-agent orchestration with explicit pedagogical strategy
**What:** A single LLM prompt is not enough for tutoring. Modern systems use multiple agents: a Strategist (decides what to teach next), a Tutor (handles the conversation), a Diagnostic agent (assesses understanding), and a Progress agent (tracks mastery).

**Implementation:**
- Khan Academy's 2026 Khanmigo: Diagnostic Agent + Curriculum Agent + Instruction Agent
- MyTutor architecture (2026): Strategist + Tutor + mastery telemetry per CCSS standard
- Duolingo Max: Immersive Scenario Agent + Pronunciation Coach Agent + Cultural Context Agent + Progress Synthesis Agent
- Pedagogical controller selects strategy per turn: Socratic / direct instruction / faded examples

**Sources:** AgentConn blog, CallSphere AI (March 2026), Khan Academy blog

---

## 3. Edge Cases Every AI Tutor Should Handle

### 3.1 Mid-stream network interruption
**The case:** Connection drops at token 200 of a 2000-token response. User sees half a sentence forever.

**Must handle:**
- Preserve partial text — don't clear it. User can read what arrived.
- Error banner: "Stream interrupted. [Retry from here]"
- Retry sends partial text back as prefilled assistant message. Model continues from where it left off — don't restart from scratch.
- Filter `AbortError` from error UI (user closing tab / pressing stop is not a crash).

**Sources:** Vadim Alakhverdov (May 2026), Athenic blog

### 3.2 Context window overflow
**The case:** After 50+ turns, the conversation history exceeds the model's context window. The system truncates silently, dropping system prompts or early constraints.

**Must handle:**
- **Non-negotiable:** System prompt must survive intact. Reserve explicit token budget for it.
- Tiered memory strategy:
  - **Hot tier:** Last 5-10 turns verbatim (in-context)
  - **Warm tier:** Running summary of everything before the hot tier (re-derived periodically)
  - **Cold tier:** Full transcript + extracted facts, indexed for similarity search, paged in on demand
- Trigger summarization at 70-80% context capacity, not at the hard limit
- Relevance-scored eviction: protect load-bearing turns (user constraints, named entities) over conversational filler

**Sources:** Tian Pan blog (April 2026), Tanuj Garg (April 2026), GenAI Patterns guide, Microsoft Agent Framework docs

### 3.3 Screen reader fatigue from streaming content
**The case:** A screen reader announces every token as it arrives — the user hears a stream of word fragments, or the screen reader races to catch up. Both are worse than useless.

**Must handle:**
- Buffer tokens to sentence boundaries before pushing to ARIA live region
- Announce discrete events: "thinking" → "response started" → "response complete" — not tokens
- Two live regions: `aria-live="polite"` for content, separate for status messages
- `aria-atomic="false"`, `aria-relevant="additions"` so only new content is announced
- Keyboard shortcut to re-read latest response (e.g., Alt+R)
- User setting to disable auto-announcement entirely
- "Transcript view" — clean linear document without live-region mechanics
- Respect `prefers-reduced-motion` for all streaming animations

**Sources:** Precision Federal guide (March 2026), claude-a11y Chrome extension, WCAG 2.2 AA guidelines

### 3.4 Student-generated cheating patterns
**The case:** Students paste homework problems and ask for direct answers. The tutor becomes a cheating tool.

**Must handle:**
- Refusal is pedagogical, not safety-driven. The tutor *must* refuse to solve homework verbatim.
- Paste-detection classifier flags suspicious sessions
- Output classifier rewrites verbatim solutions into Socratic prompts
- Teacher dashboard shows flagged suspicious sessions
- But calibrate the gap: Socratic questions must be *answerable* or students give up

**Sources:** ForaSoft guide (May 2026), Khan Academy blog, Penn study on personalized practice

### 3.5 Very long responses with code blocks
**The case:** AI generates a 200-line code block. The closing fence hasn't arrived yet. The markdown parser treats the rest of the message as a code block. DOM shifts violently when the fence arrives.

**Must handle:**
- Pre-processor tracks open/close fence count
- Apply syntax highlighting only after the code block is complete (even number of fences)
- During streaming, render code blocks as plain `<pre>` to avoid syntax highlighting flicker
- Height expansion (smooth `max-height` transition) instead of layout shift

**Sources:** DEV.to streaming LLM guide (Dec 2025), streaming markdown patterns (Maisum Hashim, April 2026)

---

## 4. Specific Recommendations

### 4.1 Streaming Response UI

| Element | Recommendation |
|---------|---------------|
| Protocol | SSE (Server-Sent Events) — simpler than WebSockets for one-way streaming |
| TTFT target | < 500ms. Show cursor pulse or "thinking" indicator during pre-token window |
| DOM updates | Batch every 50-100ms using `requestAnimationFrame`. Never re-render on every token |
| Markdown | Use a streaming parser (`streaming-markdown`) that uses `appendChild`, not `innerHTML`. Pre-process to close unterminated structures before feeding to parser |
| Sanitization | DOMPurify after every chunk. LLM output is untrusted user content. Stop rendering if sanitizer removes content |
| Auto-scroll | Stick to bottom only if user is within 80px of the bottom. If they scroll up to read earlier content, stop chasing them |
| Cancellation | Abort controller on the fetch. User presses stop → abort. Filter AbortError from error UI |
| Code blocks | Detect incomplete fences. Don't syntax-highlight mid-stream. Render as plain `<pre>` until complete |
| Cursor | Separate `<span>` for blinking cursor, not inside markdown source |

**Reference implementations:**
- Chrome Developers AI Streaming Parser (developer.chrome.com/docs/ai/render-llm-responses)
- Vercel AI SDK `useChat` hook
- Streaming-markdown NPM package
- `useBufferedContent` hook (Athenic blog pattern)

### 4.2 GenUI Widgets (Quiz, Visual Board, Formula Cards)

**Architecture — Two-phase mount:**
```
Phase 1 (during streaming):  Register widget config → emit placeholder <div>
Phase 2 (after streaming):    Walk placeholders → mount widgets into stable DOM
```

**Widget types to support:**
| Widget | Rendering tool | Notes |
|--------|---------------|-------|
| Math graphs | Canvas + recursive descent parser | Handle retina DPI (2x buffer). IntersectionObserver for animation pause |
| Quizzes (MCQ, drag-to-match) | React components, content-addressed IDs | Immediate correct/incorrect feedback, optional explanation |
| Code walkthroughs | Canvas + step-state JSON | Forward/backward stepping through variable states |
| Mind maps / flowcharts | Mermaid renderer or Excalidraw | Animated progressive drawing left-to-right |
| Formula cards | KaTeX (synchronous, faster than MathJax) | Render with KaTeX, not MathJax (async adds complexity during streaming) |
| Whiteboard | Excalidraw API (`updateScene()`) | Real-time drawing + voice sync (BoardyBoo pattern) |

**Critical:**
- No `eval()` for math expressions — use recursive descent parser (security)
- Content-addressed IDs for placeholders (`hash(widgetType + jsonConfig)`) — survive DOM resets
- Error fallback: if widget fails to render, show raw JSON config with explanation
- IntersectionObserver to pause off-screen animation loops

**Sources:** AimiChat (DEV.to, April 2026), BoardyBoo (Google ADK), Visual Learning engine (GitHub, March 2026), ChatTutor (GitHub, Geogebra + Vue)

### 4.3 Conversation Management

**Memory architecture — Three tiers:**

| Tier | Contents | Size budget | Strategy |
|------|----------|-------------|----------|
| Hot | Last 5-10 turns verbatim | 4K-8K tokens | Always in-context. Never trimmed. |
| Warm | Running summary of history before hot tier | 1K-2K tokens | Re-derived at 70-80% context capacity. Use LLM to summarize oldest unsummarized turns. |
| Cold | Full transcript + extracted facts | External DB | Indexed for similarity search. Only paged in on demand. |

**Key decisions:**
- **System prompt must survive intact** — reserve explicit token budget, never let it get evicted
- **Eviction policy:** Not LRU (wrong — early load-bearing turns get dropped, late small-talk stays). Relevance-scored: protect user constraints, named entities, explicit instructions
- **Query plan per turn:** Not every turn needs the same history. "What did I just say?" → last 2 turns. Specific fact → targeted retrieval.
- **Supersession tracking:** If user says "ignore that, use this instead," evict the old reference aggressively
- **Phase detection:** Distinguish exploration (many open threads) from execution (narrow path). Compress exploration phase when transitioning to execution.

**Chat history UX:**
- Sidebar list with auto-generated titles (from first user message / topic, not "Conversation 1")
- Search across all conversations (table-stakes for 50+ conversations)
- Conversation branching (editing a message and regenerating from that point) — powerful but adds significant UI complexity

**Storage backend:**
- Redis for hot tier (low-latency point reads, TTL-based eviction)
- SQLite for per-user single-tenant agents (whole history fits in a file)
- Postgres + pgvector when history needs to participate in transactions with other app state

**Sources:** Microsoft Agent Framework blog (April 2026), Tian Pan blog (April 2026), GenAI Patterns guide, AI UX Design guide (April 2026), Tanuj Garg (April 2026)

### 4.4 Error States

| Error type | UX pattern |
|------------|-----------|
| Stream interruption | Preserve partial content. Show error banner. Offer "Retry from here" (sends partial text back as prefill) |
| Rate limit | Inform: "Too many requests. Please wait X seconds." Show cooldown timer. Offering retry without explanation is worse. |
| Context limit | Differentiate from generic error. Show: "Conversation is getting long. Starting a new session will help me think more clearly." Offer to summarize & continue. |
| Content policy refusal | Show refusal clearly, explain why: "I can't give you the answer directly, but I can help you work through it." |
| Model timeout | Partial content + "Response took too long. Try asking in shorter sentences." |
| Hallucination / math error | This is the hardest one. Math agent (separate from conversational model) verifies calculations before final output. If inconsistency detected, flag: "Let me double-check that..." |

**Golden rule:** Never collapse all failures into a single "Something went wrong." Differentiate provider errors, policy blocks, context limits, and user-correctable issues. Preserve enough context after failure that users can retry without losing work.

**Sources:** Athenic blog, Vadim Alakhverdov (May 2026), Martha Kelly (Nov 2025), shadcn AI components

### 4.5 Session Recovery

**What happens when the user returns after hours/days:**

- **Short return (< 1 hour):** Resume exact conversation. Last message visible, input focused, scroll position preserved.
- **Medium return (< 24 hours):** Show last N messages (expanded). Optionally inject a summary of the session as a warm-tier memory. Flag: "Welcome back. Here's where you left off."
- **Long return (> 24 hours):** Show a "previous session summary" card at the top. Don't dump 100 messages. Provide link to full transcript. Offer: "Would you like to continue where you left off, or start fresh?"

**Auto-save:**
- Every message sent and received is persisted immediately (optimistic write to cold tier)
- LocalStorage / IndexedDB as fallback when network is unavailable
- Draft auto-save: what the user was typing is saved even if they navigated away

**Key insight from Tian Pan:** "Once you stop calling it a transcript and start calling it a database, the problem space rearranges itself." Session state is the *data layer* of an AI product, not a side effect of the chat UI.

**Sources:** Tian Pan blog (April 2026), Microsoft Agent Framework docs, Khan Academy session experiments

---

## 5. Competitor Analysis Summary

### Khanmigo (Khan Academy)
- **Model:** GPT-4, Claude 3.5 Sonnet for 2026 revamp
- **Strengths:** Largest content library, free ($4/mo), Socratic method, writing coach, code reviewer
- **Weaknesses:** Pull-based (students didn't seek it out), math hallucinations, chat-only UI feels like help desk, pure Socratic frustrates K-5
- **2026 changes:** Embedded into practice problems, auto-activates, multi-agent (Diagnostic + Curriculum + Instruction), improved latency by 0.3-3s
- **Key stat:** Only 15% engagement, Khan called it "a non-event"

### Duolingo Max
- **Model:** GPT-4
- **Strengths:** Character-driven (Lily the emo teen), Roleplay scenarios, Video Call, Explain My Answer for grammar, gamified progression, 2.3x faster to conversational proficiency
- **Weaknesses:** Paywalled ($29.99/mo), limited language coverage, AI can still make mistakes
- **Key insight:** Turned language learning into conversational AI + beloved characters. The character (Lily) is the UX differentiator.

### Synthesis
- **Strengths:** Game loop disguises Socratic structure. 4.5x YoY revenue growth. K-2 emoji UI through grade-12 depth. Streaks, chests, room customization, 1v1 math battle arena.
- **Weaknesses:** Hand-authored content doesn't scale. Users "run out of content" by month 3.
- **Key insight:** The game-first approach solves the engagement problem that pure chat can't.

### BoardyBoo
- **Model:** Gemini 2.5 Flash + Google ADK
- **Strengths:** Voice + whiteboard (Excalidraw), real-time drawing while speaking, multi-agent (Tutor + Planner + Calendar + Progress), animated math graphs, camera input for homework, COPPA-clean
- **Key insight:** Voice + whiteboard breaks the "text box" paradigm entirely. Drawing animates *while* the tutor speaks through early canvas push.

### Q-Chat (Quizlet) — **Shut down June 2025**
- **Reason for failure:** Per-user inference costs destroyed margins. Token economics didn't work at Quizlet's price point.

---

## 6. Summary: What Makes AI Tutoring UX Work

| Principle | Why it matters |
|-----------|---------------|
| **Push-based, not pull-based** | Students won't seek out help. AI must be embedded in the learning workflow. |
| **Game-like or character-driven, not chat-only** | Pure chat signals "answer machine." Synthesis (game) and Duolingo (characters) retain 4x better. |
| **Streaming with < 500ms TTFT** | Every 100ms of blank-screen latency = engagement erosion. |
| **Interactive widgets, not text-only** | Graph, quiz, simulation widgets embedded in responses beat walls of text for STEM learning. |
| **Multi-agent architecture** | One LLM prompt cannot handle planning + tutoring + assessment. Split the work. |
| **Handles interruptions gracefully** | Preserve partial content, retry from interruption point, never show half a sentence with no recovery path. |
| **Accessibility by design** | ARIA live regions, buffer to sentence boundaries, keyboard shortcuts, `prefers-reduced-motion`, transcript view. |
| **Context management with tiers** | Hot (recent turns), warm (summary), cold (external DB). Relevance-scored eviction, not LRU. System prompt never trimmed. |
| **Math accuracy via separate agent** | Never trust the conversational model for math. Run a separate math verification agent. |
| **Refusal is pedagogical, not punishment** | "I can't give you the answer" must feel like *teaching*, not withholding. Calibrate Socratic gap to be answerable. |

---

**Sources consulted:**
- Khan Academy Blog (May 2026) — product test results across 15M tutoring threads
- AgentConn (May 2026) — post-Khanmigo market analysis
- Chrome Developers (Jan 2025) — streaming LLM response rendering best practices
- Athenic Blog (Sep 2025) — SSE implementation and streaming UX patterns
- Vadim Alakhverdov (May 2026) — React streaming AI UX patterns
- Maisum Hashim (April 2026) — streaming response UX patterns
- Martha Kelly (Nov 2025) — UI for non-deterministic systems
- Precision Federal (March 2026) — Section 508 accessibility for AI interfaces
- Tian Pan (April 2026) — context window cliff strategies, chat history as database
- Tanuj Garg (April 2026) — LLM context window management in production
- Microsoft Agent Framework (April 2026) — chat history storage patterns
- AimiChat (DEV.to, April 2026) — interactive learning widgets in chat
- BoardyBoo (GitHub, Google ADK) — AI whiteboard tutor architecture
- LearnMate2 (arXiv 2605.06257) — personalized online learning support
- ForaSoft (May 2026) — building AI tutors students actually use
- CallSphere AI (March 2026) — Khan Academy and Duolingo multi-agent deployments
- Hechinger Report (April 2026) — quest to build a better AI tutor
- Playground Post (April 2026) — Khanmigo "non-event" analysis
- Section 508 guidelines, WCAG 2.2 AA, nchat accessibility wiki
