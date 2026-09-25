import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:dayaa_client/features/orders/presentation/views/stage_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// أيقونة كل مرحلة هي أيقونة حالة الورشة المقابلة لها في تطبيق الموظفين
/// (`OrderStatusChip.iconFor` هناك)، فيرى العميل الشكل نفسه الذي يراه الموظف (طلب المستخدم،
/// 2026-09-25).
///
/// Arrange - Act - Assert throughout.
void main() {
  test('each stage wears the icon of the workshop status it stands for', () {
    // Arrange
    final expected = <OrderStage, IconData>{
      // requested
      OrderStage.underReview: AppIcons.comments,
      // taken — «جديدة»، أول ما في «قيد التجهيز»
      OrderStage.preparing: AppIcons.statusNew,
      OrderStage.designing: AppIcons.designs,
      // printing — المطبعة نفسها
      OrderStage.producing: AppIcons.printedProduct,
      OrderStage.ready: AppIcons.activate,
      OrderStage.onTheWay: AppIcons.outForDelivery,
      OrderStage.delivered: AppIcons.ordersReceived,
      // returnedCourier — أول الرواجع
      OrderStage.returned: AppIcons.returnedCourier,
      OrderStage.cancelled: AppIcons.ordersCancelled,
      // requestRejected
      OrderStage.rejected: AppIcons.close,
      OrderStage.unknown: AppIcons.unknownStatus,
    };

    // Act
    final actual = {for (final stage in OrderStage.values) stage: stageIcon(stage)};

    // Assert
    expect(actual, expected);
  });
}
