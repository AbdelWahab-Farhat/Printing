import 'package:dayaa/features/notifications/models/app_notification.dart';
import 'package:flutter_test/flutter_test.dart';

/// The seam between `NotificationResource` and this app.
///
/// Every key asserted here is one the backend sends today — see
/// `backend/app/Application/Api/V1/Resources/NotificationResource.php`. A rename over there
/// fails here rather than showing up as a blank row in somebody's bell.
///
/// **The contract this file really defends is that nothing branches on `type`.** `title`, `body`,
/// `icon` and `route` all arrive rendered, which is what lets a notification type invented next
/// month appear in a build compiled today. So `type` is parsed and kept, and no test here asks
/// the model to *interpret* it.
///
/// Arrange - Act - Assert throughout.
void main() {
  test('parses a shortage notification, keys and all', () {
    // Arrange — one element of the `data` array from GET /notifications.
    final json = <String, dynamic>{
      'id': 412,
      'type': 'order.shortage',
      'type_label': 'نواقص طلبية',
      'title': 'طلبية O145 في النواقص',
      'body': 'العميل: مخبز الأمل',
      'icon': 'warning',
      'route': '/orders/145',
      'subject_type': 'order',
      'subject_id': 145,
      'is_read': false,
      'read_at': null,
      'created_at': '2026-09-07T09:14:22+02:00',
    };

    // Act
    final notification = AppNotification.fromJson(json);

    // Assert
    expect(notification.id, 412);
    expect(notification.type, 'order.shortage');
    expect(notification.typeLabel, 'نواقص طلبية');
    expect(notification.title, 'طلبية O145 في النواقص');
    expect(notification.body, 'العميل: مخبز الأمل');
    expect(notification.icon, 'warning');
    expect(notification.route, '/orders/145');
    expect(notification.subjectType, 'order');
    expect(notification.subjectId, 145);
    expect(notification.isRead, isFalse);
    expect(notification.readAt, isNull);
    expect(notification.createdAt, DateTime.parse('2026-09-07T09:14:22+02:00'));
  });

  test('an announcement carries no route, and that is not a malformed payload', () {
    // Arrange — a manual announcement has nothing to open, by design. This is the common
    // case, not an edge one.
    final json = <String, dynamic>{
      'id': 91,
      'type': 'announcement.manual',
      'type_label': 'إشعار عام',
      'title': 'اجتماع الساعة ٤',
      'body': 'في المكتب، الحضور إلزامي.',
      'icon': 'announcement',
      'route': null,
      'subject_type': null,
      'subject_id': null,
      'is_read': true,
      'read_at': '2026-09-07T10:00:00+02:00',
      'created_at': '2026-09-07T09:14:22+02:00',
    };

    // Act
    final notification = AppNotification.fromJson(json);

    // Assert — the tile must be able to ask "is there anywhere to go?" and be told no.
    expect(notification.route, isNull);
    expect(notification.opensSomewhere, isFalse);
    expect(notification.subjectType, isNull);
    expect(notification.subjectId, isNull);
    expect(notification.isRead, isTrue);
    expect(notification.readAt, DateTime.parse('2026-09-07T10:00:00+02:00'));
  });

  test('a route that is present makes the tile tappable', () {
    // Arrange
    final json = <String, dynamic>{
      'id': 1,
      'type': 'order.shortage',
      'type_label': 'نواقص طلبية',
      'title': 'ت',
      'body': 'ن',
      'icon': 'warning',
      'route': '/orders/9',
      'is_read': false,
      'created_at': '2026-09-07T09:14:22+02:00',
    };

    // Act
    final notification = AppNotification.fromJson(json);

    // Assert — and the absent optional keys parse as null rather than throwing.
    expect(notification.opensSomewhere, isTrue);
    expect(notification.subjectType, isNull);
    expect(notification.readAt, isNull);
  });
}
