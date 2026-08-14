import 'dart:convert';
import 'dart:typed_data';

import 'package:dayaa/features/orders/repositories/order_repository_impl.dart';
import 'package:dayaa/features/orders/usecases/record_scrap_loss.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// What actually goes down the wire when bags are written off, and what comes back.
///
/// **Two things are being pinned, and they pull in opposite directions.** Out: exactly two keys,
/// the quantity as a decimal *string*, at a path that names the line inside its order — there is
/// no price on this call, because the batches know what the bags cost and nobody in the shop
/// does. In: the entry the server wrote, whose `amount` is that cost — the one number in the
/// exchange that was not typed by the person who filled the form in.
///
/// **The response carries no `recorded_by` at all**, and that is not a null — the key is absent,
/// because this endpoint never loads the relation. A model that required it would throw on a
/// perfectly good 201, which is the sort of failure that only ever shows up in production.
///
/// Arrange - Act - Assert throughout.
class _CapturingAdapter implements HttpClientAdapter {
  String? body;
  String? path;
  String? method;

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
      body = utf8.decode(chunks.expand((chunk) => chunk).toList());
    }

    return ResponseBody.fromString(
      jsonEncode({
        'status': true,
        'message': 'تم تسجيل التلف بنجاح',
        'data': {
          'id': 7,
          'order_id': 3,
          'order_item_id': 11,
          'cost_type': 'scrap_loss',
          'cost_type_label': 'خسارة تلف',
          'quantity': '10.000',
          // Always null on a scrap loss: it is priced from the batches, never from a rate.
          'rate': null,
          'amount': '40.00',
          'notes': 'انحراف في طباعة الشعار',
          'incurred_at': '2026-08-13T12:34:56+00:00',
          'created_at': '2026-08-13T12:34:56+00:00',
          // `recorded_by` is deliberately not here — see the class doc.
        },
      }),
      201,
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
  late OrderRepositoryImpl repository;

  setUp(() {
    adapter = _CapturingAdapter();
    repository = OrderRepositoryImpl(
      Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))..httpClientAdapter = adapter,
    );
  });

  test('the line is named inside its own order', () async {
    // Arrange

    // Act
    await repository.recordScrapLoss(3, 11, quantity: '10', notes: 'انحراف في طباعة الشعار');

    // Assert — the API scopes the item to the order, so another order's line id is a 404 by
    // construction rather than a check somebody has to remember to write.
    expect(adapter.method, 'POST');
    expect(adapter.path, '/orders/3/items/11/scrap');
  });

  test('the body is the quantity and the reason, and nothing else', () async {
    // Arrange

    // Act
    await repository.recordScrapLoss(3, 11, quantity: '10', notes: 'انحراف في طباعة الشعار');

    // Assert — no price, no cost, no warehouse: the server draws the bags off the order's own
    // shelf and reads what they cost out of the batches they came from.
    final sent = jsonDecode(adapter.body!) as Map<String, dynamic>;

    expect(sent, {'quantity': '10', 'notes': 'انحراف في طباعة الشعار'});
  });

  test('the quantity stays a string all the way to the socket', () async {
    // Arrange

    // Act
    await repository.recordScrapLoss(3, 11, quantity: '10.500', notes: 'تلف أثناء القص');

    // Assert — a decimal that went through a double on the way out is a decimal the server was
    // never asked about. `numeric` accepts the string, so there is nothing to gain by parsing it.
    final sent = jsonDecode(adapter.body!) as Map<String, dynamic>;

    expect(sent['quantity'], isA<String>());
    expect(sent['quantity'], '10.500');
  });

  test('what a Libyan keyboard produced arrives as ASCII', () async {
    // Arrange — the use case is what cleans it, and this is the step that proves the cleaning
    // survives Dio's transformer rather than only the unit test above it.
    final recordScrap = RecordScrapLoss(repository);

    // Act
    await recordScrap(3, 11, quantity: '١٠٫٥', notes: '  انحراف في طباعة الشعار  ');

    // Assert
    final sent = jsonDecode(adapter.body!) as Map<String, dynamic>;

    expect(sent['quantity'], '10.5');
    expect(sent['notes'], 'انحراف في طباعة الشعار');
  });

  test('what the spoiled bags cost comes back from the server', () async {
    // Arrange

    // Act
    final result = await repository.recordScrapLoss(
      3,
      11,
      quantity: '10',
      notes: 'انحراف في طباعة الشعار',
    );

    // Assert — ten bags that arrived at four each. Nobody typed 40, and nobody could have.
    final entry = result.getOrElse(() => throw StateError('expected an entry'));

    expect(entry.id, 7);
    expect(entry.amount, '40.00');
    expect(entry.quantity, '10.000');
    expect(entry.costTypeLabel, 'خسارة تلف');
    expect(entry.isScrapLoss, isTrue);
  });

  test('a scrap entry carries no rate, and a missing recorder is not a failure', () async {
    // Arrange

    // Act
    final result = await repository.recordScrapLoss(
      3,
      11,
      quantity: '10',
      notes: 'انحراف في طباعة الشعار',
    );

    // Assert — `rate` is null by design and `recorded_by` is absent from the payload entirely.
    // Either one modelled as required would throw on the response the server actually sends.
    final entry = result.getOrElse(() => throw StateError('expected an entry'));

    expect(entry.rate, isNull);
    expect(entry.recordedBy, isNull);
  });
}
