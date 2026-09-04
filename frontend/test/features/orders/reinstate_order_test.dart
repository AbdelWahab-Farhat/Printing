import 'dart:convert';
import 'dart:typed_data';

import 'package:dartz/dartz.dart' hide Order;
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/order_detail_cubit.dart';
import 'package:dayaa/features/orders/repositories/order_repository.dart';
import 'package:dayaa/features/orders/repositories/order_repository_impl.dart';
import 'package:dayaa/features/orders/usecases/get_order.dart';
import 'package:dayaa/features/orders/usecases/manage_order_designs.dart';
import 'package:dayaa/features/orders/usecases/reinstate_order.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Undoing a cancellation made by mistake, from the wire up to the screen's Cubit.
///
/// Three claims are pinned here, and each of them is a rule that would be invisible if it broke:
///
/// - **The request carries no destination.** Where the order lands is the server's answer, read
///   off its own timeline, so a body that ever grew a `status` key would be this app inventing a
///   second way into statuses «إلغاء تام» cannot legally reach.
/// - **An empty note is not sent.** A field nobody filled is absent, not `null` — the same rule
///   every other form in this app follows.
/// - **The response replaces the order rather than triggering a re-read.** What comes back is
///   already the order with a real `available_transitions` again.
///
/// Arrange - Act - Assert throughout.
class _MockOrderRepository extends Mock implements OrderRepository {}

class _CapturingAdapter implements HttpClientAdapter {
  String? path;
  String? method;
  List<int>? body;

  String get text => utf8.decode(body ?? const []);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    path = options.path;
    method = options.method;

    if (requestStream != null) {
      body = (await requestStream.toList()).expand((chunk) => chunk).toList();
    }

