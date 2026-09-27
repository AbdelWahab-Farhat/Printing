import 'package:dayaa/core/utils/arabic_search.dart';
import 'package:flutter_test/flutter_test.dart';

/// Arabic compared the way somebody types it, not the way it is stored.
///
/// Arrange - Act - Assert throughout.
void main() {
  test('a word is found anywhere in the label, not only at its start', () {
    // Act & Assert
    expect('سعر البيع'.matchesSearch('سعر'), isTrue);
    expect('سعر البيع'.matchesSearch('بيع'), isTrue);
    expect('سعر البيع'.matchesSearch('تكلفة'), isFalse);
  });

  test('every typed word has to be there, in any order', () {
    // Act & Assert
    expect('سعر البيع'.matchesSearch('بيع سعر'), isTrue);
    expect('سعر البيع'.matchesSearch('سعر الوحدة'), isFalse);
  });

  test('hamza seats, ta marbuta and alef maqsura are folded on both sides', () {
    // Act & Assert
    expect('أسعار الطباعة'.matchesSearch('اسعار'), isTrue);
    expect('إجمالي التكلفة'.matchesSearch('اجمالي التكلفه'), isTrue);
    expect('المستوى'.matchesSearch('المستوي'), isTrue);
    expect('اسعار'.matchesSearch('أسعار'), isTrue);
  });

  test('vowel marks and the tatweel are never part of the match', () {
    // Act & Assert
    expect('المسدَّد لدى الناقل'.matchesSearch('المسدد'), isTrue);
    expect('سعـــر'.matchesSearch('سعر'), isTrue);
  });

  test('an empty search matches everything', () {
    // Act & Assert
    expect('سعر البيع'.matchesSearch(''), isTrue);
    expect('سعر البيع'.matchesSearch('   '), isTrue);
  });
}
