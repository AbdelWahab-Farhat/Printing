import 'dart:convert';
import 'dart:typed_data';

import 'package:dayaa/features/orders/repositories/order_repository_impl.dart';
import 'package:dayaa/features/orders/usecases/update_order_invoice.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// The vendor of a وسيط order survives an edit that never mentions it.
///
/// **`PUT` replaces the whole order**, so a body with no `vendor_id` is an instruction to clear
/// it — and `UpdateOrder` then asks the question `CreateOrder` asks and refuses the whole edit
/// with «الطلبية الوسيطة تحتاج مورداً». Correcting the pickup city on an order a vendor is
/// making must not walk into that.
///
/// Arrange - Act - Assert throughout.
class _CapturingAdapter implements HttpClientAdapter {
  String? body;

  /// The order as the server holds it — a وسيط one, already carrying its vendor.
  static Map<String, dynamic> order = <String, dynamic>{
    'id': 55,
    'code': '55',
    'customer_id': 3,
    'status': 'new',
    'status_label': 'جديدة',
    'is_final': false,
    'design_source': 'none',
    'design_source_label': 'بدون تصميم',
    'city_id': 1,
    'city_name': 'طرابلس',
    'fulfilment_type_label': 'توصيل',
    'is_office_pickup': false,
    'vendor_id': 7,
    'vendor_name': 'مطبعة النور',
    'items_total': '330.00',
    'design_fee': '0.00',
    'delivery_price': '20.00',
    'discount': '0.00',
    'additional_cost': '0.00',
    'grand_total': '350.00',
    'paid_amount': '0.00',
    'remaining_amount': '350.00',
    'payment_status': 'unpaid',
    'payment_status_label': 'غير مدفوعة',
  };

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (requestStream != null) {
      final chunks = await requestStream.toList();
      body = utf8.decode(chunks.expand((chunk) => chunk).toList());
    }

    return ResponseBody.fromString(
      jsonEncode({'status': true, 'message': 'تم', 'data': order}),
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
  late UpdateOrderInvoice update;

  setUp(() {
    adapter = _CapturingAdapter();
    update = UpdateOrderInvoice(
      OrderRepositoryImpl(
        Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))..httpClientAdapter = adapter,
      ),
    );
  });

  Map<String, dynamic> sent() => jsonDecode(adapter.body!) as Map<String, dynamic>;

  test('moving the pickup place sends the order’s own vendor back', () async {
    // Arrange — a وسيط order with a vendor named, opened only to fix the address.

    // Act
    await update(55, cityId: 2, regionId: 9);

    // Assert — omitting it clears the vendor, and the server then refuses the edit whole.
    expect(sent()['vendor_id'], 7);
  });

  test('an order nobody outsources sends no vendor at all', () async {
    // Arrange — the same edit on an order we make ourselves.
    _CapturingAdapter.order = <String, dynamic>{
      ..._CapturingAdapter.order,
      'vendor_id': null,
      'vendor_name': null,
    };
    addTearDown(() {
      _CapturingAdapter.order = <String, dynamic>{
        ..._CapturingAdapter.order,
        'vendor_id': 7,
        'vendor_name': 'مطبعة النور',
      };
    });

    // Act
    await update(55, cityId: 2);

    // Assert — a null is not sent as a key, the way every other untouched field is treated.
    expect(sent().containsKey('vendor_id'), isFalse);
  });
}
