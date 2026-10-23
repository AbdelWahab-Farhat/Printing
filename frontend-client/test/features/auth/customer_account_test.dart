import 'package:dayaa_client/features/auth/models/customer_account.dart';
import 'package:flutter_test/flutter_test.dart';

/// ما يقوله `auth/me` عن الحساب، كما يقرؤه التطبيق.
///
/// Arrange - Act - Assert throughout.
void main() {
  test('reads how many social links the account has', () {
    // Arrange
    final json = {'id': 1, 'name': 'عبدو', 'phone': '0944909852', 'social_links_count': 3};

    // Act
    final account = CustomerAccount.fromJson(json);

    // Assert
    expect(account.socialLinksCount, 3);
  });

  test('a response without the count — login, register — is «not told», not zero', () {
    // Arrange
    final json = {'id': 1, 'name': 'عبدو', 'phone': '0944909852'};

    // Act
    final account = CustomerAccount.fromJson(json);

    // Assert
    expect(account.socialLinksCount, isNull);
  });
}
