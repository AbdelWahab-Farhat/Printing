import 'dart:convert';
import 'dart:typed_data';

import 'package:dayaa/features/products/models/production_mode.dart';
import 'package:dayaa/features/products/repositories/product_category_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// What actually goes down the wire when a heading is saved.
///
/// **The modern key, and only the modern key.** The server still accepts `skips_production`
/// for the build already in people's hands, and guards the one case where that boolean would
/// demote a وسيط heading — but a build that knows the three-way answer has no business sending
/// the two-way one beside it, and `production_mode` wins on the server whenever both arrive.
/// Sending it alone is what stops the server having to guess.
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
        'message': 'تم الحفظ',
        'data': {
          'id': 9,
          'name': 'كروت بزنس',
          'production_mode': 'outsourced',
          'production_mode_label': 'وسيط — لدى مورد خارجي',
          'skips_production': true,
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
  late ProductCategoryRepositoryImpl repository;

  setUp(() {
    adapter = _CapturingAdapter();
    repository = ProductCategoryRepositoryImpl(
      Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))..httpClientAdapter = adapter,
    );
  });

  test('adding a heading sends its mode by the modern key', () async {
    // Arrange - Act
    await repository.create(
      name: 'كروت بزنس',
      sortOrder: 4,
      productionMode: ProductionMode.outsourced,
    );

    // Assert
    expect(adapter.method, 'POST');
    expect(adapter.path, '/product-categories');

    final sent = jsonDecode(adapter.body!) as Map<String, dynamic>;
    expect(sent['production_mode'], 'outsourced');
    expect(sent.containsKey('skips_production'), isFalse);
  });

  test('editing a heading sends its mode by the modern key', () async {
    // Arrange — a PUT replaces the whole representation, so the mode has to travel with every
    // rename or the server would be left to read a missing key as an answer.
    // Act
    await repository.update(
      9,
      name: 'كروت بزنس',
      sortOrder: 4,
      isActive: true,
      productionMode: ProductionMode.none,
    );

    // Assert
    expect(adapter.method, 'PUT');
    expect(adapter.path, '/product-categories/9');

    final sent = jsonDecode(adapter.body!) as Map<String, dynamic>;
    expect(sent['production_mode'], 'none');
    expect(sent.containsKey('skips_production'), isFalse);
  });

  test('the answer is read back as a mode', () async {
    // Arrange - Act
    final result = await repository.create(
      name: 'كروت بزنس',
      sortOrder: 4,
      productionMode: ProductionMode.outsourced,
    );

    // Assert
    final stored = result.fold((failure) => fail(failure.message), (category) => category);
    expect(stored.productionMode, ProductionMode.outsourced);
  });
}
