import 'package:dartz/dartz.dart' hide Order;
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/models/transition_field.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/order_status_cubit.dart';
import 'package:dayaa/features/orders/repositories/order_repository.dart';
import 'package:dayaa/features/orders/usecases/change_order_status.dart';
import 'package:dayaa/features/orders/usecases/get_order.dart';
import 'package:dayaa/features/shipping_companies/models/shipping_company.dart';
import 'package:dayaa/features/shipping_companies/repositories/shipping_company_repository.dart';
import 'package:dayaa/features/shipping_companies/usecases/get_shipping_companies.dart';
import 'package:dayaa/features/warehouses/models/warehouse.dart';
import 'package:dayaa/features/warehouses/repositories/warehouse_repository.dart';
import 'package:dayaa/features/warehouses/usecases/get_warehouses.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockOrderRepository extends Mock implements OrderRepository {}

class _MockWarehouseRepository extends Mock implements WarehouseRepository {}

class _MockShippingCompanyRepository extends Mock implements ShippingCompanyRepository {}

/// «الحساب» على شاشة نقل الحالة — TREASURY-DESIGN §١٩: يتبع الطريقة المختارة، ورفضُ الخزينة
/// يُعلَّق تحت حقله.
///
/// Arrange - Act - Assert throughout.
void main() {
  late _MockOrderRepository repository;
  late OrderStatusCubit cubit;

  const amount = TransitionField(
    key: 'payment_amount',
    type: TransitionFieldType.number,
    label: 'المبلغ المقبوض',
  );

  const method = TransitionField(
    key: 'payment_method',
    type: TransitionFieldType.paymentMethod,
    label: 'طريقة الدفع',
    options: [
      TransitionFieldOption(value: 'cash', label: 'كاش'),
      TransitionFieldOption(value: 'bank_card', label: 'بطاقة'),
    ],
  );

  const account = TransitionField(
    key: TransitionField.paymentAccountKey,
    type: TransitionFieldType.treasuryAccount,
    label: 'الحساب',
  );

  const toDelivered = OrderTransition(
    status: OrderStatus.delivered,
    label: 'تم الاستلام',
    fields: [amount, method, account],
  );

  const order = Order(
    id: 7,
    code: '7',
    status: OrderStatus.outForDelivery,
    statusLabel: 'جاري التوصيل',
    isFinal: false,
    availableTransitions: [toDelivered],
    customerId: 5,
    cityId: 3,
    designSource: 'customer',
    cityName: 'طرابلس',
    fulfilmentTypeLabel: 'توصيل',
    isOfficePickup: false,
    designSourceLabel: 'تصميم العميل',
    itemsAreEditable: false,
    designsAreEditable: false,
    itemsTotal: '330.00',
    designFee: '0.00',
    deliveryPrice: '20.00',
    discount: '0.00',
    grandTotal: '350.00',
  );

  Paginated<T> none<T>() => Paginated<T>(
    items: const [],
    meta: const PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: 0),
  );

  setUpAll(() => registerFallbackValue(OrderStatus.delivered));

  setUp(() async {
    repository = _MockOrderRepository();
    final warehouses = _MockWarehouseRepository();
    final carriers = _MockShippingCompanyRepository();

    when(
      () => warehouses.warehouses(
        search: any(named: 'search'),
        type: any(named: 'type'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => Right(none<Warehouse>()));
    when(
      () => carriers.companies(
        search: any(named: 'search'),
        isActive: any(named: 'isActive'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => Right(none<ShippingCompany>()));
    when(() => repository.order(7)).thenAnswer((_) async => const Right(order));

    cubit = OrderStatusCubit(
      orderId: 7,
      getOrder: GetOrder(repository),
      changeStatus: ChangeOrderStatus(repository),
      getWarehouses: GetWarehouses(warehouses),
      getShippingCompanies: GetShippingCompanies(carriers),
    );
    await cubit.load();
  });

  tearDown(() => cubit.close());

  test('تغيّرت الطريقة فيُمسح الحساب المختار — حسابُ الكاش لا يناسب البطاقة', () {
    // Arrange
    cubit
      ..setValue(method.key, 'cash')
      ..setValue(account.key, '9');

    // Act
    cubit.setValue(method.key, 'bank_card');
    final chosen = cubit.state.values[account.key];

    // Assert
    expect(chosen, isNull);
    expect(cubit.state.values[method.key], 'bank_card');
  });

  test('الطريقة نفسها مرةً ثانية لا تمسح الحساب', () {
    // Arrange
    cubit
      ..setValue(method.key, 'cash')
      ..setValue(account.key, '9');

    // Act
    cubit.setValue(method.key, 'cash');
    final chosen = cubit.state.values[account.key];

    // Assert
    expect(chosen, '9');
  });

  group('رفضُ الخزينة', () {
    void refuseWith(Map<String, List<String>> errors) => when(
      () => repository.changeStatus(
        7,
        status: any(named: 'status'),
        reason: any(named: 'reason'),
        fields: any(named: 'fields'),
      ),
    ).thenAnswer(
      (_) async => Left(
        Failure.server(message: errors.values.first.first, statusCode: 422, fieldErrors: errors),
      ),
    );

    test('يُقرأ تحت حقله باسمه، ولا يحتاج توستاً', () async {
      // Arrange
      refuseWith({
        'fields.payment_account_id': ['الحساب لا يقبل البطاقة'],
      });

      // Act
      await cubit.submit();
      final error = cubit.state.fieldError(account.key);

      // Assert
      expect(error, 'الحساب لا يقبل البطاقة');
      expect(cubit.state.hasUnrenderedErrors, isFalse);
    });

    test('ما لا حقل له على الشاشة يُقال في التوست', () async {
      // Arrange
      refuseWith({
        'fields.settlement_fee': ['أكبر من العهدة'],
        'status': ['لا يُنقل الآن'],
      });

      // Act
      await cubit.submit();
      final unrendered = cubit.state.hasUnrenderedErrors;

      // Assert
      expect(unrendered, isTrue);
    });
  });
}
