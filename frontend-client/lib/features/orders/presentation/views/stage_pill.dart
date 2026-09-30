import 'package:dayaa_client/core/theme/app_tones.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The little rounded pill that says where an order has got to.
///
/// **Shared by the list and the detail screen, because a stage must not change colour when you
/// open it.** Two copies of this mapping is two chances for «جاهزة» to be amber on one screen
/// and green on the next — which is the kind of difference nobody reports and everybody
/// notices.

/// The fill and ink of a stage pill.
///
/// **Total over [OrderStage], with no `default`.** A stage added to the API after this build
/// shipped decodes to [OrderStage.unknown] and lands on the neutral fill — it still draws, with
/// the server's own Arabic in it. The alternative, a `default` that guesses, is how «ملغاة»
/// ends up wearing the same orange as «بانتظار المراجعة».
({Color background, Color foreground}) stageTone(ColorScheme scheme, OrderStage stage) {
  return switch (stage) {
    // Something is waiting on us, or on you.
    OrderStage.underReview ||
    OrderStage.designing => (
      background: scheme.attentionContainer,
      foreground: scheme.onAttentionContainer,
    ),

    // Under way, nothing wanted from you.
    OrderStage.preparing ||
    OrderStage.producing => (
      background: scheme.infoContainer,
      foreground: scheme.onInfoContainer,
    ),

    // Moving, and close.
    OrderStage.ready ||
    OrderStage.onTheWay => (
      background: scheme.pendingContainer,
      foreground: scheme.onPendingContainer,
    ),

    // Over, and well. The green this app already owns — see `PaymentTone`, which exists because
    // Material 3 ships no success role.
    OrderStage.delivered => (
      background: scheme.paidContainer,
      foreground: scheme.onPaidContainer,
    ),

    // Over, and not well — but not an error either: a returned order is a thing that happens,
    // not a failure the customer should be alarmed by. Neutral, like «ملغاة».
    // **«مرفوضة» is neutral too, and deliberately not the error colour.** A refusal is already
    // the least welcome thing this screen says; painting it red would make the shop's answer
    // look like the customer did something wrong. The sentence under it does the explaining.
    OrderStage.returned ||
    OrderStage.cancelled ||
    OrderStage.rejected ||
    OrderStage.unknown => (
      background: scheme.surfaceContainerHigh,
      foreground: scheme.onSurfaceVariant,
    ),
  };
}

/// أيقونة المرحلة: أيقونة حالة الورشة المقابلة لها في تطبيق الموظفين (`OrderStatusChip.iconFor`
/// هناك)، فيرى العميل الشكل الذي يراه الموظف (طلب المستخدم، 2026-09-25).
///
/// **حين تجمع المرحلة حالاتٍ عدة تُؤخذ أيقونة أولاها:** «قيد التجهيز» تبدأ بـ«جديدة»، و«قيد
/// الإنتاج» بالمطبعة، و«مرتجعة» بأول الرواجع. ولا `default`: مرحلةٌ تُضاف توقف البناء هنا حتى
/// تُعطى شكلها.
IconData stageIcon(OrderStage stage) => switch (stage) {
  OrderStage.underReview => AppIcons.comments,
  OrderStage.preparing => AppIcons.statusNew,
  OrderStage.designing => AppIcons.designs,
  OrderStage.producing => AppIcons.printedProduct,
  OrderStage.ready => AppIcons.activate,
  OrderStage.onTheWay => AppIcons.outForDelivery,
  OrderStage.delivered => AppIcons.ordersReceived,
  OrderStage.returned => AppIcons.returnedCourier,
  OrderStage.cancelled => AppIcons.ordersCancelled,
  OrderStage.rejected => AppIcons.close,
  // لا يُدّعى شيءٌ عن مرحلةٍ لم يسمع بها هذا الإصدار: كلمتها وصلت معها وتقول ما هي.
  OrderStage.unknown => AppIcons.unknownStatus,
};

/// المرحلة في شارةٍ صغيرة: أيقونتها ثم كلمتها.
class StagePill extends StatelessWidget {
  const StagePill({required this.label, required this.stage, super.key}) : large = false;

  /// بحجم نصف ما يقوله الصف، لا شارةٍ في زاويته — رأس بطاقة ملاحظةٍ في «الملاحظات»، كما تُرسم
  /// الحالة بحجمها الكامل في شاشة ملاحظات الموظفين.
  const StagePill.large({required this.label, required this.stage, super.key}) : large = true;

  final String label;
  final OrderStage stage;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final tone = stageTone(context.colorScheme, stage);
    final text = large ? context.textTheme.labelLarge : context.textTheme.labelSmall;

    return Container(
      padding: large
          ? EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h)
          : EdgeInsets.symmetric(horizontal: 11.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(stageIcon(stage), size: large ? 17.sp : 14.sp, color: tone.foreground),
          SizedBox(width: large ? 6.w : 5.w),
          Text(
            // **The label the server sent**, never a translation of the value.
            label,
            style: text?.copyWith(
              color: tone.foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// أيقونة المرحلة في مربّعٍ بلونها، أوّل ما في بطاقة «طلباتي» من اليمين.
///
/// **لونٌ واحد مع شارة المرحلة وبطاقة الحالة** ([stageTone])، فلا يتبدّل لون الطلبية بين
/// الرئيسية والقائمة وما يُفتح منهما.
class StageTile extends StatelessWidget {
  const StageTile({required this.stage, super.key});

  final OrderStage stage;

  @override
  Widget build(BuildContext context) {
    final tone = stageTone(context.colorScheme, stage);

    return Container(
      width: 46.w,
      height: 46.w,
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Icon(stageIcon(stage), size: 22.sp, color: tone.foreground),
    );
  }
}
