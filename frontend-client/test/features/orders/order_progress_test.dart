import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:dayaa_client/features/orders/models/order_progress.dart';
import 'package:flutter_test/flutter_test.dart';

/// أين تقف الطلبية على شريط التقدّم في بطاقة الرئيسية.
///
/// Arrange - Act - Assert throughout.
void main() {
  test('the five steps run from review to delivery, in that order', () {
    // Arrange
    const steps = OrderStep.values;

    // Act
    final labels = steps.map((step) => step.label).toList();

    // Assert
    expect(labels, ['المراجعة', 'التجهيز', 'الإنتاج', 'جاهزة', 'التوصيل']);
  });

  test('every stage that is still moving has its step', () {
    // Arrange
    const expected = {
      OrderStage.underReview: OrderStep.review,
      OrderStage.preparing: OrderStep.preparing,
      OrderStage.producing: OrderStep.producing,
      OrderStage.ready: OrderStep.ready,
      OrderStage.onTheWay: OrderStep.delivering,
    };

    // Act
    final actual = {for (final stage in expected.keys) stage: stage.step};

    // Assert
    expect(actual, expected);
  });

  /// التصميم ليس خطوةً سادسة: الطلبية السادة لا تمرّ به، وشريطٌ فيه خطوةٌ تُقفز يُقرأ كأن شيئاً
  /// فات صاحبه.
  test('design is part of getting the order ready, not a step of its own', () {
    // Arrange
    const stage = OrderStage.designing;

    // Act
    final step = stage.step;

    // Assert
    expect(step, OrderStep.preparing);
  });

  test('an order that is over, or that this build cannot name, stands on no step', () {
    // Arrange
    const stages = [
      OrderStage.delivered,
      OrderStage.returned,
      OrderStage.cancelled,
      OrderStage.rejected,
      OrderStage.unknown,
    ];

    // Act
    final steps = stages.map((stage) => stage.step).toList();

    // Assert
    expect(steps, everyElement(isNull));
  });

  // ── بطاقة الحالة في الطلبية المفتوحة ─────────────────────────────────────────

  group('where each of the five steps stands', () {
    test('an order under review stands on the first step, with four ahead', () {
      // Arrange
      const stage = OrderStage.underReview;

      // Act
      final marks = stage.marks;

      // Assert
      expect(marks, [
        StepMark.current,
        StepMark.ahead,
        StepMark.ahead,
        StepMark.ahead,
        StepMark.ahead,
      ]);
    });

    test('an order being made has two steps behind it and two ahead', () {
      // Arrange
      const stage = OrderStage.producing;

      // Act
      final marks = stage.marks;

      // Assert
      expect(marks, [
        StepMark.done,
        StepMark.done,
        StepMark.current,
        StepMark.ahead,
        StepMark.ahead,
      ]);
    });

    /// «تم الاستلام» وحدها من النهايات لها طريق: مشته كلّه.
    test('a delivered order has walked every step', () {
      // Arrange
      const stage = OrderStage.delivered;

      // Act
      final marks = stage.marks;

      // Assert
      expect(marks, List.filled(OrderStep.values.length, StepMark.done));
    });

    test('an order that came back, was written off, refused or unknown has no road', () {
      // Arrange
      const stages = [
        OrderStage.returned,
        OrderStage.cancelled,
        OrderStage.rejected,
        OrderStage.unknown,
      ];

      // Act
      final marks = stages.map((stage) => stage.marks).toList();

      // Assert
      expect(marks, everyElement(isNull));
    });
  });

  group('when each step was reached', () {
    final year = DateTime.now().year;

    OrderTimelineEntry entry(String stage, DateTime? at) =>
        OrderTimelineEntry(stage: stage, stageLabel: stage, reachedAt: at);

    test('each step keeps the moment the order first reached it', () {
      // Arrange — «قيد التصميم» بعد «قيد التجهيز» يقع على الخطوة نفسها.
      final timeline = [
        entry('under_review', DateTime(year, 9, 25, 14, 51)),
        entry('preparing', DateTime(year, 9, 26, 10)),
        entry('designing', DateTime(year, 9, 27, 9)),
        entry('producing', DateTime(year, 9, 28, 11)),
      ];

      // Act
      final reached = reachedSteps(timeline);

      // Assert
      expect(reached, {
        OrderStep.review: DateTime(year, 9, 25, 14, 51),
        OrderStep.preparing: DateTime(year, 9, 26, 10),
        OrderStep.producing: DateTime(year, 9, 28, 11),
      });
    });

    /// طلبيةٌ استُلمت من المكتب لم تمرّ بـ«جاري التوصيل»: الاستلام يؤرّخ خطوتها الأخيرة.
    test('a collected order dates its last step by the handover', () {
      // Arrange
      final timeline = [
        entry('ready', DateTime(year, 9, 30, 12)),
        entry('delivered', DateTime(year, 10, 1, 16)),
      ];

      // Act
      final reached = reachedSteps(timeline);

      // Assert
      expect(reached[OrderStep.delivering], DateTime(year, 10, 1, 16));
    });

    test('a stage with no moment, or one this build cannot name, dates nothing', () {
      // Arrange
      final timeline = [
        entry('under_review', null),
        entry('teleported', DateTime(year, 9, 25)),
        entry('cancelled', DateTime(year, 9, 26)),
      ];

      // Act
      final reached = reachedSteps(timeline);

      // Assert
      expect(reached, isEmpty);
    });
  });
}
