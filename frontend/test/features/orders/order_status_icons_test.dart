import 'package:dayaa/core/theme/theme.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The legend behind [OrderStatusChip.iconFor].
///
/// **حالةٌ لها أيقونة تشبه أيقونة حالة أخرى لا أيقونة لها.** الشريط والبطاقة وصفحة النقل ترسم
/// جميعها من هذا الجدول، فإن تشارك «جاهزة» و«تم الاستلام» نفس الصح، أو الرواجع الثلاثة نفس
/// السهم، فالموظف يقرأ الكلمة لا الشكل — وهو بالضبط ما كانت الأيقونة لتوفّره عليه.
///
/// Arrange - Act - Assert.
void main() {
  test('every status carries a glyph of its own', () {
    // Arrange — the whole enum, `unknown` included: a status this build never heard of still
    // gets drawn, and it must not borrow another state's shape.
    const statuses = OrderStatus.values;

    // Act
    final glyphs = <IconData>{for (final status in statuses) OrderStatusChip.iconFor(status)};

    // Assert
    expect(glyphs.length, statuses.length);
  });

  test('the three returns are told apart by their glyph, not by their words', () {
    // Arrange — «راجع لدى المندوب» و«راجع لدى شركة التوصيل» و«راجع مكتب» أطول من أن تُقرأ في
    // قائمة، وهي الحالات التي يُبحث عنها أكثر من غيرها.
    const returns = [
      OrderStatus.returnedCourier,
      OrderStatus.returnedCarrier,
      OrderStatus.returnedOffice,
    ];

    // Act
    final glyphs = <IconData>{for (final status in returns) OrderStatusChip.iconFor(status)};

    // Assert
    expect(glyphs.length, 3);
  });

  group('the wash a row wears when it only *names* a status', () {
    final scheme = MaterialTheme.lightScheme();

    test('every tone washes the surface without becoming the full container', () {
      // Arrange — صفحة «تغيير الحالة» تعرض الوجهات كلها معاً: المختارة تأخذ لون الحالة كاملاً،
      // وغير المختارة كانت رمادية بلا هوية.
      for (final tone in OrderStatusTone.values) {
        // Act
        final tint = OrderStatusChip.tintFor(scheme, tone);

        // Assert
        expect(tint, isNot(scheme.surfaceContainerLow), reason: '$tone');
        expect(tint, isNot(scheme.surfaceContainerLowest), reason: '$tone');
        expect(tint, isNot(OrderStatusChip.toneColour(scheme, tone).$1), reason: '$tone');
      }
    });

    test('two tones that look different still look different washed', () {
      // Arrange — الغسل يخفّف اللون ولا يمحوه؛ ولو قرّب النغمات من بعضها لصار زينة بلا معنى.
      // النغمات التي تتقاسم أصلاً حاويةً واحدة — «قيد العمل» و«في الطريق» مثلاً — تبقى واحدة.

      // Act
      final attention = OrderStatusChip.tintFor(scheme, OrderStatusTone.attention);
      final ready = OrderStatusChip.tintFor(scheme, OrderStatusTone.ready);
      final fresh = OrderStatusChip.tintFor(scheme, OrderStatusTone.fresh);

      // Assert
      expect(attention, isNot(ready));
      expect(ready, isNot(fresh));
      expect(fresh, isNot(attention));
    });
  });
}
