import 'dart:convert';
import 'dart:typed_data';

import 'package:dayaa/features/orders/models/order_payment.dart';
import 'package:dayaa/features/orders/models/payment_settlement.dart';
import 'package:dayaa/features/orders/repositories/order_payment_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// ما تضعه قائمتا «مراجعة وتسوية الدفعات» على السلك: الأسماء التي يقرؤها الخادم، والفارغ لا يُرسل.
///
/// Arrange - Act - Assert throughout.
class _CapturingAdapter implements HttpClientAdapter {
  _CapturingAdapter(this.answer);

  final Object answer;

  String? path;
  Map<String, dynamic> query = const {};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    path = options.path;
    query = options.queryParameters;

    return ResponseBody.fromString(
      jsonEncode(answer),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  const emptyPage = {
    'status': true,
    'message': 'تم',
    'data': <Object>[],
    'meta': {'current_page': 1, 'per_page': 20, 'last_page': 1, 'total': 0},
  };

  OrderPaymentRepositoryImpl repositoryOver(_CapturingAdapter adapter) =>
      OrderPaymentRepositoryImpl(Dio()..httpClientAdapter = adapter);

  test('the review list sends the account and the detail under the server\'s names', () async {
    // Arrange
    final adapter = _CapturingAdapter(emptyPage);

    // Act
    await repositoryOver(adapter).reviewQueue(
      page: 1,
      accountId: 4,
      detail: const PaymentDetailFilter(
        method: PaymentMethod.bankTransfer,
        recordedBy: 21,
        minAmount: '100',
        maxAmount: '250.5',
      ),
    );

    // Assert
    expect(adapter.query, {
      'page': 1,
      'account_id': 4,
      'method': 'bank_transfer',
      'recorded_by': 21,
      'amount_min': '100',
      'amount_max': '250.5',
    });
  });

  test('the settled list adds where it went and who settled', () async {
    // Arrange
    final adapter = _CapturingAdapter(emptyPage);

    // Act
    await repositoryOver(adapter).settlementQueue(
      page: 1,
      state: SettlementState.settled,
      detail: const PaymentDetailFilter(toAccountId: 2, settledBy: 22),
    );

    // Assert
    expect(adapter.query, {'page': 1, 'state': 'settled', 'to_account_id': 2, 'settled_by': 22});
  });

  test('with nothing chosen the request is what it always was', () async {
    // Arrange
    final adapter = _CapturingAdapter(emptyPage);

    // Act
    await repositoryOver(adapter).reviewQueue(page: 1);

    // Assert
    expect(adapter.query, {'page': 1});
  });

  test('the options come from their own address and are read', () async {
    // Arrange
    final adapter = _CapturingAdapter(const {
      'status': true,
      'message': 'تم',
      'data': {
        'kinds': [
          {'label': 'حوالة', 'method': 'bank_transfer', 'account_id': null},
        ],
        'accounts': <Object>[],
        'recorders': <Object>[],
        'settlers': <Object>[],
      },
    });

    // Act
    final result = await repositoryOver(adapter).paymentFilterOptions();

    // Assert
    expect(adapter.path, '/order-payments/filter-options');
    expect(result.isRight(), isTrue);
    expect(result.getOrElse(PaymentFilterOptions.new).kinds.single.label, 'حوالة');
  });
}
