import 'package:dartz/dartz.dart' hide Order;
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/customers/models/customer_design.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/models/transition_field.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/order_status_cubit.dart';
import 'package:dayaa/features/orders/repositories/order_repository.dart';
import 'package:dayaa/features/orders/usecases/change_order_status.dart';
import 'package:dayaa/features/orders/usecases/get_order.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

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

  /// «كم وصل من الناقص» — the field that arrives already holding its answer.
  const received = TransitionField(
    key: 'received_11',
    type: TransitionFieldType.number,
    label: 'الواصل من نواقص 25*35',
    max: 100,
    value: '100.000',
  );

  const outOfShortage = OrderTransition(
    status: OrderStatus.printing,
    label: 'قيد الطباعة',
    fields: [received],
  );

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

  /// **A field can arrive with its own answer in it.**
  ///
  /// Leaving «نواقص» asks what arrived of the shortage, and the answer is nearly always «all of
  /// it» — so the server sends the number and the box opens holding it. Anything the clerk does
  /// is a correction to a filled form rather than a form to fill.
  group('a field that arrives filled in', () {
    test('opens holding what the server put in it', () async {
      // Arrange
      when(() => repository.order(7)).thenAnswer(
        (_) async => Right(orderWith(transitions: [outOfShortage, toCancelled])),
      );
      await cubit.load();

      // Act
      cubit.select(outOfShortage);

      // Assert
      expect(cubit.state.values['received_11'], '100.000');
    });

    test('is filled in even when it is the only way out and nobody tapped', () async {
      // Arrange — one transition is chosen for the user, so nothing would ever seed it.
      when(() => repository.order(7))
          .thenAnswer((_) async => Right(orderWith(transitions: [outOfShortage])));

      // Act
      await cubit.load();

      // Assert
      expect(cubit.state.values['received_11'], '100.000');
    });

    test('goes back to the server’s answer when the destination is chosen again', () async {
      // Arrange
      when(() => repository.order(7)).thenAnswer(
        (_) async => Right(orderWith(transitions: [outOfShortage, toCancelled])),
      );
      await cubit.load();
      cubit.select(outOfShortage);
      cubit.setValue('received_11', '40');

      // Act — off to another move and back.
      cubit.select(toCancelled);
      cubit.select(outOfShortage);

      // Assert — the prefill is part of the form, so it returns with it rather than leaving an
      // empty box where a number used to be.
      expect(cubit.state.values['received_11'], '100.000');
    });
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

  /// **A refusal must be answerable by tapping the button again.**
  ///
  /// The server refuses a move for reasons that pass on their own — a warehouse that was short
  /// when the clerk tapped and stocked a minute later. If the second tap does nothing, the
  /// screen looks broken: the message came once and never again, with no way to find out
  /// whether anything changed.
  test('the same move can be sent again after it was refused', () async {
    // Arrange
    when(() => repository.order(7))
        .thenAnswer((_) async => Right(orderWith(transitions: [toPrinting])));
    await cubit.load();

    when(
      () => repository.changeStatus(
        7,
        status: any(named: 'status'),
        reason: any(named: 'reason'),
        fields: any(named: 'fields'),
      ),
    ).thenAnswer(
      (_) async => const Left(Failure.server(message: 'الكمية المتوفرة لا تكفي')),
    );

    final seen = <OrderStatusState>[];
    final subscription = cubit.stream.listen(seen.add);

    // Act — the same tap, twice, with nothing touched in between.
    await cubit.submit();
    await cubit.submit();
    await pumpEventQueue();
    await subscription.cancel();

    // Assert — it really goes back to the server...
    verify(
      () => repository.changeStatus(
        7,
        status: any(named: 'status'),
        reason: any(named: 'reason'),
        fields: any(named: 'fields'),
      ),
    ).called(2);

    // ...and the refusal is a *new* state each time, or the screen would never say it twice.
    expect(seen.whereType<OrderStatusFailure>(), hasLength(2));
  });

  test('a correction made after a refusal is the one that gets sent', () async {
    // Arrange — the refusal a person actually acts on: the server objects to what was typed, so
    // they rewrite it and send again. «ملغاة» is the move used here because it is the one in
    // these fixtures that carries a field at all.
    when(() => repository.order(7))
        .thenAnswer((_) async => Right(orderWith(transitions: [toCancelled])));
    await cubit.load();
    cubit.setValue('reason', 'أول ما كُتب');

    when(
      () => repository.changeStatus(
        7,
        status: any(named: 'status'),
        reason: any(named: 'reason'),
        fields: any(named: 'fields'),
      ),
    ).thenAnswer(
      (_) async => const Left(Failure.server(message: 'الكمية المتوفرة لا تكفي')),
    );

    await cubit.submit();

    // Act — corrected *while standing on the refusal*, then sent again.
    cubit.setValue('reason', 'ما كُتب بعد الرفض');
    await cubit.submit();

    // Assert — the second attempt carries the correction. Recording it only from a clean form
    // dropped the edit and resent the answer that had just been refused, so the move failed
    // identically and the screen looked broken.
    final sent = verify(
      () => repository.changeStatus(
        7,
        status: any(named: 'status'),
        reason: any(named: 'reason'),
        fields: captureAny(named: 'fields'),
      ),
    ).captured;

    expect(sent, hasLength(2));
    expect((sent.first as Map)['reason'], 'أول ما كُتب');
    expect((sent.last as Map)['reason'], 'ما كُتب بعد الرفض');
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
