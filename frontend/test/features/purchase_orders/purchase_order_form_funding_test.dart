import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/investment_fund/models/fund_standing.dart';
import 'package:dayaa/features/investment_fund/models/period_orders.dart';
import 'package:dayaa/features/investment_fund/repositories/investment_fund_repository.dart';
import 'package:dayaa/features/investment_fund/usecases/investment_fund_usecases.dart';
import 'package:dayaa/features/purchase_orders/models/purchase_order.dart';
import 'package:dayaa/features/purchase_orders/presentation/viewmodel/save_purchase_order_cubit.dart';
import 'package:dayaa/features/purchase_orders/presentation/views/purchase_order_form_page.dart';
import 'package:dayaa/features/purchase_orders/repositories/purchase_order_repository.dart';
import 'package:dayaa/features/purchase_orders/usecases/purchase_order_usecases.dart';
import 'package:dayaa/features/warehouses/models/warehouse_stock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// بابُ الصندوق على نموذج أمر الشراء نفسِه.
///
/// **السؤالُ الذي تجيبه هذه الاختبارات: لمن يظهر، ومتى، وبأيّ رقم.** التمويلُ صلاحيةُ من يدير
/// المستثمرين — لا صلاحيةُ من يشتري — فبائعٌ يرفع أمراً لا يرى الصفَّ أصلاً. والأمرُ الذي موّله
/// الصندوقُ مرّةً لا يُموَّل ثانية، فالصفُّ يغيب عنه لا يُعرض معطَّلاً.
///
/// **والرقمُ الذي يُعرض تكلفةٌ واصلة لا مدفوعاً للمورد.** التوصيلُ والجمارك تُوزَّع على البنود
/// بنسبة قيمتها — هكذا يحسبها الخادم يوم الاستلام — فرفٌّ اختير من أمرٍ عليه شحن يحمل حصّته
/// منه. وبدون ذلك يقول النموذجُ «يكفي النقد» ثم يردّ الخادمُ «لا يكفي».
///
/// Arrange - Act - Assert في كلٍّ منها.
class _MockPurchaseOrderRepository extends Mock
    implements PurchaseOrderRepository {}

class _FakeFundRepository implements InvestmentFundRepository {
  _FakeFundRepository(this.cash, {this.defaultPlainSalePrice});

  /// null: قراءةٌ سقطت — لا صندوقٌ بلا نقد.
  final String? cash;

  /// سعرُ السادة الافتراضي كما يصل مع اللوحة. null يعني «لا افتراض».
  final String? defaultPlainSalePrice;

  @override
  Future<Either<Failure, FundStanding>> standing() async {
    final held = cash;

    if (held == null) {
      return const Left(Failure.network(message: 'تعذّر الاتصال'));
    }

    return Right(
      FundStanding(
        defaultPlainSalePrice: defaultPlainSalePrice,
        valuation: FundValuation(
          cash: held,
          stockOnShelf: '0.00',
          goodsInFlight: '0.00',
          receivablesAtCost: '0.00',
          profitOwed: '0.00',
          total: held,
        ),
      ),
    );
  }

  /// **الشراءُ يُرفض دائماً هنا**: ما يُختبر هو ما يقع بعد الرفض، لا الرفضُ نفسُه.
  @override
  Future<Either<Failure, Unit>> buyPurchaseOrder({
    required int purchaseOrderId,
    required List<int> stockItemIds,
    Map<int, String> printingSalePrices = const {},
  }) async => const Left(
    Failure.server(
      message: 'نقدُ الصندوق لا يكفي: المطلوب 7,700 والمتاح 3,000',
      statusCode: 422,
    ),
  );

  // أبوابٌ يطلبها العقدُ ولا تُطرق هنا.

  @override
  Future<Either<Failure, FundPeriod>> openPeriod() async =>
      const Left(Failure.server(message: 'لم يُستدعَ'));

  @override
  Future<Either<Failure, FundPeriod>> closePeriod({String? overrideReason}) async =>
      const Left(Failure.server(message: 'لم يُستدعَ'));

  @override
  Future<Either<Failure, List<FundPeriod>>> periods() async =>
      const Right(<FundPeriod>[]);

  @override
  Future<Either<Failure, PeriodOrders>> periodOrders(int periodId) async =>
      const Left(Failure.server(message: 'لم يُستدعَ'));

  @override
  Future<Either<Failure, DepositReceipt>> deposit({
    required int investorId,
    required String amount,
    String? notes,
  }) async => const Left(Failure.server(message: 'لم يُستدعَ'));

