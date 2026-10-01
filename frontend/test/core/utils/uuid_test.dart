import 'dart:math';

import 'package:dayaa/core/utils/uuid.dart';
import 'package:flutter_test/flutter_test.dart';

/// مفتاحُ الطلب الواحد — UUID من الإصدار الرابع، يولَّد على الجهاز بلا حزمة.
///
/// Arrange - Act - Assert throughout.
void main() {
  final v4 = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');

  test('يخرج بشكل UUID v4 كما يقرؤه الخادم', () {
    // Arrange
    final random = Random(7);

    // Act
    final token = uuidV4(random);

    // Assert
    expect(token, matches(v4));
  });

  test('مفتاحان متتاليان لا يتطابقان', () {
    // Arrange
    final tokens = <String>{};

    // Act
    for (var i = 0; i < 200; i++) {
      tokens.add(uuidV4());
    }

    // Assert
    expect(tokens, hasLength(200));
    expect(tokens.every(v4.hasMatch), isTrue);
  });
}
