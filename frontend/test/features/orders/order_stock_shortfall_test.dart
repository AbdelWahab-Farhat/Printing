import 'dart:convert';
import 'dart:typed_data';

import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/repositories/order_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// A shelf that cannot cover the order, and what the foreman is told about it.
///
/// **This pins a promise the backend makes about this app.** `OrderStockShortfall` weighs every
/// line before anything moves and reports the short sizes under `fields.warehouse_id`, and its
/// own docblock says the app "renders them under the message rather than as a second toast".
/// Nothing on this side enforced that: it works because `Failure.details` joins the `errors` map
/// and `showFailure` passes it as the snackbar's subtitle — two general mechanisms that were
/// never written with this refusal in mind and could be changed by somebody who has never heard
/// of it. So the payload is asserted here, in the shape the server actually sends.
///
/// **The two cases are deliberately different shapes.** One short size repeats its sentence in
/// the `errors` list, so the app must *drop* the duplicate — saying it twice in one toast reads
/// as a bug. Several short sizes get a heading and one entry each, and every entry has to
/// survive: the whole reason the backend stopped refusing line-by-line was that a second short
/// size stayed hidden until the first was restocked.
///
/// Arrange - Act - Assert throughout.
class _RefusingAdapter implements HttpClientAdapter {
  _RefusingAdapter(this.body);

  final Map<String, dynamic> body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode(body),
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
  /// Moving an order to «جاهزة», which is where stock now leaves the shelf and therefore the
  /// only move that can be refused this way.
  Future<Failure> refusal(Map<String, dynamic> body) async {
    final repository = OrderRepositoryImpl(
      Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
        ..httpClientAdapter = _RefusingAdapter(body),
    );

    final result = await repository.changeStatus(
      3,
      status: OrderStatus.ready,
      fields: const {'warehouse_id': 1},
    );

    return result.fold((failure) => failure, (_) => throw StateError('expected a refusal'));
  }

  test('one short size is named once, not twice', () async {
    // Arrange — exactly what `OrderStockShortfall` sends for a single shortfall: the sentence is
    // the message, and the `errors` entry repeats it so the payload keeps one shape either way.
    const sentence =
        'الكمية المتوفرة من «كيس شحن — 25*35» في المخزن (5.000) لا تكفي للكمية المطلوبة (40.000)';

    // Act
    final failure = await refusal(const {
      'status': false,
      'message': sentence,
      'errors': {
        'fields.warehouse_id': [sentence],
      },
    });

    // Assert — the size is named in the line the foreman reads, and the duplicate underneath is
    // dropped rather than printed a second time.
    expect(failure.message, sentence);
    expect(failure.details, isNull);
  });

  test('every short size survives, not only the first one reached', () async {
    // Arrange — one size short on the shelf and a second with no balance there at all. This is
    // the case the up-front check exists for.
    // Act
    final failure = await refusal(const {
      'status': false,
      'message': 'لا يوجد رصيد كافٍ في المخزن للمواد التالية',
      'errors': {
        'fields.warehouse_id': [
          '«كيس شحن — 25*35»: المتوفر (5.000) والمطلوب (40.000)',
          '«كيس نايلون — 30*40»: المتوفر (0.000) والمطلوب (80.000)',
        ],
      },
    });

    // Assert — the heading leads, both entries follow it, one per line. A refusal that named
    // only the first size would send the storekeeper back for the second one tomorrow.
    expect(failure.message, 'لا يوجد رصيد كافٍ في المخزن للمواد التالية');
    expect(failure.details, contains('«كيس شحن — 25*35»: المتوفر (5.000) والمطلوب (40.000)'));
    expect(failure.details, contains('«كيس نايلون — 30*40»: المتوفر (0.000) والمطلوب (80.000)'));
    expect(failure.details!.split('\n'), hasLength(2));
  });

  test('the sizes carry the order own names, whatever the catalogue says now', () async {
    // Arrange — the lines' snapshots, so an order refers to a size by what it was written with
    // rather than by a name the catalogue has since been given.
    // Act
    final failure = await refusal(const {
      'status': false,
      'message': 'لا يوجد رصيد كافٍ في المخزن للمواد التالية',
      'errors': {
        'fields.warehouse_id': [
          '«الاسم القديم — 25*35»: المتوفر (0.000) والمطلوب (10.000)',
          '«كيس نايلون — 30*40»: المتوفر (0.000) والمطلوب (80.000)',
        ],
      },
    });

    // Assert — passed through as sent. Nothing here rewrites, re-orders or re-translates a
    // sentence the server composed.
    expect(failure.details, startsWith('«الاسم القديم — 25*35»'));
  });
}
