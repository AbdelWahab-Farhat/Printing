import 'package:dayaa/features/purchase_orders/models/purchase_order.dart';
import 'package:dayaa/features/purchase_orders/presentation/widgets/purchase_order_filter_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// تصفية أوامر الشراء — the sheet behind the button beside the search box.
///
/// This screen carried the four states as a scrolling row of chips across the top, and it failed
/// the way the orders list's did: «ملغى» lived off the edge of a row nothing suggested continued,
/// and the band cost height on every screen to say «الكل» almost all the time. What replaced it
/// is tested here — every state reachable, the choice applied on «تطبيق», and «الكل» told apart
/// from a dismissed sheet.
///
/// Arrange - Act - Assert throughout.
void main() {
  late PurchaseOrderStatus? applied;
  late bool wasApplied;

  setUp(() {
    applied = null;
    wasApplied = false;
  });

  /// A real phone, not the 800×600 the test binding defaults to.
  void useAPhone(WidgetTester tester) {
    tester.view
      ..physicalSize = const Size(430 * 3, 932 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  Widget host({PurchaseOrderStatus? selected}) => ScreenUtilInit(
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
          child: PurchaseOrderFilterButton(
            selected: selected,
            onApplied: (status) {
              applied = status;
              wasApplied = true;
            },
          ),
        ),
      ),
    ),
  );

  Future<void> openTheSheet(WidgetTester tester) async {
    await tester.tap(find.byType(PurchaseOrderFilterButton));
    await tester.pumpAndSettle();
  }

  Future<void> tapOption(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.text(label));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
    await tester.pump();
  }

  testWidgets('every state is on the sheet, and so is a way back to الكل', (tester) async {
    // Arrange
    useAPhone(tester);
    await tester.pumpWidget(host());

    // Act
    await openTheSheet(tester);

    // Assert — all four named before any order is loaded, which is why the enum carries its own
    // Arabic rather than reading a `status_label` off an order.
    for (final status in PurchaseOrderStatus.choices) {
      expect(find.text(status.label), findsOneWidget, reason: status.wire);
    }

    expect(find.text('الكل'), findsOneWidget);
  });

  testWidgets('picking a state answers only once تطبيق is pressed', (tester) async {
    // Arrange
    useAPhone(tester);
    await tester.pumpWidget(host());
    await openTheSheet(tester);

    // Act — tapped, but not yet applied.
    await tapOption(tester, 'ملغى');

    // Assert — a mis-tap is still correctable without reopening the sheet.
    expect(wasApplied, isFalse);

    // Act
    await tapOption(tester, 'تطبيق');
    await tester.pumpAndSettle();

    // Assert
    expect(wasApplied, isTrue);
    expect(applied, PurchaseOrderStatus.cancelled);
  });

  testWidgets('clearing the filter is an answer, and dismissing is not', (tester) async {
    // Arrange — a list already narrowed to «ملغى».
    useAPhone(tester);
    await tester.pumpWidget(host(selected: PurchaseOrderStatus.cancelled));
    await openTheSheet(tester);

    // Act — «مسح الفلاتر», then apply.
    await tapOption(tester, 'مسح الفلاتر');
    await tapOption(tester, 'تطبيق');
    await tester.pumpAndSettle();

    // Assert — «الكل» is a decision the list has to hear, and it travels as a sentinel precisely
    // because `showModalBottomSheet` answers null for a *dismissed* sheet.
    expect(wasApplied, isTrue);
    expect(applied, isNull);
  });

  testWidgets('a dismissed sheet changes nothing', (tester) async {
    // Arrange
    useAPhone(tester);
    await tester.pumpWidget(host(selected: PurchaseOrderStatus.cancelled));
    await openTheSheet(tester);

    // Act — picked something, then swiped the sheet away rather than applying.
    await tapOption(tester, 'جديد');
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    // Assert — the list stays where it was. Changing your mind must not be the same gesture as
    // clearing the filter.
    expect(wasApplied, isFalse);
  });

  testWidgets('the button says whether the list is narrowed before it is opened', (tester) async {
    // Arrange — the whole reason the states may live behind a tap.
    useAPhone(tester);

    // Act
    await tester.pumpWidget(host());

    // Assert — neutral on «الكل».
    final neutral = tester.widget<Material>(
      find.ancestor(of: find.byType(InkWell), matching: find.byType(Material)).first,
    );

    // Act
    await tester.pumpWidget(host(selected: PurchaseOrderStatus.cancelled));

    // Assert — filled once something is picked.
    final active = tester.widget<Material>(
      find.ancestor(of: find.byType(InkWell), matching: find.byType(Material)).first,
    );

    expect(active.color, isNot(neutral.color));
  });
}
