import 'package:dayaa_client/core/theme/app_tones.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/utils/dates.dart';
import 'package:dayaa_client/core/utils/text_direction.dart';
import 'package:dayaa_client/features/support/models/support_ticket.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// صفُّ تذكرةٍ في «الدعم» — على شكل صفّ محادثةٍ في قائمة تيليغرام.
///
/// دائرةٌ بلون حال التذكرة، ثم الموضوع ووقتُ آخر رسالة، وتحتهما آخرُ ما قيل وعددُ ما لم يُقرأ.
/// **الموضوع بحجم العنوان والباقي بحجم النص** — سطور القوائم لا تنزل إلى حجم التعليق.
///
/// **العدد في دائرةٍ برتقالية لا حمراء.** ردُّ المحل ما جاء العميل ينتظره، لا خطأٌ ينبَّه إليه؛
/// والأحمر في هذا التطبيق لما انكسر.
class TicketRow extends StatelessWidget {
  const TicketRow({required this.ticket, required this.onOpen, super.key});

  final SupportTicket ticket;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;
    final unread = ticket.unreadCount;

    final (avatarFill, avatarInk) = switch (ticket.status) {
      TicketStatus.open => (scheme.attentionContainer, scheme.onAttentionContainer),
      TicketStatus.inProgress => (scheme.infoContainer, scheme.onInfoContainer),
      TicketStatus.closed || TicketStatus.unknown => (
        scheme.surfaceContainerHigh,
        scheme.onSurfaceVariant,
      ),
    };

    final preview = ticket.preview;
    // سطر المعاينة يجري كما كُتب، ويصطفّ مع بقية الصفّ على حافة التطبيق.
    final own = preview?.readingDirection;
    final appDirection = Directionality.of(context);

    return InkWell(
      onTap: onOpen,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50.w,
              height: 50.w,
              decoration: BoxDecoration(color: avatarFill, shape: BoxShape.circle),
              child: Icon(AppIcons.comments, size: 24.sp, color: avatarInk),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          ticket.subject,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (ticket.lastMessageAt case final at?) ...[
                        SizedBox(width: 8.w),
                        Text(
                          _whenLabel(at),
                          style: text.bodySmall?.copyWith(
                            color: unread > 0 ? scheme.primary : scheme.onSurfaceVariant,
                            fontWeight: unread > 0 ? FontWeight.w700 : null,
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 3.h),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          preview ?? ticket.statusLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textDirection: own,
                          textAlign: own == null || own == appDirection
                              ? TextAlign.start
                              : TextAlign.end,
                          style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                      if (unread > 0) ...[
                        SizedBox(width: 8.w),
                        _UnreadCount(count: unread),
                      ],
                    ],
                  ),
                  if (ticket.order != null || ticket.status == TicketStatus.inProgress) ...[
                    SizedBox(height: 6.h),
                    Wrap(
                      spacing: 6.w,
                      runSpacing: 4.h,
                      children: [
                        if (ticket.status == TicketStatus.inProgress)
                          _Tag(
                            label: ticket.statusLabel,
                            fill: scheme.infoContainer,
                            ink: scheme.onInfoContainer,
                          ),
                        if (ticket.order case final order?)
                          _Tag(
                            label: 'طلبية #${order.code}',
                            fill: scheme.surfaceContainerHigh,
                            ink: scheme.onSurfaceVariant,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// الساعة لما كان اليوم، و«أمس»، وإلا التاريخ بلا سنةٍ إن كانت هذه — كما تكتب قائمة المحادثات.
  static String _whenLabel(DateTime at) {
    final local = at.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return switch (today.difference(DateTime(local.year, local.month, local.day)).inDays) {
      0 => local.timeLabel,
      1 => 'أمس',
      _ => local.shortDayLabel,
    };
  }
}

class _UnreadCount extends StatelessWidget {
  const _UnreadCount({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Semantics(
      label: count == 1 ? 'ردّ جديد' : '$count ردود جديدة',
      child: ExcludeSemantics(
        child: Container(
          constraints: BoxConstraints(minWidth: 24.w),
          padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(999.r),
          ),
          child: Text(
            count > 99 ? '99+' : '$count',
            textAlign: TextAlign.center,
            style: context.textTheme.labelMedium?.copyWith(
              color: scheme.onPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.fill, required this.ink});

  final String label;
  final Color fill;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 2.h),
      decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(999.r)),
      child: Text(
        label,
        style: context.textTheme.labelMedium?.copyWith(color: ink, fontWeight: FontWeight.w700),
      ),
    );
  }
}
