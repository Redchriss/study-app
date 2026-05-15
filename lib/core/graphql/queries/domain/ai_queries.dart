const String kCreateChatSession = r'''
mutation CreateChatSession($materialId: ID) {
  createChatSession(materialId: $materialId) {
    session { id title }
  }
}
''';

const String kSendMessage = r'''
mutation SendMessage($sessionId: ID!, $content: String!, $materialId: ID, $studyMode: String) {
  sendMessage(
    sessionId: $sessionId
    content: $content
    materialId: $materialId
    studyMode: $studyMode
  ) {
    success
    error
    message { id messageText isUser timestamp }
    creditsCost
    creditsRemaining
  }
}
''';

const String kChatMessages = r'''
query ChatMessages($sessionId: ID!) {
  chatMessages(sessionId: $sessionId) {
    id messageText isUser timestamp
  }
}
''';
