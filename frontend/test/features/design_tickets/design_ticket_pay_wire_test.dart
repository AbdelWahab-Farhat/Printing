import 'dart:convert';
import 'dart:typed_data';

import 'package:dayaa/features/design_tickets/models/design_ticket.dart';
import 'package:dayaa/features/design_tickets/repositories/design_ticket_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// «أجر التصميم» على السلك: ما يُرسل، وما يُقرأ.
///
/// Arrange - Act - Assert في كل اختبار.
class _CapturingAdapter implements HttpClientAdapter {
  String? path;
  String? method;
  String? body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    path = options.path;
    method = options.method;

    if (requestStream != null) {
      final chunks = await requestStream.toList();
      body = utf8.decode(chunks.expand((chunk) => chunk).toList(), allowMalformed: true);
    }

    return ResponseBody.fromString(
      jsonEncode({'status': false, 'message': 'البيانات غير صحيحة'}),
      422,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _CapturingAdapter adapter;
  late DesignTicketRepositoryImpl repository;

  setUp(() {
    adapter = _CapturingAdapter();
    repository = DesignTicketRepositoryImpl(
      Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))..httpClientAdapter = adapter,
    );
  });

  Map<String, dynamic> sent() => jsonDecode(adapter.body!) as Map<String, dynamic>;

  test('a new ticket carries the pay when one was written', () async {
    // Act
    await repository.create(customerId: 1, title: 'كيس', description: 'أسود', designerPay: '50');

    // Assert
    expect(sent()['designer_pay'], '50');
  });

  test('a new ticket leaves the pay out when the box is empty', () async {
    // Act
    await repository.create(customerId: 1, title: 'كيس', description: 'أسود');

    // Assert
    expect(sent().containsKey('designer_pay'), isFalse);
  });

  test('taking a ticket states the pay when the reader wrote one', () async {
    // Act
    await repository.accept(7, designerPay: '65');

    // Assert
    expect(adapter.path, endsWith('/design-tickets/7/acceptance'));
    expect(sent()['designer_pay'], '65');
  });

  test('taking a ticket sends nothing when no pay was written', () async {
    // Act
    await repository.accept(7);

    // Assert
    expect(adapter.body, isNull);
  });

  test('changing the pay sends it, and null clears it', () async {
    // Act
    await repository.setPay(7, designerPay: null);

    // Assert
    expect(adapter.method, 'PATCH');
    expect(adapter.path, endsWith('/design-tickets/7/pay'));
    expect(sent().containsKey('designer_pay'), isTrue);
    expect(sent()['designer_pay'], isNull);
  });

  test('an approval names the amount the reader agreed to', () async {
    // Act
    await repository.reviewVersion(7, 3, verdict: 'approved', confirmedPay: '50.00');

    // Assert
    expect(sent()['confirmed_pay'], '50.00');
  });

  test('a change request says nothing about money', () async {
    // Act
    await repository.reviewVersion(7, 3, verdict: 'changes_requested', note: 'كبّر الشعار');

    // Assert
    expect(sent().containsKey('confirmed_pay'), isFalse);
  });

  test('the ticket reads the pay, the suggestion and the flag', () {
    // Arrange
    final json = {
      'id': 1,
      'code': 'D1',
      'title': 'كيس',
      'description': 'أسود',
      'status': 'in_progress',
      'status_label': 'قيد التصميم',
      'customer_id': 1,
      'customer_name': 'متجر',
      'designer_pay': '50.00',
      'suggested_pay': '75.00',
      'can_set_pay': true,
    };

    // Act
    final ticket = DesignTicket.fromJson(json);

    // Assert
    expect(ticket.designerPay, '50.00');
    expect(ticket.suggestedPay, '75.00');
    expect(ticket.canSetPay, isTrue);
  });
}
