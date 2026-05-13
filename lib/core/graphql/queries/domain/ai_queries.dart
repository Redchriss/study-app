const String kCreateChatSession = r'''
mutation CreateChatSession($subjectId: ID) {
  createChatSession(subjectId: $subjectId) {
    session { id title }
  }
}
''';

const String kSendMessage = r'''
mutation SendMessage($sessionId: ID!, $message: String!) {
  sendMessage(sessionId: $sessionId, message: $message) {
    message { id messageText isUser timestamp }
    reply { id messageText timestamp }
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
