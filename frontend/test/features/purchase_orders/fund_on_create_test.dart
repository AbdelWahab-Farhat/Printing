import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/investment_fund/repositories/investment_fund_repository.dart';
import 'package:dayaa/features/investment_fund/usecases/investment_fund_usecases.dart';
import 'package:dayaa/features/purchase_orders/models/purchase_order.dart';
import 'package:dayaa/features/purchase_orders/presentation/viewmodel/save_purchase_order_cubit.dart';
import 'package:dayaa/features/purchase_orders/repositories/purchase_order_repository.dart';
import 'package:dayaa/features/purchase_orders/usecases/purchase_order_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// **أن يُموَّل الأمرُ في الضغطة التي أنشأته.**
///
/// كان التمويلُ باباً لا يُفتح إلا بعد الحفظ — من زرِّ الشاشة العائم على تفصيل الأمر — فمن أراد
/// أن يشتري الصندوقُ لورياً أنشأ الأمر، ثم بحث عن الزرّ، ثم ملأ شاشةً ثانية. والشراءُ قرارٌ
/// يُتَّخذ قبل الإنشاء لا بعده.
///
/// وما يُثبَّت هنا ثلاثة:
///
/// 1. **الحفظُ أوّلاً ثم التمويل** — لا رقمَ لأمرٍ لم يُكتب بعد، فلا بابَ للصندوق قبله.
/// 2. **سقوطُ التمويل لا يبتلع الأمر** — النقدُ قد لا يكفي، والأمرُ مكتوبٌ على كل حال، فيعود
///    إلى الشاشة التي خلفه كاملاً ومعه سببُ الرفض.
/// 3. **بلا طلبٍ لا يُطرق البابُ أصلاً** — أمرُ شراءٍ عاديّ يمرّ كما كان يمرّ.
///
/// Arrange - Act - Assert في كلٍّ منها.
class _MockPurchaseOrderRepository extends Mock
    implements PurchaseOrderRepository {}

class _MockInvestmentFundRepository extends Mock
    implements InvestmentFundRepository {}

