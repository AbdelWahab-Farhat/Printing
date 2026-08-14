import 'package:dayaa/features/customers/models/customers_filter.dart';
import 'package:dayaa/features/customers/presentation/widgets/customers_filter_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// The sheet behind the button beside the search box: «زبائن بدون طلب» and «الأقدم طلباً».
///
/// Arrange - Act - Assert throughout.
void main() {
  /// The same frame the app boots into: ScreenUtil at the reference size, Arabic, RTL.
  Widget host(Widget child) {
    return ScreenUtilInit(
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
          body: Directionality(textDirection: TextDirection.rtl, child: Center(child: child)),
        ),
      ),
    );
  }

  testWidgets('the sheet answers with both questions on one «تطبيق»', (tester) async {
    // Arrange
    CustomersFilter? applied;
    await tester.pumpWidget(
      host(
        CustomersFilterButton(
          filter: CustomersFilter.none,
          onApplied: (filter) => applied = filter,
        ),
      ),
    );

    // Act
    await tester.tap(find.byType(CustomersFilterButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('بدون طلبات'));
    await tester.tap(find.text('الأقدم طلباً'));
    await tester.pump();
    await tester.tap(find.text('تطبيق'));
    await tester.pumpAndSettle();

    // Assert — one callback carrying both, not one per tap: two would fetch the list twice for
    // a single «تطبيق».
    expect(applied, const CustomersFilter(hasOrders: false, leastRecentOrderFirst: true));
  });

  testWidgets('the orders question has three answers, and picking one drops the last', (
    tester,
  ) async {
    // Arrange
    CustomersFilter? applied;
    await tester.pumpWidget(
      host(
        CustomersFilterButton(
          filter: const CustomersFilter(hasOrders: false),
          onApplied: (filter) => applied = filter,
        ),
      ),
    );

    // Act — «لديهم طلبات» over «بدون طلبات»: these replace each other, they do not add up.
    await tester.tap(find.byType(CustomersFilterButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('لديهم طلبات'));
    await tester.pump();
    await tester.tap(find.text('تطبيق'));
    await tester.pumpAndSettle();

    // Assert
    expect(applied, const CustomersFilter(hasOrders: true));
  });

  testWidgets('«الكل» is a way back to the whole register', (tester) async {
    // Arrange
    CustomersFilter? applied;
    await tester.pumpWidget(
      host(
        CustomersFilterButton(
          filter: const CustomersFilter(hasOrders: true),
          onApplied: (filter) => applied = filter,
        ),
      ),
    );

    // Act
    await tester.tap(find.byType(CustomersFilterButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الكل'));
    await tester.pump();
    await tester.tap(find.text('تطبيق'));
    await tester.pumpAndSettle();

    // Assert — null, not false: «الكل» must not come back as «بدون طلبات», which is the bug a
    // two-state flag would have made unavoidable.
    expect(applied?.hasOrders, isNull);
  });

  testWidgets('the sheet opens on the answers already given', (tester) async {
    // Arrange
    await tester.pumpWidget(
      host(
        CustomersFilterButton(
          filter: const CustomersFilter(hasOrders: false),
          onApplied: (_) {},
        ),
      ),
    );

    // Act
    await tester.tap(find.byType(CustomersFilterButton));
    await tester.pumpAndSettle();

    // Assert — «مسح الفلاتر» appears only when there is something to clear, so its presence is
    // the sheet saying it knows the list is already narrowed.
    expect(find.text('مسح الفلاتر'), findsOneWidget);
  });

  testWidgets('«مسح الفلاتر» hands back the plain list rather than closing the sheet', (
    tester,
  ) async {
    // Arrange
    CustomersFilter? applied;
    await tester.pumpWidget(
      host(
        CustomersFilterButton(
          filter: const CustomersFilter(hasOrders: false, leastRecentOrderFirst: true),
          onApplied: (filter) => applied = filter,
        ),
      ),
    );

    // Act
    await tester.tap(find.byType(CustomersFilterButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('مسح الفلاتر'));
    await tester.pump();
    await tester.tap(find.text('تطبيق'));
    await tester.pumpAndSettle();

    // Assert
    expect(applied, CustomersFilter.none);
  });

  testWidgets('closing the sheet without applying changes nothing', (tester) async {
    // Arrange
    var applications = 0;
    await tester.pumpWidget(
      host(
        CustomersFilterButton(filter: CustomersFilter.none, onApplied: (_) => applications++),
      ),
    );

    // Act — ticking an option and dismissing is «غيّرت رأيي», and the list must not move.
    await tester.tap(find.byType(CustomersFilterButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('بدون طلبات'));
    await tester.pump();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    // Assert
    expect(applications, 0);
  });
}
