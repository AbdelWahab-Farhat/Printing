import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/stock_effect.dart';
import 'package:flutter_test/flutter_test.dart';

/// What the confirmation dialog is going to say, parsed rather than composed.
///
/// **Every Arabic sentence in `stock_effect` is the server's, and none of it is written here.**
/// The precedent is `TransitionFields::deductionPreview()`, whose own comment gives the two
/// rules this inherits: it is a *hint* rather than a field, so it reaches every build without a
/// release; and it cannot drift from what the action will do, because the preview and the action
/// read the same accessor. A `switch` in Dart that turned `kind` into a sentence would break
/// both — it would ship on the app's release cycle, and it would be a second opinion about what
/// the delete is about to do.
///
/// So this file pins the *shape* and nothing about the wording: the three kinds, the lines, and
/// the note that only the restore carries.
///
/// Arrange - Act - Assert throughout.
void main() {
  group('deleted_at', () {
    test('a live order carries no stamp, and says so', () {
      // Arrange
      final json = _orderJson();

      // Act
      final order = Order.fromJson(json);

      // Assert
      expect(order.deletedAt, isNull);
      expect(order.isArchived, isFalse);
    });

    test('an archived order carries the instant it was archived', () {
      // Arrange — the one key both lists read: الطلبيات drops the row when it appears and the
      // archive drops it when it goes.
      final json = _orderJson(deletedAt: '2026-09-10T09:00:00+00:00');

      // Act
      final order = Order.fromJson(json);

      // Assert
      expect(order.deletedAt, DateTime.parse('2026-09-10T09:00:00+00:00'));
      expect(order.isArchived, isTrue);
    });

    test('a list row without the key at all is a live order', () {
      // Arrange — an older server, or a payload trimmed on the way. «مفقود» is «حيّة» and never
      // «محذوفة»: the safe reading of a missing stamp is the order still being in the shop.
      final json = _orderJson()..remove('deleted_at');

      // Act
      final order = Order.fromJson(json);

      // Assert
      expect(order.isArchived, isFalse);
    });
  });

  group('stock_effect.stock', () {
    test('a delete that returns goods lists them, line by line', () {
      // Arrange — the headline and each label are the server's own words.
      final json = _effectJson(
        stock: <String, dynamic>{
          'kind': 'return',
          'warning': 'سيُعاد إلى المخزن ما خصمته هذه الطلبية:',
          'lines': [
            {'label': 'كيس شحن 25*35', 'quantity': '300', 'unit': 'قطعة'},
          ],
          'note': null,
        },
      );

      // Act
      final effect = StockEffect.fromJson(json);

      // Assert
      expect(effect.stock.kind, StockEffectKind.returnToShelf);
      expect(effect.stock.warning, 'سيُعاد إلى المخزن ما خصمته هذه الطلبية:');
      expect(effect.stock.lines.single.label, 'كيس شحن 25*35');
      expect(effect.stock.lines.single.quantity, '300');
      expect(effect.stock.lines.single.unit, 'قطعة');
      expect(effect.stock.note, isNull);
      expect(effect.stock.movesStock, isTrue);
    });

    test('a restore warns that the cost changes, in a second paragraph', () {
      // Arrange — the note exists for the one thing nobody would guess: the new deduction eats
      // today's layers, so the order comes back costing something else.
      final json = _effectJson(
        stock: <String, dynamic>{
          'kind': 'rededuct',
          'warning': 'سيُخصم من المخزن من جديد:',
          'lines': [
            {'label': 'كيس شحن 25*35', 'quantity': '300', 'unit': 'قطعة'},
          ],
          'note': 'وقد تختلف تكلفة الطلبية عمّا كانت، لأن الخصم الجديد يأكل طبقات اليوم',
        },
      );

      // Act
      final effect = StockEffect.fromJson(json);

      // Assert
      expect(effect.stock.kind, StockEffectKind.rededuct);
      expect(
        effect.stock.note,
        'وقد تختلف تكلفة الطلبية عمّا كانت، لأن الخصم الجديد يأكل طبقات اليوم',
      );
      expect(effect.stock.movesStock, isTrue);
    });

    test('«none» is an empty list and a sentence, not an absent block', () {
      // Arrange — an order whose stock a cancellation already put back. The server still sends a
      // warning, and it still gets shown: «لا شيء يتحرّك» is an answer worth reading before a
      // delete, and a dialog that showed nothing would read as a dialog that failed to load.
      final json = _effectJson(
        stock: <String, dynamic>{
          'kind': 'none',
          'warning': 'لن يتحرّك أي مخزون بحذف هذه الطلبية.',
          'lines': <Map<String, dynamic>>[],
          'note': null,
        },
      );

      // Act
      final effect = StockEffect.fromJson(json);

      // Assert
      expect(effect.stock.kind, StockEffectKind.none);
      expect(effect.stock.lines, isEmpty);
      expect(effect.stock.movesStock, isFalse);
    });

    test('a kind this build has never heard of still renders its sentence', () {
      // Arrange — the same forward compatibility `OrderStatus.unknown` buys the list: a server
      // that grows a fourth kind must not blank the warning it sent with it.
      final json = _effectJson(
        stock: <String, dynamic>{
          'kind': 'something_new',
          'warning': 'كلامٌ من خادمٍ أحدث.',
          'lines': <Map<String, dynamic>>[],
          'note': null,
        },
      );

      // Act
      final effect = StockEffect.fromJson(json);

      // Assert
      expect(effect.stock.kind, StockEffectKind.unknown);
      expect(effect.stock.warning, 'كلامٌ من خادمٍ أحدث.');
    });
  });

  group('stock_effect.money', () {
    test('a delete names every kind of money it is about to reverse', () {
      // Arrange — §٢٫١ made the delete write reversal entries instead of refusing to run, so the
      // confirmation has to say what is about to be undone, kind by kind, with its figure. The
      // amounts are the server's: it read them from the very ledger the delete will walk, so the
      // number shown cannot differ from the number written.
      final json = _effectJson(
        money: <String, dynamic>{
          'kind': 'reverse',
          'warning': 'سيُعكس ما قُبض على هذه الطلبية:',
          'lines': [
            {'label': 'مدفوع', 'amount': '1200.00', 'currency': 'د.ل'},
            {'label': 'تحصيل مندوب', 'amount': '300.00', 'currency': 'د.ل'},
          ],
          'note': 'والاستعادة لا تُعيدها.',
        },
      );

      // Act
      final effect = StockEffect.fromJson(json);

      // Assert
      expect(effect.money?.kind, MoneyEffectKind.reverse);
      expect(effect.money?.lines, hasLength(2));
      expect(effect.money?.lines.first.label, 'مدفوع');
      expect(effect.money?.lines.first.amount, '1200.00');
      expect(effect.money?.lines.first.currency, 'د.ل');
      expect(effect.money?.note, 'والاستعادة لا تُعيدها.');
    });

    test('an order with nothing collected carries no money block at all', () {
      // Arrange — §٧٫١ is explicit that this is null rather than an empty section: a heading that
      // resolves to «لا يوجد» is a heading somebody read for no reason.
      final json = _effectJson();

      // Act
      final effect = StockEffect.fromJson(json);

      // Assert
      expect(effect.money, isNull);
      expect(effect.isLoud, isFalse);
    });

    test('a restore says the reversed money is not coming back, and lists none of it', () {
      // Arrange — the sentence this whole section exists for. Without it a reader takes «سيُعكس»
      // for «and it can be undone», which is the one wrong idea the dialog must prevent: the
      // payment has to be entered again by hand if the money really was taken.
      //
      // No lines, deliberately: the amounts belonged to the confirmation that *did* the
      // reversing, where they could still change somebody's mind. Here they would be a bill for
      // a decision already taken.
      final json = _effectJson(
        money: <String, dynamic>{
          'kind': 'reversed',
          'warning': 'الدفعات المعكوسة لا تعود.',
          'lines': <Map<String, dynamic>>[],
          'note': null,
        },
      );

      // Act
      final effect = StockEffect.fromJson(json);

      // Assert
      expect(effect.money?.kind, MoneyEffectKind.reversed);
      expect(effect.money?.lines, isEmpty);
      expect(effect.isLoud, isTrue);
    });

    test('a money kind this build has never heard of still renders its sentence', () {
      // Arrange — as with the stock kinds: a newer server must never blank its own warning.
      final json = _effectJson(
        money: <String, dynamic>{
          'kind': 'written_off_somehow',
          'warning': 'كلامٌ ماليٌّ من خادمٍ أحدث.',
          'lines': <Map<String, dynamic>>[],
          'note': null,
        },
      );

      // Act
      final effect = StockEffect.fromJson(json);

      // Assert
      expect(effect.money?.kind, MoneyEffectKind.unknown);
      expect(effect.money?.warning, 'كلامٌ ماليٌّ من خادمٍ أحدث.');
    });
  });

  group('stock_effect on the order', () {
    test('the list rows never carry one — it belongs to the order that was opened', () {
      // Arrange — building it costs a per-line read of the movement ledger and a walk of the
      // payment ledger, and no row on a list is about to be deleted.
      final json = _orderJson();

      // Act
      final order = Order.fromJson(json);

      // Assert
      expect(order.stockEffect, isNull);
    });

    test('an opened order carries the preview of what its button would do', () {
      // Arrange
      final json = _orderJson()..['stock_effect'] = _effectJson(
        stock: <String, dynamic>{
          'kind': 'return',
          'warning': 'سيُعاد إلى المخزن ما خصمته هذه الطلبية:',
          'lines': [
            {'label': 'كيس شحن 25*35', 'quantity': '300', 'unit': 'قطعة'},
          ],
          'note': null,
        },
      );

      // Act
      final order = Order.fromJson(json);

      // Assert
      expect(order.stockEffect?.stock.kind, StockEffectKind.returnToShelf);
      expect(order.stockEffect?.stock.lines, hasLength(1));
    });
  });
}

/// The envelope, money-first as the server builds it — see §٧٫١ for why that order is not Dart's
/// to choose. `money` defaults to absent, which is the common case: most orders carry no money.
Map<String, dynamic> _effectJson({
  Map<String, dynamic>? money,
  Map<String, dynamic>? stock,
}) => <String, dynamic>{
  'money': money,
  'stock':
      stock ??
      <String, dynamic>{
        'kind': 'none',
        'warning': 'لن يتحرّك أي مخزون بحذف هذه الطلبية.',
        'lines': <Map<String, dynamic>>[],
        'note': null,
      },
};

Map<String, dynamic> _orderJson({String? deletedAt}) => <String, dynamic>{
  'id': 7,
  'code': '7',
  'status': 'ready',
  'status_label': 'جاهزة',
  'is_final': false,
  'customer_id': 5,
  'city_id': 3,
  'design_source': 'none',
  'city_name': 'طرابلس',
  'fulfilment_type_label': 'توصيل',
  'is_office_pickup': false,
  'design_source_label': 'بدون تصميم',
  'items_total': '330.00',
  'design_fee': '0.00',
  'delivery_price': '20.00',
  'discount': '0.00',
  'grand_total': '350.00',
  'deleted_at': deletedAt,
};
