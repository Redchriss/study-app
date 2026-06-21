const String kNotifications = r'''
query Notifications($unreadOnly: Boolean, $limit: Int) {
  notifications(onlyUnread: $unreadOnly, limit: $limit) {
    edges {
      node {
        id
        notifType
        bodyPreview
        isRead
        createdAt
      }
    }
    totalCount
  }
  unreadNotificationCount
}
''';

const String kMarkNotificationRead = r'''
mutation MarkNotificationRead($notificationId: ID!) {
  markNotificationRead(notificationId: $notificationId) { success }
}
''';

const String kMarkAllNotificationsRead = r'''
mutation MarkAllNotificationsRead {
  markAllNotificationsRead { success }
}
''';

const String kModmailThreads = r'''
query ModmailThreads($communitySlug: String!, $archived: Boolean) {
  modmailThreads(communitySlug: $communitySlug, archived: $archived) {
    id subject isArchived isInternal createdAt lastUpdated
    community { slug name }
    messages {
      id body isInternal createdAt
      author { id username }
    }
  }
}
''';

const String kModmailThread = r'''
query ModmailThread($threadId: ID!) {
  modmailThread(threadId: $threadId) {
    id subject isArchived isInternal createdAt lastUpdated
    community { slug name }
    messages {
      id body isInternal createdAt
      author { id username }
    }
  }
}
''';

const String kSendModmail = r'''
mutation SendModmail($communitySlug: String!, $subject: String!, $body: String!) {
  sendModmail(communitySlug: $communitySlug, subject: $subject, body: $body) {
    id subject
  }
}
''';

const String kReplyModmail = r'''
mutation ReplyModmail($threadId: ID!, $body: String!, $isInternal: Boolean) {
  replyModmail(threadId: $threadId, body: $body, isInternal: $isInternal) {
    id body createdAt
  }
}
''';

const String kArchiveModmailThread = r'''
mutation ArchiveModmailThread($threadId: ID!) {
  archiveModmailThread(threadId: $threadId) { success }
}
''';

const String kNotificationPreferences = r'''
query NotificationPreferences {
  notificationPreferences {
    pushEnabled
    emailEnabled
    studyReminders
    communityReplies
    mentorshipUpdates
    marketingEmails
  }
}
''';

