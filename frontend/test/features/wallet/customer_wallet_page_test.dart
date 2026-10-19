import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/investors/presentation/widgets/investor_money_tile.dart';
import 'package:dayaa/features/wallet/models/wallet_models.dart';
import 'package:dayaa/features/wallet/presentation/viewmodel/customer_wallet_cubit.dart';
import 'package:dayaa/features/wallet/presentation/viewmodel/wallet_entries_cubit.dart';
import 'package:dayaa/features/wallet/presentation/views/customer_wallet_page.dart';
import 'package:dayaa/features/wallet/repositories/wallet_repository.dart';
import 'package:dayaa/features/wallet/usecases/wallet_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockWalletRepository extends Mock implements WalletRepository {}

/// محفظة العميل في تطبيق الموظفين — **على شكل محفظة المستثمر** (طلب صاحب العمل، ٢٠٢٦-١٠-١١):
/// الرصيدُ في البطاقة الكبيرة والزرّان فيها بصلاحياتهما (٢٠٢٦-١٠-١٧)، و«إلغاء الحركة» على السطر
/// نفسه.
///
/// Arrange - Act - Assert throughout.
void main() {
  late _MockWalletRepository repository;

  const topUp = CustomerWalletEntry(
    id: 7,
    customerId: 3,
    type: 'topup',
    typeLabel: 'شحن المحفظة',
    isIn: true,
    amount: '100.00',
    methodLabel: 'كاش',
    accountName: 'الخزنة',
    reference: 'TOPUP-01M537R0RWATZK0JMKJ5GCWM67',
    recorderName: 'عبدالوهاب',
    canReverse: true,
  );

  const paid = CustomerWalletEntry(
    id: 8,
    customerId: 3,
    type: 'order_payment',
    typeLabel: 'دفع طلبية',
    isIn: false,
    amount: '40.00',
    orderId: 1304,
  );

  setUpAll(() => registerFallbackValue(WalletEntryFilter.all));

  Future<void> open(WidgetTester tester, {required List<String> permissions}) async {
    await sl.reset();
    repository = _MockWalletRepository();

    when(() => repository.wallet(3)).thenAnswer(
      (_) async => const Right(CustomerWallet(customerId: 3, balance: '60.00')),
    );
    when(
      () => repository.entries(
        customerId: 3,
        page: any(named: 'page'),
        filter: any(named: 'filter'),
        search: any(named: 'search'),
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer(
      (_) async => const Right(
        Paginated(
          items: [paid, topUp],
          meta: PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: 2),
        ),
      ),
    );

    sl
      ..registerSingleton<Session>(
        Session()
          ..adopt(
            AuthUser(id: 1, name: 'عبدالوهاب', phone: '0911234567', permissions: permissions),
          ),
      )
      ..registerFactoryParam<CustomerWalletCubit, int, void>(
        (customerId, _) => CustomerWalletCubit(
          customerId: customerId,
          getWallet: GetCustomerWallet(repository),
          topUp: TopUpCustomerWallet(repository),
          adjust: AdjustCustomerWallet(repository),
        ),
      )
      ..registerFactoryParam<WalletEntriesCubit, int?, void>(
        (customerId, _) => WalletEntriesCubit(
          customerId: customerId,
          getEntries: GetCustomerWalletEntries(repository),
          reverseEntry: ReverseCustomerWalletEntry(repository),
        ),
      );

    tester.view
      ..physicalSize = const Size(1290, 2796)
      ..devicePixelRatio = 3;
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
          home: CustomerWalletPage(customerId: 3, customerName: 'علي'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the balance is the hero card, as on an investor', (tester) async {
    // Arrange & Act
    await open(tester, permissions: const ['customers.wallet.view']);

    // Assert
    final hero = find.byType(InvestorMoneyTile);
    expect(hero, findsOneWidget);
    expect(tester.widget<InvestorMoneyTile>(hero).amount, '60.00');
    expect(tester.widget<InvestorMoneyTile>(hero).artwork, isNotNull);
    expect(find.text('علي'), findsOneWidget);
  });

  testWidgets('the balance card carries no sentence under the number', (tester) async {
    // Arrange & Act
    await open(tester, permissions: const ['customers.wallet.view']);

    // Assert — «تُشحن ولا يُسحب منها» was a note nobody needed (٢٠٢٦-١٠-١٧).
    expect(tester.widget<InvestorMoneyTile>(find.byType(InvestorMoneyTile)).caption, isNull);
    expect(find.textContaining('يُسحب'), findsNothing);
  });

  testWidgets('the actions sit inside the balance card, each behind its grant', (tester) async {
    // Arrange & Act
    await open(
      tester,
      permissions: const ['customers.wallet.view', 'customers.wallet.topup'],
    );

    // Assert
    final inCard = find.descendant(
      of: find.byType(InvestorMoneyTile),
      matching: find.widgetWithText(AppButton, 'شحن المحفظة'),
    );
    expect(inCard, findsOneWidget);
    expect(find.widgetWithText(AppButton, 'تعديل الرصيد'), findsNothing);
  });

  testWidgets('both actions, side by side in the card', (tester) async {
    // Arrange & Act
    await open(
      tester,
      permissions: const [
        'customers.wallet.view',
        'customers.wallet.topup',
        'customers.wallet.adjust',
      ],
    );

    // Assert
    Finder inCard(String label) => find.descendant(
      of: find.byType(InvestorMoneyTile),
      matching: find.widgetWithText(AppButton, label),
    );
    expect(inCard('شحن المحفظة'), findsOneWidget);
    expect(inCard('تعديل الرصيد'), findsOneWidget);
    expect(
      tester.getCenter(inCard('شحن المحفظة')).dy,
      closeTo(tester.getCenter(inCard('تعديل الرصيد')).dy, 1),
    );
  });

  testWidgets('the top-up sheet opens on its fields, with no note under the title', (
    tester,
  ) async {
    // Arrange
    await open(
      tester,
      permissions: const ['customers.wallet.view', 'customers.wallet.topup'],
    );

    // Act
    await tester.tap(find.widgetWithText(AppButton, 'شحن المحفظة'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.textContaining('يُسحب'), findsNothing);
    expect(find.textContaining('محفظة علي'), findsNothing);
  });

  testWidgets('«تعديل الرصيد» opens a sheet, not a dialog', (tester) async {
    // Arrange
    await open(
      tester,
      permissions: const ['customers.wallet.view', 'customers.wallet.adjust'],
    );

    // Act
    await tester.tap(find.widgetWithText(AppButton, 'تعديل الرصيد'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('a reader with no grant to move money sees no buttons', (tester) async {
    // Arrange & Act
    await open(tester, permissions: const ['customers.wallet.view']);

    // Assert
    expect(find.widgetWithText(AppButton, 'شحن المحفظة'), findsNothing);
    expect(find.widgetWithText(AppButton, 'تعديل الرصيد'), findsNothing);
  });

  testWidgets('«إلغاء الحركة» sits on the row the server says may be undone, alone', (
    tester,
  ) async {
    // Arrange & Act
    await open(tester, permissions: const ['customers.wallet.view']);

    // Assert — the top-up may be undone, the order payment is undone on its order.
    expect(find.text('إلغاء الحركة'), findsOneWidget);
    expect(find.text('+100 د.ل'), findsOneWidget);
    expect(find.text('−40 د.ل'), findsOneWidget);
    expect(find.textContaining('عبدالوهاب'), findsOneWidget);
  });

  testWidgets('a row names how the money came in, and nothing more', (tester) async {
    // Arrange & Act
    await open(tester, permissions: const ['customers.wallet.view']);

    // Assert — no account, no reference, no order number: only the method.
    expect(find.text('كاش'), findsOneWidget);
    expect(find.textContaining('الخزنة'), findsNothing);
    expect(find.textContaining('TOPUP-'), findsNothing);
    expect(find.textContaining('1304'), findsNothing);
  });
}
