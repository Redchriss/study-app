const String kNotifications = r'''
query Notifications($unreadOnly: Boolean) {
  notifications(unreadOnly: $unreadOnly) {
    id notificationType message link isRead createdAt
  }
  unreadNotificationCount
}
''';

const String kMarkAllNotificationsRead = r'''
mutation MarkAllNotificationsRead {
  markAllNotificationsRead { success }
}
''';