    return ResponseBody.fromString(
      jsonEncode({'status': true, 'message': 'تم', 'data': _orderJson}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// The order as the server sends it back: no longer cancelled, and standing where it was.
const _orderJson = <String, dynamic>{
  'id': 9,
  'code': '1225',
  'status': 'office_pickup',
  'status_label': 'استلام مكتب',
  'is_final': false,
  'is_closed': false,
  'available_transitions': <Object>[],
  'reinstate_to': null,
  'reinstate_to_label': null,
  'customer_id': 1,
  'city_id': 1,
  'design_source': 'none',
  'city_name': 'طرابلس',
  'fulfilment_type_label': 'إستلام مكتب',
  'is_office_pickup': true,
  'design_source_label': 'بدون تصميم',
  'items_total': '650.00',
  'design_fee': '0.00',
  'delivery_price': '0.00',
  'discount': '0.00',
  'grand_total': '650.00',
};

void main() {
  group('the wire', () {
    late _CapturingAdapter adapter;
    late OrderRepositoryImpl repository;

    setUp(() {
      adapter = _CapturingAdapter();
      repository = OrderRepositoryImpl(
        Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))..httpClientAdapter = adapter,
      );
    });

    test('it posts to the order\'s own reinstate path and names no destination', () async {
      // Act
      await repository.reinstate(9, reason: 'أُلغيت بالخطأ');

      // Assert — a POST, because the server records a row on the timeline; and a body holding
      // the note and nothing else. A `status` key here would be the bug this test exists for.
      expect(adapter.method, 'POST');
      expect(adapter.path, '/orders/9/reinstate');

      final sent = jsonDecode(adapter.text) as Map<String, dynamic>;

      expect(sent, {'reason': 'أُلغيت بالخطأ'});
    });

    test('a note nobody typed is left out rather than sent as null', () async {
      // Act
      await repository.reinstate(9);

      // Assert
      final sent = jsonDecode(adapter.text) as Map<String, dynamic>;

      expect(sent, isEmpty);
    });

    test('a note of nothing but spaces is dropped on the way out', () async {
      // Arrange — the use case owns the trimming, exactly as ChangeOrderStatus does
      final reinstate = ReinstateOrder(repository);

      // Act
      await reinstate(9, reason: '   ');

      // Assert
      final sent = jsonDecode(adapter.text) as Map<String, dynamic>;

      expect(sent, isEmpty);
    });

    test('the order that comes back is the one the screen shows', () async {
      // Act
      final result = await repository.reinstate(9);

      // Assert — no re-read is needed: the response is the order, out of «إلغاء تام»
      final order = result.getOrElse(() => throw StateError('refused'));

      expect(order.status, OrderStatus.officePickup);
      expect(order.isFinal, isFalse);
      expect(order.canReinstate, isFalse);
    });
  });

  group('the model', () {
    test('a cancelled order names where the undo would put it', () {
      // Arrange
      final json = Map<String, dynamic>.from(_orderJson)
        ..['status'] = 'cancelled'
        ..['status_label'] = 'إلغاء تام'
        ..['is_final'] = true
        ..['reinstate_to'] = 'office_pickup'
        ..['reinstate_to_label'] = 'استلام مكتب';

      // Act
      final order = Order.fromJson(json);

      // Assert — the status itself, so the button can say it before the tap
      expect(order.canReinstate, isTrue);
      expect(order.reinstateTo, OrderStatus.officePickup);
      expect(order.reinstateToLabel, 'استلام مكتب');
    });

    test('an order the server offered no undo on says so', () {
      // Act
      final order = Order.fromJson(Map<String, dynamic>.from(_orderJson));

      // Assert
      expect(order.reinstateTo, isNull);
      expect(order.canReinstate, isFalse);
    });
  });

  group('the cubit', () {
    late _MockOrderRepository repository;
    late OrderDetailCubit cubit;

    Order cancelled() => Order.fromJson(
      Map<String, dynamic>.from(_orderJson)
        ..['status'] = 'cancelled'
        ..['status_label'] = 'إلغاء تام'
        ..['is_final'] = true
        ..['reinstate_to'] = 'office_pickup'
        ..['reinstate_to_label'] = 'استلام مكتب',
    );

    Order reinstated() => Order.fromJson(Map<String, dynamic>.from(_orderJson));

    setUp(() {
      repository = _MockOrderRepository();
      cubit = OrderDetailCubit(
        orderId: 9,
        getOrder: GetOrder(repository),
        addDesign: AddOrderDesign(repository),
        reviewDesign: ReviewOrderDesign(repository),
        reinstateOrder: ReinstateOrder(repository),
      );
    });

    tearDown(() => cubit.close());

    test('the answer replaces the order on screen', () async {
      // Arrange
      when(() => repository.order(9)).thenAnswer((_) async => Right(cancelled()));
      when(
        () => repository.reinstate(9, reason: any(named: 'reason')),
      ).thenAnswer((_) async => Right(reinstated()));

      await cubit.load();

      // Act
      final failure = await cubit.reinstate(reason: 'بالخطأ');

      // Assert — no second fetch: the response is already the order
      expect(failure, isNull);
      expect(cubit.state.order?.status, OrderStatus.officePickup);
      expect(cubit.state.isWorking, isFalse);
      verify(() => repository.order(9)).called(1);
    });

    test('a refusal is handed back and the order is left exactly as it was', () async {
      // Arrange
      when(() => repository.order(9)).thenAnswer((_) async => Right(cancelled()));
      when(() => repository.reinstate(9, reason: any(named: 'reason'))).thenAnswer(
        (_) async => const Left(
          Failure.server(message: 'لا يوجد في سجل الطلبية الحالة التي أُلغيت منها'),
        ),
      );

      await cubit.load();

      // Act
      final failure = await cubit.reinstate();

      // Assert — the screen keeps the cancelled order and shows the server's own sentence
      expect(failure, isNotNull);
      expect(cubit.state.order?.status, OrderStatus.cancelled);
      expect(cubit.state.isWorking, isFalse);
    });
  });
}
