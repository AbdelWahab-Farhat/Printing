import 'package:dartz/dartz.dart' hide Order;
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/instant_orders/models/instant_models.dart';
import 'package:dayaa/features/instant_orders/presentation/viewmodel/instant_order_cubit.dart';
import 'package:dayaa/features/instant_orders/repositories/instant_order_repository.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements InstantOrderRepository {}

/// The instant-order screen's logic — INSTANT-ORDERS-PLAN.md §3–§4.
///
/// Arrange - Act - Assert throughout.
void main() {
  late _MockRepository repository;

  const qarji = SellingBranch(id: 7, name: 'مكتب قرجي', warehouseName: 'مخزن بريمولا');
  const waliAlAhd = SellingBranch(id: 8, name: 'مكتب ولي العهد');

  const bags = InstantProduct(
    id: 1,
    name: 'أكياس شحن',
    unitLabel: 'كجم',
    variants: [
      InstantVariant(
        id: 11,
        label: '35×40',
        stockItemId: 101,
        available: 7,
        priceTiers: [
          InstantPriceTier(minQuantity: 1, unitPrice: 10),
          InstantPriceTier(minQuantity: 10, unitPrice: 9),
        ],
      ),
    ],
  );

  const catalogue = InstantCatalogue(products: [bags], warehouseName: 'مخزن بريمولا');

  setUp(() {
    repository = _MockRepository();
    when(() => repository.products(any())).thenAnswer((_) async => const Right(catalogue));
  });

  test('a single branch is chosen for the employee and its catalogue is read', () async {
    // Arrange
    when(() => repository.branches()).thenAnswer((_) async => const Right([qarji]));
    final cubit = InstantOrderCubit(repository: repository);

    // Act
    await cubit.load();

    // Assert
    expect(cubit.state.branchId, 7);
    expect(cubit.state.catalogue?.warehouseName, 'مخزن بريمولا');
    verify(() => repository.products(7)).called(1);
  });

  test('several branches wait for a choice, and no products are listed before it', () async {
    // Arrange
    when(() => repository.branches()).thenAnswer((_) async => const Right([qarji, waliAlAhd]));
    final cubit = InstantOrderCubit(repository: repository);

    // Act
    await cubit.load();

    // Assert
    expect(cubit.state.branchId, isNull);
    expect(cubit.state.catalogue, isNull);
    verifyNever(() => repository.products(any()));

    await cubit.chooseBranch(8);
    expect(cubit.state.branchId, 8);
    verify(() => repository.products(8)).called(1);
  });

  test('a line asking more than the shelf holds is marked, counting repeated sizes together', () async {
    // Arrange
    when(() => repository.branches()).thenAnswer((_) async => const Right([qarji]));
    final cubit = InstantOrderCubit(repository: repository);
    await cubit.load();

    // Act — 5 then 5 more of a size with 7 free: one line of 10.
    cubit
      ..addLine(bags, bags.variants.single, 5)
      ..addLine(bags, bags.variants.single, 5);

    // Assert
    expect(cubit.state.lines, hasLength(1));
    expect(cubit.state.lines.single.quantity, 10);
    expect(cubit.shortfallFor(cubit.state.lines.single), 'الكمية غير متوفرة — المتاح 7 كجم');
    expect(cubit.hasShortfall, isTrue);

    cubit.setQuantity(0, 7);
    expect(cubit.hasShortfall, isFalse);
    // 7 × 10 — the tier from 10 on does not apply yet.
    expect(cubit.estimatedTotal, 70);
  });

  test('a sale is sent with the branch, the customer as typed and the lines', () async {
    // Arrange
    when(() => repository.branches()).thenAnswer((_) async => const Right([qarji]));
    when(
      () => repository.create(
        clientToken: any(named: 'clientToken'),
        branchId: any(named: 'branchId'),
        phone: any(named: 'phone'),
        name: any(named: 'name'),
        cityId: any(named: 'cityId'),
        regionId: any(named: 'regionId'),
        lines: any(named: 'lines'),
        discount: any(named: 'discount'),
        notes: any(named: 'notes'),
      ),
    ).thenAnswer((_) async => const Left(Failure.server(message: 'refused')));
    final cubit = InstantOrderCubit(repository: repository);
    await cubit.load();
    cubit.addLine(bags, bags.variants.single, 3);

    // Act
    await cubit.submit(phone: '0912345678', name: 'سالم', cityId: 3, regionId: null, discount: 0, notes: null);
    await cubit.submit(phone: '0912345678', name: 'سالم', cityId: 3, regionId: null, discount: 0, notes: null);

    // Assert — the same token both times, so a retry is never a second sale.
    final tokens = verify(
      () => repository.create(
        clientToken: captureAny(named: 'clientToken'),
        branchId: 7,
        phone: '0912345678',
        name: 'سالم',
        cityId: 3,
        regionId: null,
        lines: any(named: 'lines'),
        discount: 0,
        notes: null,
      ),
    ).captured;

    expect(tokens, hasLength(2));
    expect(tokens.first, tokens.last);
    expect(cubit.state.submitFailure, isA<ServerFailure>());
  });

  test('an edit stays at its branch and counts what the order holds as free to it', () async {
    // Arrange
    when(() => repository.branches()).thenAnswer((_) async => const Right([qarji]));
    final order = Order.fromJson(_instantOrderJson);
    final cubit = InstantOrderCubit(repository: repository, editing: order);

    // Act
    await cubit.load();

    // Assert — 7 free on the shelf plus the 5 this order already holds.
    expect(cubit.state.branchId, 7);
    expect(cubit.state.lines.single.lineId, 501);
    expect(cubit.availableFor(11), 12);

    cubit.setQuantity(0, 12);
    expect(cubit.hasShortfall, isFalse);

    await cubit.chooseBranch(8);
    expect(cubit.state.branchId, 7, reason: 'an edit never moves the branch');
  });
}

const Map<String, dynamic> _instantOrderJson = {
  'id': 90,
  'code': '1090',
  'status': 'new',
  'status_label': 'جديدة',
  'order_type': 'instant',
  'order_type_label': 'فورية',
  'is_late': false,
  'is_final': false,
  'customer_id': 4,
  'city_id': 7,
  'city_name': 'مكتب قرجي',
  'design_source': 'none',
  'fulfilment_type_label': 'استلام مكتب',
  'is_office_pickup': true,
  'design_source_label': 'بدون تصميم',
  'items_total': '50.00',
  'design_fee': '0.00',
  'delivery_price': '0.00',
  'discount': '0.00',
  'grand_total': '50.00',
  'items': [
    {
      'id': 501,
      'product_id': 1,
      'product_variant_id': 11,
      'product_name': 'أكياس شحن',
      'variant_label': '35×40',
      'pricing_unit_label': 'كجم',
      'quantity': '5.000',
    },
  ],
};
