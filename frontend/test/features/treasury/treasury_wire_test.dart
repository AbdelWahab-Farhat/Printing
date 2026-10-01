import 'dart:convert';
import 'dart:typed_data';

import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/repositories/treasury_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// ما يضعه مستودع الخزينة على السلك — المفاتيح التي يقرؤها الخادم حرفاً.
///
/// Arrange - Act - Assert throughout.
class _CapturingAdapter implements HttpClientAdapter {
  _CapturingAdapter(this.answer);

  /// ما يُجاب به الطلب، ملفوفاً في غلاف الخادم.
  final Object? answer;

  RequestOptions? request;
  Object? body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;

    if (requestStream != null) {
      final bytes = (await requestStream.toList()).expand((chunk) => chunk).toList();
      body = jsonDecode(utf8.decode(bytes));
    }

    return ResponseBody.fromString(
      jsonEncode({
        'status': true,
        'message': 'تم',
        'data': answer,
        'meta': {'current_page': 1, 'per_page': 1, 'last_page': 1, 'total': 0},
      }),
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
  TreasuryRepositoryImpl repositoryOver(_CapturingAdapter adapter) => TreasuryRepositoryImpl(
    Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))..httpClientAdapter = adapter,
  );

  const operation = {
    'id': 31,
    'type': 'deposit',
    'type_label': 'إيداع',
    'amount': '50.00',
    'is_reversible': true,
  };

  const payment = {
    'id': 5,
    'type': 'payment',
    'type_label': 'دفعة',
    'amount': '1080.00',
    'method_label': 'حوالة',
    'treasury_account': {'id': 2, 'name': 'المصرف'},
    'is_reversible': true,
  };

  test('العملية اليدوية تحمل مفتاح الطلب، فلا تُسجَّل الإعادة مرتين', () async {
    // Arrange
    final adapter = _CapturingAdapter(operation);
    final repository = repositoryOver(adapter);

    // Act
    final result = await repository.recordOperation(
      kind: OperationKind.deposit,
      amount: '50',
      toAccountId: 1,
      clientToken: 'b9f1c1a2-0b8e-4c2a-9d33-2f0f6e9a7c11',
    );

    // Assert
    expect(result.isRight(), isTrue);
    expect(adapter.request?.path, '/treasury/operations');
    expect(adapter.body, containsPair('client_token', 'b9f1c1a2-0b8e-4c2a-9d33-2f0f6e9a7c11'));
  });

  test('دفعة المورد تحمل مفتاح الطلب، وتعود بالصف الذي كتبه الخادم', () async {
    // Arrange
    final adapter = _CapturingAdapter(payment);
    final repository = repositoryOver(adapter);

    // Act
    final result = await repository.payVendor(
      vendorId: 9,
      purchaseOrderId: 4,
      amount: '1080',
      method: 'bank_transfer',
      clientToken: '0c4d1e2f-3a4b-4c5d-8e6f-7a8b9c0d1e2f',
    );

    // Assert
    expect(adapter.request?.path, '/vendors/9/payments');
    expect(adapter.body, containsPair('client_token', '0c4d1e2f-3a4b-4c5d-8e6f-7a8b9c0d1e2f'));
    expect(result.fold((_) => null, (row) => row.id), 5);
    expect(result.fold((_) => null, (row) => row.accountName), 'المصرف');
  });

  test('عكس دفعة المورد يعود بصف العكس', () async {
    // Arrange
    final adapter = _CapturingAdapter({...payment, 'id': 6, 'type': 'reversal'});
    final repository = repositoryOver(adapter);

    // Act
    final result = await repository.reverseVendorPayment(
      vendorId: 9,
      paymentId: 5,
      reason: 'سُجّلت مرتين',
    );

    // Assert
    expect(adapter.request?.path, '/vendors/9/payments/5/reverse');
    expect(adapter.body, {'reason': 'سُجّلت مرتين'});
    expect(result.fold((_) => null, (row) => row.isReversal), isTrue);
  });

  test('مسحُ الملاحظات يُرسلها فارغةً صراحةً — غيابُ المفتاح يتركها كما هي', () async {
    // Arrange
    final account = {'id': 3, 'name': 'مصرف علي', 'kind': 'bank', 'kind_label': 'مصرف'};
    final clearing = _CapturingAdapter(account);
    final untouched = _CapturingAdapter(account);

    // Act
    await repositoryOver(clearing).saveAccount(id: 3, name: 'مصرف علي', notes: '');
    await repositoryOver(untouched).saveAccount(id: 3, name: 'مصرف علي');

    // Assert
    expect(clearing.body, containsPair('notes', ''));
    expect(untouched.body, isNot(contains('notes')));
  });

  test('سجلّ الحساب يُرسل الفلتر والبحث والحجم حين يُطلبان، ولا يرسل فراغاً', () async {
    // Arrange
    final expenses = _CapturingAdapter(const <Object>[]);
    final orders = _CapturingAdapter(const <Object>[]);
    final plain = _CapturingAdapter(const <Object>[]);

    // Act
    await repositoryOver(expenses).movements(
      7,
      page: 2,
      perPage: 1,
      filter: MovementFilter.expenses,
      search: '1290',
    );
    await repositoryOver(orders).movements(7, page: 1, filter: MovementFilter.orders);
    await repositoryOver(plain).movements(7, page: 1);

    // Assert
    expect(expenses.request?.queryParameters, {
      'page': 2,
      'per_page': 1,
      'kind': 'expense',
      'search': '1290',
    });
    expect(orders.request?.queryParameters, {'page': 1, 'has_order': 1});
    expect(plain.request?.queryParameters, {'page': 1});
  });
}