void main() {
  late _MockPurchaseOrderRepository orders;
  late _MockInvestmentFundRepository fund;

  /// ما يردّه الخادمُ بعد الكتابة — ورقمُه هو ما يُموَّل.
  const saved = PurchaseOrder(
    id: 77,
    vendorId: 3,
    status: PurchaseOrderStatus.fresh,
    statusLabel: 'جديد',
    orderDate: '2026-09-22',
  );

  const shortOfCash = Failure.server(
    message: 'نقدُ الصندوق لا يكفي: المطلوب 8,500 والمتاح 3,200',
    statusCode: 422,
  );

  setUpAll(() {
    registerFallbackValue(<PurchaseOrderLine>[]);
    registerFallbackValue(<PurchaseOrderAdditionalCostLine>[]);
  });

  setUp(() {
    orders = _MockPurchaseOrderRepository();
    fund = _MockInvestmentFundRepository();

    when(
      () => orders.create(
        vendorId: any(named: 'vendorId'),
        warehouseId: any(named: 'warehouseId'),
        orderDate: any(named: 'orderDate'),
        items: any(named: 'items'),
        additionalCosts: any(named: 'additionalCosts'),
        expectedDate: any(named: 'expectedDate'),
        notes: any(named: 'notes'),
      ),
    ).thenAnswer((_) async => const Right(saved));
  });

  SavePurchaseOrderCubit build() => SavePurchaseOrderCubit(
    saveOrder: SavePurchaseOrder(orders),
    buyWithFund: BuyWithFund(fund),
  );

  Future<void> submit(
    SavePurchaseOrderCubit cubit, {
    FundPurchaseRequest? funding,
  }) => cubit.submit(
    vendorId: 3,
    warehouseId: 1,
    orderDate: '2026-09-22',
    items: const [
      DraftLine(stockItemId: 4, quantity: '100', baseTotalCost: '5000'),
      DraftLine(stockItemId: 9, quantity: '50', baseTotalCost: '2000'),
    ],
    funding: funding,
  );

  blocTest<SavePurchaseOrderCubit, SavePurchaseOrderState>(
    'أمرٌ يُنشأ ويشتريه الصندوقُ في الضغطة نفسها',
    setUp: () {
      // Arrange — الرفّان معاً، وسعرُ سادةِ أحدهما مكتوبٌ والآخرُ متروك: هذا بالضبط ما تسمح به
      // الشاشة، وما يجب أن يصل إلى الخادم بلا مفتاحٍ للفارغ — صفرٌ يسلّم المطبعةَ بضاعةً بلا ثمن.
      when(
        () => fund.buyPurchaseOrder(
          purchaseOrderId: 77,
          stockItemIds: [4, 9],
          printingSalePrices: {4: '3.5'},
        ),
      ).thenAnswer((_) async => const Right(unit));
    },
    build: build,
    // Act
    act: (cubit) => submit(
      cubit,
      funding: (stockItemIds: [4, 9], printingSalePrices: {4: '3.5'}),
    ),
    // Assert — حالةٌ واحدةٌ للعملين: الزرُّ يبقى دائراً حتى يفرغ البابان، فلا تُغلق الشاشة على
    // تمويلٍ ما زال في الطريق.
    expect: () => const [
      SavePurchaseOrderState.submitting(),
      SavePurchaseOrderState.success(saved),
    ],
    verify: (_) {
      verify(
        () => fund.buyPurchaseOrder(
          purchaseOrderId: 77,
          stockItemIds: [4, 9],
          printingSalePrices: {4: '3.5'},
        ),
      ).called(1);
    },
  );

  blocTest<SavePurchaseOrderCubit, SavePurchaseOrderState>(
    'سقوطُ التمويل لا يُسقط الأمر — يعود ومعه سببُ الرفض',
    setUp: () {
      // Arrange — «لا يكفي النقد» أكثرُ الردود وقوعاً: الصندوقُ يساوي كثيراً وفي درجه قليل.
      when(
        () => fund.buyPurchaseOrder(
          purchaseOrderId: 77,
          stockItemIds: [4, 9],
          printingSalePrices: const {},
        ),
      ).thenAnswer((_) async => const Left(shortOfCash));
    },
    build: build,
    // Act
    act: (cubit) => submit(
      cubit,
      funding: (stockItemIds: [4, 9], printingSalePrices: const {}),
    ),
    // Assert — **نجاحٌ يحمل عثرة، لا فشل.** الأمرُ كُتب في الخادم، فحالةُ فشلٍ هنا تُبقي الشاشة
    // مفتوحةً على نموذجٍ ضغطةٌ ثانيةٌ عليه تكتب أمراً ثانياً.
    expect: () => const [
      SavePurchaseOrderState.submitting(),
      SavePurchaseOrderState.success(saved, fundingFailure: shortOfCash),
    ],
  );

  blocTest<SavePurchaseOrderCubit, SavePurchaseOrderState>(
    'أمرٌ بلا تمويلٍ مطلوب لا يطرق بابَ الصندوق',
    build: build,
    // Act
    act: submit,
    // Assert
    expect: () => const [
      SavePurchaseOrderState.submitting(),
      SavePurchaseOrderState.success(saved),
    ],
    verify: (_) {
      verifyNever(
        () => fund.buyPurchaseOrder(
          purchaseOrderId: any(named: 'purchaseOrderId'),
          stockItemIds: any(named: 'stockItemIds'),
          printingSalePrices: any(named: 'printingSalePrices'),
        ),
      );
    },
  );

  blocTest<SavePurchaseOrderCubit, SavePurchaseOrderState>(
    'أمرٌ رفضه الخادم لا يُموَّل — لا رقمَ لما لم يُكتب',
    setUp: () {
      // Arrange
      when(
        () => orders.create(
          vendorId: any(named: 'vendorId'),
          warehouseId: any(named: 'warehouseId'),
          orderDate: any(named: 'orderDate'),
          items: any(named: 'items'),
          additionalCosts: any(named: 'additionalCosts'),
          expectedDate: any(named: 'expectedDate'),
          notes: any(named: 'notes'),
        ),
      ).thenAnswer(
        (_) async => const Left(
          Failure.server(
            message: 'البيانات المدخلة غير صحيحة',
            statusCode: 422,
            fieldErrors: {
              'items.0.stock_item_id': ['المادة المحددة غير موجودة'],
            },
          ),
        ),
      );
    },
    build: build,
    // Act
    act: (cubit) => submit(
      cubit,
      funding: (stockItemIds: [4, 9], printingSalePrices: const {}),
    ),
    // Assert
    expect: () => [
      const SavePurchaseOrderState.submitting(),
      isA<SavePurchaseOrderFailure>(),
    ],
    verify: (_) {
      verifyNever(
        () => fund.buyPurchaseOrder(
          purchaseOrderId: any(named: 'purchaseOrderId'),
          stockItemIds: any(named: 'stockItemIds'),
          printingSalePrices: any(named: 'printingSalePrices'),
        ),
      );
    },
  );
}
