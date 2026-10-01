import 'package:dayaa/core/error/failure.dart';
import 'package:flutter_test/flutter_test.dart';

/// أخطاءُ الحقول تحت حقولها، والباقي في التوست — RULES §5.
///
/// Arrange - Act - Assert throughout.
void main() {
  const refused = Failure.server(
    message: 'المبلغ يتجاوز الرصيد',
    statusCode: 422,
    fieldErrors: {
      'amount': ['المبلغ يتجاوز الرصيد'],
      'from_account_id': ['الحساب معطَّل'],
    },
  );

  test('رسالة الحقل تُقرأ باسمه', () {
    // Act
    final amount = refused.fieldError('amount');
    final missing = refused.fieldError('notes');

    // Assert
    expect(amount, 'المبلغ يتجاوز الرصيد');
    expect(missing, isNull);
  });

  test('رفضٌ كل حقوله لها مربّع لا يحتاج توستاً', () {
    // Act
    final beyond = refused.hasErrorsBeyond({'amount', 'from_account_id'});

    // Assert
    expect(beyond, isFalse);
  });

  test('حقلٌ لا مربّع له يُقال في التوست', () {
    // Act
    final beyond = refused.hasErrorsBeyond({'amount'});

    // Assert
    expect(beyond, isTrue);
  });

  test('رفضٌ بلا حقول، أو انقطاع، يُقال كله في التوست', () {
    // Arrange
    const domain = Failure.server(message: 'لا يُعطَّل حساب فيه مال', statusCode: 422);
    const offline = Failure.network(message: FailureMessages.noConnection);

    // Act
    final domainBeyond = domain.hasErrorsBeyond({'amount'});
    final offlineBeyond = offline.hasErrorsBeyond({'amount'});
    final offlineField = offline.fieldError('amount');

    // Assert
    expect(domainBeyond, isTrue);
    expect(offlineBeyond, isTrue);
    expect(offlineField, isNull);
  });
}
