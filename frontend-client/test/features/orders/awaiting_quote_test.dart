import 'dart:io';

import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:flutter_test/flutter_test.dart';

/// An order for something the shop has not priced yet.
///
/// **The one thing worth pinning here is that "no price" survives the wire as null.** The
/// server deliberately sends null rather than the figure it holds — while a line is unquoted the
/// stored total is the sum of the *priced* lines only, which is a smaller number than the
/// customer will be asked for. A model that decoded that null into `'0.00'`, or that still
/// required the field, would put a wrong figure back on the screen the server took pains to keep
/// off it.
///
/// The stage half is the same shape of promise: «مرفوضة» is its own stage and must not decode to
/// [OrderStage.unknown] — this app has already shipped an enum where two cases silently decoded
/// to nothing and a notice never once appeared.
///
/// Arrange - Act - Assert throughout.
void main() {
  /// A row of «طلباتي» as the list endpoint sends one, with the money left out the way the
  /// server leaves it out.
  Map<String, dynamic> unpricedRow() => <String, dynamic>{
    'id': 1,
    'code': '1228',
    'stage': 'under_review',
    'stage_label': 'بانتظار المراجعة',
    'is_open': true,
    'total': null,
    'is_awaiting_quote': true,
  };

  group('a row with no price yet', () {
    test('decodes with no total rather than refusing the row', () {
      // Arrange
      final json = unpricedRow();

      // Act
      final order = CustomerOrder.fromJson(json);

      // Assert — `total` used to be required. An order the shop has not quoted has no total,
      // and a model that insisted on one could not represent the order at all.
      expect(order.total, isNull);
      expect(order.isAwaitingQuote, isTrue);
    });

    test('a priced row still carries its figure', () {
      // Arrange
      final json = unpricedRow()
        ..['total'] = '250.00'
        ..['is_awaiting_quote'] = false;

      // Act
      final order = CustomerOrder.fromJson(json);

      // Assert — the other side of it: nothing about this change makes an ordinary order
      // ambiguous.
      expect(order.total, '250.00');
      expect(order.isAwaitingQuote, isFalse);
    });

    test('an older payload with no flag at all is treated as priced', () {
      // Arrange — a server that has not shipped this field yet.
      final json = unpricedRow()
        ..remove('is_awaiting_quote')
        ..['total'] = '250.00';

      // Act
      final order = CustomerOrder.fromJson(json);

      // Assert — defaulting to false is the safe direction: an order that *is* priced and is
      // wrongly drawn as «يُحدَّد بعد المراجعة» hides a number the customer is owed.
      expect(order.isAwaitingQuote, isFalse);
    });
  });

  group('an order opened', () {
    test('every money field can be absent together', () {
      // Arrange
      final json = <String, dynamic>{
        'id': 1,
        'code': '1228',
        'stage': 'under_review',
        'stage_label': 'بانتظار المراجعة',
        'is_open': true,
        'items': [
          {
            'id': 9,
            'product_name': 'كروت',
            'variant_label': 'كروت عادية',
            'quantity': '100.000',
            'unit_price': null,
            'line_total': null,
          },
        ],
        'items_total': null,
        'total': null,
        'balance': null,
        'is_awaiting_quote': true,
      };

      // Act
      final order = CustomerOrderDetail.fromJson(json);

      // Assert — the line is still drawn: the customer ordered it and is entitled to see it,
      // with the price said to be coming rather than the row quietly missing.
      expect(order.items, hasLength(1));
      expect(order.items.first.productName, 'كروت');
      expect(order.items.first.unitPrice, isNull);
      expect(order.items.first.lineTotal, isNull);
      expect(order.total, isNull);
      expect(order.balance, isNull);
      expect(order.isAwaitingQuote, isTrue);
    });
  });

  group('the refused stage', () {
    test('decodes to its own stage, not to cancelled and not to unknown', () {
      // Arrange
      final json = <String, dynamic>{
        'id': 1,
        'code': '1228',
        'stage': 'rejected',
        'stage_label': 'مرفوضة',
        'is_open': false,
        'total': null,
        'is_awaiting_quote': true,
        'rejection_reason': 'المقاس غير متوفر لدينا حالياً',
      };

      // Act
      final order = CustomerOrderDetail.fromJson(json);

      // Assert — **not `unknown`**, which is what an unrecognised word decodes to. Landing
      // there would mean this build cannot read a stage the server is already sending.
      expect(order.stage, OrderStage.rejected);
      expect(order.stage, isNot(OrderStage.cancelled));
      expect(order.stage, isNot(OrderStage.unknown));
      expect(order.isOpen, isFalse);
      expect(order.rejectionReason, 'المقاس غير متوفر لدينا حالياً');
    });

    test('the wire spelling matches the one the backend declares', () {
      // Arrange — read from the PHP rather than repeated here, the arrangement every other
      // contract test in this repo uses. Skips when the backend is not checked out beside it.
      final source = File('../backend/app/Domain/Order/Enums/CustomerOrderStage.php');

      if (!source.existsSync()) {
        markTestSkipped('backend not checked out beside this app');

        return;
      }

      final php = source.readAsStringSync();

      // Act
      final wires = RegExp(r"case \w+ = '([^']+)';")
          .allMatches(php)
          .map((match) => match.group(1)!)
          .toSet();

      // Assert — every stage the server can send is one this build decodes to something other
      // than `unknown`.
      for (final wire in wires) {
        final stage = CustomerOrderDetail.fromJson(<String, dynamic>{
          'id': 1,
          'code': '1228',
          'stage': wire,
          'stage_label': 'أيًّا كان',
        }).stage;

        expect(
          stage,
          isNot(OrderStage.unknown),
          reason: "the server sends '$wire' and this build does not recognise it",
        );
      }
    });
  });
}
