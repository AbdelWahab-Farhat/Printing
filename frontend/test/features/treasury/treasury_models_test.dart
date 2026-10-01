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

    test('«علينا» يبقى «علينا» بعد نسخةٍ معدَّلة — لا يصير حساباً عادياً بعد الحفظ', () {
      // Arrange
      final account = TreasuryAccount.fromJson({
        'id': 21,
        'name': 'المورد الذهبي',
        'kind': 'payable',
        'kind_label': 'علينا',
        'is_payable': true,
        'vendor_id': 7,
        'balance': '-1000.00',
      });

      // Act
      final made = account.copyWith(isActive: false);

      // Assert
      expect(made.isPayable, isTrue);
      expect(made.vendorId, 7);
      expect(made.isVendorPayable, isTrue);
      expect(made.owed, '1000.00');
    });

    test('ترقيعُ القائمة بعد حفظٍ يُبقي مجموعَ «علينا» كما قاله الخادم', () {
      // Arrange
      final list = TreasuryAccounts.fromJson({
        'accounts': const <Map<String, dynamic>>[],
        'total': '500.00',
        'payables_total': '1200.00',
        'can_view_all': true,
      });

      // Act
      final patched = list.withAccounts(const []);

      // Assert
      expect(patched.payablesTotal, '1200.00');
      expect(patched.total, '500.00');
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

    VendorPayment row(int id, String type, String amount, {int? reverses}) => VendorPayment(
      id: id,
      type: type,
      typeLabel: type,
      amount: amount,
      isReversed: false,
      isReversible: true,
      reversesPaymentId: reverses,
    );

    const summary = PurchaseOrderPayments(
      total: '1000.00',
      paid: '400.00',
      credited: '50.00',
      remaining: '550.00',
      payableUpTo: '550.00',
      predatesTreasury: false,
      payments: [],
    );

    test('الخصمُ يُنقص المتبقي وما يُدفع، ولا يزيد المدفوع — كما يجمع الخادم', () {
      // Arrange
      final credit = row(8, 'credit', '100.00');

      // Act
      final patched = summary.withPayment(credit);

      // Assert
      expect(credit.isCredit, isTrue);
      expect(patched.paid, '400.00');
      expect(patched.credited, '150.00');
      expect(patched.remaining, '450.00');
      expect(patched.payableUpTo, '450.00');
      expect(patched.payments.first.id, 8);
    });

    test('الدفعةُ تزيد المدفوع وتُنقص ما يُدفع، وتُبقي الخصم كما هو', () {
      // Arrange
      final payment = row(9, 'payment', '200.00');

      // Act
      final patched = summary.withPayment(payment);

      // Assert
      expect(patched.paid, '600.00');
      expect(patched.credited, '50.00');
      expect(patched.remaining, '350.00');
      expect(patched.payableUpTo, '350.00');
    });

    test('عكسُ خصمٍ يُعيده إلى المتبقي ولا يمسّ المدفوع', () {
      // Arrange
      final credit = row(8, 'credit', '50.00');
      final reversal = row(10, 'reversal', '50.00', reverses: 8);
      final before = PurchaseOrderPayments(
        total: summary.total,
        paid: summary.paid,
        credited: summary.credited,
        remaining: summary.remaining,
        payableUpTo: summary.payableUpTo,
        predatesTreasury: false,
        payments: [credit],
      );

      // Act
      final patched = before.withReversal(credit, reversal);

      // Assert
      expect(patched.paid, '400.00');
      expect(patched.credited, '0.00');
      expect(patched.remaining, '600.00');
      expect(patched.payableUpTo, '600.00');
    });

    test('دفعةٌ على أمرٍ قبل الخزينة تُنقص ما بقي يُدفع عليه، ولا متبقّي يُخترع', () {
      // Arrange
      const old = PurchaseOrderPayments(
        total: '1000.00',
        paid: '400.00',
        payableUpTo: '600.00',
        predatesTreasury: true,
        payments: [],
      );

      // Act
      final patched = old.withPayment(row(11, 'payment', '100.00'));

      // Assert
      expect(patched.remaining, isNull);
      expect(patched.payableUpTo, '500.00');
      expect(patched.predatesTreasury, isTrue);
    });
  });
}
