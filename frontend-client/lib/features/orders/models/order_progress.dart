import 'package:dayaa_client/features/orders/models/customer_order.dart';

/// الخطوات الخمس على شريط التقدّم في بطاقة الطلبية على الرئيسية.
///
/// **رسمٌ للموضع، لا ترجمةٌ للمرحلة.** كلمة المرحلة تأتي من الخادم وتُرسم في الشارة كما هي
/// (`stageLabel`)، وهذا الملف لا يسمّي مرحلةً ولا يشرحها. كل ما يقرّره أين تقف الطلبية على
/// الشريط، كما يقرّر `stageTone` لونها: كلاهما رسمٌ لما أرسله الخادم، لا نسخةٌ ثانية من
/// مفرداته.
///
/// **خمس خطوات، و«قيد التصميم» داخل «التجهيز».** الطلبية السادة لا تمرّ بالتصميم، وشريطٌ فيه
/// خطوةٌ تُقفز يوحي لصاحبه بأن شيئاً فاته.
enum OrderStep {
  review('المراجعة'),
  preparing('التجهيز'),
  producing('الإنتاج'),
  ready('جاهزة'),
  delivering('التوصيل');

  const OrderStep(this.label);

  final String label;
}

extension OrderStageStep on OrderStage {
  /// الخطوة التي بلغتها الطلبية، أو null لطلبيةٍ انتهت (وصلت أو رجعت أو أُلغيت أو رُفضت) أو
  /// لمرحلةٍ لا يعرفها هذا الإصدار. تلك لا شريط لها.
  ///
  /// **بلا `default`**: مرحلةٌ تُضاف إلى [OrderStage] توقف البناء هنا حتى يُقال أين تقف.
  OrderStep? get step => switch (this) {
    OrderStage.underReview => OrderStep.review,
    OrderStage.preparing || OrderStage.designing => OrderStep.preparing,
    OrderStage.producing => OrderStep.producing,
    OrderStage.ready => OrderStep.ready,
    OrderStage.onTheWay => OrderStep.delivering,
    OrderStage.delivered ||
    OrderStage.returned ||
    OrderStage.cancelled ||
    OrderStage.rejected ||
    OrderStage.unknown => null,
  };

  /// أين تقف كل خطوةٍ من الخمس، بترتيبها — لمسار بطاقة الحالة في الطلبية المفتوحة.
  ///
  /// **«تم الاستلام» وحدها من النهايات لها طريق**: مشته كلّه، فخطواته كلها تمّت. أما المرتجعة
  /// والملغاة والمرفوضة ومرحلةٌ لا يعرفها هذا الإصدار فلا طريق لها (null): خطواتٌ تمّت ثم لا
  /// شيء توحي بطلبيةٍ واقفةٍ في منتصف الطريق، وهي ليست كذلك.
  List<StepMark>? get marks => switch (this) {
    OrderStage.delivered => List.filled(OrderStep.values.length, StepMark.done),
    _ => switch (step) {
      null => null,
      final current => [
        for (final each in OrderStep.values)
          each.index < current.index
              ? StepMark.done
              : each == current
              ? StepMark.current
              : StepMark.ahead,
      ],
    },
  };
}

/// خطوةٌ مضت، أو التي تقف عليها الطلبية، أو خطوةٌ أمامها.
enum StepMark { done, current, ahead }

/// متى بلغت الطلبية كل خطوة: أول لحظةٍ بلغت فيها مرحلةً تقع على تلك الخطوة.
///
/// **يُطوى المسار على الخطوات كما يطويه الخادم على المراحل.** «قيد التصميم» تقع على «التجهيز»
/// فلا تكتب فوقه تاريخها، و«تم الاستلام» تقع على «التوصيل»: طلبيةٌ استُلمت من المكتب لم تمرّ
/// بـ«جاري التوصيل»، فيؤرّخ الاستلامُ خطوتها الأخيرة. وما لا خطوة له — رجوعٌ أو إلغاءٌ أو مرحلةٌ
/// مجهولة — لا يؤرّخ شيئاً.
Map<OrderStep, DateTime> reachedSteps(List<OrderTimelineEntry> timeline) {
  final reached = <OrderStep, DateTime>{};

  for (final entry in timeline) {
    final at = entry.reachedAt;
    final step = switch (entry.orderStage) {
      OrderStage.delivered => OrderStep.delivering,
      final stage => stage.step,
    };

    if (at == null || step == null) continue;

    final earlier = reached[step];
    if (earlier == null || at.isBefore(earlier)) reached[step] = at;
  }

  return reached;
}
