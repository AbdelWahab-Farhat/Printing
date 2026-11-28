import 'package:dayaa/features/home/models/home_summary.dart';
import 'package:dayaa/features/home/presentation/widgets/instant_board_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// The branch counter's board on the home screen — INSTANT-ORDERS-PLAN.md §11.
///
/// Arrange - Act - Assert throughout.
void main() {
  Widget host(InstantBoard board, {VoidCallback? onNewOrder, VoidCallback? onOpenLate}) {
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
          body: SingleChildScrollView(
            child: InstantBoardSection(
              board: board,
              onNewOrder: onNewOrder ?? () {},
              onOpenStatus: (_) {},
              onOpenLate: onOpenLate ?? () {},
            ),
          ),
        ),
      ),
    );
  }

  const statuses = [
    OrderStatusCount(status: 'new', label: 'جديدة', count: 3),
    OrderStatusCount(status: 'delivered', label: 'تم الاستلام', count: 1),
    OrderStatusCount(status: 'cancelled', label: 'إلغاء تام', count: 0),
    OrderStatusCount(status: 'settled', label: 'تم التسوية', count: 9),
  ];

  testWidgets('without a branch the button is drawn disabled and says why', (tester) async {
    // Arrange
    var opened = false;
    await tester.pumpWidget(
      host(const InstantBoard(canCreate: true, statuses: statuses), onNewOrder: () => opened = true),
    );

    // Act
    await tester.tap(find.text('طلب فوري'));
    await tester.pump();

    // Assert
    expect(opened, isFalse);
    expect(find.text('لا يوجد فرع نشط مُسنَد لك — راجع الإدارة'), findsOneWidget);
  });

  testWidgets('with a branch the button opens the form and the counters are drawn', (tester) async {
    // Arrange
    var opened = false;
    await tester.pumpWidget(
      host(
        const InstantBoard(
          canCreate: true,
          branches: [BranchRef(id: 7, name: 'مكتب قرجي')],
          statuses: statuses,
          pickupCount: 4,
        ),
        onNewOrder: () => opened = true,
      ),
    );

    // Act
    await tester.tap(find.text('طلب فوري'));
    await tester.pump();

    // Assert — only the two statuses the counter works, though the server sent four
    expect(opened, isTrue);
    expect(find.text('جديدة'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('تم الاستلام'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('إلغاء تام'), findsNothing);
    expect(find.textContaining('تم التسوية'), findsNothing);
    // The «استلام مكتب» card is gone with its heading, though the server still counts it.
    expect(find.text('طلبات الحجز'), findsNothing);
    expect(find.text('استلام مكتب'), findsNothing);
    expect(find.text('4'), findsNothing);
    // No late orders, no late card.
    expect(find.textContaining('متأخرة'), findsNothing);
  });

  testWidgets('late orders get their own card, which opens their list', (tester) async {
    // Arrange
    var opened = false;
    await tester.pumpWidget(
      host(
        const InstantBoard(statuses: statuses, lateCount: 2, lateAfterHours: 24),
        onOpenLate: () => opened = true,
      ),
    );

    // Act
    await tester.tap(find.text('متأخرة (أكثر من 24 ساعة)'));
    await tester.pump();

    // Assert
    expect(opened, isTrue);
    // A reader who cannot sell sees the counters, and no button at all.
    expect(find.text('طلب فوري'), findsNothing);
  });
}
