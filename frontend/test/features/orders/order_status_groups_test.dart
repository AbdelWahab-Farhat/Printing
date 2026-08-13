import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:printing/features/orders/models/order_status.dart';

/// The two queues the customer screen asks for, and the line between them.
///
/// «الطلبات الجارية» and «الطلبات المستلمة» are the only groups this app draws over the
/// statuses, and both fall out of one predicate — [OrderStatus.isFinished] — rather than out of
/// two hand-written lists that could disagree with each other. These tests pin that.
///
/// The last one reads `OrderStatus.php` and checks the line is the same line the server draws in
/// `isClosed()`, which is the mechanical guard that keeps the two languages saying one thing.
/// It **skips** when the backend is not checked out beside this repo, exactly as
/// `order_status_contract_test.dart` does.
///
/// Arrange - Act - Assert throughout.
void main() {
  group('the two groups', () {
    test('«الجارية» is every status that is not over, and nothing else', () {
      // Arrange — the three the business calls finished. See CUSTOMER-ORDERS-SECTION.md §١.
      const over = {OrderStatus.delivered, OrderStatus.settled, OrderStatus.cancelled};

      // Act
      final inProgress = OrderStatus.inProgress.toSet();

      // Assert
      expect(
        inProgress,
        OrderStatus.values.toSet().difference({...over, OrderStatus.unknown}),
        reason: 'a status that is neither finished nor in progress is a queue nobody can reach',
      );
    });

    test('a returned order is still in progress', () {
      // Arrange — the three links of the return chain, plus the second attempt out of it.
      const returns = [
        OrderStatus.returnedCourier,
        OrderStatus.returnedCarrier,
        OrderStatus.returnedOffice,
        OrderStatus.resend,
      ];

      // Act
      final inProgress = OrderStatus.inProgress;

      // Assert — a parcel on its way back is work somebody still owes a decision on.
      for (final status in returns) {
        expect(inProgress, contains(status), reason: '«${status.label}» dropped out of الجارية');
      }
    });

    test('«المستلمة» is تم الاستلام and تم التسوية', () {
      // Act
      final received = OrderStatus.received;

      // Assert — settled is delivered *and* paid for, so it is received by definition. Leaving
      // it out would empty this list as orders were settled, which is the opposite of the word.
      expect(received, [OrderStatus.delivered, OrderStatus.settled]);
    });

    test('«إلغاء تام» is in neither group', () {
      // Act & Assert — nobody is working on it, and it reached nobody.
      expect(OrderStatus.inProgress, isNot(contains(OrderStatus.cancelled)));
      expect(OrderStatus.received, isNot(contains(OrderStatus.cancelled)));
    });

    test('neither group offers «unknown», which the server has never defined', () {
      // Act & Assert — sending it as a filter would ask for a status that does not exist.
      expect(OrderStatus.inProgress, isNot(contains(OrderStatus.unknown)));
      expect(OrderStatus.received, isNot(contains(OrderStatus.unknown)));
    });
  });

  test('the line this app draws is the line the server draws in isClosed()', () {
    // Arrange
    final source = File('../backend/app/Domain/Order/Enums/OrderStatus.php');
    if (!source.existsSync()) {
      markTestSkipped('backend not checked out beside this one — nothing to compare against');

      return;
    }

    final php = source.readAsStringSync();

    /// `case New = 'new';` → {New: new}, so a case named in a method body can be given its wire.
    final wireOf = <String, String>{
      for (final match in RegExp("case (\\w+) = '([^']+)';").allMatches(php))
        match.group(1)!: match.group(2)!,
    };

    // `isFinal()` and `isClosed()` together name all three: the two finals, plus «تم الاستلام»
    // which `isClosed()` adds by name. Read from those two methods alone — a regex over the
    // whole file would collect every `self::` in the state machine.
    String body(String name) {
      final start = php.indexOf('public function $name(): bool');
      final open = php.indexOf('{', start);

      return php.substring(open, php.indexOf('}', open));
    }

    // Act
    final closed = {
      for (final match in RegExp(r'self::(\w+)').allMatches(body('isFinal') + body('isClosed')))
        ?wireOf[match.group(1)!],
    };

    final finished = OrderStatus.values
        .where((status) => status.isFinished && status != OrderStatus.unknown)
        .map((status) => status.wire)
        .toSet();

    // Assert — named in each direction: one failure is a status this app still treats as work,
    // the other is one it has stopped counting while the server still has moves for it.
    expect(closed, isNotEmpty, reason: 'the regex matched nothing — did the PHP file change shape?');
    expect(
      finished.difference(closed),
      isEmpty,
      reason: 'this app calls statuses finished that the server still considers open',
    );
    expect(
      closed.difference(finished),
      isEmpty,
      reason: 'the server closes statuses this app still counts as «جارية»',
    );
  });
}
