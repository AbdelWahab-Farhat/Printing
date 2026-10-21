import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/features/investors/models/investor.dart';
import 'package:dayaa/features/investors/models/profit_sources.dart';
import 'package:dayaa/features/investors/presentation/viewmodel/investor_detail_cubit.dart';
import 'package:dayaa/features/investors/presentation/viewmodel/profit_sources_cubit.dart';
import 'package:dayaa/features/investors/presentation/views/investor_detail_page.dart';
import 'package:dayaa/features/investors/usecases/investor_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetInvestor extends Mock implements GetInvestor {}

class _MockRecordWalletEntry extends Mock implements RecordWalletEntry {}

class _MockGetProfitSources extends Mock implements GetProfitSources {}

/// «مصدر الربح» — كلُّ بوّابةٍ على بطاقة الأرباح تُفتح على ما صنعها.
///
/// Arrange - Act - Assert في كلٍّ منها.
void main() {
  late _MockGetInvestor getInvestor;
  late _MockGetProfitSources getSources;

  setUpAll(() => registerFallbackValue(ProfitGate.pending));

  setUp(() async {
    await sl.reset();
    getInvestor = _MockGetInvestor();
    getSources = _MockGetProfitSources();
    sl
      ..registerSingleton<Session>(Session())
      ..registerFactory<InvestorDetailCubit>(
        () => InvestorDetailCubit(
          getInvestor: getInvestor,
          recordWalletEntry: _MockRecordWalletEntry(),
        ),
      )
      ..registerFactory<ProfitSourcesCubit>(() => ProfitSourcesCubit(getSources: getSources));

    when(() => getInvestor(7)).thenAnswer(
      (_) async => const Right(
        Investor(
          id: 7,
          code: 'I7',
          name: 'أحمد',
          balances: InvestorBalances(wallet: WalletPots(capital: '2000.00', profit: '200.00')),
          profitFigures: ProfitFigures(
            awaitingDelivery: '750.00',
            ordersAwaitingDelivery: 2,
            pending: '195.00',
            available: '200.00',
          ),
        ),
      ),
    );
  });

  tearDown(() async => sl.reset());

  Widget host() {
    return ScreenUtilInit(
      designSize: const Size(430, 932),
      builder: (context, _) => const MaterialApp(
        locale: Locale('ar'),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: InvestorDetailPage(investorId: 7),
        ),
      ),
    );
  }

  Future<void> open(WidgetTester tester, String gate) async {
    tester.view.physicalSize = const Size(1290, 4200);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await tester.tap(find.text(gate));
    await tester.pumpAndSettle();
  }

  // ما يرسله الخادمُ لـ`gate=pending`، بشكله.
  final pending = ProfitSources.fromJson(const {
    'gate': 'pending',
    'total': '195.00',
    'groups': [
      {
        'key': 'period:3',
        'title': 'P3',
        'starts_on': '2026-10-01',
        'ends_on': '2026-10-31',
        'status': 'open',
        'status_label': 'مفتوحة',
        'total': '105.00',
        'lines': [
          {
            'kind': 'order',
            'key': 'order:41:awaiting_period_end',
            'order_id': 41,
            'code': 'ORD-41',
            'customer_name': 'مخبز النور',
            'order_status': 'delivered',
            'order_status_label': 'تم الاستلام',
            'state': 'awaiting_period_end',
            'state_label': 'بانتظار انتهاء الفترة',
            'amount': '120.00',
            'occurred_at': '2026-10-05T10:00:00+02:00',
          },
          {
            'kind': 'entry',
            'key': 'expenses',
            'label': 'نصيبه من المصاريف',
            'amount': '-15.00',
            'occurred_at': '2026-10-06T10:00:00+02:00',
          },
        ],
      },
      {
        'key': 'period:2',
        'title': 'P2',
        'starts_on': '2026-09-01',
        'ends_on': '2026-09-30',
        'status': 'closing',
        'status_label': 'قيد الإغلاق',
        'total': '90.00',
        'lines': [
          {
            'kind': 'order',
            'key': 'order:33:awaiting_payment',
            'order_id': 33,
            'code': 'ORD-33',
            'state': 'awaiting_payment',
            'state_label': 'بانتظار التحصيل',
            'amount': '90.00',
          },
        ],
      },
    ],
  });

  final available = ProfitSources.fromJson(const {
    'gate': 'available',
    'total': '200.00',
    'groups': [
      {
        'key': 'available',
        'total': '200.00',
        'lines': [
          {
            'kind': 'entry',
            'key': 'entry:9',
            'label': 'سحب أرباح',
            'amount': '-100.00',
            'occurred_at': '2026-10-10T10:00:00+02:00',
          },
          {
            'kind': 'release',
            'key': 'release:period:2',
            'label': 'أُفرج عنه من P2',
            'amount': '300.00',
            'occurred_at': '2026-10-01T10:00:00+02:00',
            'children': [
              {
                'kind': 'order',
                'key': 'order:30:released',
                'order_id': 30,
                'code': 'ORD-30',
                'state': 'released',
                'state_label': 'استُلم الربح',
                'amount': '300.00',
              },
            ],
          },
        ],
      },
    ],
  });

  testWidgets('«معلّقة» opens onto its periods, its orders and what is not an order', (tester) async {
    // Arrange
    when(() => getSources(7, ProfitGate.pending)).thenAnswer((_) async => Right(pending));

    // Act
    await open(tester, 'معلّقة');

    // Assert — مجموعُ الورقة رقمُ البطاقة، والفترتان بحالهما، والطلبيةُ بحالها، والمصاريفُ سطرُها.
    verify(() => getSources(7, ProfitGate.pending)).called(1);
    expect(find.text('أرباح معلّقة'), findsOneWidget);
    expect(find.text('195 د.ل'), findsNWidgets(2));
    expect(find.text('P3'), findsOneWidget);
    expect(find.text('مفتوحة'), findsOneWidget);
    expect(find.text('ORD-41'), findsOneWidget);
    expect(find.text('بانتظار انتهاء الفترة'), findsOneWidget);
    expect(find.text('نصيبه من المصاريف'), findsOneWidget);
    expect(find.text('-15 د.ل'), findsOneWidget);
    expect(find.text('P2'), findsOneWidget);
    expect(find.text('بانتظار التحصيل'), findsOneWidget);
  });

  testWidgets('«متاحة للسحب» is a reconciliation whose release opens onto its orders', (tester) async {
    // Arrange
    when(() => getSources(7, ProfitGate.available)).thenAnswer((_) async => Right(available));

    // Act
    await open(tester, 'متاحة للسحب');

    // Assert — الإفراجُ مطويٌّ على طلبياته، والسحبُ سطرُه بسالبه.
    expect(find.text('أرباح متاحة للسحب'), findsWidgets);
    expect(find.text('أُفرج عنه من P2'), findsOneWidget);
    expect(find.text('سحب أرباح'), findsOneWidget);
    expect(find.text('-100 د.ل'), findsOneWidget);
    expect(find.text('ORD-30'), findsNothing);

    await tester.tap(find.text('أُفرج عنه من P2'));
    await tester.pumpAndSettle();

    expect(find.text('ORD-30'), findsOneWidget);
    expect(find.text('استُلم الربح'), findsOneWidget);
  });

  testWidgets('«قيد التسليم» asks for its own gate', (tester) async {
    // Arrange
    when(() => getSources(7, ProfitGate.awaitingDelivery)).thenAnswer(
      (_) async => const Right(ProfitSources(gate: 'awaiting_delivery', total: '0.00')),
    );

    // Act
    await open(tester, 'قيد التسليم');

    // Assert
    verify(() => getSources(7, ProfitGate.awaitingDelivery)).called(1);
    expect(find.text('ربح قيد التسليم'), findsOneWidget);
    expect(find.text('لا شيء خلف هذا الرقم'), findsOneWidget);
  });

  testWidgets('a failure says so and can be retried', (tester) async {
    // Arrange
    var calls = 0;
    when(() => getSources(7, ProfitGate.pending)).thenAnswer((_) async {
      calls++;

      return calls == 1 ? const Left(ServerFailure(message: 'تعذر التحميل')) : Right(pending);
    });

    // Act
    await open(tester, 'معلّقة');

    expect(find.text('تعذر التحميل'), findsOneWidget);

    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('ORD-41'), findsOneWidget);
  });
}
