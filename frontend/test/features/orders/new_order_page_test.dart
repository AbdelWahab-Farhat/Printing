import 'package:dartz/dartz.dart' hide Order;
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/customers/models/customer.dart';
import 'package:dayaa/features/customers/presentation/viewmodel/customer_detail_cubit.dart';
import 'package:dayaa/features/customers/repositories/customer_repository.dart';
import 'package:dayaa/features/customers/usecases/get_customer.dart';
import 'package:dayaa/features/customers/usecases/set_customer_activation.dart';
import 'package:dayaa/features/orders/models/new_order.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/line_quote_cubit.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/take_order_cubit.dart';
import 'package:dayaa/features/orders/presentation/views/new_order_page.dart';
import 'package:dayaa/features/orders/repositories/order_repository.dart';
import 'package:dayaa/features/orders/usecases/take_order.dart';
import 'package:dayaa/features/products/repositories/product_repository.dart';
import 'package:dayaa/features/products/usecases/get_price_quote.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// طلبية جديدة, as it is seen.
///
/// Real Cubits, real use cases, fake repositories — so the permission gates and the rule that
/// the customer is read rather than chosen are exercised rather than described.
///
/// Arrange - Act - Assert throughout.
class _MockCustomerRepository extends Mock implements CustomerRepository {}

class _MockOrderRepository extends Mock implements OrderRepository {}

class _MockProductRepository extends Mock implements ProductRepository {}

class _FakeNewOrder extends Fake implements NewOrder {}

