import 'package:dartz/dartz.dart' hide Order;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/customers/models/customer_design.dart';
import 'package:printing/features/orders/models/order.dart';
import 'package:printing/features/orders/models/order_status.dart';
import 'package:printing/features/orders/models/transition_field.dart';
import 'package:printing/features/orders/presentation/viewmodel/order_status_cubit.dart';
import 'package:printing/features/orders/repositories/order_repository.dart';
import 'package:printing/features/orders/usecases/change_order_status.dart';
import 'package:printing/features/orders/usecases/get_order.dart';

class _MockOrderRepository extends Mock implements OrderRepository {}

/// Moving one order, and carrying whatever the chosen path asked for.
///
/// **Nothing in here knows what `design_ids` means.** The field arrived on the transition, its
/// value is whatever the widget for that kind produced, and this Cubit turns it into the shape
/// the server described. That is the whole point: a new field on a path costs nothing here.
///
/// Arrange - Act - Assert throughout.
void main() {
  late _MockOrderRepository repository;
  late OrderStatusCubit cubit;

  const artwork = TransitionField(
    key: 'design_ids',
    type: TransitionFieldType.customerDesigns,
    label: 'التصاميم',
    isRequired: true,
    multiple: true,
  );

  const reason = TransitionField(
    key: 'reason',
    type: TransitionFieldType.text,
    label: 'السبب',
    isRequired: true,
    multiline: true,
  );

  const toDesigning = OrderTransition(
    status: OrderStatus.designing,
    label: 'قيد التصميم',
    fields: [artwork],
  );

  const toPrinting = OrderTransition(status: OrderStatus.printing, label: 'قيد الطباعة');

  const toCancelled = OrderTransition(
    status: OrderStatus.cancelled,
    label: 'ملغاة',
    requiresReason: true,
    fields: [reason],
  );

  Order orderWith({List<OrderTransition> transitions = const []}) {
    return Order(
      id: 7,
      code: '7',
      status: OrderStatus.taken,
      statusLabel: 'جديدة',
      isFinal: false,
      availableTransitions: transitions,
      customerId: 5,
      cityId: 3,
      designSource: 'customer',
      cityName: 'طرابلس',
      fulfilmentTypeLabel: 'توصيل',
      isOfficePickup: false,
      designSourceLabel: 'تصميم العميل',
      itemsAreEditable: true,
      designsAreEditable: true,
      itemsTotal: '330.00',
      designFee: '0.00',
      deliveryPrice: '20.00',
      discount: '0.00',
      grandTotal: '350.00',
    );
  }

  CustomerDesign design(int id) => CustomerDesign(
    id: id,
    customerId: 5,
    label: 'تصميم $id',
    kind: DesignKind.image,
    kindLabel: 'صورة',
  );

  setUpAll(() => registerFallbackValue(OrderStatus.printing));

  setUp(() {
    repository = _MockOrderRepository();
    cubit = OrderStatusCubit(
      orderId: 7,
      getOrder: GetOrder(repository),
      changeStatus: ChangeOrderStatus(repository),
    );
  });

  tearDown(() => cubit.close());

  // ───────────────────────────── opening the screen ─────────────────────────────

  test('the only move on offer is chosen already', () async {
    // Arrange
    when(() => repository.order(7))
        .thenAnswer((_) async => Right(orderWith(transitions: [toPrinting])));

    // Act
    await cubit.load();

    // Assert — a list of one that still has to be tapped is a tap that tells nobody anything.
    expect(cubit.state.selected?.status, OrderStatus.printing);
  });

  test('two moves are left for the user to choose between', () async {
    // Arrange
    when(() => repository.order(7)).thenAnswer(
      (_) async => Right(orderWith(transitions: [toDesigning, toPrinting])),
    );

    // Act
    await cubit.load();

    // Assert
    expect(cubit.state.selected, isNull);
    expect(cubit.state.canSubmit, isFalse);
  });

  // ───────────────────────────── what a path asks for ─────────────────────────────

  test('a path that asks for artwork cannot be sent without it', () async {
    // Arrange
    when(() => repository.order(7)).thenAnswer(
      (_) async => Right(orderWith(transitions: [toDesigning, toPrinting])),
    );
    await cubit.load();

    // Act
    cubit.select(toDesigning);

    // Assert — the server refuses this too; the button spares the round trip.
    expect(cubit.state.canSubmit, isFalse);

    // Act — and once it is there.
    cubit.setValue('design_ids', [design(12)]);

    // Assert
    expect(cubit.state.canSubmit, isTrue);
  });

  test('the path beside it asks for nothing and can be sent at once', () async {
    // Arrange
    when(() => repository.order(7)).thenAnswer(
      (_) async => Right(orderWith(transitions: [toDesigning, toPrinting])),
    );
    await cubit.load();

    // Act
    cubit.select(toPrinting);

    // Assert
    expect(cubit.state.canSubmit, isTrue);
  });

  test('changing the destination throws away what was filled in for the last one', () async {
    // Arrange
    when(() => repository.order(7)).thenAnswer(
      (_) async => Right(orderWith(transitions: [toDesigning, toCancelled])),
    );
    await cubit.load();
    cubit.select(toCancelled);
    cubit.setValue('reason', 'العميل غيّر رأيه');

    // Act
    cubit.select(toDesigning);

    // Assert — two paths may both have a `reason`, and carrying one across would send a
    // sentence written about a different move.
    expect(cubit.state.values, isEmpty);
  });

  // ───────────────────────────── sending it ─────────────────────────────

  test('artwork travels as ids and nothing else', () async {
    // Arrange
    when(() => repository.order(7))
        .thenAnswer((_) async => Right(orderWith(transitions: [toDesigning])));
    await cubit.load();
    cubit.setValue('design_ids', [design(12), design(13)]);

    when(
      () => repository.changeStatus(
        7,
        status: any(named: 'status'),
        reason: any(named: 'reason'),
        fields: any(named: 'fields'),
      ),
    ).thenAnswer((_) async => Right(orderWith()));

    // Act
    await cubit.submit();

    // Assert — the file lives in the customer's library; the order points at it.
    final sent = verify(
      () => repository.changeStatus(
        7,
        status: any(named: 'status'),
        reason: any(named: 'reason'),
        fields: captureAny(named: 'fields'),
      ),
    ).captured.last;

    expect(sent, {'design_ids': [12, 13]});
  });

  test('a sentence of spaces is not sent at all', () async {
    // Arrange
    when(() => repository.order(7))
        .thenAnswer((_) async => Right(orderWith(transitions: [toCancelled])));
    await cubit.load();
    cubit.setValue('reason', '   ');

    when(
      () => repository.changeStatus(
        7,
        status: any(named: 'status'),
        reason: any(named: 'reason'),
        fields: any(named: 'fields'),
      ),
    ).thenAnswer((_) async => Right(orderWith()));

    // Act
    await cubit.submit();

    // Assert — sending it would satisfy a required-field check while telling the next reader
    // nothing, so the server's own refusal is the honest ending.
    final sent = verify(
      () => repository.changeStatus(
        7,
        status: any(named: 'status'),
        reason: any(named: 'reason'),
        fields: captureAny(named: 'fields'),
      ),
    ).captured.last;

    expect(sent, isEmpty);
  });

  test('a refused move keeps everything that was filled in', () async {
    // Arrange
    when(() => repository.order(7))
        .thenAnswer((_) async => Right(orderWith(transitions: [toDesigning])));
    await cubit.load();
    cubit.setValue('design_ids', [design(12)]);

    when(
      () => repository.changeStatus(
        7,
        status: any(named: 'status'),
        reason: any(named: 'reason'),
        fields: any(named: 'fields'),
      ),
    ).thenAnswer(
      (_) async => const Left(Failure.server(message: 'التصاميم مطلوبة')),
    );

    // Act
    final result = await cubit.submit();

    // Assert — a dropped connection must not cost somebody the files they just picked.
    expect(result, isNull);
    expect(cubit.state, isA<OrderStatusFailure>());
    expect(cubit.state.selected?.status, OrderStatus.designing);
    expect(cubit.state.values['design_ids'], isNotEmpty);
  });

  test('nothing is sent before a destination is picked', () async {
    // Arrange
    when(() => repository.order(7)).thenAnswer(
      (_) async => Right(orderWith(transitions: [toDesigning, toPrinting])),
    );
    await cubit.load();

    // Act
    final result = await cubit.submit();

    // Assert
    expect(result, isNull);
    verifyNever(
      () => repository.changeStatus(
        any(),
        status: any(named: 'status'),
        reason: any(named: 'reason'),
        fields: any(named: 'fields'),
      ),
    );
  });
}
