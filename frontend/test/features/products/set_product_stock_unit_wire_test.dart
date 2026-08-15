import 'dart:convert';
import 'dart:typed_data';

import 'package:dayaa/features/products/models/pricing_unit.dart';
import 'package:dayaa/features/products/repositories/product_repository_impl.dart';
import 'package:dayaa/features/products/usecases/set_product_stock_unit.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Declaring what a product's stock is counted in, down to the socket.
///
/// **A PATCH of its own, and not a field on the product form.** `PUT /products/{id}` carries no
/// `stock_unit` rule at all — sending one there is silently ignored — because this is an
/// inventory fact rather than a catalogue one: the server cascades it to every warehouse balance
/// and every cost batch for the product's variants, in one transaction. A field on the edit form
/// would make that ride along with a rename.
///
/// Nothing is converted by the call, and that is the point of it. The figures on the shelves were
/// correct in their own unit before and stay correct after; what changes is what the unit is
/// *called* from here on.
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
        'message': 'تم تحديث وحدة المخزون',
        // The full product resource, refreshed — so the screen has nothing left to reconcile.
        'data': {
          'id': 14,
          'code': 'P14',
          'slug': 'shipping-bag',
          'name': 'كيس شحن',
          'pricing_unit': 'piece',
          'pricing_unit_label': 'قطعة',
          'stock_unit': 'kilogram',
          'stock_unit_label': 'كيلوغرام',
          'pricing_mode': 'tiered',
          'pricing_mode_label': 'حسب الكمية',
          'has_listed_prices': true,
          'min_order_quantity': '100.000',
          'is_active': true,
        },
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
  late _CapturingAdapter adapter;
  late ProductRepositoryImpl repository;

  setUp(() {
    adapter = _CapturingAdapter();
    repository = ProductRepositoryImpl(
      Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))..httpClientAdapter = adapter,
    );
  });

  test('the product is named in the path, and the verb is a PATCH', () async {
    // Arrange

    // Act
    await repository.setStockUnit(14, PricingUnit.kilogram);

    // Assert — a PATCH rather than a PUT: one declared fact about the product changes, and the
    // rest of the resource is not being restated.
    expect(adapter.method, 'PATCH');
    expect(adapter.path, '/products/14/stock-unit');
  });

  test('the body is the unit and nothing else', () async {
    // Arrange

    // Act
    await repository.setStockUnit(14, PricingUnit.kilogram);

    // Assert — the wire value, not the Arabic label: the label is the server's to send back.
    final sent = jsonDecode(adapter.body!) as Map<String, dynamic>;

    expect(sent, {'unit': 'kilogram'});
  });

  test('the refreshed product comes back, both units on it', () async {
    // Arrange

    // Act
    final result = await repository.setStockUnit(14, PricingUnit.kilogram);

    // Assert — sold by the piece, counted by the kilo. One product, two units, and the screen
    // reads both off the answer rather than patching its own copy.
    final product = result.getOrElse(() => throw StateError('expected a product'));

    expect(product.pricingUnit, 'piece');
    expect(product.stockUnit, 'kilogram');
    expect(product.stockUnitLabel, 'كيلوغرام');
    expect(product.stocksInAnotherUnit, isTrue);
  });

  test('the use case passes the unit through untouched', () async {
    // Arrange — nothing to normalise here: the value is an enum, not something typed.
    final setStockUnit = SetProductStockUnit(repository);

    // Act
    await setStockUnit(14, PricingUnit.piece);

    // Assert
    final sent = jsonDecode(adapter.body!) as Map<String, dynamic>;

    expect(sent['unit'], 'piece');
  });
}
