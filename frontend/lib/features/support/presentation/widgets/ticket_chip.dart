import 'package:dayaa/core/theme/app_tones.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/features/support/models/support_ticket.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// لونُ كلّ حالة — أزرقُ للمفتوحة، وكهرمانيٌّ لما قيد المعالجة، وأخضرُ للمغلقة: مفتاحُ بريمولا
/// نفسه، من ألوان هذا التطبيق.
///
/// واحدٌ لشريحة البطاقة ولنقطة شريحة التصفية، فلا يتعلّم القارئ مفتاحين.
Color ticketStatusHue(ColorScheme scheme, TicketStatus status) => switch (status) {
  TicketStatus.open => scheme.tertiary,
  TicketStatus.inProgress => scheme.warn,
  TicketStatus.closed => scheme.paid,
  TicketStatus.unknown => scheme.onSurfaceVariant,
};

/// وصفةٌ واحدة لكل شريحةٍ ملوّنة على البطاقة: مسحةٌ من اللون، وحدٌّ منه، والكلمةُ باللون نفسه.
///
/// المسحةُ في الداكن أقوى منها في الفاتح، وإلا ذابت في سطح البطاقة. منقولةٌ من `ticketChipTone`
/// في بريمولا.
({Color background, Color border, Color foreground}) ticketChipTone(
  Color hue,
  Brightness brightness,
) {
  final isDark = brightness == Brightness.dark;

  return (
    background: hue.withValues(alpha: isDark ? .22 : .14),
    border: hue.withValues(alpha: isDark ? .45 : .40),
    foreground: hue,
  );
}

/// شكلٌ واحد لكل شريحةٍ على بطاقة التذكرة: الحالة، والمكتب، والعميل، والطلب، والوقت.
///
/// أيقونةٌ **أو** نقطةٌ في أوّلها، لا الاثنتان. بلا حدٍّ إلا حين يُعطى [border] — فالشرائحُ
/// الملوّنة وحدها تحمل حدّاً، وخمسُ شرائح محدودة ترسم على البطاقة خطوطاً لا تتسع لها.
class TicketChip extends StatelessWidget {
  const TicketChip({
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
    this.dotColor,
    this.border,
    this.dense = false,
    super.key,
  });

  /// شريحةُ مكتب التذكرة — على مكتب من هي: أحمرُ ما لم يأخذها أحد، واللونُ الأساسيّ حين تكون لي،
  /// ومحايدةٌ لاسم زميل. الشريحةُ الوحيدة التي لونُها دعوةٌ إلى فعل، على البطاقة وفي شريط المحادثة.
  factory TicketChip.desk(
    BuildContext context, {
    required SupportTicket ticket,
    required int? me,
    bool dense = false,
    Key? key,
  }) {
    final scheme = context.colorScheme;

    if (ticket.assignedTo == null) {
      return TicketChip.tinted(
        context,
        key: key,
        label: 'غير مُسندة',
        hue: scheme.error,
        icon: AppIcons.unassigned,
        dense: dense,
      );
    }

    // اسمي على تذكرتي لا يقول شيئاً؛ «تذكرتك» تقول إنها عليّ أنا.
    if (me != null && ticket.assignedTo == me) {
      return TicketChip.tinted(
        context,
        key: key,
        label: 'تذكرتك',
        hue: scheme.primary,
        icon: AppIcons.assignedToMe,
        dense: dense,
      );
    }

    // اسمُ زميل معلومةٌ لا استدعاء، فهو محايد.
    return TicketChip.neutral(
      context,
      key: key,
      label: ticket.assignee?.name ?? 'موظف آخر',
      icon: AppIcons.person,
      dense: dense,
    );
  }

  /// شريحةٌ محايدة: سطحٌ واحد والكلمةُ بتمام قوّتها.
  factory TicketChip.neutral(
    BuildContext context, {
    required String label,
    IconData? icon,
    bool quiet = false,
    bool dense = false,
    Key? key,
  }) {
    final scheme = context.colorScheme;

    return TicketChip(
      key: key,
      label: label,
      icon: icon,
      background: scheme.surfaceContainerHighest,
      foreground: quiet ? scheme.onSurfaceVariant : scheme.onSurface,
      dense: dense,
    );
  }

  /// شريحةٌ ملوّنة بوصفة [ticketChipTone].
  factory TicketChip.tinted(
    BuildContext context, {
    required String label,
    required Color hue,
    IconData? icon,
    bool dot = false,
    bool dense = false,
    Key? key,
  }) {
    final tone = ticketChipTone(hue, Theme.of(context).brightness);

    return TicketChip(
      key: key,
      label: label,
      icon: dot ? null : icon,
      dotColor: dot ? hue : null,
      background: tone.background,
      foreground: tone.foreground,
      border: tone.border,
      dense: dense,
    );
  }

  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;
  final Color? dotColor;
  final Color? border;

  /// الحجمُ الصغير — في شريط المحادثة تحت اسم العميل، كشرائح بريمولا هناك: كبسولةٌ أضيق.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final leading = switch ((dotColor, icon)) {
      (final Color dot, _) => Container(
        width: (dense ? 7 : 8).r,
        height: (dense ? 7 : 8).r,
        decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
      ),
      (null, final IconData glyph) => Icon(glyph, size: (dense ? 13 : 15).sp, color: foreground),
      _ => null,
    };

    return Container(
      padding: dense
          ? EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h)
          : EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(dense ? 999 : 10.r),
        border: border == null ? null : Border.all(color: border!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading, SizedBox(width: (dense ? 5 : 6).w)],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.labelMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
