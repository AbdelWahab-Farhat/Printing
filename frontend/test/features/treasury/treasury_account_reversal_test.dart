import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/presentation/views/treasury_account_page.dart';
import 'package:dayaa/features/treasury/usecases/treasury_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'treasury_fixtures.dart';

/// صفحة الحساب — اللمسة تفتح مصدر المال، والعكس في «...» وحدها، والسجل يُرقَّع بعده. فلترُ
/// «الكل · الطلبيات · المصاريف» والبحثُ برقم الطلبية في `treasury_account_page_test.dart`.
/// TREASURY-DESIGN §٩.
///
/// Arrange - Act - Assert throughout.
void main() {
  late MockTreasuryRepository repository;

  final detail = TreasuryAccountDetail(
    account: TreasuryAccount.fromJson({
      'id': 5,
      'name': 'مصرف علي',
      'kind': 'bank',
      'kind_label': 'مصرف',
      'balance': '300.00',
      'holder': {'id': 3, 'name': 'علي'},
    }),
  );

  final deposit = movement(id: 70, operationId: 30, balanceAfter: '300.00');
  final payment = movement(
    id: 60,
    kind: 'payment',
    kindLabel: 'دفعة زبون',
    operationId: null,
    orderId: 1260,
    isReversible: false,
    balanceAfter: '250.00',
    occurredAt: DateTime(2026, 9, 29, 12),
  );

  setUp(() async {
    await sl.reset();
    repository = MockTreasuryRepository();

    when(() => repository.account(5)).thenAnswer((_) async => Right(detail));
    when(
      () => repository.movements(5, page: 1),
    ).thenAnswer((_) async => Right(pageOf([deposit, payment])));

    sl
      ..registerSingleton<Session>(
        Session()..adopt(
          const AuthUser(
            id: 1,
            name: 'عبدالوهاب',
            phone: '0911234567',
            permissions: ['treasury.view', 'treasury.reverse'],
          ),
        ),
      )
      ..registerLazySingleton(() => GetTreasuryAccount(repository))
      ..registerLazySingleton(() => GetTreasuryAccounts(repository))
      ..registerLazySingleton(() => RecordTreasuryOperation(repository))
      ..registerLazySingleton(() => SaveTreasuryAccount(repository))
      ..registerLazySingleton(() => GetAccountMovements(repository))
      ..registerLazySingleton(() => ReverseTreasuryOperation(repository));
  });

  tearDown(() => sl.reset());

  Widget host() {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const TreasuryAccountPage(accountId: 5)),
        GoRoute(
          path: '/orders/:id',
          builder: (_, state) => Scaffold(body: Text('الطلبية ${state.pathParameters['id']}')),
        ),
      ],
    );

    return ScreenUtilInit(
      designSize: const Size(430, 932),
      builder: (context, _) => MaterialApp.router(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: router,
      ),
    );
  }

  testWidgets('tapping a reversible line does not reverse it; its «...» offers the reversal', (
    tester,
  ) async {
    // Arrange
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('إيداع').last);
    await tester.pumpAndSettle();
    final dialogsAfterTap = find.byType(AlertDialog).evaluate().length;
    await tester.tap(find.byTooltip('خيارات الحركة'));
    await tester.pumpAndSettle();

    // Assert
    expect(dialogsAfterTap, 0);
    expect(find.text('عكس العملية'), findsOneWidget);
  });

  testWidgets('a line that belongs to an order opens the order, and offers no reversal', (
    tester,
  ) async {
    // Arrange
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    final optionsOnScreen = find.byTooltip('خيارات الحركة').evaluate().length;

    // Act
    await tester.tap(find.text('دفعة زبون').last);
    await tester.pumpAndSettle();

    // Assert — «...» واحدة في الصفحة: للإيداع، لا للدفعة.
    expect(optionsOnScreen, 1);
    expect(find.text('الطلبية 1260'), findsOneWidget);
  });

  testWidgets('the balance carries no line under it', (tester) async {
    // Arrange
    await tester.pumpWidget(host());

    // Act
    await tester.pumpAndSettle();

    // Assert — النوع وصاحب الحساب كانا تحت الرقم حاشيةً.
    expect(find.text('مصرف · باسم علي'), findsNothing);
    expect(find.text('300 د.ل'), findsOneWidget);
  });

  testWidgets('a reversal strikes the line and puts the server\'s line above it', (tester) async {
    // Arrange
    when(() => repository.reverseOperation(30, reason: 'سُجّل مرتين')).thenAnswer(
      (_) async => const Right(
        TreasuryOperation(
          id: 31,
          type: 'deposit',
          typeLabel: 'إيداع',
          amount: '50.00',
          isReversible: false,
        ),
      ),
    );
    when(() => repository.movements(5, page: 1, perPage: 1)).thenAnswer(
      (_) async => Right(
        pageOf([
          movement(
            id: 71,
            isIn: false,
            signedAmount: '-50.00',
            balanceAfter: '250.00',
            operationId: 31,
            isReversal: true,
            isReversible: false,
            reversesMovementId: 70,
            occurredAt: DateTime(2026, 9, 30, 11),
          ),
        ]),
      ),
    );
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.byTooltip('خيارات الحركة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('عكس العملية'));
    await tester.pumpAndSettle();
    // حقلُ السبب في الحوار، لا مربّعُ البحث برقم الطلبية تحت الرصيد.
    await tester.enterText(find.byType(AppTextField).last, 'سُجّل مرتين');
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'عكس العملية'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    // Assert — السجلّ رُقِّع، ولم يُقرأ من صفحته الأولى من جديد.
    final original = tester.widget<Text>(find.text('إيداع').last);
    expect(find.text('إلغاء: إيداع'), findsOneWidget);
    expect(original.style?.decoration, TextDecoration.lineThrough);
    expect(find.byTooltip('خيارات الحركة'), findsNothing);
    verify(() => repository.movements(5, page: 1)).called(1);
  });
}
