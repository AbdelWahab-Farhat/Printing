import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/customers/models/customer.dart';
import 'package:dayaa/features/customers/presentation/viewmodel/customer_detail_cubit.dart';
import 'package:dayaa/features/customers/presentation/views/customer_detail_page.dart';
import 'package:dayaa/features/customers/repositories/customer_repository.dart';
import 'package:dayaa/features/customers/usecases/get_customer.dart';
import 'package:dayaa/features/customers/usecases/set_customer_activation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// What staff do to a customer from their screen.
///
/// «طلبية جديدة» and «تعديل العميل» sit on the page side by side, and switching the customer off
/// or on sits in the status band — none of them behind the dial. The order is taken from inside
/// the customer, so this screen is the door; see NEW-ORDER-DESIGN.md §١.
///
/// Arrange - Act - Assert throughout.
class _MockCustomerRepository extends Mock implements CustomerRepository {}

void main() {
  late _MockCustomerRepository repository;
  late Session session;

  const customer = Customer(
    id: 7,
    code: 'C7',
    name: 'مطبعة النور',
    phone: '0913334444',
    isActive: true,
  );

  const deactivated = Customer(
    id: 7,
    code: 'C7',
    name: 'مطبعة النور',
    phone: '0913334444',
    isActive: false,
  );

  AuthUser userWith(List<String> permissions) =>
      AuthUser(id: 1, name: 'عبدالوهاب', phone: '0911234567', permissions: permissions);

  setUp(() async {
    await Injector.reset();

    repository = _MockCustomerRepository();
    session = Session();

    when(() => repository.customer(7)).thenAnswer((_) async => const Right(customer));

    sl
      ..registerSingleton<Session>(session)
      ..registerFactoryParam<CustomerDetailCubit, int, void>(
        (customerId, _) => CustomerDetailCubit(
          customerId: customerId,
          getCustomer: GetCustomer(repository),
          setActivation: SetCustomerActivation(repository),
        ),
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
      home: CustomerDetailPage(customerId: 7),
    ),
  );

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
  }

  group('the buttons under the status band', () {
    testWidgets('somebody who may take orders is offered one without opening anything', (
      tester,
    ) async {
      // Arrange
      session.adopt(userWith(['customers.view', 'orders.manage']));

      // Act
      await open(tester);

      // Assert — on the page itself, not behind the dial.
      expect(find.text('طلبية جديدة'), findsOneWidget);
      expect(find.text('تعديل العميل'), findsNothing);
    });

    testWidgets('somebody who may not is not offered it', (tester) async {
      // Arrange — a courtesy, never a boundary: `orders.manage` on the route and on the API is
      // what actually refuses.
      session.adopt(userWith(['customers.view', 'customers.manage']));

      // Act
      await open(tester);

      // Assert
      expect(find.text('طلبية جديدة'), findsNothing);
      expect(find.text('تعديل العميل'), findsOneWidget);
    });

    testWidgets('with both allowed, the two share one row, the order first', (tester) async {
      // Arrange
      session.adopt(userWith(['customers.view', 'customers.manage', 'orders.manage']));

      // Act
      await open(tester);

      // Assert — the same line, and in RTL «first» is the right-hand side.
      final order = tester.getRect(find.text('طلبية جديدة'));
      final edit = tester.getRect(find.text('تعديل العميل'));
      expect(order.center.dy, moreOrLessEquals(edit.center.dy, epsilon: 1));
      expect(order.left, greaterThan(edit.right));
    });

    testWidgets('a deactivated customer is not sold to from here', (tester) async {
      // Arrange — somebody the shop has stopped selling to. Turning them back on is one tap
      // away in the band above, and `CreateOrder` refuses the request as well.
      when(() => repository.customer(7)).thenAnswer((_) async => const Right(deactivated));
      session.adopt(userWith(['customers.view', 'customers.manage', 'orders.manage']));

      // Act
      await open(tester);

      // Assert
      expect(find.text('طلبية جديدة'), findsNothing);
      expect(find.text('تعديل العميل'), findsOneWidget);
      // …and the way back is right there, which is what keeps this a refusal rather than a
      // dead end.
      expect(find.text('تنشيط'), findsOneWidget);
    });

    testWidgets('neither of them has left the dial a copy', (tester) async {
      // Arrange
      session.adopt(userWith(['customers.view', 'customers.manage', 'orders.manage']));
      await open(tester);

      // Act
      await tester.tap(find.byType(FloatingActionButton).last);
      await tester.pumpAndSettle();

      // Assert — one of each, the one on the page.
      expect(find.text('طلبية جديدة'), findsOneWidget);
      expect(find.text('تعديل العميل'), findsOneWidget);
      expect(find.text('تعطيل العميل'), findsNothing);
    });
  });

  group('the switch in the status band', () {
    testWidgets('deactivating asks first, and a cancel changes nothing', (tester) async {
      // Arrange
      session.adopt(userWith(['customers.view', 'customers.manage']));
      await open(tester);

      // Act
      await tester.tap(find.text('تعطيل'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('تعطيل العميل؟'), findsOneWidget);

      await tester.tap(find.text('إلغاء'));
      await tester.pumpAndSettle();

      verifyNever(
        () => repository.setActivation(any(), isActive: any(named: 'isActive')),
      );
    });

    testWidgets('a confirmed deactivation is sent', (tester) async {
      // Arrange
      when(
        () => repository.setActivation(7, isActive: false),
      ).thenAnswer((_) async => const Right(deactivated));
      session.adopt(userWith(['customers.view', 'customers.manage']));
      await open(tester);

      // Act — the dialog's own «تعطيل» sits over the band's, so it is the last one found.
      await tester.tap(find.text('تعطيل'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تعطيل').last);
      await tester.pumpAndSettle();

      // Assert — and the band now offers the way back.
      verify(() => repository.setActivation(7, isActive: false)).called(1);
      expect(find.text('تنشيط'), findsOneWidget);
    });

    testWidgets('turning somebody back on asks nothing', (tester) async {
      // Arrange
      when(() => repository.customer(7)).thenAnswer((_) async => const Right(deactivated));
      when(
        () => repository.setActivation(7, isActive: true),
      ).thenAnswer((_) async => const Right(customer));
      session.adopt(userWith(['customers.view', 'customers.manage']));
      await open(tester);

      // Act
      await tester.tap(find.text('تنشيط'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(AlertDialog), findsNothing);
      verify(() => repository.setActivation(7, isActive: true)).called(1);
      expect(find.text('تعطيل'), findsOneWidget);
    });

    testWidgets('somebody who may not manage customers is not offered it', (tester) async {
      // Arrange
      session.adopt(userWith(['customers.view', 'orders.manage']));

      // Act
      await open(tester);

      // Assert — the band still says what the customer is; it just has no switch.
      expect(find.text('عميل نشِط'), findsOneWidget);
      expect(find.text('تعطيل'), findsNothing);
    });
  });
}
