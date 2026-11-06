import 'package:dayaa/features/employee_wallet/models/employee_wallet_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// ما يقرؤه التطبيق من السلك. Docs/employees/EMPLOYEE-WALLET-DESIGN.md §٧.
///
/// **سطران من موردين**: من يدير المحافظ يرى الحساب واسم من سجّل، وصاحبُ المحفظة لا يراهما — فالنموذج
/// واحد، وما لا يرسله الخادم يبقى فارغاً ولا يُخمَّن.
///
/// Arrange - Act - Assert throughout.
void main() {
  group('سطر المحفظة', () {
    test('يقرأ سطر من يدير المحافظ كاملاً', () {
      // Arrange
      final json = <String, dynamic>{
        'id': 9,
        'user_id': 4,
        'user': {'id': 4, 'code': 'E4', 'name': 'محمد عز الدين', 'phone': '0944909851'},
        'type': 'credit',
        'type_label': 'مستحق',
        'direction': 'in',
        'amount': '2500.00',
        'method': null,
        'method_label': null,
        'treasury_account': null,
        'category': {'id': 3, 'name': 'رواتب'},
        'notes': 'راتب أكتوبر',
        'occurred_at': '2026-11-01T09:15:00+02:00',
        'is_reversed': true,
        'can_reverse': false,
        'reversal': {'id': 12, 'reason': 'كُتبت لموظفٍ آخر'},
        'recorder': {'id': 1, 'name': 'سارة'},
      };

      // Act
      final entry = EmployeeWalletEntry.fromJson(json);

      // Assert
      expect(entry.userId, 4);
      expect(entry.employeeName, 'محمد عز الدين');
      expect(entry.isIn, isTrue);
      expect(entry.categoryName, 'رواتب');
      expect(entry.reversalReason, 'كُتبت لموظفٍ آخر');
      expect(entry.recorderName, 'سارة');
      expect(entry.isReversed, isTrue);
      expect(entry.occurredAt, DateTime.parse('2026-11-01T07:15:00Z').toLocal());
    });

    test('يقرأ سطر صاحب المحفظة، وما لا يصله يبقى فارغاً', () {
      // Arrange — MyWalletEntryResource: لا حساب، ولا من سجّل، ولا `can_reverse`.
      final json = <String, dynamic>{
        'id': 9,
        'type': 'withdrawal',
        'type_label': 'سحب',
        'direction': 'out',
        'amount': '1450.00',
        'method_label': 'كاش',
        'category_name': null,
        'notes': null,
        'is_reversed': false,
        'occurred_at': '2026-11-06T10:42:00+02:00',
      };

      // Act
      final entry = EmployeeWalletEntry.fromJson(json);

      // Assert
      expect(entry.isIn, isFalse);
      expect(entry.methodLabel, 'كاش');
      expect(entry.userId, isNull);
      expect(entry.recorderName, isNull);
      expect(entry.canReverse, isFalse);
    });

    test('يأخذ اسم التصنيف من مورد صاحب المحفظة أيضاً', () {
      // Arrange
      final json = <String, dynamic>{
        'id': 9,
        'type': 'credit',
        'type_label': 'مستحق',
        'direction': 'in',
        'amount': '2500.00',
        'category_name': 'رواتب',
      };

      // Act
      final entry = EmployeeWalletEntry.fromJson(json);

      // Assert
      expect(entry.categoryName, 'رواتب');
    });

    test('العكس يتجه حيث يقول الخادم', () {
      // Arrange
      final json = <String, dynamic>{
        'id': 7,
        'type': 'reversal',
        'type_label': 'عكس حركة',
        'direction': 'in',
        'amount': '350.00',
      };

      // Act
      final entry = EmployeeWalletEntry.fromJson(json);

      // Assert
      expect(entry.isReversal, isTrue);
      expect(entry.isIn, isTrue);
    });

    test('السطر بعد عكسه يُشطب، ولا يُعكس ثانية', () {
      // Arrange
      const entry = EmployeeWalletEntry(
        id: 5,
        type: 'withdrawal',
        typeLabel: 'سحب',
        direction: 'out',
        amount: '350.00',
        canReverse: true,
      );

      // Act
      final reversed = entry.markedReversed('كُتبت لموظفٍ آخر');

      // Assert
      expect(reversed.isReversed, isTrue);
      expect(reversed.canReverse, isFalse);
      expect(reversed.reversalReason, 'كُتبت لموظفٍ آخر');
    });
  });

  group('المحفظة', () {
    test('الراتب غائب لمن لا يملك رؤيته، و`can_move` يقوله الخادم', () {
      // Arrange
      final json = <String, dynamic>{
        'user_id': 4,
        'balance': '1500.00',
        'can_move': false,
        'recent': <Object>[],
      };

      // Act
      final wallet = EmployeeWallet.fromJson(json);

      // Assert
      expect(wallet.balance, '1500.00');
      expect(wallet.canMove, isFalse);
      expect(wallet.salary, isNull);
    });

    test('يقترح الراتب كما أرسله الخادم', () {
      // Arrange
      final json = <String, dynamic>{'balance': '0.00', 'can_move': true, 'salary': '2500.00'};

      // Act
      final wallet = EmployeeWallet.fromJson(json);

      // Assert
      expect(wallet.salary, '2500.00');
      expect(wallet.canMove, isTrue);
    });

    test('«محفظتي» لا تحرّك شيئاً: المفتاح غائب أصلاً', () {
      // Arrange
      final json = <String, dynamic>{'balance': '1500.00', 'recent': <Object>[]};

      // Act
      final wallet = EmployeeWallet.fromJson(json);

      // Assert
      expect(wallet.canMove, isFalse);
    });

    test('الكتابة تعود بالسطر والرصيد بعده', () {
      // Arrange
      final json = <String, dynamic>{
        'entry': {
          'id': 3,
          'user_id': 4,
          'type': 'deposit',
          'type_label': 'إيداع',
          'direction': 'in',
          'amount': '300.00',
        },
        'balance': '1800.00',
      };

      // Act
      final write = EmployeeWalletWrite.fromJson(json);

      // Assert
      expect(write.entry.id, 3);
      expect(write.balance, '1800.00');
    });
  });

  group('فلتر السجل', () {
    EmployeeWalletEntry ofType(String type) => EmployeeWalletEntry(
      id: 1,
      type: type,
      typeLabel: type,
      direction: 'in',
      amount: '1.00',
    );

    test('«تعديل» يجمع الزيادة والنقص، لأنهما رقاقة واحدة', () {
      // Arrange
      const filter = EmployeeWalletEntryFilter.adjustment;

      // Act
      final up = filter.covers(ofType('adjustment_credit'));
      final down = filter.covers(ofType('adjustment_debit'));
      final other = filter.covers(ofType('deposit'));

      // Assert
      expect(up, isTrue);
      expect(down, isTrue);
      expect(other, isFalse);
    });

    test('«الكل» يغطي كل شيء، والبقية نوعها وحده', () {
      // Arrange
      final reversal = ofType('reversal');

      // Act
      final inAll = EmployeeWalletEntryFilter.all.covers(reversal);
      final inWithdrawals = EmployeeWalletEntryFilter.withdrawal.covers(reversal);

      // Assert
      expect(inAll, isTrue);
      expect(inWithdrawals, isFalse);
    });
  });

  group('طريقة الدفع', () {
    test('الحوالة وحدها تتطلب واصلاً', () {
      // Arrange
      const methods = EmployeeWalletMethod.values;

      // Act
      final needing = [
        for (final method in methods)
          if (method.requiresReceipt) method,
      ];

      // Assert
      expect(needing, [EmployeeWalletMethod.bankTransfer]);
      expect(methods.map((method) => method.wire), [
        'cash',
        'bank_transfer',
        'bank_card',
        'libyana',
      ]);
    });
  });
}
