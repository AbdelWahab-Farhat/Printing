import 'dart:io';

import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:flutter_test/flutter_test.dart';

/// اختيارات «طلباتي»: «كل الحالات»، ثم المراحل العشر كلها بترتيب ما تمرّ به الطلبية (طلب
/// المستخدم، 2026-09-25).
///
/// Arrange - Act - Assert throughout.
void main() {
  CustomerOrder at(OrderStage stage) =>
      CustomerOrder(id: 1, code: '1228', stage: stage, stageLabel: stage.name);

  test('«كل الحالات» first, then every stage in the order an order walks them', () {
    // Arrange
    const filters = OrdersFilter.values;

    // Act
    final labels = filters.map((filter) => filter.label).toList();

    // Assert
    expect(labels, [
      'كل الحالات',
      'بانتظار المراجعة',
      'قيد التجهيز',
      'قيد التصميم',
      'قيد الإنتاج',
      'جاهزة',
      'جاري التوصيل',
      'تم الاستلام',
      'مرتجعة',
      'ملغاة',
      'مرفوضة',
    ]);
  });

  test('every stage this build can name can be chosen, and «unknown» cannot', () {
    // Arrange
    final named = OrderStage.values.where((stage) => stage != OrderStage.unknown).toSet();

    // Act
    final chipped = OrdersFilter.values.map((filter) => filter.stage).nonNulls.toSet();

    // Assert
    expect(chipped, named);
  });

  /// الاسم الذي على السلك لا اسم العضو في Dart: `underReview` ليست `under_review`، وهذا خطأٌ
  /// شُحن مرةً في هذا التطبيق بلا أي عَرَضٍ ظاهر.
  test('each choice asks the server in its own spelling, and «كل الحالات» asks for nothing', () {
    // Arrange
    const filters = OrdersFilter.values;

    // Act
    final parameters = {for (final filter in filters) filter: filter.stageParameter};

    // Assert
    expect(parameters, {
      OrdersFilter.all: null,
      OrdersFilter.underReview: 'under_review',
      OrdersFilter.preparing: 'preparing',
      OrdersFilter.designing: 'designing',
      OrdersFilter.producing: 'producing',
      OrdersFilter.ready: 'ready',
      OrdersFilter.onTheWay: 'on_the_way',
      OrdersFilter.delivered: 'delivered',
      OrdersFilter.returned: 'returned',
      OrdersFilter.cancelled: 'cancelled',
      OrdersFilter.rejected: 'rejected',
    });
  });

  test('an order belongs under its own stage and under «كل الحالات», and nowhere else', () {
    // Arrange
    final order = at(OrderStage.producing);

    // Act
    final admitting = OrdersFilter.values.where((filter) => filter.admits(order)).toList();

    // Assert
    expect(admitting, [OrdersFilter.all, OrdersFilter.producing]);
  });

  /// الاختيارات تُكتب في التطبيق لأن لا طلبية في اليد تُقرأ منها كلمتها، واختيارٌ لا طلبية خلفه
  /// هو بالضبط الذي قد يُسأل عنه. فتُمسك هنا بكلمات الخادم نفسها، مقروءةً من ملف PHP.
  test('the choices say what the server says on the orders they select', () {
    // Arrange
    final source = File('../backend/app/Domain/Order/Enums/CustomerOrderStage.php');
    if (!source.existsSync()) {
      markTestSkipped('backend not checked out beside this one');

      return;
    }
    final php = source.readAsStringSync();
    final labelBlock = RegExp(
      r'function label\(\): string\s*\{\s*return match \(\$this\) \{(.*?)\};',
      dotAll: true,
    ).firstMatch(php);

    // Act
    final serverLabels = {
      for (final match in RegExp(r"self::(\w+) => '([^']+)'").allMatches(labelBlock!.group(1)!))
        match.group(1)!: match.group(2)!,
    };

    // Assert
    String caseOf(OrderStage stage) => stage.name[0].toUpperCase() + stage.name.substring(1);
    for (final filter in OrdersFilter.values.skip(1)) {
      expect(filter.label, serverLabels[caseOf(filter.stage!)], reason: filter.name);
    }
  });
}
