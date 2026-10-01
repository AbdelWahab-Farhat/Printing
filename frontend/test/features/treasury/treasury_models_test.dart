import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/models/vendor_payment.dart';
import 'package:flutter_test/flutter_test.dart';

/// ما ترسله نقاط الخزينة، مقروءاً بتسامح: مفتاحٌ غائب لا يُسقط القائمة.
///
/// Arrange - Act - Assert throughout.
void main() {
  group('الحساب', () {
    test('نوعٌ لا يعرفه هذا الإصدار يُقرأ «غير معروف» ويبقى الحساب مقروءاً', () {
      // Arrange
      final json = {
        'id': 12,
        'name': 'بطاقة مسبقة الدفع',
        'kind': 'prepaid_card',
        'kind_label': 'بطاقة مسبقة',
        'balance': '40.00',
      };

      // Act
      final account = TreasuryAccount.fromJson(json);

      // Assert
      expect(account.kind, AccountKind.unknown);
      expect(account.kindLabel, 'بطاقة مسبقة');
      expect(account.name, 'بطاقة مسبقة الدفع');
      expect(account.balance, '40.00');
    });

    test('نسخةٌ معدَّلة تغيّر ما طُلب وتُبقي الباقي', () {
      // Arrange
      final account = TreasuryAccount.fromJson({
        'id': 3,
        'name': 'مصرف علي',
        'kind': 'bank',
        'kind_label': 'مصرف',
        'is_default': false,
        'balance': '300.00',
        'pickup_city_id': 40,
      });

      // Act
      final made = account.copyWith(isDefault: true, clearPickupCity: true);

      // Assert
      expect(made.isDefault, isTrue);
      expect(made.pickupCityId, isNull);
      expect(made.name, 'مصرف علي');
      expect(made.balance, '300.00');
    });
  });

  group('سطر السجل', () {
    test('يحمل ما يقوله الخادم عن عكسه', () {
      // Arrange
      final json = {
        'id': 9,
        'direction': 'in',
        'kind': 'deposit',
        'kind_label': 'إيداع',
        'signed_amount': '50.00',
        'operation_id': 4,
        'is_reversible': true,
        'is_reversed': false,
        'reverses_movement_id': null,
      };

      // Act
      final movement = TreasuryMovement.fromJson(json);

      // Assert
      expect(movement.isReversible, isTrue);
      expect(movement.isReversed, isFalse);
      expect(movement.reversesMovementId, isNull);
    });

    test('خادمٌ لا يرسل `is_reversible` لا يُعرض فيه عكس', () {
      // Arrange
      final json = {
        'id': 9,
        'direction': 'out',
        'kind': 'withdrawal',
        'kind_label': 'سحب',
        'signed_amount': '-20.00',
        'operation_id': 4,
      };

      // Act
      final movement = TreasuryMovement.fromJson(json);

      // Assert
      expect(movement.isReversible, isFalse);
      expect(movement.isReversed, isFalse);
    });

    test('العكس يعلّم الأصل ويغلق بابه', () {
      // Arrange
      final movement = TreasuryMovement.fromJson({
        'id': 9,
        'direction': 'in',
        'kind': 'deposit',
        'kind_label': 'إيداع',
        'signed_amount': '50.00',
        'is_reversible': true,
      });

      // Act
      final reversed = movement.markedReversed();

      // Assert
      expect(reversed.isReversed, isTrue);
      expect(reversed.isReversible, isFalse);
      expect(reversed.id, 9);
      expect(reversed.signedAmount, '50.00');
    });
  });

  group('خيارات المنتقي', () {
    test('اسم «تلقائي» من `suggested_name` ولو كان حساباً ليس في القائمة', () {
      // Arrange — طردٌ للنورس في الطريق: الكاش اليدوي ينزل في حساب النورس، وليس من الخيارات.
      final json = {
        'accounts': [
          {'id': 1, 'name': 'الخزنة الرئيسية', 'kind_label': 'خزنة', 'is_default': true},
        ],
        'suggested_id': 4,
        'suggested_name': 'النورس',
      };

      // Act
      final options = AccountOptions.fromJson(json);

      // Assert
      expect(options.suggestedId, 4);
      expect(options.suggestedName, 'النورس');
    });

    test('خادمٌ أقدم بلا `suggested_name` يُسمّى من القائمة', () {
      // Arrange
      final json = {
        'accounts': [
          {'id': 2, 'name': 'المصرف', 'kind_label': 'مصرف', 'is_default': true},
          {'id': 7, 'name': 'مصرف علي', 'kind_label': 'مصرف', 'is_default': false},
        ],
        'suggested_id': 7,
      };

      // Act
      final options = AccountOptions.fromJson(json);

      // Assert
      expect(options.suggestedName, 'مصرف علي');
    });
  });

  group('دفعة المورد', () {
    test('عكسٌ يُقرأ عكساً، والأصل يُعلَّم معكوساً', () {
      // Arrange
      final payment = VendorPayment.fromJson({
        'id': 5,
        'type': 'payment',
        'type_label': 'دفعة',
        'amount': '1080.00',
        'is_reversible': true,
      });
      final reversal = VendorPayment.fromJson({
        'id': 6,
        'type': 'reversal',
        'type_label': 'عكس دفعة',
        'amount': '1080.00',
        'reverses_payment_id': 5,
      });

      // Act
      final marked = payment.markedReversed();

      // Assert
      expect(reversal.isReversal, isTrue);
      expect(reversal.reversesPaymentId, 5);
      expect(marked.isReversed, isTrue);
      expect(marked.isReversible, isFalse);
    });
  });
}
