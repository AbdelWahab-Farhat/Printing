import 'package:dayaa/core/pagination/changes.dart';
import 'package:flutter_test/flutter_test.dart';

/// The detail half of patching: what a screen hands back on the way out.
///
/// Arrange - Act - Assert throughout.
void main() {
  group('Changes', () {
    test('hands back nothing when the screen only read', () {
      // Arrange
      final changes = Changes<String>();

      // Act — one load, then a pull that answered the same.
      changes
        ..saw('العميل')
        ..saw('العميل');

      // Assert — the list behind has this row already; redrawing it is work for no change.
      expect(changes.result, isNull);
    });

    test('hands back the newest reading when something moved', () {
      // Arrange
      final changes = Changes<String>();

      // Act
      changes
        ..saw('العميل')
        ..saw('العميل المعدل');

      // Assert
      expect(changes.result, 'العميل المعدل');
    });

    test('measures against the first reading, not the one before last', () {
      // Arrange
      final changes = Changes<String>();

      // Act — edited, then edited back.
      changes
        ..saw('العميل')
        ..saw('العميل المعدل')
        ..saw('العميل');

      // Assert — the row on the list behind is already this; nothing to redraw.
      expect(changes.result, isNull);
    });

    test('ignores the states that carry no reading at all', () {
      // Arrange — loading and a failure before anything arrived.
      final changes = Changes<String>();

      // Act
      changes
        ..saw(null)
        ..saw(null);

      // Assert
      expect(changes.result, isNull);
    });

    test('a screen that never loaded hands back nothing', () {
      // Arrange
      final changes = Changes<String>();

      // Assert
      expect(changes.result, isNull);
    });
  });
}
