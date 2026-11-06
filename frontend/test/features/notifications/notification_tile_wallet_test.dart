import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/features/notifications/models/app_notification.dart';
import 'package:dayaa/features/notifications/presentation/widgets/notification_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// إشعار «تحرّكت محفظتك» يُرسم بأيقونة المحفظة لا بالجرس الاحتياطي، وبلا مبلغ.
///
/// Arrange - Act - Assert throughout.
void main() {
  testWidgets('يُرسم بأيقونة المحفظة', (tester) async {
    // Arrange
    final notification = AppNotification(
      id: 1,
      type: 'employee_wallet.moved',
      typeLabel: 'حركة على محفظتك',
      title: 'أُضيف مبلغ إلى محفظتك',
      body: 'اضغط لعرض رصيدك',
      icon: 'wallet',
      route: '/my-wallet',
      isRead: false,
      createdAt: DateTime(2026, 11, 6),
    );

    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: NotificationTile(notification: notification)),
      ),
    );

    // Assert
    expect(find.byIcon(AppIcons.wallet), findsOneWidget);
    expect(find.byIcon(AppIcons.notifications), findsNothing);
  });
}
