import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/investors/presentation/widgets/investor_money_tile.dart';
import 'package:dayaa/features/online_payments/models/online_payment_models.dart';
import 'package:dayaa/features/online_payments/presentation/viewmodel/online_payments_cubit.dart';
import 'package:dayaa/features/online_payments/presentation/views/online_payments_page.dart';
import 'package:dayaa/features/online_payments/repositories/online_payment_repository.dart';
import 'package:dayaa/features/online_payments/usecases/online_payment_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockOnlinePaymentRepository extends Mock implements OnlinePaymentRepository {}

/// «المدفوعات الإلكترونية» في تطبيق الموظفين — رصيد «Ezone» في الرأس، و«تحويل إلى المصرف» لمن
/// يسجّل عمليات الحسابات وحده، والمحاولاتُ بحالاتها.
///
/// Arrange - Act - Assert throughout.
void main() {
  late _MockOnlinePaymentRepository repository;

  const succeeded = PaymentIntent(
    id: 4,
    uuid: 'b1c2',
    customerName: 'علي',
    methodLabel: 'سداد',
    status: IntentStatus.succeeded,
    statusLabel: 'تم الشحن',
    netAmount: '100.00',
    grossAmount: '102.50',
    customerFee: '2.50',
    feePayerLabel: 'الزبون',
    reference: 'DY-0004',
  );

  setUpAll(() => registerFallbackValue(IntentFilter.all));

  Future<void> open(WidgetTester tester, {required List<String> permissions, bool enabled = true}) async {
    await sl.reset();
    repository = _MockOnlinePaymentRepository();

    when(
      () => repository.intents(page: any(named: 'page'), filter: any(named: 'filter'), search: any(named: 'search')),
    ).thenAnswer(
      (_) async => Right(
        Paginated(
          items: const [succeeded],
          meta: const PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: 1),
          extraMeta: {'enabled': enabled, 'ezone_balance': '1250.00'},
        ),
      ),
    );

    sl
      ..registerSingleton<Session>(
        Session()..adopt(AuthUser(id: 1, name: 'عبدالوهاب', phone: '0911234567', permissions: permissions)),
      )
      ..registerFactory<OnlinePaymentsCubit>(
        () => OnlinePaymentsCubit(
          getIntents: GetPaymentIntents(repository),
          recheck: RecheckPaymentIntent(repository),
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
          home: OnlinePaymentsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the head is what Ezone holds, and each attempt is a row', (tester) async {
    // Arrange & Act
    await open(tester, permissions: const ['payments.online.view']);

    // Assert
    final tile = find.byType(InvestorMoneyTile);
    expect(tile, findsOneWidget);
    expect(tester.widget<InvestorMoneyTile>(tile).amount, '1250.00');
    expect(find.text('علي'), findsOneWidget);
    expect(find.text('100 د.ل'), findsOneWidget);
  });

  testWidgets('a reader of online payments alone is not offered «تحويل إلى المصرف»', (tester) async {
    // Arrange & Act
    await open(tester, permissions: const ['payments.online.view']);

    // Assert
    expect(find.widgetWithText(AppButton, 'تحويل إلى المصرف'), findsNothing);
  });

  testWidgets('who records treasury operations is offered «تحويل إلى المصرف»', (tester) async {
    // Arrange & Act
    await open(tester, permissions: const ['payments.online.view', 'treasury.record']);

    // Assert
    expect(find.widgetWithText(AppButton, 'تحويل إلى المصرف'), findsOneWidget);
  });

  testWidgets('switched off on the server, the head says customers see no top-up', (tester) async {
    // Arrange & Act
    await open(tester, permissions: const ['payments.online.view'], enabled: false);

    // Assert
    expect(find.textContaining('مطفأ'), findsOneWidget);
  });
}
