import 'package:dayaa/core/utils/dates.dart';
import 'package:flutter_test/flutter_test.dart';

/// كيف يُكتب التاريخ في هذا التطبيق.
///
/// One formatter for every screen, so «14 أغسطس 2026» reads the same on a customer's card, in a
/// history and on a stock ledger. What it must never produce is the wire's `2026-08-14` — that
/// shape belongs to the code that builds a query string, and mixing the two is how a display
/// helper ends up in a request.
///
/// Arrange - Act - Assert throughout.
void main() {
  group('the day', () {
    test('is said the way somebody would say it', () {
      // Arrange
      final at = DateTime(2026, 8, 14, 14, 30);

      // Act - Assert — Arabic month, Latin digits: the same digits every other number in this
      // app is drawn with.
      expect(at.dayLabel, '14 أغسطس 2026');
    });

    test('names the months Libya uses', () {
      // Arrange - Act - Assert — not «كانون الثاني» and the Levantine set.
      expect(DateTime(2026).dayLabel, '1 يناير 2026');
      expect(DateTime(2026, 12, 31).dayLabel, '31 ديسمبر 2026');
    });

    test('drops the year when it is this one', () {
      // Arrange — a column of rows from this month repeating «2026» says nothing twenty times.
      final now = DateTime.now();
      final thisYear = DateTime(now.year, 3, 5);

      // Act - Assert
      expect(thisYear.shortDayLabel, '5 مارس');
      expect(DateTime(2019, 3, 5).shortDayLabel, '5 مارس 2019');
    });
  });

  group('the time', () {
    test('is twelve-hour, as the shop says it', () {
      // Arrange - Act - Assert
      expect(DateTime(2026, 8, 14, 14, 30).timeLabel, '2:30 م');
      expect(DateTime(2026, 8, 14, 9, 5).timeLabel, '9:05 ص');
    });

    test('midnight and noon are the two a naive clock gets wrong', () {
      // Arrange - Act - Assert — «0:00» is a clock nobody in the shop owns.
      expect(DateTime(2026, 8, 14, 0, 30).timeLabel, '12:30 ص');
      expect(DateTime(2026, 8, 14, 12, 30).timeLabel, '12:30 م');
    });
  });

  group('the stamp', () {
    test('carries the time when the column held one', () {
      // Arrange - Act - Assert
      expect(DateTime(2026, 8, 14, 14, 30).stampLabel, '14 أغسطس 2026 · 2:30 م');
    });

    test('says the date alone when the clock says nothing', () {
      // Arrange — an expected delivery, a period boundary: stored as midnight exactly, and
      // «12:00 ص» beside it would invent a precision the column never had.
      final dateOnly = DateTime(2026, 8, 18);

      // Act - Assert
      expect(dateOnly.stampLabel, '18 أغسطس 2026');
    });
  });

  group('the relative day', () {
    test('calls today today and yesterday yesterday', () {
      // Arrange — on the screen somebody opens right after making a change, the top heading is
      // the one they are looking for.
      final now = DateTime.now();

      // Act - Assert
      expect(now.relativeDayLabel, 'اليوم');
      expect(now.subtract(const Duration(days: 1)).relativeDayLabel, 'أمس');
    });

    test('anything older is named by its date', () {
      // Arrange - Act - Assert — «منذ ٣ أيام» is arithmetic the reader has to undo.
      expect(DateTime(2026).relativeDayLabel, '1 يناير 2026');
    });

    test('is decided by the day, not by the twenty-four hours before now', () {
      // Arrange — 11pm yesterday is «أمس» at 1am today, even though it is two hours ago.
      final now = DateTime.now();
      final lastNight = DateTime(now.year, now.month, now.day).subtract(const Duration(hours: 1));

      // Act - Assert
      expect(lastNight.relativeDayLabel, 'أمس');
    });
  });
}
