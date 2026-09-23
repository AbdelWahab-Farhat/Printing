import 'package:dayaa/core/utils/arabic_counts.dart';
import 'package:flutter_test/flutter_test.dart';

/// العددُ والمعدود — «يومين» لا «2 يوم»، و«11 يوماً» لا «11 أيام».
///
/// Arrange - Act - Assert throughout, matching the backend's standard.
void main() {
  group('arabicCount', () {
    String days(int n) => arabicCount(n, one: 'يوم', two: 'يومين', few: 'أيام', many: 'يوماً');

    test('one and two are words, not numbers', () {
      // Arrange
      const one = 1;
      const two = 2;

      // Act
      final single = days(one);
      final pair = days(two);

      // Assert
      expect(single, 'يوم');
      expect(pair, 'يومين');
    });

    test('three to ten take the plural', () {
      expect(days(3), '3 أيام');
      expect(days(10), '10 أيام');
    });

    test('eleven and above take the singular', () {
      expect(days(11), '11 يوماً');
      expect(days(99), '99 يوماً');
      expect(days(100), '100 يوماً');
    });

    test('past a hundred the last two digits decide', () {
      expect(days(103), '103 أيام');
      expect(days(111), '111 يوماً');
    });
  });

  group('sinceDays', () {
    test('the day it became due reads as today', () {
      // Arrange
      const overdue = 0;

      // Act
      final phrase = sinceDays(overdue);

      // Assert
      expect(phrase, 'منذ اليوم');
    });

    test('later days are counted', () {
      expect(sinceDays(1), 'منذ يوم');
      expect(sinceDays(2), 'منذ يومين');
      expect(sinceDays(3), 'منذ 3 أيام');
      expect(sinceDays(12), 'منذ 12 يوماً');
    });
  });

  group('ordersCount', () {
    test('counts orders the way they are said', () {
      expect(ordersCount(1), 'طلبية واحدة');
      expect(ordersCount(2), 'طلبيتين');
      expect(ordersCount(3), '3 طلبيات');
      expect(ordersCount(14), '14 طلبية');
    });
  });
}
