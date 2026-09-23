import 'package:dayaa/core/widgets/filter_option_chip.dart';
import 'package:dayaa/features/investors/presentation/widgets/investor_profit_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// بطاقةُ الربح الواحدة: المجموعُ أولاً، ثم زرٌّ لكل بوّابة يُظهر رقمَها وحده.
///
/// Arrange - Act - Assert في كلٍّ منها.
void main() {
  Widget host() {
    return ScreenUtilInit(
      designSize: const Size(430, 932),
      builder: (context, _) => const MaterialApp(
        locale: Locale('ar'),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: InvestorProfitTile(
              awaitingDelivery: '750.00',
              pending: '1500.00',
              available: '300.50',
            ),
          ),
        ),
      ),
    );
  }

  FilterOptionChip chip(WidgetTester tester, String label) => tester.widget<FilterOptionChip>(
    find.ancestor(of: find.text(label), matching: find.byType(FilterOptionChip)),
  );

  testWidgets('opens on the total of the three gates', (tester) async {
    // Arrange
    final widget = host();

    // Act
    await tester.pumpWidget(widget);

    // Assert — 750 + 1,500 + 300.50، جمعٌ على السلسلة لا على `double`؛ و«الكل» هو المختار.
    expect(find.text('إجمالي الأرباح'), findsOneWidget);
    expect(find.text('2,550.5 د.ل'), findsOneWidget);
    expect(chip(tester, 'الكل').isSelected, isTrue);
    // لا شرحَ تحت الرقم — الاسمُ فوقه يكفيه.
    expect(find.text('ما لم يُسحب بعد'), findsNothing);
    expect(chip(tester, 'قيد التسليم').isSelected, isFalse);
  });

  testWidgets('a gate\'s button shows that gate alone, and «الكل» goes back to the total', (
    tester,
  ) async {
    // Arrange
    await tester.pumpWidget(host());

    // Act
    await tester.tap(find.text('قيد التسليم'));
    await tester.pump();

    // Assert
    expect(find.text('ربح قيد التسليم'), findsOneWidget);
    expect(find.text('750 د.ل'), findsOneWidget);
    expect(find.text('لا طلبيات في الطريق'), findsNothing);

    // Act
    await tester.tap(find.text('معلّقة'));
    await tester.pump();

    // Assert
    expect(find.text('أرباح معلّقة'), findsOneWidget);
    expect(find.text('1,500 د.ل'), findsOneWidget);
    expect(find.text('سُلِّمت — تُتاح بانتهاء فترتها وتحصيلها'), findsNothing);

    // Act
    await tester.tap(find.text('متاحة للسحب'));
    await tester.pump();

    // Assert
    expect(find.text('أرباح متاحة للسحب'), findsOneWidget);
    expect(find.text('300.5 د.ل'), findsOneWidget);

    // Act — الزرُّ نفسُه مرّةً ثانية يُبقيه، فالرجوعُ بـ«الكل» وحده.
    await tester.tap(find.text('متاحة للسحب'));
    await tester.pump();

    // Assert
    expect(find.text('أرباح متاحة للسحب'), findsOneWidget);
    expect(chip(tester, 'متاحة للسحب').isSelected, isTrue);

    // Act
    await tester.tap(find.text('الكل'));
    await tester.pump();

    // Assert
    expect(find.text('إجمالي الأرباح'), findsOneWidget);
    expect(find.text('2,550.5 د.ل'), findsOneWidget);
    expect(chip(tester, 'الكل').isSelected, isTrue);
    expect(chip(tester, 'متاحة للسحب').isSelected, isFalse);
  });
}
