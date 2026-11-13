import 'package:dayaa/features/notifications/models/push_preference.dart';
import 'package:flutter_test/flutter_test.dart';

/// The shape `GET /users/{id}/notification-preferences` publishes.
///
/// Arrange - Act - Assert throughout.
void main() {
  test('a group and its switches are read from the wire', () {
    // Arrange
    final json = <String, dynamic>{
      'type': 'order.status',
      'label': 'حالة طلبية',
      'icon': 'order',
      'switches': [
        {'scope': 'ready', 'label': 'جاهزة', 'push': true},
        {'scope': 'settled', 'label': 'تم التسوية', 'push': false},
      ],
    };

    // Act
    final group = PushPreferenceGroup.fromJson(json);

    // Assert
    expect(group.type, 'order.status');
    expect(group.switches, hasLength(2));
    expect(group.switches.last.push, isFalse);
    expect(group.isSingle, isFalse);
  });

  test('a type that is one switch is drawn as one row', () {
    // Arrange
    const group = PushPreferenceGroup(
      type: 'order.shortage',
      label: 'نواقص طلبية',
      icon: 'warning',
      switches: [PushSwitch(scope: '', label: 'نواقص طلبية', push: true)],
    );

    // Assert
    expect(group.isSingle, isTrue);
  });
}
