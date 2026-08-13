import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:printing/features/manufacturing_cost_rates/models/manufacturing_cost_rate.dart';
import 'package:printing/features/manufacturing_cost_rates/repositories/manufacturing_cost_rate_repository_impl.dart';

/// What actually leaves the phone for معدلات تكلفة التصنيع.
///
/// **Three of these are things the server would accept while meaning something else**, which is
/// exactly the class of bug no screen shows:
///
/// - `is_active` is a `0`/`1` the API filters on; sending `true` narrows nothing and quietly
///   returns both.
/// - an update is a **full replacement**. A body that leaves out `product_id` demotes a
///   product-wide rate into the workshop-wide default, one that leaves out `is_active` re-offers
///   a rate somebody stopped, and one that leaves out `notes` erases them — all silently, all
///   with a 200.
/// - `cost_type` in the *query string* is parsed with a bare `from()` on the server, so a value
///   the enum cannot read is a 500 rather than a 422. Nothing but a known wire value may be sent.
///
/// Requests are stopped at the door, so nothing here needs a server.
///
/// Arrange - Act - Assert throughout.
void main() {
  late _Capture capture;
  late ManufacturingCostRateRepositoryImpl repository;

  setUp(() {
    capture = _Capture();
    repository = ManufacturingCostRateRepositoryImpl(
      Dio(BaseOptions(baseUrl: 'http://test/api/v1'))..interceptors.add(capture),
    );
  });

  // ─────────────────────────────── the list ───────────────────────────────

  group('the list', () {
    test('an unfiltered list asks for the whole ladder', () async {
      // Arrange — a rung left out of the answer is a rung nobody can see is missing.
      // Act
      await repository.rates();

      // Assert
      expect(capture.uri!.path, endsWith('/manufacturing-cost-rates'));
      expect(capture.uri!.query, isNot(contains('cost_type')));
      expect(capture.uri!.query, isNot(contains('is_active')));
      expect(capture.uri!.query, isNot(contains('product_id')));
    });

    test('the active filter goes out as the 0/1 the server reads', () async {
      // Act
      await repository.rates(isActive: false);

      // Assert — `false` on the wire is not what the API filters on.
      expect(capture.uri!.queryParameters['is_active'], '0');
    });

    test('the kind of cost travels as the server\'s own wire value', () async {
      // Act
      await repository.rates(costType: ManufacturingCostType.machineRuntime);

      // Assert
      expect(capture.uri!.queryParameters['cost_type'], 'machine_runtime');
    });

    test('a kind this build cannot name is not sent at all', () async {
      // Arrange — `unknown` is what the app *reads* when the server adds a case. Its wire is the
      // empty string, and this filter is parsed with a bare `from()`: sending it is a 500.
      // Act
      await repository.rates(costType: ManufacturingCostType.unknown);

      // Assert
      expect(capture.uri!.query, isNot(contains('cost_type')));
    });

    test('narrowing to one rung sends that id and no other', () async {
      // Act
      await repository.rates(productVariantId: 11);

      // Assert
      expect(capture.uri!.queryParameters['product_variant_id'], '11');
      expect(capture.uri!.query, isNot(contains('product_id')));
    });

    test('one rate is read by its own id', () async {
      // Act
      await repository.rate(7);

      // Assert
      expect(capture.method, 'GET');
      expect(capture.uri!.path, endsWith('/manufacturing-cost-rates/7'));
    });
  });

  // ───────────────────────────── writing one ─────────────────────────────

  group('adding one', () {
    test('every key travels, including the rungs it is not pinned to', () async {
      // Act
      await repository.create(
        costType: ManufacturingCostType.labor,
        ratePerUnit: '3.5',
        productId: 3,
      );

      // Assert — the ids are the rung, so the absent one has to arrive as a null rather than be
      // left out: the server fills a missing key with its own default.
      final body = capture.body! as Map<String, dynamic>;

      expect(capture.method, 'POST');
      expect(body['product_id'], 3);
      expect(body.containsKey('product_variant_id'), isTrue);
      expect(body['product_variant_id'], isNull);
      expect(body['cost_type'], 'labor');
      expect(body['is_active'], true);
      expect(body.containsKey('notes'), isTrue);
    });

    test('the rate stays the text it was typed as', () async {
      // Arrange — `0.850` through a `double` is how a decimal comes back as something else.
      // Act
      await repository.create(
        costType: ManufacturingCostType.overhead,
        ratePerUnit: '0.850',
      );

      // Assert
      final body = capture.body! as Map<String, dynamic>;

      expect(body['rate_per_unit'], isA<String>());
      expect(body['rate_per_unit'], '0.850');
    });
  });

  group('correcting one', () {
    test('an update is a full replacement, so the rung and the activation travel', () async {
      // Act
      await repository.update(
        7,
        costType: ManufacturingCostType.labor,
        ratePerUnit: '4',
        productId: 3,
        isActive: false,
      );

      // Assert — leaving `product_id` out would demote this to the default rate, and leaving
      // `is_active` out would quietly start applying it again.
      final body = capture.body! as Map<String, dynamic>;

      expect(capture.method, 'PUT');
      expect(capture.uri!.path, endsWith('/manufacturing-cost-rates/7'));
      expect(body['product_id'], 3);
      expect(body['product_variant_id'], isNull);
      expect(body['is_active'], false);
      expect(body.containsKey('notes'), isTrue, reason: 'a cleared note must arrive as a null');
      expect(body['notes'], isNull);
    });

    test('activation is its own PATCH, carrying nothing else', () async {
      // Act
      await repository.setActivation(7, isActive: false);

      // Assert
      expect(capture.method, 'PATCH');
      expect(capture.uri!.path, endsWith('/manufacturing-cost-rates/7/activation'));
      expect(capture.body, <String, dynamic>{'is_active': false});
    });

    test('a delete names the rate and sends no body', () async {
      // Act
      await repository.delete(7);

      // Assert
      expect(capture.method, 'DELETE');
      expect(capture.uri!.path, endsWith('/manufacturing-cost-rates/7'));
      expect(capture.body, isNull);
    });
  });
}

/// Rejects every request, keeping what it was about to send.
class _Capture extends Interceptor {
  Uri? uri;
  Object? body;
  String? method;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    uri = options.uri;
    body = options.data;
    method = options.method;

    handler.reject(DioException(requestOptions: options, message: 'captured'), true);
  }
}
