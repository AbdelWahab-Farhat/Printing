import 'dart:convert';
import 'dart:typed_data';

import 'package:dayaa/features/employee_wallet/models/employee_wallet_models.dart';
import 'package:dayaa/features/employee_wallet/repositories/employee_wallet_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// ما يخرج على السلك فعلاً: المسار، والمفاتيح، و`client_token` — RULES §٦.
class _CapturingAdapter implements HttpClientAdapter {
  String? path;
  String? method;
  String? body;
  Map<String, String> query = const {};

  /// ما يردّ به الخادم، لكل طلب.
  Object? data = {
    'entry': {
      'id': 3,
      'user_id': 4,
      'type': 'deposit',
      'type_label': 'إيداع',
      'direction': 'in',
      'amount': '300.00',
    },
    'balance': '1800.00',
  };

  Map<String, Object?>? meta;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    path = options.path;
    method = options.method;
    query = options.uri.queryParameters;

    if (requestStream != null) {
      final chunks = await requestStream.toList();
      body = utf8.decode(chunks.expand((chunk) => chunk).toList(), allowMalformed: true);
    }

    return ResponseBody.fromString(
      jsonEncode({'status': true, 'message': 'تم', 'data': data, 'meta': ?meta}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Arrange - Act - Assert throughout.
void main() {
  late _CapturingAdapter adapter;
  late EmployeeWalletRepositoryImpl repository;

  const page = {'current_page': 1, 'per_page': 20, 'last_page': 1, 'total': 0};

  setUp(() {
    adapter = _CapturingAdapter();
    repository = EmployeeWalletRepositoryImpl(
      Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))..httpClientAdapter = adapter,
    );
  });

  test('الإيداع يرسل الطريقة والحساب والرمز، ويسقط الفارغ', () async {
    // Arrange
    const draft = EmployeeMoneyDraft(
      amount: '300',
      method: EmployeeWalletMethod.cash,
      treasuryAccountId: 2,
      reference: '  ',
    );

    // Act
    final result = await repository.deposit(4, draft, clientToken: 'token-1');

    // Assert
    expect(result.isRight(), isTrue);
    expect(adapter.path, '/users/4/wallet/deposits');
    expect(adapter.method, 'POST');
    expect(adapter.body, contains('name="amount"'));
    expect(adapter.body, contains('name="method"'));
    expect(adapter.body, contains('cash'));
    expect(adapter.body, contains('name="treasury_account_id"'));
    expect(adapter.body, contains('name="client_token"'));
    expect(adapter.body, contains('token-1'));
    expect(adapter.body, isNot(contains('name="reference"')));
    expect(adapter.body, isNot(contains('name="notes"')));
  });

  test('السحب يذهب إلى مساره', () async {
    // Arrange
    const draft = EmployeeMoneyDraft(amount: '500', method: EmployeeWalletMethod.libyana);

    // Act
    await repository.withdraw(4, draft, clientToken: 'token-2');

    // Assert
    expect(adapter.path, '/users/4/wallet/withdrawals');
    expect(adapter.body, contains('libyana'));
  });

  test('المستحق يرسل التصنيف، ولا طريقة فيه ولا حساب', () async {
    // Arrange
    const draft = EmployeeCreditDraft(amount: '2500.00', categoryId: 3, notes: ' راتب أكتوبر ');

    // Act
    await repository.credit(4, draft, clientToken: 'token-3');

    // Assert
    expect(adapter.path, '/users/4/wallet/credits');
    expect(jsonDecode(adapter.body!), {
      'amount': '2500.00',
      'category_id': 3,
      'notes': 'راتب أكتوبر',
      'client_token': 'token-3',
    });
  });

  test('التعديل يقول الاتجاه بكلمة الخادم', () async {
    // Arrange
    const reason = ' رصيد افتتاحي ';

    // Act
    await repository.adjust(
      4,
      amount: '150',
      credit: false,
      reason: reason,
      clientToken: 'token-4',
    );

    // Assert
    expect(adapter.path, '/users/4/wallet/adjustments');
    expect(jsonDecode(adapter.body!), {
      'direction': 'debit',
      'amount': '150',
      'reason': 'رصيد افتتاحي',
      'client_token': 'token-4',
    });
  });

  test('العكس على سطره، والسبب مقصوص', () async {
    // Arrange
    const reason = ' كُتبت لموظفٍ آخر ';

    // Act
    await repository.reverse(5, reason: reason);

    // Assert
    expect(adapter.path, '/employee-wallet-entries/5/reverse');
    expect(jsonDecode(adapter.body!), {'reason': 'كُتبت لموظفٍ آخر'});
  });

  test('محفظة موظف تُقرأ من مساره', () async {
    // Arrange
    adapter.data = {'user_id': 4, 'balance': '1500.00', 'can_move': true, 'salary': '2500.00'};

    // Act
    final result = await repository.wallet(4);

    // Assert
    expect(adapter.path, '/users/4/wallet');
    expect(result.getOrElse(() => throw StateError('فشل')).salary, '2500.00');
  });

  test('«محفظتي» تُقرأ من مسارها', () async {
    // Arrange
    adapter.data = {'balance': '1500.00', 'recent': <Object>[]};

    // Act
    final result = await repository.myWallet();

    // Assert
    expect(adapter.path, '/my-wallet');
    expect(result.getOrElse(() => throw StateError('فشل')).balance, '1500.00');
  });

  group('السجل', () {
    setUp(() {
      adapter
        ..data = <Object>[]
        ..meta = page;
    });

    test('سجل موظف واحد: فلتره ومداه، ولا بحث فيه', () async {
      // Arrange
      final from = DateTime(2026, 11);
      final to = DateTime(2026, 11, 6);

      // Act
      await repository.entries(
        const EmployeeWalletLedger.of(4),
        page: 2,
        filter: EmployeeWalletEntryFilter.adjustment,
        search: 'لا يصل',
        from: from,
        to: to,
      );

      // Assert
      expect(adapter.path, '/users/4/wallet/entries');
      expect(adapter.query, {
        'page': '2',
        'type': 'adjustment',
        'from': '2026-11-01',
        'to': '2026-11-06',
      });
    });

    test('كل المحافظ يُبحث فيها باسم الموظف', () async {
      // Arrange
      const search = 'محمد';

      // Act
      await repository.entries(const EmployeeWalletLedger.all(), page: 1, search: search);

      // Assert
      expect(adapter.path, '/employee-wallet-entries');
      expect(adapter.query, {'page': '1', 'q': 'محمد'});
    });

    test('سجل «محفظتي» من مساره، و«الكل» لا يرسل نوعاً', () async {
      // Arrange
      const filter = EmployeeWalletEntryFilter.all;

      // Act
      await repository.entries(const EmployeeWalletLedger.mine(), page: 1, filter: filter);

      // Assert
      expect(adapter.path, '/my-wallet/entries');
      expect(adapter.query, {'page': '1'});
    });
  });
}
