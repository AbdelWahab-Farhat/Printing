import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/filter_option_chip.dart';
import 'package:dayaa/features/orders/models/additional_cost_reason.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/presentation/widgets/additional_cost_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// Charging the customer for what no line on the order describes.
///
/// The sheet answers with what was typed and sends nothing — the split every form on the order
/// screen follows. What it *does* own are the server's two rules, checked here so the refusal is
/// instant: an amount needs a category, and «أخرى» needs words.
///
/// Arrange - Act - Assert throughout.
void main() {
  Order order({
    String cost = '0.00',
    AdditionalCostReason? reason,
    String? note,
  }) => Order(
    id: 1,
    code: '1',
    status: OrderStatus.ready,
    statusLabel: 'جاهزة',
    isFinal: false,
    customerId: 10,
    cityId: 1,
    designSource: 'customer',
    cityName: 'طرابلس',
    fulfilmentTypeLabel: 'توصيل',
    isOfficePickup: false,
    designSourceLabel: 'من الزبون',
    itemsTotal: '110.00',
    designFee: '0.00',
    deliveryPrice: '0.00',
    discount: '0.00',
    additionalCost: cost,
    additionalCostReason: reason,
    additionalCostNote: note,
    grandTotal: '110.00',
    remainingAmount: '110.00',
    paymentStatusLabel: 'غير مدفوعة',
  );

  /// Opens the sheet the way the order screen does, and hands back a way to read what it
  /// answered — which is only known once it has closed.
  Future<ValueGetter<AdditionalCostDraft?>> open(WidgetTester tester, Order subject) async {
    AdditionalCostDraft? draft;

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(430, 932),
        builder: (context, _) => MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    draft = await showAdditionalCostSheet(context: context, order: subject);
                  },
                  child: const Text('افتح'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('افتح'));
    await tester.pumpAndSettle();

    return () => draft;
  }

  testWidgets('the five categories are the whole vocabulary, and «غير معروف» is not one', (
    tester,
  ) async {
    // Arrange
    await open(tester, order());

    // Act
    final chips = tester.widgetList<FilterOptionChip>(find.byType(FilterOptionChip));

    // Assert
    expect(chips.length, 5);
    expect(find.text('تغليف خاص'), findsOneWidget);
    expect(find.text('أخرى'), findsOneWidget);
    expect(find.text('غير معروف'), findsNothing);
  });

  testWidgets('it opens on what the order already carries', (tester) async {
    // Arrange — correcting «١٠» to «١٥» should be one keystroke, not a retype.
    await open(
      tester,
      order(cost: '10.00', reason: AdditionalCostReason.transport, note: 'نقل للفرع'),
    );

    // Act
    final chip = tester.widget<FilterOptionChip>(
      find.widgetWithText(FilterOptionChip, 'نقل'),
    );

    // Assert — the padded decimals a database keeps are trimmed off the way in.
    expect(find.text('10'), findsOneWidget);
    expect(find.text('نقل للفرع'), findsOneWidget);
    expect(chip.isSelected, isTrue);
  });

  testWidgets('an amount with no category cannot be saved', (tester) async {
    // Arrange
    await open(tester, order());

    // Act
    await tester.enterText(find.byType(TextFormField).first, '10');
    await tester.pumpAndSettle();

    // Assert — the server's own rule, and a button that waits rather than one that argues back.
    expect(find.text('اختر سبب التكلفة الإضافية'), findsOneWidget);
    expect(tester.widget<AppButton>(find.byType(AppButton)).onPressed, isNull);
  });

  testWidgets('«أخرى» is refused without words of its own', (tester) async {
    // Arrange
    await open(tester, order());
    await tester.enterText(find.byType(TextFormField).first, '25');
    await tester.tap(find.text('أخرى'));
    await tester.pumpAndSettle();

    // Act — save with the note still empty.
    await tester.tap(find.byType(AppButton));
    await tester.pumpAndSettle();

    // Assert — the sheet stays open and says which field it is.
    expect(find.text('اكتب سبب التكلفة الإضافية عند اختيار «أخرى»'), findsOneWidget);
  });

  testWidgets('a charge is answered as it was typed, category and all', (tester) async {
    // Arrange
    final answer = await open(tester, order());
    await tester.enterText(find.byType(TextFormField).first, '١٠٫٥');
    await tester.tap(find.text('تغليف خاص'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).last, 'علبة كرتون مزدوجة');

    // Act
    await tester.tap(find.byType(AppButton));
    await tester.pumpAndSettle();

    // Assert — the digits are handed over exactly as the keyboard produced them: normalising
    // happens in one place, on the way to the server.
    expect(answer()?.amount, '١٠٫٥');
    expect(answer()?.reason, AdditionalCostReason.specialPackaging);
    expect(answer()?.note, 'علبة كرتون مزدوجة');
  });

  testWidgets('clearing the box answers with an empty amount and no category', (tester) async {
    // Arrange — «أفرغ الحقل لإلغائها»: the gesture that removes a charge.
    final answer = await open(
      tester,
      order(cost: '10.00', reason: AdditionalCostReason.transport),
    );

    // Act
    await tester.enterText(find.byType(TextFormField).first, '');
    await tester.pumpAndSettle();
    await tester.tap(find.byType(AppButton));
    await tester.pumpAndSettle();

    // Assert — the category goes with the money, and the use case turns the empty box into the
    // «٠٫٠٠» the server needs to hear.
    expect(answer()?.amount, isEmpty);
    expect(answer()?.reason, isNull);
  });
}
