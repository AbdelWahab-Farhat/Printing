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
  const StagePill({required this.label, required this.stage, super.key});

  final String label;
  final OrderStage stage;

  @override
  Widget build(BuildContext context) {
    final tone = stageTone(context.colorScheme, stage);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(stageIcon(stage), size: 14.sp, color: tone.foreground),
          SizedBox(width: 5.w),
          Text(
            // **The label the server sent**, never a translation of the value.
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: tone.foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// المرحلة شريطاً بعرض البطاقة، كشريط الحالة أعلى بطاقة الطلبية في تطبيق الموظفين: الكلمة في
/// الوسط وأيقونتها بعدها — في آخر السطر العربي — على لون المرحلة.
///
/// **المرحلة أول ما تُمسح البطاقة لأجله**، فتُعطى عرض البطاقة كله لا زاويةً منها.
class StageBanner extends StatelessWidget {
  const StageBanner({required this.label, required this.stage, super.key});

  /// كلمة الخادم كما هي.
  final String label;
  final OrderStage stage;

  @override
  Widget build(BuildContext context) {
    final tone = stageTone(context.colorScheme, stage);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.labelLarge?.copyWith(
                color: tone.foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Icon(stageIcon(stage), size: 20.sp, color: tone.foreground),
        ],
      ),
    );
  }
}
