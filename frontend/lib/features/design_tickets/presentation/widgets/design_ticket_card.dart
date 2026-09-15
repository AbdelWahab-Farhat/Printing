import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket.dart';
import 'package:dayaa/features/design_tickets/presentation/widgets/design_ticket_status_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// One ticket, as a row in the queue.
///
/// **The customer's name comes off the snapshot on the ticket**, never from a customer that would
/// have to be fetched — a designer holds no grant on that table, and this card has to draw for
/// them exactly as it does for the employee who raised it.
///
/// «الطابور المشترك» is called out rather than left to an absent designer's name: unclaimed work
/// is the one thing a designer is scrolling for, and «—» where a name would be does not say it.
class DesignTicketCard extends StatelessWidget {
  const DesignTicketCard({required this.ticket, required this.onTap, super.key});

  final DesignTicket ticket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;
    final designer = ticket.workingDesigner;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(14.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ticket.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  DesignTicketStatusPill(status: ticket.status, label: ticket.statusLabel),
                ],
              ),
              SizedBox(height: 6.h),
              Row(
                children: [
                  Icon(AppIcons.person, size: 14.sp, color: scheme.onSurfaceVariant),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Text(
                      ticket.customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ),
                  Text(
                    ticket.code,
                    style: text.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Row(
                children: [
                  Icon(
                    ticket.isInSharedPool ? AppIcons.employees : AppIcons.person,
                    size: 14.sp,
                    color: scheme.onSurfaceVariant,
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Text(
                      ticket.isInSharedPool
                          ? 'الطابور المشترك'
                          : designer?.name ?? 'غير مُسنَد',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(
                        color: ticket.isInSharedPool ? scheme.primary : scheme.onSurfaceVariant,
                        fontWeight: ticket.isInSharedPool ? FontWeight.w700 : null,
                      ),
                    ),
                  ),
                  if (ticket.versionCount > 0) ...[
                    Icon(AppIcons.document, size: 14.sp, color: scheme.onSurfaceVariant),
                    SizedBox(width: 4.w),
                    Text(
                      '${ticket.versionCount} نسخة',
                      style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
