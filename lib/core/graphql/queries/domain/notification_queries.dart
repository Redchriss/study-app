const String kNotifications = r'''
query Notifications($unreadOnly: Boolean) {
  notifications(unreadOnly: $unreadOnly) {
    id
    notificationType
    message
    isRead
    createdAt
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


