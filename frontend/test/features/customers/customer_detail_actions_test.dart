import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:printing/core/di/injector.dart';
import 'package:printing/core/session/session.dart';
import 'package:printing/features/auth/models/auth_user.dart';
import 'package:printing/features/customers/models/customer.dart';
import 'package:printing/features/customers/presentation/viewmodel/customer_detail_cubit.dart';
import 'package:printing/features/customers/presentation/views/customer_detail_page.dart';
import 'package:printing/features/customers/repositories/customer_repository.dart';
import 'package:printing/features/customers/usecases/get_customer.dart';
import 'package:printing/features/customers/usecases/set_customer_activation.dart';

/// The way into «طلبية جديدة».
///
/// The order is taken from inside the customer, so this screen is the door — and these are the
/// two rules about who finds it open. See NEW-ORDER-DESIGN.md §١.
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

  /// Opens the speed dial, which keeps its labels hidden until it is pressed.
  Future<void> openTheDial(WidgetTester tester) async {
    await tester.tap(find.byType(FloatingActionButton).last);
    await tester.pumpAndSettle();
  }

  testWidgets('somebody who may take orders is offered one from the customer', (
    tester,
  ) async {
    // Arrange
    session.adopt(userWith(['customers.view', 'orders.manage']));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await openTheDial(tester);

    // Assert — and it is the first action, so it opens nearest the thumb.
    expect(find.text('طلبية جديدة'), findsOneWidget);
  });

  testWidgets('somebody who may not is not offered it', (tester) async {
    // Arrange — a courtesy, never a boundary: `orders.manage` on the route and on the API is
    // what actually refuses.
    session.adopt(userWith(['customers.view', 'customers.manage']));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await openTheDial(tester);

    // Assert
    expect(find.text('طلبية جديدة'), findsNothing);
  });

  testWidgets('a deactivated customer is not sold to from here', (tester) async {
    // Arrange — somebody the shop has stopped selling to. Turning them back on is one tap away
    // on this same screen, and `CreateOrder` refuses the request as well.
    when(() => repository.customer(7)).thenAnswer(
      (_) async => const Right(
        Customer(
          id: 7,
          code: 'C7',
          name: 'مطبعة النور',
          phone: '0913334444',
          isActive: false,
        ),
      ),
    );
    session.adopt(userWith(['customers.view', 'customers.manage', 'orders.manage']));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await openTheDial(tester);

    // Assert
    expect(find.text('طلبية جديدة'), findsNothing);
    // …and the way back is right there, which is what keeps this a refusal rather than a
    // dead end.
    expect(find.text('تنشيط العميل'), findsOneWidget);
  });
}
