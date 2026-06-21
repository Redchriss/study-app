List<String> suggestionsForMode(String studyMode) {
  switch (studyMode) {
    case 'quiz':
      return [
        'Quiz me on photosynthesis',
        'Test me on Form 2 algebra',
        'Ask 5 MSCE revision questions',
      ];
    case 'plan':
      return [
        'Plan my revision for tomorrow',
        'Make a 30-minute study session',
        'What should I study first for exams?',
      ];
    case 'memorize':
      return [
        'Help me memorize the parts of the heart',
        'Give me a mnemonic for acids and bases',
        'Memory hooks for respiration steps',
      ];
    case 'revise':
      return [
        'Quick summary of respiration',
        'Key points for photosynthesis',
        'Revise this topic fast',
      ];
    case 'coursework':
      return [
        'Write a 1500-word essay on climate change',
        'Lab report on enzyme activity experiment',
        'Presentation slides on cell division',
        'Draft section 1 of my outline',
        'Approve outline and start drafting',
      ];
    default:
      return [
        'Explain fractions simply',
        'Help me understand osmosis',
        "What is Newton's 3rd law?",
      ];
  }
}

String modePlaceholder(String studyMode) {
  switch (studyMode) {
    case 'quiz':
      return 'Ask me a quiz question...';
    case 'plan':
      return 'Tell me your goal to plan...';
    case 'memorize':
      return 'What do you need to memorize?';
    case 'revise':
      return 'What topic to revise?';
    case 'coursework':
      return 'Describe your assignment brief...';
    default:
      return 'Ask anything about your studies...';
  }
}

String modeHint(String studyMode) {
  switch (studyMode) {
    case 'quiz':
      return "I'll test you one question at a time.";
    case 'plan':
      return "I'll organize what to study and when.";
    case 'memorize':
      return "I'll build mnemonics and memory hooks.";
    case 'revise':
      return "I'll compress topics into fast revision.";
    case 'coursework':
      return "I'll draft essays, reports, and presentations.";
    default:
      return "I'll explain, then check your understanding.";
  }
}
