import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:flutter_test/flutter_test.dart';

/// The seam between Laravel's `snake_case` and this app, for the two fields the employee screen
/// was built around — tested against the exact body `UserResource` sends.
///
/// Arrange - Act - Assert throughout.
void main() {
  Map<String, dynamic> body(Map<String, dynamic> overrides) => <String, dynamic>{
    'id': 4,
    'name': 'محمد عز الدين',
    'phone': '0944909851',
    'email': 'mohamed@printing.ly',
    'employee_code': 'E4',
    ...overrides,
  };

  test('parses the wage as the decimal string the server sent', () {
    // Arrange
    final json = body({'is_active': true, 'salary': '2500.00'});

    // Act
    final user = AuthUser.fromJson(json);

    // Assert — a String, never a double: money round-tripped through a float is how 2500.10
    // becomes 2500.099999 on a payslip.
    expect(user.salary, '2500.00');
    expect(user.salary, isA<String>());
  });

  test('a wage nobody has agreed is null, which is not a wage of nothing', () {
    // Arrange — the server sends the key with an explicit null for a reader who may see wages.
    final json = body({'is_active': true, 'salary': null});

    // Act
    final user = AuthUser.fromJson(json);

    // Assert
    expect(user.salary, isNull);
  });

  test('a reader who may not see wages gets no key at all, and reads the same as null', () {
    // Arrange — the two are told apart by permission on the screen, not by the model: one hides
    // the section, the other prints «لم يُحدَّد» inside it.
    final json = body({'is_active': true});

    // Act
    final user = AuthUser.fromJson(json);

    // Assert
    expect(user.salary, isNull);
  });

  test('a stopped account comes back stopped', () {
    // Arrange
    final json = body({'is_active': false});

    // Act
    final user = AuthUser.fromJson(json);

    // Assert
    expect(user.isActive, isFalse);
  });

  test('a response that predates the column reads as an account in use', () {
    // Arrange — `is_active` missing entirely, which is every response older than this feature.
    final json = body({});

    // Act
    final user = AuthUser.fromJson(json);

    // Assert — defaulting to stopped would draw «موقوف» on every employee against an older
    // server, which is the one direction of this guess that does harm.
    expect(user.isActive, isTrue);
  });
}
