import 'package:dayaa/features/purchase_orders/models/purchase_order.dart';
import 'package:dayaa/features/purchase_orders/models/purchase_order_counts.dart';
import 'package:dayaa/features/purchase_orders/models/purchase_orders_filter.dart';
import 'package:dayaa/features/vendors/presentation/viewmodel/vendor_purchase_order_counts_cubit.dart';
import 'package:dayaa/features/vendors/presentation/widgets/vendor_purchase_orders_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// «إدارة أوامر الشراء» on the supplier screen — four ways into one supplier's orders.
///
/// **What is worth proving is that each row opens what its label promises.** A row reading
/// «المكتملة» that opens every supplier's paperwork is the failure this section exists to avoid,
/// and it is invisible to anybody reading the screen.
///
/// Arrange - Act - Assert throughout.
void main() {
  const counts = PurchaseOrderCounts(
    byStatus: {'new': 2, 'arrived': 1, 'completed': 9, 'cancelled': 3},
    total: 15,
  );

  late List<PurchaseOrdersFilter> opened;

  setUp(() => opened = <PurchaseOrdersFilter>[]);

  Widget host({VendorPurchaseOrderCountsState? state}) => ScreenUtilInit(
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
          child: VendorPurchaseOrdersSection(
            vendorId: 4,
            vendorName: 'مصنع الصفا',
            state: state ?? const VendorPurchaseOrderCountsState.loaded(counts),
            onOpen: opened.add,
          ),
        ),
      ),
    ),
  );

  testWidgets('it offers the four ways in', (tester) async {
    // Arrange & Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('كل أوامر الشراء'), findsOneWidget);
    expect(find.text('أوامر الشراء الجارية'), findsOneWidget);
    expect(find.text('أوامر الشراء المكتملة'), findsOneWidget);
    expect(find.text('أوامر الشراء الملغاة'), findsOneWidget);
  });

  testWidgets('each row carries its own number', (tester) async {
    // Arrange & Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — 15 in all, 3 still owed a move (2 drafted + 1 on its way), 9 fully received,
    // 3 written off.
    expect(find.text('15'), findsOneWidget);
    expect(find.text('9'), findsOneWidget);
    expect(find.text('3'), findsNWidgets(2));
  });

  testWidgets('«كل أوامر الشراء» asks for this supplier and no status', (tester) async {
    // Arrange
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('كل أوامر الشراء'));
    await tester.pumpAndSettle();

    // Assert
    expect(opened.single.vendorId, 4);
    expect(opened.single.statuses, isEmpty, reason: 'كل means every status, cancellations too');
  });

  testWidgets('«الجارية» asks for the drafted and the ones on their way', (tester) async {
    // Arrange
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('أوامر الشراء الجارية'));
    await tester.pumpAndSettle();

    // Assert — the same group the number above it was added up from, or the tap contradicts the
    // count beside it.
    expect(opened.single.vendorId, 4);
    expect(opened.single.statuses, ['new', 'arrived']);
  });

  testWidgets('«المكتملة» asks for completed alone', (tester) async {
    // Arrange
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('أوامر الشراء المكتملة'));
    await tester.pumpAndSettle();

    // Assert
    expect(opened.single.vendorId, 4);
    expect(opened.single.statuses, ['completed']);
  });

  testWidgets('«الملغاة» asks for the cancellations alone', (tester) async {
    // Arrange
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('أوامر الشراء الملغاة'));
    await tester.pumpAndSettle();

    // Assert — its own box, not something to be dug out of «الكل».
    expect(opened.single.vendorId, 4);
    expect(opened.single.statuses, PurchaseOrderStatus.cancellations.map((s) => s.wire).toList());
  });

  testWidgets('the screen each row opens says whose orders it is showing', (tester) async {
    // Arrange
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('أوامر الشراء الجارية'));
    await tester.pumpAndSettle();

    // Assert — the title travels with the filter because the destination has no other way to
    // name the supplier: it was handed an id, not a vendor.
    expect(opened.single.title, contains('مصنع الصفا'));
  });

  testWidgets('counts that could not be read leave the rows open and bare', (tester) async {
    // Arrange & Act
    await tester.pumpWidget(host(state: const VendorPurchaseOrderCountsState.loading()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('أوامر الشراء الجارية'));
    await tester.pumpAndSettle();

    // Assert — reaching a supplier's orders must not depend on having counted them first.
    expect(opened, hasLength(1));
    expect(find.text('15'), findsNothing);
  });
}
