import 'package:dayaa/features/shortages/repositories/shortage_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// What actually goes on the wire for a shortage.
///
/// **The Impl is tested directly, not a fake of the contract.** What is worth pinning is the
/// shape of the request — the paths, the keys, and above all **which fields are omitted** — and a
/// fake of the abstract repository would assert nothing about any of that.
///
/// The omissions are the point: the list endpoint reads its filters without validating them, so a
/// literal `"null"` reaching an enum is a 500 rather than an empty page.
///
/// Arrange - Act - Assert throughout.
void main() {
  late Dio dio;
  late ShortageRepositoryImpl repository;
  late RequestOptions captured;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          captured = options;
          handler.reject(DioException(requestOptions: options, message: 'captured'), true);
        },
      ),
    );
    repository = ShortageRepositoryImpl(dio);
  });

  group('the list', () {
    test('omits every filter nobody set', () async {
      // Act
      await repository.shortages();

      // Assert — only the page and its size, and nothing that could arrive as "null".
      expect(captured.path, '/shortages');
      expect(captured.queryParameters.keys, containsAll(<String>['page', 'per_page']));
      expect(captured.queryParameters.containsKey('assigned_to'), isFalse);
      expect(captured.queryParameters.containsKey('source'), isFalse);
      expect(captured.queryParameters.containsKey('status'), isFalse);
      expect(captured.queryParameters.containsKey('search'), isFalse);
    });

    test('«me» and «none» travel as words, because neither is an id', () async {
      // Arrange - Act — «me» is only knowable on the server from the bearer token, and «none» is
      // a null a query string cannot otherwise carry.
      await repository.shortages(assignedTo: 'me');
      expect(captured.queryParameters['assigned_to'], 'me');

      await repository.shortages(assignedTo: 'none');

      // Assert
      expect(captured.queryParameters['assigned_to'], 'none');
    });

    test('the status is a list, and one status travels the same way as two', () async {
      // Act
      await repository.shortages(statuses: const ['searching']);

      // Assert — sent as `status[]=searching` by the client's multiCompatible format.
      expect(captured.queryParameters['status'], const ['searching']);
    });
  });

  group('the board', () {
    test('is asked with every filter except the status', () async {
      // Act
      await repository.statusCounts(assignedTo: 'me', source: 'order', search: 'كيس');

      // Assert — a chip row exists to say what *else* there is; counting only the status already
      // selected would make every chip but one read zero.
      expect(captured.path, '/shortages/summary');
      expect(captured.queryParameters['assigned_to'], 'me');
      expect(captured.queryParameters['source'], 'order');
      expect(captured.queryParameters['search'], 'كيس');
      expect(captured.queryParameters.containsKey('status'), isFalse);
    });
  });

  group('recording a supply', () {
    test('omits the warehouse on a shortage that has no shelf', () async {
      // Arrange - Act — sending one is a 422 in its own right: it tells the server goods are
      // moving when they are not.
      await repository.recordSupply(41, quantity: '20', amount: '500', method: 'cash');

      // Assert
      expect(captured.path, '/shortages/41/supplies');
      final body = captured.data! as Map<String, dynamic>;
      expect(body['quantity'], '20');
      expect(body.containsKey('warehouse_id'), isFalse);
      expect(body.containsKey('occurred_on'), isFalse);
    });

    test('sends the warehouse when the goods have one to land on', () async {
      // Act
      await repository.recordSupply(41, quantity: '20', amount: '500', method: 'cash', warehouseId: 3);

      // Assert
      expect((captured.data! as Map<String, dynamic>)['warehouse_id'], 3);
    });

    test('the undo is a POST to the row, not a DELETE', () async {
      // Act
      await repository.reverseSupply(41, 77, reason: 'سُجّلت مرتين');

      // Assert — it writes a new ledger entry rather than removing one; the history is the point.
      expect(captured.path, '/shortages/41/supplies/77/reversal');
      expect(captured.method, 'POST');
    });

    test('the undo sends «reason», which is the key the endpoint validates', () async {
      // Arrange - Act — this sent `notes` and, because nothing ever collected a value, the body
      // went out as `{}`. Every reversal came back 422 «سبب العكس مطلوب» and the row's action
      // looked broken. The same shape the unit picker above was caught in.
      await repository.reverseSupply(41, 77, reason: 'سُجّلت مرتين');

      // Assert
      final body = captured.data! as Map<String, dynamic>;
      expect(body['reason'], 'سُجّلت مرتين');
      expect(body.containsKey('notes'), isFalse);
    });
  });

  group('writing one down', () {
    test('sends the unit, which the server requires', () async {
      // Arrange - Act — the form shipped without a unit picker once and every hand-written
      // shortage came back «الوحدة مطلوبة». The field is not optional on a create.
      await repository.create(name: 'شريط لاصق عريض', quantity: '200', unit: 'piece');

      // Assert
      expect(captured.path, '/shortages');
      final body = captured.data! as Map<String, dynamic>;
      expect(body['name'], 'شريط لاصق عريض');
      expect(body['required_quantity'], '200');
      expect(body['unit'], 'piece');
    });

    test('sends the type when one was chosen', () async {
      // Act
      await repository.create(
        name: 'ورق A4',
        quantity: '3000',
        unit: 'piece',
        type: 'printing_paper',
      );

      // Assert — the second axis beside `source`: that says who wrote the row down, this says
      // what the shop is out of.
      final body = captured.data! as Map<String, dynamic>;
      expect(body['type'], 'printing_paper');
    });

    test('omits the type rather than guessing the default', () async {
      // Act
      await repository.create(name: 'شريط لاصق عريض', quantity: '200', unit: 'piece');

      // Assert — the server defaults it to «أخرى». A client that sent that itself would make one
      // default two decisions in two places, and they would drift.
      final body = captured.data! as Map<String, dynamic>;
      expect(body.containsKey('type'), isFalse);
    });

    test('omits the catalogue ids a free-text shortage does not have', () async {
      // Act
      await repository.create(name: 'شريط لاصق عريض', quantity: '200', unit: 'piece');

      // Assert — a null in a body is not the same hazard as one in a query string, but the
      // server reads «absent» as «this names no product» and a null would be a claim.
      final body = captured.data! as Map<String, dynamic>;
      expect(body.containsKey('product_id'), isFalse);
      expect(body.containsKey('product_variant_id'), isFalse);
    });
  });

  group('stating the weight', () {
    test('a PATCH to the shortage, carrying the quantity alone', () async {
      // Act — the weight nobody could know when the shortage was declared, stated from the
      // shortage's own screen rather than by a detour through the order.
      await repository.setWarehouseQuantity(41, quantity: '12.5');

      // Assert
      expect(captured.path, '/shortages/41/warehouse-quantity');
      expect(captured.method, 'PATCH');
      expect((captured.data! as Map<String, dynamic>)['quantity'], '12.5');
    });
  });

  group('assigning', () {
    test('a null is the instruction, not its absence', () async {
      // Arrange - Act — «غير مُسنَد» is a queue a supervisor works from, so putting a shortage
      // back into it is a write like any other. Omitting the key would say «leave it as it is».
      await repository.assign(41, userId: null);

      // Assert
      expect(captured.path, '/shortages/41/assignee');
      expect(captured.method, 'PATCH');
      expect((captured.data! as Map<String, dynamic>).containsKey('assigned_to_user_id'), isTrue);
      expect((captured.data! as Map<String, dynamic>)['assigned_to_user_id'], isNull);
    });
  });
}
