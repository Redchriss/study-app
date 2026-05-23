const String kNotifications = r'''
query Notifications($onlyUnread: Boolean, $notifType: String, $limit: Int, $after: String) {
  notifications(onlyUnread: $onlyUnread, notifType: $notifType, limit: $limit, after: $after) {
    edges {
      cursor
      node {
        id notifType isRead bodyPreview
        community { slug name }
        post { id slug }
        comment { id }
        createdAt
      }
    }
    pageInfo { hasNextPage endCursor }
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
