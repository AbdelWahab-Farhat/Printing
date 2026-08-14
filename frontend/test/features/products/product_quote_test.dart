import 'dart:convert';
import 'dart:typed_data';

import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/products/repositories/product_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Asking the catalogue what a quantity costs.
///
/// **Why this test reads the wire rather than the model.** A quote is the one number in this app
/// that a person quotes down a phone, and every value in it is a decimal *string* on purpose —
/// `1.100`, not `1.1`. A test that only checked `PriceQuote.fromJson` would still pass on the
/// day somebody parses one of these into a `double` somewhere between Dio and the screen. This
/// one asserts on the bytes sent and on the strings that come back out.
///
/// Arrange - Act - Assert throughout.
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.body, {this.statusCode = 200});

  final Map<String, dynamic> body;
  final int statusCode;

  String? path;
  String? sent;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    path = options.path;

    if (requestStream != null) {
      final chunks = await requestStream.toList();
      sent = utf8.decode(chunks.expand((chunk) => chunk).toList());
    }

    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ProductRepositoryImpl _repositoryOn(_StubAdapter adapter) => ProductRepositoryImpl(
  Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))..httpClientAdapter = adapter,
);

void main() {
  test('a quote is asked for by size and quantity, on that product’s own path', () async {
    // Arrange
    final adapter = _StubAdapter({
      'status': true,
      'message': 'تم',
      'data': {
        'quantity': '300.000',
        'unit': 'piece',
        'unit_label': 'قطعة',
        'unit_price': '1.100',
        'total': '330.000',
        'applied_tier_min_quantity': '100.000',
        'next_tier': null,
      },
    });

    // Act
    await _repositoryOn(adapter).quote(productId: 7, variantId: 12, quantity: '300');

    // Assert
    expect(adapter.path, '/products/7/quote');
    expect(jsonDecode(adapter.sent!), {'variant_id': 12, 'quantity': '300'});
  });

  test('every number comes back as the string the server sent', () async {
    // Arrange — 1.100 and 330.000 are what the catalogue printed. A `double` would render the
    // first as 1.1 and could turn the second into 330.00000000000006.
    final adapter = _StubAdapter({
      'status': true,
      'message': 'تم',
      'data': {
        'quantity': '300.000',
        'unit': 'piece',
        'unit_label': 'قطعة',
        'unit_price': '1.100',
        'total': '330.000',
        'applied_tier_min_quantity': '100.000',
        'next_tier': {
          'min_quantity': '1000.000',
          'unit_price': '0.950',
          'quantity_to_reach': '700.000',
        },
      },
    });

    // Act
    final result = await _repositoryOn(adapter).quote(
      productId: 7,
      variantId: 12,
      quantity: '300',
    );

    // Assert
    final quote = result.getOrElse(() => throw StateError('expected a quote'));
    expect(quote.unitPrice, '1.100');
    expect(quote.total, '330.000');
    expect(quote.appliedTierMinQuantity, '100.000');
    expect(quote.nextTier?.unitPrice, '0.950');
    expect(quote.nextTier?.quantityToReach, '700.000');
  });

  test('a product with no listed prices answers with the server’s refusal', () async {
    // Arrange — `ProductRequiresManualQuote`, which is a 422 with a sentence worth showing
    // rather than an error the screen has to invent words for.
    final adapter = _StubAdapter({
      'status': false,
      'message': 'المنتج «أكياس ورقية» يُسعَّر حسب الطلب',
    }, statusCode: 422);

    // Act
    final result = await _repositoryOn(adapter).quote(
      productId: 9,
      variantId: 3,
      quantity: '50',
    );

    // Assert
    final failure = result.fold((failure) => failure, (_) => null);
    expect(failure, isA<Failure>());
    expect(failure!.message, 'المنتج «أكياس ورقية» يُسعَّر حسب الطلب');
  });

  test('the numbers are trimmed for reading without being changed', () async {
    // Arrange — `'300.000'` reads as a quantity to a database and as noise to a person.
    final adapter = _StubAdapter({
      'status': true,
      'message': 'تم',
      'data': {
        'quantity': '300.000',
        'unit': 'piece',
        'unit_label': 'قطعة',
        'unit_price': '1.100',
        'total': '330.000',
        'applied_tier_min_quantity': '100.000',
        'next_tier': null,
      },
    });

    // Act
    final result = await _repositoryOn(adapter).quote(
      productId: 7,
      variantId: 12,
      quantity: '300',
    );

    // Assert — the label is for the eye; the value underneath is untouched.
    final quote = result.getOrElse(() => throw StateError('expected a quote'));
    expect(quote.quantityLabel, '300');
    expect(quote.totalLabel, '330');
    expect(quote.total, '330.000');
  });
}
