import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/features/investors/models/investor.dart';
import 'package:dayaa/features/investors/models/profit_sources.dart';
import 'package:dayaa/features/investors/presentation/viewmodel/investor_detail_cubit.dart';
import 'package:dayaa/features/investors/presentation/viewmodel/profit_sources_cubit.dart';
import 'package:dayaa/features/investors/presentation/views/investor_detail_page.dart';
import 'package:dayaa/features/investors/presentation/views/profit_sources_page.dart';
import 'package:dayaa/features/investors/usecases/investor_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetInvestor extends Mock implements GetInvestor {}

class _MockRecordWalletEntry extends Mock implements RecordWalletEntry {}

class _MockGetProfitSources extends Mock implements GetProfitSources {}

/// «مصدر الربح» — كلُّ بوّابةٍ على بطاقة الأرباح تُفتح صفحةً على ما صنعها: ملخّصٌ يقسم الرقمَ على
/// فتراته، ثم بطاقةٌ لكل فترة.
///
/// Arrange - Act - Assert في كلٍّ منها.
void main() {
  late _MockGetInvestor getInvestor;
  late _MockGetProfitSources getSources;

  /// مسارُ الصفحة حين فُتحت فوق صفحة المستثمر.
  String? pushed;

  /// مسارُ الطلبية حين فُتحت فوق الصفحة — وحدَه، لأن go_router يعيد بناءَ ما تحتها.
  String? openedOrder;

  setUpAll(() => registerFallbackValue(ProfitGate.pending));

  setUp(() async {
    await sl.reset();
    pushed = null;
    openedOrder = null;
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

  // مساراتُ التطبيق بأشكالها، والصفحةُ الحقيقية خلف مسارها.
  Widget host() {
    final router = GoRouter(
      initialLocation: Routes.investor(7),
      routes: [
        GoRoute(
          path: '/investors/:id/profit/:gate',
          builder: (context, state) {
            pushed = state.uri.path;

            return ProfitSourcesPage(
              investorId: int.parse(state.pathParameters['id']!),
              gate: ProfitGate.fromValue(state.pathParameters['gate'])!,
            );
          },
        ),
        GoRoute(
          path: '/investors/:id',
          builder: (context, state) =>
              InvestorDetailPage(investorId: int.parse(state.pathParameters['id']!)),
        ),
        GoRoute(
          path: '/orders/:id',
          builder: (context, state) {
            openedOrder = state.uri.path;

            return Scaffold(appBar: AppBar(), body: const SizedBox.shrink());
          },
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

  Future<void> open(WidgetTester tester, String gate) async {
    tester.view.physicalSize = const Size(1290, 4200);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await tester.tap(find.text(gate));
    await tester.pumpAndSettle();
  }

  Map<String, Object?> order(int id, String state, String stateLabel, String amount) => {
    'kind': 'order',
    'key': 'order:$id:$state',
    'order_id': id,
    'code': 'ORD-$id',
    'customer_name': 'مخبز النور',
    'order_status': 'delivered',
    'order_status_label': 'تم الاستلام',
    'state': state,
    'state_label': stateLabel,
    'amount': amount,
    'occurred_at': '2026-10-05T10:00:00+02:00',
  };

  // ما يرسله الخادمُ لـ`gate=pending`، بشكله: فترةٌ مفتوحة وأخرى قيد الإغلاق.
  final pending = ProfitSources.fromJson({
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
          order(41, 'awaiting_period_end', 'بانتظار انتهاء الفترة', '120.00'),
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
        'lines': [order(33, 'awaiting_payment', 'بانتظار التحصيل', '90.00')],
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

  testWidgets('«معلّقة» opens a page, not a sheet', (tester) async {
    // Arrange
    when(() => getSources(7, ProfitGate.pending)).thenAnswer((_) async => Right(pending));

    // Act
    await open(tester, 'معلّقة');

    // Assert — صفحةٌ بمسارها وزرِّ رجوعها، فوق صفحة المستثمر.
    verify(() => getSources(7, ProfitGate.pending)).called(1);
    expect(pushed, '/investors/7/profit/pending');
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.widgetWithText(AppBar, 'أرباح معلّقة'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
  });

  testWidgets('the summary splits the figure over its periods, and each period is a card', (
    tester,
  ) async {
    // Arrange
    when(() => getSources(7, ProfitGate.pending)).thenAnswer((_) async => Right(pending));

    // Act
    await open(tester, 'معلّقة');

    // Assert — المجموعُ مرّةً في الملخّص، وكلُّ فترةٍ باسمها ومجموعِها مرّتين: في الملخّص وعلى
    // بطاقتها. وشريطُ الحصص لأن الفترتين موجبتان.
    expect(find.text('195 د.ل'), findsOneWidget);
    expect(find.text('P3'), findsNWidgets(2));
    expect(find.text('105 د.ل'), findsNWidgets(2));
    expect(find.text('P2'), findsNWidgets(2));
    expect(find.byKey(const ValueKey('profit-share-bar')), findsOneWidget);
    expect(find.text('ORD-41'), findsOneWidget);
    expect(find.text('120 د.ل'), findsOneWidget);
    expect(find.text('نصيبه من المصاريف'), findsOneWidget);
    expect(find.text('-15 د.ل'), findsOneWidget);
  });

  testWidgets('a period says once what its orders wait for, not on every row', (tester) async {
    // Arrange
    when(() => getSources(7, ProfitGate.pending)).thenAnswer((_) async => Right(pending));

    // Act
    await open(tester, 'معلّقة');

    // Assert — الحالةُ وأيامُ الفترة سطرٌ واحد تحت اسمها، ولا شارةَ على الطلبية، ولا «مفتوحة»
    // بجانب «بانتظار انتهاء الفترة» تقول الشيءَ نفسَه.
    expect(find.text('بانتظار انتهاء الفترة · 1 – 31 أكتوبر 2026'), findsOneWidget);
    expect(find.text('بانتظار التحصيل · 1 – 30 سبتمبر 2026'), findsOneWidget);
    expect(find.text('بانتظار انتهاء الفترة'), findsNothing);
    expect(find.text('بانتظار التحصيل'), findsNothing);
    expect(find.text('مفتوحة'), findsNothing);
  });

  testWidgets('a period whose orders wait for different things heads each wait once', (
    tester,
  ) async {
    // Arrange — فترةٌ قيد الإغلاق: طلبيةٌ أُفرج عن ربحها، وأخرى تنتظر التحصيل، والإفراجُ سالباً.
    when(() => getSources(7, ProfitGate.pending)).thenAnswer(
      (_) async => Right(
        ProfitSources.fromJson({
          'gate': 'pending',
          'total': '90.00',
          'groups': [
            {
              'key': 'period:2',
              'title': 'P2',
              'starts_on': '2026-09-01',
              'ends_on': '2026-09-30',
              'status': 'closing',
              'status_label': 'قيد الإغلاق',
              'total': '90.00',
              'lines': [
                order(33, 'awaiting_payment', 'بانتظار التحصيل', '90.00'),
                order(30, 'released', 'استُلم الربح', '300.00'),
                {
                  'kind': 'entry',
                  'key': 'type:profit_release',
                  'label': 'أُفرج عنه',
                  'amount': '-300.00',
                  'occurred_at': '2026-10-01T10:00:00+02:00',
                },
              ],
            },
          ],
        }),
      ),
    );

    // Act
    await open(tester, 'معلّقة');

    // Assert — حالُ الفترة تحت اسمها، وكلُّ انتظارٍ عنوانٌ فوق طلبياته. وفترةٌ واحدة لا ملخّصَ
    // يقسمها: اسمُها مرّةً على بطاقتها.
    expect(find.text('قيد الإغلاق · 1 – 30 سبتمبر 2026'), findsOneWidget);
    expect(find.text('بانتظار التحصيل'), findsOneWidget);
    expect(find.text('استُلم الربح'), findsOneWidget);
    expect(find.text('P2'), findsOneWidget);
    expect(find.byKey(const ValueKey('profit-share-bar')), findsNothing);
    expect(find.text('أُفرج عنه'), findsOneWidget);
  });

  testWidgets('no share bar when a period is in loss, and a nameless deal still has a name', (
    tester,
  ) async {
    // Arrange — صفقةٌ قديمة اسمُها فارغ، وفترةٌ بخسارة.
    when(() => getSources(7, ProfitGate.pending)).thenAnswer(
      (_) async => Right(
        ProfitSources.fromJson({
          'gate': 'pending',
          'total': '70.00',
          'groups': [
            {
              'key': 'period:3',
              'title': 'P3',
              'status': 'open',
              'status_label': 'مفتوحة',
              'total': '-20.00',
              'lines': [
                {'kind': 'entry', 'key': 'expenses', 'label': 'نصيبه من المصاريف', 'amount': '-20.00'},
              ],
            },
            {
              'key': 'deal:4',
              'title': '',
              'total': '90.00',
              'lines': [order(12, 'awaiting_deal_close', 'بانتظار إقفال الصفقة', '90.00')],
            },
          ],
        }),
      ),
    );

    // Act
    await open(tester, 'معلّقة');

    // Assert — الشريطُ يقسم موجباً فقط، والقائمةُ تبقى. والصفقةُ بلا اسمٍ «صفقة سابقة».
    expect(find.byKey(const ValueKey('profit-share-bar')), findsNothing);
    expect(find.text('-20 د.ل'), findsNWidgets(3));
    expect(find.text('صفقة سابقة'), findsNWidgets(2));
    expect(find.text('بانتظار إقفال الصفقة'), findsOneWidget);
  });

  testWidgets('an order opens over the page, which stays beneath it', (tester) async {
    // Arrange
    when(() => getSources(7, ProfitGate.pending)).thenAnswer((_) async => Right(pending));
    await open(tester, 'معلّقة');

    // Act
    await tester.tap(find.text('ORD-41'));
    await tester.pumpAndSettle();

    // Assert
    expect(openedOrder, '/orders/41');

    // «Back» بالإنجليزية ما يبحث عنه pageBack، والتطبيقُ بالعربية.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'أرباح معلّقة'), findsOneWidget);
  });

  testWidgets('«متاحة للسحب» is one card whose release opens onto its orders', (tester) async {
    // Arrange
    when(() => getSources(7, ProfitGate.available)).thenAnswer((_) async => Right(available));

    // Act
    await open(tester, 'متاحة للسحب');

    // Assert — قائمةٌ واحدة بلا عنوان: لا ملخّصَ يقسمها، والإفراجُ مطويٌّ على طلبياته.
    expect(find.widgetWithText(AppBar, 'أرباح متاحة للسحب'), findsOneWidget);
    expect(find.text('200 د.ل'), findsOneWidget);
    expect(find.text('أُفرج عنه من P2'), findsOneWidget);
    expect(find.text('سحب أرباح'), findsOneWidget);
    expect(find.text('-100 د.ل'), findsOneWidget);
    expect(find.text('ORD-30'), findsNothing);

    await tester.tap(find.text('أُفرج عنه من P2'));
    await tester.pumpAndSettle();

    expect(find.text('ORD-30'), findsOneWidget);
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
    expect(pushed, '/investors/7/profit/awaiting_delivery');
    expect(find.widgetWithText(AppBar, 'ربح قيد التسليم'), findsOneWidget);
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

  test('a gate is read back from its path segment, and a stranger one is not a gate', () {
    // Arrange
    const segments = ['awaiting_delivery', 'pending', 'available', 'wallet', null];

    // Act
    final gates = segments.map(ProfitGate.fromValue).toList();

    // Assert
    expect(gates, [ProfitGate.awaitingDelivery, ProfitGate.pending, ProfitGate.available, null, null]);
  });
}
