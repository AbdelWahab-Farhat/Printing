import 'dart:async';

import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/features/support/models/support_ticket.dart';
import 'package:dayaa/features/support/presentation/widgets/ticket_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// ما يُفعل بالتذكرة من «⋮».
enum ThreadAction { take, giveBack, call, openCustomer, close }

/// شريطُ المحادثة كشريط بريمولا: **اسمُ العميل في الوسط، وتحته شرائحُ الحالة والمكتب والكود،
/// وما يُفعل بالتذكرة في «⋮».**
///
/// الحالةُ والمكتبُ بألوان بطاقة الطابور نفسها ([ticketStatusHue]، [TicketChip.desk])، فلا يتعلّم
/// الموظف مفتاحين. والكودُ يُنسخ باللمس — هو ما يُقال في الهاتف ويُبحث به.
///
/// وتحت الشريط خطٌّ رفيع يتحرّك ما دام أمرٌ في الطريق — إسنادٌ أو إغلاق — كما في بريمولا.
class ThreadBar extends StatelessWidget implements PreferredSizeWidget {
  const ThreadBar({
    required this.ticket,
    required this.me,
    required this.actions,
    required this.onAction,
    this.isWorking = false,
    super.key,
  });

  final SupportTicket ticket;
  final int? me;

  /// ما يحقّ لهذا القارئ على هذه التذكرة، بترتيبه في القائمة. فارغةٌ: لا «⋮».
  final List<ThreadAction> actions;
  final void Function(ThreadAction action) onAction;
  final bool isWorking;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 8 + 2);

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final customer = ticket.customer;
    final code = customer?.code?.trim();
    final name = customer?.name?.trim();
    final hasName = name != null && name.isNotEmpty;
    final hasCode = code != null && code.isNotEmpty;

    return AppBar(
      centerTitle: true,
      titleSpacing: 0,
      toolbarHeight: kToolbarHeight + 8,
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            hasName ? name : (hasCode ? code : 'عميل'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, height: 1.2),
          ),
          SizedBox(height: 4.h),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // كلمةُ الخادم (`status_label`)، ولونُها من التطبيق.
              Flexible(
                child: TicketChip.tinted(
                  context,
                  label: ticket.statusLabel,
                  hue: ticketStatusHue(scheme, ticket.status),
                  dot: true,
                  dense: true,
                ),
              ),
              SizedBox(width: 5.w),
              Flexible(child: TicketChip.desk(context, ticket: ticket, me: me, dense: true)),
              if (hasName && hasCode) ...[
                SizedBox(width: 5.w),
                Flexible(child: _CodeChip(code: code)),
              ],
            ],
          ),
        ],
      ),
      actions: [
        if (actions.isNotEmpty)
          _TicketMenu(
            actions: actions,
            phone: customer?.phone,
            enabled: !isWorking,
            onSelected: onAction,
          ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(2),
        child: SizedBox(
          height: 2,
          child: isWorking ? LinearProgressIndicator(color: scheme.primary) : null,
        ),
      ),
    );
  }
}

/// كودُ العميل — يُنسخ باللمس.
class _CodeChip extends StatelessWidget {
  const _CodeChip({required this.code});

  final String code;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: code));

    if (context.mounted) context.showSuccess('نُسخ كود العميل');
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'نسخ كود العميل',
      child: GestureDetector(
        onTap: () => unawaited(_copy(context)),
        child: TicketChip.tinted(
          context,
          label: code,
          hue: context.colorScheme.primary,
          icon: AppIcons.person,
          dense: true,
        ),
      ),
    );
  }
}

/// «⋮» — ما يُفعل بالتذكرة، كقائمة بريمولا: أيقونةٌ وكلمة، وتحتها ما يوضّحها حين يلزم.
class _TicketMenu extends StatelessWidget {
  const _TicketMenu({
    required this.actions,
    required this.phone,
    required this.enabled,
    required this.onSelected,
  });

  final List<ThreadAction> actions;
  final String? phone;
  final bool enabled;
  final void Function(ThreadAction action) onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return PopupMenuButton<ThreadAction>(
      enabled: enabled,
      tooltip: 'إجراءات التذكرة',
      icon: Icon(AppIcons.more),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final action in actions)
          PopupMenuItem<ThreadAction>(
            value: action,
            child: switch (action) {
              ThreadAction.take => _MenuRow(icon: AppIcons.unassigned, label: 'خذها'),
              ThreadAction.giveBack => _MenuRow(icon: AppIcons.person, label: 'أعدها للطابور'),
              // الرقمُ تحت الكلمة: يُرى قبل أن يُتّصل به.
              ThreadAction.call => _MenuRow(
                icon: AppIcons.phone,
                label: 'اتصال بالعميل',
                subtitle: phone,
              ),
              ThreadAction.openCustomer => _MenuRow(icon: AppIcons.customers, label: 'ملف العميل'),
              ThreadAction.close => _MenuRow(
                icon: AppIcons.settled,
                label: 'إغلاق التذكرة',
                color: scheme.error,
              ),
            },
          ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label, this.subtitle, this.color});

  final IconData icon;
  final String label;
  final String? subtitle;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final ink = color ?? scheme.onSurface;

    return Row(
      children: [
        Icon(icon, size: 20.sp, color: color ?? scheme.onSurfaceVariant),
        SizedBox(width: 12.w),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: context.textTheme.bodyLarge?.copyWith(color: ink, fontWeight: FontWeight.w600),
              ),
              if (subtitle case final text?)
                Text(
                  text,
                  // الهاتف يُقرأ من اليسار إلى اليمين حتى في شاشةٍ عربية.
                  textDirection: TextDirection.ltr,
                  style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// الموضوعُ مثبّتاً تحت الشريط — كرسالةٍ مثبّتة في تيليغرام — والطلبُ الذي تتعلّق به في طرفه،
/// يُفتح باللمس.
///
/// **مثبّتٌ لا في المحادثة**: الشريطُ فوقه يسمّي العميل، والموضوعُ هو «عمّ يسأل» — يبقى ظاهراً
/// وإن طالت المحادثة.
class PinnedSubject extends StatelessWidget {
  const PinnedSubject({required this.ticket, this.onOpenOrder, super.key});

  final SupportTicket ticket;
  final VoidCallback? onOpenOrder;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Material(
      color: scheme.surface,
      child: Container(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
        ),
        child: Row(
          children: [
            Container(
              width: 3.w,
              height: 34.h,
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الموضوع',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    ticket.subject,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            if (ticket.order case final order?) ...[
              SizedBox(width: 8.w),
              Semantics(
                button: onOpenOrder != null,
                child: GestureDetector(
                  onTap: onOpenOrder,
                  child: TicketChip(
                    label: 'طلب ${order.code}',
                    icon: AppIcons.orders,
                    background: scheme.secondaryContainer,
                    foreground: scheme.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
