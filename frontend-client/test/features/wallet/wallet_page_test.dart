import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/network/paginated.dart';
import 'package:dayaa_client/features/auth/models/customer_account.dart';
import 'package:dayaa_client/features/auth/repositories/auth_repository.dart';
import 'package:dayaa_client/features/auth/usecases/get_current_customer.dart';
import 'package:dayaa_client/features/wallet/models/online_top_up_models.dart';
import 'package:dayaa_client/features/wallet/models/wallet_models.dart';
import 'package:dayaa_client/features/wallet/presentation/viewmodel/wallet_entries_cubit.dart';
import 'package:dayaa_client/features/wallet/presentation/views/wallet_page.dart';
import 'package:dayaa_client/features/wallet/repositories/top_up_repository.dart';
import 'package:dayaa_client/features/wallet/repositories/wallet_repository.dart';
import 'package:dayaa_client/features/wallet/usecases/top_up_usecases.dart';
import 'package:dayaa_client/features/wallet/usecases/wallet_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuth extends Mock implements AuthRepository {}

class _MockWallet extends Mock implements WalletRepository {}

class _MockTopUp extends Mock implements TopUpRepository {}

/// «محفظتي» على نسق بريمولا — البطاقة باسم الزبون ورمزه ورصيده، و«شحن المحفظة» عليها ما دام الشحن
/// مفعّلاً، والمعاملات بطاقاتٌ تقول «وارد» أو «صادر».
///
/// Arrange - Act - Assert throughout.
void main() {
  setUpAll(() => registerFallbackValue(MyWalletFilter.all));

  tearDown(() async => sl.reset());

  Future<void> open(WidgetTester tester, {required bool topUpEnabled}) async {
    tester.view
      ..physicalSize = const Size(430, 932)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final auth = _MockAuth();
    final wallet = _MockWallet();
    final topUp = _MockTopUp();

    when(auth.currentCustomer).thenAnswer(
      (_) async => const Right(CustomerAccount(id: 3, name: 'علي', phone: '0911111111', code: 'C-102')),
    );
    when(() => wallet.entries(page: any(named: 'page'), filter: any(named: 'filter'))).thenAnswer(
      (_) async => const Right(
        Paginated(
          items: [
            MyWalletEntry(id: 2, type: 'order_payment', typeLabel: 'دفع طلبية', isIn: false, amount: '40.00', orderId: 1286),
            MyWalletEntry(id: 1, type: 'topup', typeLabel: 'شحن المحفظة', isIn: true, amount: '100.00', methodLabel: 'شحن إلكتروني'),
          ],
          meta: PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: 2),
          extraMeta: {'balance': '60.00'},
        ),
      ),
    );
    when(topUp.methods).thenAnswer(
      (_) async => Right(TopUpMethods(enabled: topUpEnabled, feePayer: 'customer', methods: const [])),
    );

    sl
      ..registerLazySingleton(() => GetCurrentCustomer(auth))
      ..registerLazySingleton(() => GetTopUpMethods(topUp))
      ..registerFactory(() => WalletEntriesCubit(getEntries: GetWalletEntries(wallet)));

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
          home: WalletPage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('the card carries the name, the code and the balance', (tester) async {
    // Arrange & Act
    await open(tester, topUpEnabled: true);

    // Assert
    expect(find.text('علي - C-102'), findsOneWidget);
    expect(find.text('60'), findsOneWidget);
    expect(find.text('د.ل'), findsOneWidget);
    expect(find.text('FlyerX'), findsOneWidget);
  });

  testWidgets('«شحن المحفظة» sits on the card while online top-ups are on', (tester) async {
    // Arrange & Act
    await open(tester, topUpEnabled: true);

    // Assert
    expect(find.text('شحن المحفظة'), findsOneWidget);
  });

  testWidgets('with online top-ups off there is no button that would not work', (tester) async {
    // Arrange & Act
    await open(tester, topUpEnabled: false);

    // Assert
    expect(find.text('شحن المحفظة'), findsNothing);
  });

  testWidgets('each movement is a card that says وارد or صادر, and an order payment opens its order', (tester) async {
    // Arrange & Act
    await open(tester, topUpEnabled: true);

    // Assert
    expect(find.text('وارد'), findsOneWidget);
    expect(find.text('صادر'), findsOneWidget);
    expect(find.text('عبر شحن إلكتروني'), findsOneWidget);
    expect(find.text('عرض الطلبية 1286'), findsOneWidget);
  });
}
