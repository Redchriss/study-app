class UploadMaterialLabels {
  static String levelLabel(String educationLevel) {
    switch (educationLevel) {
      case 'primary':
        return 'Primary';
      case 'tertiary':
        return 'Tertiary / University';
      default:
        return 'Secondary';
    }
  }

  static String titlePlaceholder(String contentType, String educationLevel) {
    switch (contentType) {
      case 'pdf':
        if (educationLevel == 'primary') {
          return 'e.g. Standard 7 Maths – Fractions';
        }
        if (educationLevel == 'tertiary') {
          return 'e.g. UNIMA Physics 201 – Thermodynamics Notes';
        }
        return 'e.g. Form 3 Biology – Respiration';
      case 'image':
        if (educationLevel == 'primary') {
          return 'e.g. Diagram – Water Cycle';
        }
        if (educationLevel == 'tertiary') {
          return 'e.g. Anatomy Diagram – Digestive System';
        }
        return 'e.g. MSCE Geography – Rainfall Map';
      case 'video':
        if (educationLevel == 'primary') {
          return 'e.g. English Lesson – Parts of Speech';
        }
        if (educationLevel == 'tertiary') {
          return 'e.g. Organic Chemistry – Alkene Reactions';
        }
        return 'e.g. MSCE Mathematics – Differentiation';
      case 'text':
        if (educationLevel == 'primary')
          return 'e.g. Science Summary – Living Things';
        if (educationLevel == 'tertiary')
          return 'e.g. Law Notes – Constitutional Law';
        return 'e.g. History Notes – Colonial Malawi';
      default:
        return 'e.g. Form 3 Biology Notes – Respiration';
    }
  }

  static String descPlaceholder(String educationLevel) {
    if (educationLevel == 'primary') {
      return 'What topic does this cover? What standard is it for?';
    }
    if (educationLevel == 'tertiary') {
      return 'What course, year, and topics are covered in this material?';
    }
    return 'What form and subject is this for? What topics does it cover?';
  }

  static String primaryHint(String contentType) {
    switch (contentType) {
      case 'pdf':
        return 'Upload revision booklets, topic handouts, or scanned notes that students can read in-app.';
      case 'image':
        return 'Upload diagrams, worked examples, maps, or annotated pages students can zoom into.';
      case 'video':
        return 'Use a YouTube lesson so students can watch in-app and the AI can reuse transcripts when available.';
      case 'text':
        return 'Paste notes directly or attach a readable file if you already have one.';
      default:
        return '';
    }
  }

  static String fileButtonLabel(String contentType) {
    switch (contentType) {
      case 'pdf':
        return 'Choose PDF';
      case 'image':
        return 'Choose Image';
      case 'text':
        return 'Attach File';
      default:
        return 'Choose File';
    }
  }

  static List<String> allowedExtensions(String contentType) {
    switch (contentType) {
      case 'pdf':
        return const ['pdf'];
      case 'image':
        return const ['png', 'jpg', 'jpeg', 'gif', 'webp'];
      case 'text':
        return const ['pdf', 'doc', 'docx', 'txt', 'ppt', 'pptx'];
      default:
        return const [];
    }
  }
}
