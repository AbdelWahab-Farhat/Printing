import 'package:dayaa/features/home/models/home_summary.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reading the home screen's numbers off the wire.
///
/// **The one thing worth pinning here is the key names.** These numbers were a fixed snapshot in
/// the app for months, so nothing ever proved the model could parse a real reply — and a wrong
/// key does not crash, it quietly reads as zero on a board whose whole point is the numbers.
///
/// The payload below is what `GET /home/summary` returns, copied from `HomeSummaryResource`.
///
/// Arrange - Act - Assert throughout.
void main() {
  test('the summary is read from the reply the server actually sends', () {
    // Arrange
    final payload = <String, dynamic>{
      'total_orders': 26,
      'customers_count': 9,
      'daily_orders': 2,
      'monthly_orders': 11,
      'statuses': [
        {'status': 'new', 'label': 'جديدة', 'count': 4},
        {'status': 'printing', 'label': 'قيد الطباعة', 'count': 7},
        {'status': 'resend', 'label': 'إعادة إرسال', 'count': 0},
      ],
    };

    // Act
    final summary = HomeSummary.fromJson(payload);

    // Assert
    expect(summary.totalOrders, 26);
    expect(summary.customersCount, 9);
    expect(summary.dailyOrders, 2);
    expect(summary.monthlyOrders, 11);

    expect(summary.statuses, hasLength(3));
    expect(summary.statuses.first.status, 'new');
    // The Arabic comes down the wire: this app holds no translation table, so a status added on
    // the server appears on the board with the right word and no release.
    expect(summary.statuses.first.label, 'جديدة');
    expect(summary.statuses.first.count, 4);
  });

  test('a status with nothing in it is a card, not an absence', () {
    // Arrange — the server sends every status including the zeros, on purpose.
    final payload = <String, dynamic>{
      'total_orders': 0,
      'customers_count': 0,
      'daily_orders': 0,
      'monthly_orders': 0,
      'statuses': [
        {'status': 'shortage', 'label': 'نواقص', 'count': 0},
      ],
    };

    // Act
    final summary = HomeSummary.fromJson(payload);

    // Assert — zero is an answer; a missing card would be "we did not ask".
    expect(summary.statuses.single.count, 0);
    expect(summary.isEmpty, isTrue);
  });
}