void main() {
  late _MockCustomerRepository customers;
  late _MockOrderRepository orders;
  late _MockProductRepository products;
  late Session session;

  const customer = Customer(
    id: 7,
    code: 'C7',
    name: 'مطبعة النور',
    phone: '0913334444',
    isActive: true,
    shops: [CustomerShop(id: 3, name: 'فرع سوق الجمعة')],
  );

  setUpAll(() => registerFallbackValue(_FakeNewOrder()));

  AuthUser userWith(List<String> permissions) =>
      AuthUser(id: 1, name: 'عبدالوهاب', phone: '0911234567', permissions: permissions);

  setUp(() async {
    await Injector.reset();

    customers = _MockCustomerRepository();
    orders = _MockOrderRepository();
    products = _MockProductRepository();
    session = Session();

    when(() => customers.customer(7)).thenAnswer((_) async => const Right(customer));

    sl
      ..registerSingleton<Session>(session)
      ..registerFactoryParam<CustomerDetailCubit, int, void>(
        (customerId, _) => CustomerDetailCubit(
          customerId: customerId,
          getCustomer: GetCustomer(customers),
          setActivation: SetCustomerActivation(customers),
        ),
      )
      ..registerFactoryParam<TakeOrderCubit, int, void>(
        (customerId, _) =>
            TakeOrderCubit(takeOrder: TakeOrder(orders), customerId: customerId),
      )
      ..registerFactory<LineQuoteCubit>(
        () => LineQuoteCubit(getPriceQuote: GetPriceQuote(products)),
      );
  });

  tearDown(Injector.reset);

  Widget host() => ScreenUtilInit(
    designSize: const Size(430, 932),
    builder: (context, _) => const MaterialApp(
      locale: Locale('ar'),
      supportedLocales: [Locale('ar')],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: NewOrderPage(customerId: 7),
    ),
  );

  testWidgets('the customer is stated, and there is no way to change them', (tester) async {
    // Arrange — the whole reason this form lives inside a customer: `customer_id` is read on
    // create and ignored afterwards, so a box that could name the wrong one would be a mistake
    // only a cancellation can undo.
    session.adopt(userWith(['orders.manage']));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('مطبعة النور'), findsOneWidget);
    expect(find.text('C7'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'العميل'), findsNothing);
  });

  testWidgets('the discount box is only there for somebody who may discount', (tester) async {
    // Arrange
    session.adopt(userWith(['orders.manage']));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — a courtesy; `orders.discount` is enforced inside the domain either way.
    expect(find.text('قيمة الخصم'), findsNothing);
  });

  testWidgets('and it is there for somebody who may', (tester) async {
    // Arrange
    session.adopt(userWith(['orders.manage', 'orders.discount']));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    // Below the fold on a phone, and a `ListView` does not build what is off screen.
    await tester.dragUntilVisible(
      find.text('قيمة الخصم'),
      find.byType(ListView),
      const Offset(0, -200),
    );

    // Assert
    expect(find.text('قيمة الخصم'), findsOneWidget);
  });

  testWidgets('the design fee appears only when the design is ours', (tester) async {
    // Arrange — the fee is the one thing `design_source` changes about the money, and the
    // server only counts it for `in_house`.
    session.adopt(userWith(['orders.manage']));
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    expect(find.text('أجرة التصميم'), findsNothing);

    // Act
    await tester.tap(find.text('من عندنا'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('أجرة التصميم'), findsOneWidget);
  });

  testWidgets('artwork is chosen while the order is being taken', (tester) async {
    // Arrange — this is the reversal of NEW-ORDER-DESIGN.md §٧ س٣. The customer very often walks
    // in with the finished file; recording it used to mean creating the order, opening it, and
    // walking it through «قيد التصميم» for work nobody was doing.
    session.adopt(userWith(['orders.manage']));
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('تصميم العميل'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('اختيار التصميم'), findsOneWidget);
  });

  testWidgets('our own work is offered the picker too', (tester) async {
    // Arrange — `design_source` answers whose work the artwork was, which is the question that
    // moves money. Whether a file exists yet is a different one, and our designer often
    // finishes before the order is taken.
    session.adopt(userWith(['orders.manage']));
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('من عندنا'));
    await tester.pumpAndSettle();

    // Assert — the fee and the files, side by side.
    expect(find.text('أجرة التصميم'), findsOneWidget);
    expect(find.text('اختيار التصميم'), findsOneWidget);
  });

  testWidgets('«بدون تصميم» is not offered a file to pick', (tester) async {
    // Arrange — that source means a repeat print of something already agreed, or plain bags.
    // There is no file, and the use case drops any that were picked before the switch.
    session.adopt(userWith(['orders.manage']));

    // Act — the default, untouched.
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — and nothing is said about it either: the segment is the whole answer.
    expect(find.text('اختيار التصميم'), findsNothing);
    expect(find.textContaining('طلبية بلا تصميم'), findsNothing);
  });

  testWidgets('an order with no line cannot be sent', (tester) async {
    // Arrange
    session.adopt(userWith(['orders.manage']));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — disabled rather than refused on tap: nothing has been typed to be wrong yet.
    final button = tester.widget<InkWell>(
      find.ancestor(of: find.text('إنشاء الطلبية'), matching: find.byType(InkWell)).first,
    );
    expect(button.onTap, isNull);
    verifyNever(() => orders.create(any()));
  });

  testWidgets('the customer’s shops are offered, and none is the default', (tester) async {
    // Arrange
    session.adopt(userWith(['orders.manage']));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — optional, and «بدون تحديد» is a real answer rather than an unfilled box.
    expect(find.text('فرع سوق الجمعة'), findsOneWidget);
    final chosen = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'بدون تحديد'),
    );
    expect(chosen.selected, isTrue);
  });

  testWidgets('a customer with no shops is not asked which shop', (tester) async {
    // Arrange
    when(() => customers.customer(7)).thenAnswer(
      (_) async => const Right(Customer(
        id: 7,
        code: 'C7',
        name: 'مطبعة النور',
        phone: '0913334444',
        isActive: true,
        shops: [],
      )),
    );
    session.adopt(userWith(['orders.manage']));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — a section with one meaningless answer in it is furniture.
    expect(find.text('المحل'), findsNothing);
  });

  testWidgets('the phone box opens filled with the customer’s own number', (tester) async {
    // Arrange — everything else under «الاستلام» is already on the order through the customer
    // and their shop; the number is the one thing that is sometimes somebody else's.
    session.adopt(userWith(['orders.manage']));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.widgetWithText(TextField, '0913334444'), findsOneWidget);
    // And the two the customer's record already answers are not asked again.
    expect(find.text('اسم المستلِم'), findsNothing);
    expect(find.text('تفاصيل العنوان'), findsNothing);
  });

  testWidgets('a number typed over the prefill is not overwritten', (tester) async {
    // Arrange — the screen rebuilds on every keystroke elsewhere on the form, and a prefill
    // that ran on each rebuild would fight whoever is typing.
    session.adopt(userWith(['orders.manage']));
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.enterText(find.widgetWithText(TextField, '0913334444'), '0925556666');
    await tester.tap(find.text('من عندنا'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.widgetWithText(TextField, '0925556666'), findsOneWidget);
  });

  testWidgets('the delivery price is never added up here, and never explained', (
    tester,
  ) async {
    // Arrange
    session.adopt(userWith(['orders.manage']));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — no sentence about the delivery price under the place: when a city is chosen
    // its price sits inside the city's own tile (see `PlacePickerTile.trailing`), and before
    // one is chosen there is nothing to say. The estimate covers the lines only, and says so.
    expect(find.textContaining('سعر التوصيل'), findsNothing);

    await tester.dragUntilVisible(
      find.text('إجمالي البنود (تقديري)'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    expect(find.text('إجمالي البنود (تقديري)'), findsOneWidget);
  });

  testWidgets('the phone sits with the place, under one «الاستلام» heading', (tester) async {
    // Arrange — where it goes and who answers for it are two halves of one question; the
    // number used to sit three sections lower under a heading of its own.
    session.adopt(userWith(['orders.manage']));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('الاستلام'), findsOneWidget);
    expect(find.text('مكان الاستلام'), findsNothing);
    final place = tester.getTopLeft(find.text('المدينة')).dy;
    final phone = tester.getTopLeft(find.widgetWithText(TextField, '0913334444')).dy;
    final lines = tester.getTopLeft(find.text('البنود')).dy;
    expect(phone, greaterThan(place));
    expect(phone, lessThan(lines));
  });

  testWidgets('adding a product is a small action on the «البنود» heading', (tester) async {
    // Arrange — not a full-width button under the list, which cost the form a row and read
    // louder than «إنشاء الطلبية» itself.
    session.adopt(userWith(['orders.manage']));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — on the same line as the heading.
    final action = find.widgetWithText(TextButton, 'إضافة منتج');
    expect(action, findsOneWidget);
    final heading = tester.getCenter(find.text('البنود')).dy;
    expect(tester.getCenter(action).dy, moreOrLessEquals(heading, epsilon: 12));
  });
}
