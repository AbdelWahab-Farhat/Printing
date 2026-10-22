import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/core/utils/text_direction.dart';
import 'package:dayaa/features/internal_tickets/models/internal_ticket.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// صفُّ تذكرةٍ داخلية في القائمة، كصفّ بريمولا: **الزميلُ** أوّلاً — مَن أكلّم — ثم العنوان،
/// والكودُ ونوعُ المشكلة والأولوية، ومعاينةُ آخر ما قيل («🎤 رسالة صوتية ٠:٤٢» للصوت)، والوقت،
/// وعددُ غير المقروء معلّقاً على الزاوية كبطاقة الدعم.
///
/// والمديرُ الذي ليس طرفاً يرى الاسمين معاً — «سالم ← هدى» — لأنه لا «زميل» له فيها.
class InternalTicketCard extends StatelessWidget {
  const InternalTicketCard({required this.ticket, required this.onOpen, this.me, super.key});

  final InternalTicket ticket;
  final VoidCallback onOpen;
  final int? me;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final unread = ticket.unreadCount;
    final other = ticket.otherSideOf(me);
    final who =
        other?.name ?? [ticket.opener?.name, ticket.assignee?.name].whereType<String>().join(' ← ');
    final last = ticket.lastMessage;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Theme.of(context).brightness == Brightness.dark
              ? scheme.surfaceContainer
              : scheme.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
            side: BorderSide(color: unread > 0 ? scheme.primary : scheme.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onOpen,
            child: Padding(
              padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(AppIcons.person, size: 18.sp, color: scheme.onSurfaceVariant),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          who,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (last?.sentAt ?? ticket.lastMessageAt case final at?)
                        Text(
                          at.toLocal().relativeDayLabel,
                          style: context.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    ticket.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textDirection: ticket.title.readingDirection,
                    style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (last != null && last.preview.isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    _Preview(last: last, mine: last.authorId == me),
                  ],
                  SizedBox(height: 8.h),
                  Wrap(
                    spacing: 6.w,
                    runSpacing: 6.h,
                    children: [
                      _Tag(label: ticket.code),
                      if (ticket.category case final category?) _Tag(label: category.name),
                      if (ticket.priority == InternalTicketPriority.high)
                        _Tag(label: ticket.priorityLabel, urgent: true),
                      if (!ticket.status.isOpen) _Tag(label: ticket.statusLabel),
                      if (ticket.order case final order?) _Tag(label: 'الطلبية ${order.code}'),
                      if (ticket.customer?.name case final customer?) _Tag(label: customer),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (unread > 0)
          PositionedDirectional(
            top: -9.h,
            end: -6.w,
            child: _UnreadBadge(count: unread),
          ),
      ],
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.last, required this.mine});

  final InternalLastMessage last;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final seconds = last.durationSeconds;
    final text = last.kind == 'voice' && seconds != null
        ? '${last.preview} ${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}'
        : last.preview;

    return Text(
      mine ? 'أنت: $text' : text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, this.urgent = false});

  final String label;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: urgent ? scheme.errorContainer : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
        child: Text(
          label,
          style: context.textTheme.labelSmall?.copyWith(
            color: urgent ? scheme.onErrorContainer : scheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      constraints: BoxConstraints(minWidth: 26.w),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: scheme.error,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.surface, width: 2),
      ),
      child: Text(
        count > 99 ? '+99' : '$count',
        textAlign: TextAlign.center,
        style: context.textTheme.labelMedium?.copyWith(
          color: scheme.onError,
          fontWeight: FontWeight.w800,
          height: 1.1,
        ),
      ),
    );
  }
}