  @override
  Future<Either<Failure, Unit>> withdraw({
    required int investorId,
    required String amount,
    String? notes,
  }) async => const Left(Failure.server(message: 'لم يُستدعَ'));

  @override
  Future<Either<Failure, Unit>> recordExpense({
    required String kind,
    required String name,
    required String amount,
    required String incurredOn,
    String? notes,
  }) async => const Left(Failure.server(message: 'لم يُستدعَ'));
}

void main() {
  late Session session;
  late _MockPurchaseOrderRepository orders;

  setUpAll(() {
    registerFallbackValue(<PurchaseOrderLine>[]);
    registerFallbackValue(<PurchaseOrderAdditionalCostLine>[]);
  });

  /// أمرٌ قائمٌ لم يموّله أحد: رفّان، وشحنٌ يُوزَّع عليهما.
  const order = PurchaseOrder(
    id: 77,
    vendorId: 3,
    warehouseId: 1,
    status: PurchaseOrderStatus.fresh,
    statusLabel: 'جديد',
    orderDate: '2026-09-22',
    items: [
      PurchaseOrderItem(
        id: 1,
        stockItemId: 4,
        stockItem: StockItemRef(
          id: 4,
          code: 'S4',
          name: 'كيس شحن',
          displayName: 'كيس شحن 25*35',
        ),
        quantityOrdered: '100.000',
        quantityReceived: '0.000',
        quantityRemaining: '100.000',
        baseTotalCost: '5000.00',
        unit: 'kilogram',
        unitLabel: 'كجم',
      ),
      PurchaseOrderItem(
        id: 2,
        stockItemId: 9,
        stockItem: StockItemRef(
          id: 9,
          code: 'S9',
          name: 'كيس شحن',
          displayName: 'كيس شحن 30*40',
        ),
        quantityOrdered: '50.000',
        quantityReceived: '0.000',
        quantityRemaining: '50.000',
        baseTotalCost: '2000.00',
        unit: 'piece',
        unitLabel: 'قطعة',
      ),
    ],
    additionalCosts: [
      PurchaseOrderAdditionalCost(id: 1, name: 'توصيل', amount: '700.00'),
    ],
  );

  AuthUser userWith(List<String> permissions) => AuthUser(
    id: 1,
    name: 'عبدالوهاب',
    phone: '0911234567',
    permissions: permissions,
  );

  Future<void> register(String? cash, {String? plainPrice}) async {
    await Injector.reset();
    session = Session();
    orders = _MockPurchaseOrderRepository();

    final fund = _FakeFundRepository(cash, defaultPlainSalePrice: plainPrice);

    sl
      ..registerSingleton<Session>(session)
      ..registerLazySingleton<GetFundStanding>(() => GetFundStanding(fund))
      ..registerFactory<SavePurchaseOrderCubit>(
        () => SavePurchaseOrderCubit(
          saveOrder: SavePurchaseOrder(orders),
          buyWithFund: BuyWithFund(fund),
        ),
      );
  }

  tearDown(Injector.reset);

  /// التمريرُ إلى ما لم يُبنَ بعد. **القائمةُ الأولى لا أيُّ متمرِّر**: لكلّ حقلِ نصٍّ متمرِّرُه
  /// الخاصّ، فالافتراضُ يجد عشرةً ويسقط بـ«too many elements».
  Future<void> scrollTo(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(
      target,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    // التمريرُ يبنيه، و`ensureVisible` يُنزله داخل الإطار: بناؤه وحده يترك نقرةً تقع خارج الشاشة.
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
  }

  Widget host({PurchaseOrder? existing}) => ScreenUtilInit(
    designSize: const Size(430, 932),
    builder: (context, _) => MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: PurchaseOrderFormPage(order: existing),
      ),
    ),
  );

  testWidgets('من يدير المستثمرين يرى صفَّ الصندوق على النموذج', (tester) async {
    // Arrange
    await register('12000.00');
    session.adopt(userWith(['purchase_orders.manage', 'investors.manage']));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — الصفُّ معروضٌ مطفأً: الشراءُ قرارٌ يُتَّخذ، لا افتراضٌ يُنسى.
    expect(find.text('يشتريه الصندوق بماله'), findsOneWidget);
  });

  testWidgets('ومن يشتري ولا يدير المستثمرين لا يراه', (tester) async {
    // Arrange — صلاحيةُ أمر الشراء وحدها.
    await register('12000.00');
    session.adopt(userWith(['purchase_orders.manage']));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('يشتريه الصندوق بماله'), findsNothing);
  });

  testWidgets('وأمرٌ موّله الصندوقُ مرّةً لا يُعرض عليه الصفُّ ثانية', (tester) async {
    // Arrange — التمويلُ يُعلَن قبل وصول البضاعة ومرّةً واحدة، والخادمُ يرفض الثانية باسم
    // صفقتها. فالصفُّ يغيب بدل أن يَعِد بما يُرفض.
    await register('12000.00');
    session.adopt(userWith(['purchase_orders.manage', 'investors.manage']));

    // Act
    await tester.pumpWidget(
      host(
        existing: order.copyWith(
          investorFunding: const [
            PurchaseOrderFunding(
              dealId: 5,
              code: 'FUND',
              isFund: true,
              status: 'open',
              statusLabel: 'مفتوحة',
              investorProfitSharePercent: '50.00',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('يشتريه الصندوق بماله'), findsNothing);
  });

  testWidgets('التفعيلُ يُظهر نقدَ الصندوق وتكلفةَ ما اختير — بحصّته من الشحن', (
    tester,
  ) async {
    // Arrange — ٥٠٠٠ و٢٠٠٠ وشحنُ ٧٠٠: الكلُّ ٧٧٠٠.
    await register('12000.00');
    session.adopt(userWith(['purchase_orders.manage', 'investors.manage']));
    await tester.pumpWidget(host(existing: order));
    await tester.pumpAndSettle();

    // Act — النموذجُ أطولُ من الشاشة، فالصفُّ يُبلَغ بالتمرير كما يبلغه صاحبُه.
    await scrollTo(tester, find.text('يشتريه الصندوق بماله'));
    await tester.tap(find.text('يشتريه الصندوق بماله'));
    await tester.pumpAndSettle();

    // Assert — الرفوفُ كلُّها مختارةٌ بادئَ الأمر، فالتكلفةُ تكلفةُ اللوري كلِّه.
    expect(find.text('12,000 د.ل'), findsOneWidget);
    expect(find.text('7,700 د.ل'), findsOneWidget);
  });

  testWidgets('ورفعُ الصحِّ عن رفٍّ يأخذ معه حصّتَه من الشحن', (tester) async {
    // Arrange
    await register('12000.00');
    session.adopt(userWith(['purchase_orders.manage', 'investors.manage']));
    await tester.pumpWidget(host(existing: order));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('يشتريه الصندوق بماله'));
    await tester.tap(find.text('يشتريه الصندوق بماله'));
    await tester.pumpAndSettle();

    // Act — يبقى الرفُّ الأوّل وحده: ٥٠٠٠ من ٧٠٠٠، فحصّتُه من الشحن ٥٠٠.
    await scrollTo(tester, find.text('كيس شحن 30*40').last);
    await tester.tap(find.text('كيس شحن 30*40').last);
    await tester.pumpAndSettle();

    // Assert — ٥٥٠٠ لا ٥٠٠٠: الشحنُ يُوزَّع بنسبة القيمة، وهو ما سيقيس به الخادمُ نقدَ الصندوق.
    //
    // ومرّتان لأنهما رقمان متساويان بحقّ: تكلفةُ الرفّ الباقي واصلةً (٥٠٠٠ + ٥٠٠)، ومجموعُ ما
    // اختير — ولا شيءَ معه.
    expect(find.text('5,500 د.ل'), findsNWidgets(2));
  });

  testWidgets('وقراءةٌ سقطت لا تُقال «لا يكفي» — ولا «صفر»', (tester) async {
    // Arrange — الشبكةُ ردّت بلا شيء. والصندوقُ قد يكون ملآنَ.
    await register(null);
    session.adopt(userWith(['purchase_orders.manage', 'investors.manage']));
    await tester.pumpWidget(host(existing: order));
    await tester.pumpAndSettle();

    // Act
    await scrollTo(tester, find.text('يشتريه الصندوق بماله'));
    await tester.tap(find.text('يشتريه الصندوق بماله'));
    await tester.pumpAndSettle();

    // Assert — الرفوفُ تُختار والتكلفةُ تُحسب، وسطرُ النقد وحده يغيب: السقفُ يفرضه الخادمُ
    // لحظةَ الشراء ويسمّي الرقمين في رفضه.
    expect(find.text('نقد الصندوق'), findsNothing);
    expect(
      find.text('نقد الصندوق لا يكفي — الباقي بضاعةٌ ومستحقّاتٌ لم تُحصَّل'),
      findsNothing,
    );
    expect(find.text('7,700 د.ل'), findsOneWidget);
  });

  testWidgets('ونقدٌ لا يكفي يُقال قبل الحفظ لا بعده', (tester) async {
    // Arrange — الصندوقُ قد يساوي كثيراً وفي درجه قليل.
    await register('3000.00');
    session.adopt(userWith(['purchase_orders.manage', 'investors.manage']));
    await tester.pumpWidget(host(existing: order));
    await tester.pumpAndSettle();

    // Act
    await scrollTo(tester, find.text('يشتريه الصندوق بماله'));
    await tester.tap(find.text('يشتريه الصندوق بماله'));
    await tester.pumpAndSettle();

    // Assert
    expect(
      find.text('نقد الصندوق لا يكفي — الباقي بضاعةٌ ومستحقّاتٌ لم تُحصَّل'),
      findsOneWidget,
    );
  });

  testWidgets('والرقمُ يتحرّك مع ما يُكتب — شحنٌ يُصحَّح يُصحِّحه معه', (tester) async {
    // Arrange — صفُّ الصندوق مفتوحٌ على ٧٧٠٠: سطران بـ٧٠٠٠ وتوصيلٌ بـ٧٠٠.
    await register('12000.00');
    session.adopt(userWith(['purchase_orders.manage', 'investors.manage']));
    await tester.pumpWidget(host(existing: order));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('يشتريه الصندوق بماله'));
    await tester.tap(find.text('يشتريه الصندوق بماله'));
    await tester.pumpAndSettle();

    // Act — جاءت فاتورةُ الناقل: ٧٠٠ ← ١٧٠٠.
    final delivery = find.widgetWithText(TextField, 'القيمة (د.ل)');
    await tester.ensureVisible(delivery);
    await tester.pumpAndSettle();
    await tester.enterText(delivery, '1700');
    await tester.pumpAndSettle();

    // Assert — ٨٧٠٠. ورقمٌ لا يتحرّك مع ما يُكتب فوقه رقمٌ يكذب، وعليه يُقرَّر إن كان في الدرج
    // ما يكفي.
    await scrollTo(tester, find.text('8,700 د.ل'));
    expect(find.text('8,700 د.ل'), findsOneWidget);
    expect(find.text('7,700 د.ل'), findsNothing);
  });

  testWidgets('الافتراضُ يملأ حقلَ رفّ الكيلو قبل أن يُكتب رقم', (tester) async {
    // Arrange — **الثغرةُ التي يسدّها هذا الحقل.** مربعٌ فارغٌ يُترك فارغاً، والبضاعةُ تمشي
    // إلى المطبعة بالتكلفة، فيعود المستثمرُ يشارك في ربح الطباعة — عكسُ ما وُضع السعرُ له.
    await register('12000.00', plainPrice: '32.000');
    session.adopt(userWith(['purchase_orders.manage', 'investors.manage']));
    await tester.pumpWidget(host(existing: order));
    await tester.pumpAndSettle();

    // Act
    await scrollTo(tester, find.text('يشتريه الصندوق بماله'));
    await tester.tap(find.text('يشتريه الصندوق بماله'));
    await tester.pumpAndSettle();

    // Assert — «32» لا «32.000»: أصفارُ الحشو قرارُ عرضٍ يُتَّخذ مرّةً، والمربعُ يُكتب فيه.
    expect(find.widgetWithText(TextField, '32'), findsOneWidget);
    expect(find.text('سعر السادة للكجم (د.ل، اختياري)'), findsOneWidget);
  });

  testWidgets('ورفٌّ يُعدّ بالقطعة يُفتح فارغاً — الافتراضُ سعرُ كيلو', (tester) async {
    // Arrange — ٣٢ د.ل للكيلو على رفٍّ يُعدّ بالقطعة رقمٌ خاطئٌ يُكتب في صمت.
    await register('12000.00', plainPrice: '32.000');
    session.adopt(userWith(['purchase_orders.manage', 'investors.manage']));
    await tester.pumpWidget(host(existing: order));
    await tester.pumpAndSettle();

    // Act
    await scrollTo(tester, find.text('يشتريه الصندوق بماله'));
    await tester.tap(find.text('يشتريه الصندوق بماله'));
    await tester.pumpAndSettle();

    // Assert — حقلُه هو الفارغ، وتسميتُه تقول وحدتَه فمن أراد سعراً كتبه.
    expect(find.widgetWithText(TextField, '32'), findsOneWidget);
    expect(find.text('سعر السادة للقطعة (د.ل، اختياري)'), findsOneWidget);
  });

  testWidgets('كُتب الأمرُ ولم يشترِه الصندوق: يُقال في حوارٍ لا في شريطٍ عابر', (
    tester,
  ) async {
    // Arrange — **الحارسُ على الشاشة لا يمنع هذه الحال، وهي سببُ بقاء الحوار.** النقدُ الذي
    // قرأته الشاشةُ يكفي، ثم أُنفق بين القراءة والضغطة — أمرٌ آخرُ اشتراه الصندوق، أو سحبٌ خرج
    // — فيرفض الخادمُ وحدَه. والسقفُ الحقيقيّ عنده دائماً.
    await register('12000.00');
    session.adopt(userWith(['purchase_orders.manage', 'investors.manage']));
    when(
      () => orders.update(
        77,
        vendorId: any(named: 'vendorId'),
        warehouseId: any(named: 'warehouseId'),
        orderDate: any(named: 'orderDate'),
        items: any(named: 'items'),
        additionalCosts: any(named: 'additionalCosts'),
        expectedDate: any(named: 'expectedDate'),
        notes: any(named: 'notes'),
      ),
    ).thenAnswer((_) async => const Right(order));

    await tester.pumpWidget(host(existing: order));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('يشتريه الصندوق بماله'));
    await tester.tap(find.text('يشتريه الصندوق بماله'));
    await tester.pumpAndSettle();

    // Act
    await scrollTo(tester, find.text('حفظ التعديلات'));
    await tester.tap(find.text('حفظ التعديلات'));
    await tester.pumpAndSettle();

    // Assert — نصُّ الخادم كما أرسله، ومعه أين يُعاد الكرّة. وشريطٌ يمرّ في ثانيتين على شاشةٍ
    // تُغلق كان يترك صاحبَه يظنّ أن الصندوق اشترى.
    expect(find.text('كُتب الأمر، ولم يشترِه الصندوق'), findsOneWidget);
    expect(
      find.textContaining('نقدُ الصندوق لا يكفي: المطلوب 7,700 والمتاح 3,000'),
      findsOneWidget,
    );
  });

  testWidgets('ونقدٌ لا يكفي يمنع الحفظ أصلاً — لا أمرٌ يُكتب ثم يُعتذَر عنه', (
    tester,
  ) async {
    // Arrange — ٣٠٠٠ في الدرج و٧٧٠٠ على الطاولة. **كان الأمرُ يُكتب ثم يُقال «لم يشترِه
    // الصندوق»**، فيبقى أمرٌ بلا تمويلٍ في النظام ويُطلب من صاحبه أن يعيد الكرّة من شاشةٍ
    // أخرى — وهو ما رفضه المالك: «امنعه أصلاً وليس تحذيراً».
    await register('3000.00');
    session.adopt(userWith(['purchase_orders.manage', 'investors.manage']));

    await tester.pumpWidget(host(existing: order));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('يشتريه الصندوق بماله'));
    await tester.tap(find.text('يشتريه الصندوق بماله'));
    await tester.pumpAndSettle();

    // Act
    await scrollTo(tester, find.text('حفظ التعديلات'));
    await tester.tap(find.text('حفظ التعديلات'));
    await tester.pumpAndSettle();

    // Assert — لا شيءَ ذهب إلى الخادم، ولا حوارَ اعتذار؛ الشكوى مكانُها الشاشةُ التي ما زالت
    // مفتوحةً ليُصلح فيها ما اختار.
    verifyNever(
      () => orders.update(
        any(),
        vendorId: any(named: 'vendorId'),
        warehouseId: any(named: 'warehouseId'),
        orderDate: any(named: 'orderDate'),
        items: any(named: 'items'),
        additionalCosts: any(named: 'additionalCosts'),
        expectedDate: any(named: 'expectedDate'),
        notes: any(named: 'notes'),
      ),
    );
    expect(find.text('كُتب الأمر، ولم يشترِه الصندوق'), findsNothing);
    expect(
      find.text('نقد الصندوق لا يكفي — أزل رفّاً أو ارفع الصحَّ عن «يشتريه الصندوق بماله»'),
      findsOneWidget,
    );

    // **فخّان لا واحد، وترتيبُهما لازم.** الشريطُ يحمل مؤقّتَ إخفاءٍ لثلاث ثوانٍ و`pumpAndSettle`
    // يسوّي الحركاتِ لا المؤقّتات، فيسقط الاختبارُ بـ«A Timer is still pending». وتمريرُ الوقت
    // وحدَه يُطلق حركةَ الخروج ويترك `AnimationController` حيّاً على `Navigator`، فيسقط
    // بـ«disposed with an active Ticker». فالمؤقّتُ أولاً ثم التسوية.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });
}
