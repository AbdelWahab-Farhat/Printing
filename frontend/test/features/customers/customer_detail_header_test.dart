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
import 'package:dayaa/features/wallet/models/wallet_models.dart';
import 'package:dayaa/features/wallet/presentation/viewmodel/customer_wallet_cubit.dart';
import 'package:dayaa/features/wallet/repositories/wallet_repository.dart';
import 'package:dayaa/features/wallet/usecases/wallet_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCustomerRepository extends Mock implements CustomerRepository {}

class _MockWalletRepository extends Mock implements WalletRepository {}

/// العميلُ ومحفظتُه في بطاقةٍ واحدة أعلى شاشته — بطلب صاحب العمل (٢٠٢٦-١٠-١٧): «خلّي رصيد
/// المحفظة وكود العميل ومعلوماته في بطاقة واحدة وهي بالأعلى».
///
/// Arrange - Act - Assert throughout.
void main() {
  late _MockCustomerRepository customers;
  late _MockWalletRepository wallets;
  late Session session;

  const customer = Customer(
    id: 7,
    code: 'A730',
    name: 'مطبعة النور',
    phone: '0910000002',
    isActive: true,
    shops: [],
  );

  AuthUser userWith(List<String> permissions) =>
      AuthUser(id: 1, name: 'عبدالوهاب', phone: '0911234567', permissions: permissions);

  setUp(() async {
    await Injector.reset();

    customers = _MockCustomerRepository();
    wallets = _MockWalletRepository();
    session = Session();

    when(() => customers.customer(7)).thenAnswer((_) async => const Right(customer));
    when(() => wallets.wallet(7)).thenAnswer(
      (_) async => const Right(CustomerWallet(customerId: 7, balance: '20200.00')),
    );

    sl
      ..registerSingleton<Session>(session)
      ..registerFactoryParam<CustomerDetailCubit, int, void>(
        (customerId, _) => CustomerDetailCubit(
          customerId: customerId,
          getCustomer: GetCustomer(customers),
          setActivation: SetCustomerActivation(customers),
        ),
      )
      ..registerFactoryParam<CustomerWalletCubit, int, void>(
        (customerId, _) => CustomerWalletCubit(
          customerId: customerId,
          getWallet: GetCustomerWallet(wallets),
          topUp: TopUpCustomerWallet(wallets),
          adjust: AdjustCustomerWallet(wallets),
        ),
      );
  });

  tearDown(Injector.reset);

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
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
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder inHeader(Finder matching) =>
      find.descendant(of: find.byKey(CustomerDetailPage.headerKey), matching: matching);

  testWidgets('the name, the phone, the code and the balance are one card', (tester) async {
    // Arrange
    session.adopt(userWith(['customers.view', 'customers.wallet.view']));

    // Act
    await open(tester);

    // Assert
    expect(find.byKey(CustomerDetailPage.headerKey), findsOneWidget);
    expect(inHeader(find.text('مطبعة النور')), findsOneWidget);
    expect(inHeader(find.text('0910000002')), findsOneWidget);
    expect(inHeader(find.text('A730')), findsOneWidget);
    expect(inHeader(find.text('رصيد المحفظة')), findsOneWidget);
    expect(inHeader(find.text('20,200 د.ل')), findsOneWidget);
  });

  testWidgets('the card is the top of the page, above the status band', (tester) async {
    // Arrange
    session.adopt(userWith(['customers.view', 'customers.wallet.view']));

    // Act
    await open(tester);

    // Assert
    final card = tester.getRect(find.byKey(CustomerDetailPage.headerKey));
    expect(card.bottom, lessThan(tester.getTopLeft(find.text('عميل نشِط')).dy));
  });

  testWidgets('the balance stands alone — no sentence under it', (tester) async {
    // Arrange
    session.adopt(userWith(['customers.view', 'customers.wallet.view']));

    // Act
    await open(tester);

    // Assert
    expect(find.text('السجل والشحن'), findsNothing);
  });

  testWidgets('without the grant to read the wallet the card is the customer alone', (
    tester,
  ) async {
    // Arrange
    session.adopt(userWith(['customers.view']));

    // Act
    await open(tester);

    // Assert
    expect(inHeader(find.text('A730')), findsOneWidget);
    expect(find.text('رصيد المحفظة'), findsNothing);
    verifyNever(() => wallets.wallet(any()));
  });
}
