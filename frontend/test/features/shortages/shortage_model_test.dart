import 'package:dayaa/features/shortages/models/shortage.dart';
import 'package:dayaa/features/shortages/models/shortage_counts.dart';
import 'package:dayaa/features/shortages/models/shortage_supply.dart';
import 'package:flutter_test/flutter_test.dart';

/// What the wire says, and what this app makes of it.
///
/// **Two shapes of the same record.** On the list the nested objects are `whenLoaded` and simply
/// **absent** — not null, absent — while the matching ids are always there; on the detail they
/// arrive, and so does the ledger. A model that required any of them would fail to parse a page
/// of forty.
///
/// Arrange - Act - Assert throughout.
void main() {
  /// The list shape: ids, no nested objects, no supplies.
  Map<String, dynamic> listJson() => {
    'id': 41,
    'code': 'N41',
    'source': 'order',
    'source_label': 'من طلبية',
    'name': 'كيس شحن — 25*35',
    'unit': 'kilogram',
    'unit_label': 'كجم',
    'required_quantity': '30.000',
    'supplied_quantity': '20.000',
    'remaining_quantity': '10.000',
    'total_paid': '500.00',
    'status': 'searching',
    'status_label': 'جاري البحث',
    'is_final': false,
    'available_transitions': [
      {'value': 'unavailable', 'label': 'غير متوفر'},
    ],
    'is_editable': false,
    'is_stockable': true,
    'order_id': 1204,
    'order_item_id': 3310,
    'customer_id': 88,
    'product_id': 12,
    'product_variant_id': 45,
    'assigned_to_user_id': 6,
    'created_by_user_id': 2,
    'description': null,
    'created_at': '2026-09-12T08:14:00+00:00',
    'updated_at': '2026-09-12T09:02:11+00:00',
  };

  group('the list shape', () {
    test('parses with every nested object absent', () {
      // Arrange - Act
      final shortage = Shortage.fromJson(listJson());

      // Assert — the ids are what a card falls back on.
      expect(shortage.order, isNull);
      expect(shortage.orderId, 1204);
      expect(shortage.assignee, isNull);
      expect(shortage.assignedToUserId, 6);
      expect(shortage.supplies, isEmpty);
    });

    test('the quantities stay the strings the server printed', () {
      // Arrange - Act
      final shortage = Shortage.fromJson(listJson());

      // Assert — parsed only to compare, never to display: a double is where «30.000» stops
      // being the figure the server sent.
      expect(shortage.requiredQuantity, '30.000');
      expect(shortage.remainingQuantity, '10.000');
      expect(shortage.totalPaid, '500.00');
    });

    test('a status this build has never heard of lands on unknown, and still draws', () {
      // Arrange — one new case on the server must not turn a whole page into a parse failure.
      final json = listJson()..['status'] = 'haggling';
      json['status_label'] = 'قيد المساومة';

      // Act
      final shortage = Shortage.fromJson(json);

      // Assert — the label is the server's, so the word on screen is right even here.
      expect(shortage.status, ShortageStatus.unknown);
      expect(shortage.statusLabel, 'قيد المساومة');
    });

    test('«مكتمل» is never something this app offers to move to', () {
      // Arrange — it is written by arithmetic when the remainder reaches zero.
      final shortage = Shortage.fromJson(listJson());

      // Act - Assert — the buttons are drawn from this list and from nothing else.
      expect(shortage.availableTransitions.map((t) => t.value), isNot(contains('completed')));
      expect(shortage.canChangeStatus, isTrue);
    });
  });

  group('the detail shape', () {
    test('parses the nested objects and the ledger', () {
      // Arrange
      final json = listJson()
        ..['order'] = {'id': 1204, 'code': '1204', 'status': 'shortage', 'is_archived': false}
        ..['customer'] = {'id': 88, 'name': 'محل النور', 'phone': '0910000000'}
        ..['assignee'] = {'id': 6, 'name': 'محمد', 'employee_code': 'E6'}
        ..['supplies'] = [
          {
            'id': 77,
            'shortage_id': 41,
            'kind': 'purchased',
            'kind_label': 'شراء',
            'quantity': '20.000',
            'amount': '500.00',
            'method': 'cash',
            'method_label': 'كاش',
            'occurred_on': '2026-09-11',
            'warehouse_id': 3,
            'warehouse': {'id': 3, 'name': 'المخزن الرئيسي'},
            'stock_movement_id': 912,
            'moved_stock': true,
            'is_reversal': false,
            'is_reversed': false,
            'is_reversible': true,
            'recorded_by_user_id': 6,
            'recorder': {'id': 6, 'name': 'محمد', 'employee_code': 'E6'},
            'created_at': '2026-09-11T10:20:00+00:00',
          },
        ];

      // Act
      final shortage = Shortage.fromJson(json);

      // Assert
      expect(shortage.order?.code, '1204');
      expect(shortage.assignee?.name, 'محمد');
      expect(shortage.supplies.single.warehouse?.name, 'المخزن الرئيسي');
      expect(shortage.supplies.single.movedStock, isTrue);
    });

    test('an arrival from the order carries no money at all', () {
      // Arrange — nobody in this section created it: a colleague typed what turned up into the
      // order screen when the order left «نواقص».
      final supply = ShortageSupply.fromJson({
        'id': 78,
        'shortage_id': 41,
        'kind': 'resolved_externally',
        'kind_label': 'وصلت من الطلبية',
        'quantity': '10.000',
        'amount': null,
        'method': null,
        'method_label': null,
        'moved_stock': false,
        'is_reversal': false,
        'is_reversed': false,
        'is_reversible': false,
      });

      // Act - Assert — the table prints a dash for these, never «0.00», which would read as a
      // free purchase and sit wrongly in anybody's mental total.
      expect(supply.kind, SupplyKind.resolvedExternally);
      expect(supply.hasMoney, isFalse);
      expect(supply.isReversible, isFalse);
    });

    test('a reversal and the row it reversed are both struck through', () {
      // Arrange
      Map<String, dynamic> row({required bool isReversal, required bool isReversed}) => {
        'id': 79,
        'shortage_id': 41,
        'kind': isReversal ? 'reversal' : 'purchased',
        'kind_label': isReversal ? 'عكس عملية' : 'شراء',
        'quantity': isReversal ? '-20.000' : '20.000',
        'is_reversal': isReversal,
        'is_reversed': isReversed,
        'is_reversible': false,
      };

      // Act - Assert — both stay in the table: §٩ asks for a log of every operation, and a
      // correction that vanished would make the arithmetic look like a mistake.
      expect(ShortageSupply.fromJson(row(isReversal: true, isReversed: false)).isStruckThrough, isTrue);
      expect(ShortageSupply.fromJson(row(isReversal: false, isReversed: true)).isStruckThrough, isTrue);
      expect(ShortageSupply.fromJson(row(isReversal: false, isReversed: false)).isStruckThrough, isFalse);
    });
  });

  group('what the card reads off it', () {
    test('a manual shortage names no order', () {
      // Arrange
      final json = listJson()
        ..['source'] = 'manual'
        ..['source_label'] = 'يدوي'
        ..remove('order_id');

      // Act
      final shortage = Shortage.fromJson(json);

      // Assert — «يدوي» is what the card draws instead.
      expect(shortage.isFromOrder, isFalse);
      expect(shortage.orderCode, isNull);
    });

    test('an order-born shortage names its order even without the object', () {
      // Arrange - Act — the list payload carries the id alone.
      final shortage = Shortage.fromJson(listJson());

      // Assert
      expect(shortage.orderCode, '1204');
    });

    test('nothing owed is not outstanding', () {
      // Arrange
      final json = listJson()
        ..['remaining_quantity'] = '0.000'
        ..['status'] = 'completed'
        ..['status_label'] = 'مكتمل';

      // Act - Assert
      expect(Shortage.fromJson(json).isOutstanding, isFalse);
    });

    test('a quantity is printed with the unit the server named it in', () {
      // Arrange - Act
      final shortage = Shortage.fromJson(listJson());

      // Assert — trimmed of the column's padding, like every other figure in this app.
      expect(shortage.withUnit(shortage.remainingQuantity), '10 كجم');
    });

    test('a manual shortage with no unit prints the bare figure', () {
      // Arrange
      final json = listJson()
        ..remove('unit')
        ..remove('unit_label');

      // Act - Assert
      expect(Shortage.fromJson(json).withUnit('4.000'), '4');
    });
  });

  group('the board', () {
    test('parses the counts and reads the total rather than summing it', () {
      // Arrange — a status added after this build shipped is inside `total` and not inside the
      // four chips, so summing would quietly undercount.
      final counts = ShortageCounts.fromJson({
        'counts': {'new': 12, 'searching': 7, 'unavailable': 3, 'completed': 25},
        'total': 50,
      });

      // Act - Assert
      expect(counts.forStatus(ShortageStatus.fresh), 12);
      expect(counts.total, 50);
      expect(counts.total, isNot(12 + 7 + 3 + 25));
    });

    test('a status the server did not mention reads zero, not null', () {
      // Arrange
      const counts = ShortageCounts.empty();

      // Act - Assert
      expect(counts.forStatus(ShortageStatus.completed), 0);
    });
  });
}
