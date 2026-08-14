import 'dart:io';

import 'package:dayaa/features/purchase_orders/models/purchase_order.dart';
import 'package:flutter_test/flutter_test.dart';

/// The three queues a supplier's screen asks for, and the lines between them.
///
/// «الجارية», «المكتملة» and «الملغاة» are the only groups this app draws over the purchase-order
/// statuses, and all three fall out of one predicate — [PurchaseOrderStatus.isFinal] — rather
/// than out of three hand-written lists that could disagree with each other and with the counts
/// printed beside them. These tests pin that, the same way `order_status_groups_test.dart` pins
/// the customer screen's pair. See VENDOR-PURCHASE-ORDERS-SECTION.md §١.
///
/// The last one reads `PurchaseOrderStatus.php` and checks the line is the server's own line,
/// and **skips** when the backend is not checked out beside this repo.
///
/// Arrange - Act - Assert throughout.
void main() {
  group('the three groups', () {
    test('«الجارية» is every status that is not over, and nothing else', () {
      // Arrange — the two the business calls over.
      const over = {PurchaseOrderStatus.completed, PurchaseOrderStatus.cancelled};

      // Act
      final inProgress = PurchaseOrderStatus.inProgress.toSet();

      // Assert
      expect(
        inProgress,
        PurchaseOrderStatus.values.toSet().difference({...over, PurchaseOrderStatus.unknown}),
        reason: 'a status that is neither over nor in progress is a queue nobody can reach',
      );
    });

    test('a draft nobody has sent is still in progress', () {
      // Act
      final inProgress = PurchaseOrderStatus.inProgress;

      // Assert — «جديد» is stock we decided to buy and have not bought. A purchase order
      // forgotten in that state for a month is the whole reason this queue is worth opening.
      expect(inProgress, contains(PurchaseOrderStatus.fresh));
    });

    test('«المكتملة» is completed alone', () {
      // Act
      final fulfilled = PurchaseOrderStatus.fulfilled;

      // Assert — the only status reached by goods actually turning up, never by a declaration.
      expect(fulfilled, [PurchaseOrderStatus.completed]);
    });

    test('«الملغاة» is every cancellation, and it is its own box', () {
      // Act
      final cancellations = PurchaseOrderStatus.cancellations;

      // Assert
      expect(cancellations, [PurchaseOrderStatus.cancelled]);
    });

    test('the three groups do not overlap, and together they are every status', () {
      // Arrange
      final groups = [
        ...PurchaseOrderStatus.inProgress,
        ...PurchaseOrderStatus.fulfilled,
        ...PurchaseOrderStatus.cancellations,
      ];

      // Act
      final unique = groups.toSet();

      // Assert — a status in two boxes would be counted twice by the numbers on the screen; a
      // status in none would be reachable only through «الكل».
      expect(unique.length, groups.length, reason: 'a status appears in two groups');
      expect(unique, PurchaseOrderStatus.choices.toSet());
    });

    test('«غير معروفة» is in none of them', () {
      // Act & Assert — this app's own invention for a status the server added after this build
      // shipped. Sending it as a filter would ask for something that does not exist.
      expect(PurchaseOrderStatus.inProgress, isNot(contains(PurchaseOrderStatus.unknown)));
      expect(PurchaseOrderStatus.fulfilled, isNot(contains(PurchaseOrderStatus.unknown)));
      expect(PurchaseOrderStatus.cancellations, isNot(contains(PurchaseOrderStatus.unknown)));
    });
  });

  group('against the backend', () {
    final source = File('../backend/app/Domain/PurchaseOrder/Enums/PurchaseOrderStatus.php');

    test('«الجارية» is the complement of the server\'s own isFinal()', () {
      // Arrange
      if (!source.existsSync()) {
        markTestSkipped('backend not checked out beside this one — nothing to compare against');

        return;
      }

      final php = source.readAsStringSync();
      final method = php.substring(php.indexOf('public function isFinal(): bool'));
      final finalCases = RegExp(r'self::(\w+)')
          .allMatches(method.substring(0, method.indexOf('}')))
          .map((match) => match.group(1)!.toLowerCase())
          .toSet();

      // Act
      final over = PurchaseOrderStatus.choices
          .where((status) => !PurchaseOrderStatus.inProgress.contains(status))
          .map((status) => status.name.toLowerCase())
          .toSet();

      // Assert — the server calls `completed` and `cancelled` final; anything else in either
      // list means one side moved and the other did not.
      expect(over, finalCases);
    });
  });
}
