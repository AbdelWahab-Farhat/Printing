import 'dart:convert';
import 'dart:typed_data';

import 'package:dayaa/features/orders/models/additional_cost_reason.dart';
import 'package:dayaa/features/orders/repositories/order_repository_impl.dart';
import 'package:dayaa/features/orders/usecases/update_order_invoice.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// What actually goes down the wire when the charge is set — and when it is not touched.
///
/// **`PUT` replaces the whole order**, which makes the field that is *not* being edited the
/// interesting one: an address correction that dropped `additional_cost_reason` would be a 422
/// about a field nobody opened, and one that dropped `additional_cost` would quietly wipe money
/// off the invoice. The repository re-reads the order first and echoes all three back.
///
/// Arrange - Act - Assert throughout.
class _CapturingAdapter implements HttpClientAdapter {
  String? body;
  String? method;

  /// The order as the server holds it — already carrying a charge, so the echo has something
  /// to be wrong about.
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
    'items_total': '330.00',
    'design_fee': '0.00',
    'delivery_price': '20.00',
    'discount': '0.00',
    'additional_cost': '10.00',
    'additional_cost_reason': 'special_packaging',
    'additional_cost_reason_label': 'تغليف خاص',
    'additional_cost_note': 'علبة كرتون مزدوجة',
    'grand_total': '360.00',
    'paid_amount': '0.00',
    'remaining_amount': '360.00',
    'payment_status': 'unpaid',
    'payment_status_label': 'غير مدفوعة',
  };

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    method = options.method;

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

  test('an edit that says nothing about the charge sends the order’s own three back', () async {
    // Arrange — the address being corrected on an order that already carries a charge.

    // Act
    await update(55, cityId: 2);

    // Assert — the amount is unchanged, so the server lets it through without the grant; drop
    // the reason and the same edit becomes a 422 about a field nobody opened.
    expect(adapter.method, 'PUT');
    expect(sent()['additional_cost'], '10.00');
    expect(sent()['additional_cost_reason'], 'special_packaging');
    expect(sent()['additional_cost_note'], 'علبة كرتون مزدوجة');
  });

  test('setting a charge sends the amount, its category and its words together', () async {
    // Arrange

    // Act
    await update(
      55,
      additionalCost: '٢٥٫٥',
      additionalCostReason: AdditionalCostReason.other,
      additionalCostNote: 'أجرة عامل تحميل',
    );

    // Assert — Arabic-Indic digits and the comma the keyboard produces are normalised on the
    // way out; the server refuses «٢٥٫٥» as a number.
    expect(sent()['additional_cost'], '25.5');
    expect(sent()['additional_cost_reason'], 'other');
    expect(sent()['additional_cost_note'], 'أجرة عامل تحميل');
  });

  test('clearing the box charges nothing, and takes the category with it', () async {
    // Arrange — an empty field is «لا تكلفة إضافية», which is a number and not a silence.

    // Act
    await update(55, additionalCost: '', additionalCostReason: AdditionalCostReason.transport);

    // Assert — a category for money nobody is charging is what the server refuses.
    expect(sent()['additional_cost'], '0.00');
    expect(sent().containsKey('additional_cost_reason'), isFalse);
    expect(sent().containsKey('additional_cost_note'), isFalse);
  });

  test('a reason with no amount is not sent as a charge of nothing', () async {
    // Arrange — the chips can be tapped before the box is filled.

    // Act
    await update(55, additionalCost: '0', additionalCostReason: AdditionalCostReason.modification);

    // Assert
    expect(sent()['additional_cost'], '0');
    expect(sent().containsKey('additional_cost_reason'), isFalse);
  });
}
