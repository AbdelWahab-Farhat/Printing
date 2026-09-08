import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/features/orders/models/orders_sort.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_sort_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// ترتيب القائمة، بضغطةٍ واحدة.
///
/// **كان شريحةً في ورقة التصفية ونُزع.** الشرائح كلّها هناك تُنقص من القائمة، والترتيب لا يُنقص
/// شيئاً — فشريحةٌ لا تصغّر النتيجة بين شرائحَ تصغّرها تُقرأ كفلترٍ لا يعمل؛ وكانت فوق ذلك تكلّف
/// ثلاث ضغطات (فتحٌ واختيارٌ و«تطبيق») لسؤالٍ بجوابين.
///
/// Arrange - Act - Assert throughout.
void main() {
  late OrdersSort? toggledTo;

  setUp(() => toggledTo = null);

  Widget host(OrdersSort sort) => ScreenUtilInit(
    designSize: const Size(430, 932),
    builder: (context, _) => MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: Center(
          child: OrderSortButton(
            sort: sort,
            onToggled: (next) => toggledTo = next,
          ),
        ),
      ),
    ),
  );

  testWidgets('one tap turns the list round', (tester) async {
    // Arrange
    await tester.pumpWidget(host(OrdersSort.newest));

    // Act
    await tester.tap(find.byType(OrderSortButton));
    await tester.pump();

    // Assert — no sheet, no «تطبيق»: the whole control is the tap.
    expect(toggledTo, OrdersSort.oldest);
  });

  testWidgets('and the next tap turns it back', (tester) async {
    // Arrange
    await tester.pumpWidget(host(OrdersSort.oldest));

    // Act
    await tester.tap(find.byType(OrderSortButton));
    await tester.pump();

    // Assert
    expect(toggledTo, OrdersSort.newest);
  });

  testWidgets('the arrow says which way the list runs now', (tester) async {
    // Arrange — a button showing the state it *would* move to makes the reader work out the
    // current one before every tap.
    await tester.pumpWidget(host(OrdersSort.newest));

    // Act - Assert
    expect(find.byIcon(AppIcons.sortNewest), findsOneWidget);

    // Act
    await tester.pumpWidget(host(OrdersSort.oldest));

    // Assert
    expect(find.byIcon(AppIcons.sortOldest), findsOneWidget);
  });

  testWidgets('a list running backwards is visible without opening anything', (tester) async {
    // Arrange — «الأقدم أولاً» is a state somebody has to be able to notice from the screen
    // they are already on, the same way a narrowed list fills the filter button.
    await tester.pumpWidget(host(OrdersSort.newest));
    final button = find.descendant(
      of: find.byType(OrderSortButton),
      matching: find.byType(Material),
    );

    // Act
    final neutral = tester.widget<Material>(button.first).color;
    await tester.pumpWidget(host(OrdersSort.oldest));
    final active = tester.widget<Material>(button.first).color;

    // Assert
    expect(active, isNot(neutral));
  });

  testWidgets('the word is behind the arrow for anyone who needs it', (tester) async {
    // Arrange — a glyph alone says «up» to somebody who has not tapped it yet.
    await tester.pumpWidget(host(OrdersSort.oldest));

    // Act
    final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));

    // Assert
    expect(tooltip.message, OrdersSort.oldest.label);
  });
}
