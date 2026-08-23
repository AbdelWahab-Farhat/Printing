import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dayaa/core/files/picked_file.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/repositories/order_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// What a move actually puts on the wire — in **two** formats, and why there are two.
///
/// Every move this app has ever made went up as JSON. Then «تم الاستلام» started carrying the
/// الواصل, and a file cannot travel in a JSON body. Rather than switch every move to multipart
/// to serve two statuses — putting warehouse ids, design ids and quantities through a different
/// encoding to buy tidiness — the body changes shape only when a file is actually attached.
///
/// That is a deliberate departure from `OrderPaymentRepositoryImpl`, which is always multipart:
/// that endpoint was new and always took a receipt, so one format cost it nothing. **The price
/// of the departure is this file**: both formats are pinned, so the JSON path cannot regress
/// while the multipart one is being worked on, or the other way round.
///
/// Arrange - Act - Assert throughout.
class _CapturingAdapter implements HttpClientAdapter {
  List<int>? body;
  String? contentType;

  String get text => utf8.decode(body ?? const []);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    contentType = options.contentType;

    if (requestStream != null) {
      body = (await requestStream.toList()).expand((chunk) => chunk).toList();
    }

    return ResponseBody.fromString(
      jsonEncode({
        'status': true,
        'message': 'تم',
        'data': {
          'id': 3,
          'code': 'ORD-3',
          'status': 'delivered',
          'status_label': 'تم الاستلام',
          'is_final': false,
          'is_closed': true,
          'available_transitions': <Object>[],
          'progress': <Object>[],
          'items_are_editable': false,
          'designs_are_editable': false,
          'destination_is_editable': false,
          'customer_id': 1,
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
  late OrderRepositoryImpl repository;
  late File receipt;

  setUp(() {
    adapter = _CapturingAdapter();
    repository = OrderRepositoryImpl(
      Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))..httpClientAdapter = adapter,
    );

    // A real file on disk, because `MultipartFile.fromFile` streams from one rather than taking
    // bytes handed to it.
    receipt = File('${Directory.systemTemp.path}/waseel-wire-test.pdf')
      ..writeAsBytesSync(utf8.encode('%PDF-1.4 pretend'));
  });

  tearDown(() {
    if (receipt.existsSync()) receipt.deleteSync();
  });

  test('a move with no file stays exactly the JSON it has always been', () async {
    // Arrange — the commonest move in the shop, and the one carrying most of the app's history.

    // Act
    await repository.changeStatus(
      3,
      status: OrderStatus.ready,
      fields: const {'warehouse_id': 2, 'warehouse_quantity_31': '12.500'},
    );

    // Assert — one nested object, sent as the transition described it. A number stays a number
    // and an id stays an int: nothing about this path changed when files arrived.
    final sent = jsonDecode(adapter.text) as Map<String, dynamic>;

    expect(sent['status'], 'ready');
    expect(sent['fields'], {'warehouse_id': 2, 'warehouse_quantity_31': '12.500'});
    expect(adapter.contentType, isNot(contains('multipart')));
  });

  test('a move carrying a receipt goes up as multipart, keyed the same way', () async {
    // Arrange
    final file = PickedFile(path: receipt.path, name: 'waseel.pdf', sizeBytes: 16);

    // Act
    await repository.changeStatus(
      3,
      status: OrderStatus.delivered,
      reason: 'استلمها بنفسه',
      fields: {
        'payment_amount': '200.00',
        'payment_method': 'bank_transfer',
        'payment_receipt': file,
      },
    );

    // Assert — `fields[key]`, which is how Laravel reads a nested bag back out of a multipart
    // body. The keys are the transition's own, untouched: the format changed and the contract
    // did not.
    expect(adapter.contentType, contains('multipart/form-data'));
    expect(adapter.text, contains('name="status"'));
    expect(adapter.text, contains('name="reason"'));
    expect(adapter.text, contains('name="fields[payment_amount]"'));
    expect(adapter.text, contains('name="fields[payment_method]"'));
    expect(adapter.text, contains('200.00'));
    expect(adapter.text, contains('bank_transfer'));
  });

  test('the file travels under its own name, not a made-up one', () async {
    // Arrange — the server records this as `receipt_original_filename`, so an invented `.pdf`
    // on what is really a photograph would be a lie stored on the payment for good.
    final file = PickedFile(path: receipt.path, name: 'حوالة الزبون.pdf', sizeBytes: 16);

    // Act
    await repository.changeStatus(
      3,
      status: OrderStatus.delivered,
      fields: {'payment_amount': '200.00', 'payment_method': 'bank_transfer', 'payment_receipt': file},
    );

    // Assert
    expect(adapter.text, contains('name="fields[payment_receipt]"'));
    expect(adapter.text, contains('حوالة الزبون.pdf'));
    expect(adapter.text, contains('%PDF-1.4 pretend'));
  });
}
