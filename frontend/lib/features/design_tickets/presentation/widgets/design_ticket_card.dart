import 'dart:async';

import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/image_viewer.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket.dart';
import 'package:dayaa/features/design_tickets/presentation/widgets/design_ticket_status_pill.dart';
import 'package:dayaa/features/design_tickets/presentation/widgets/design_version_tile.dart';
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
///
/// **«قبول» is on the row, and only where the server says this reader may take this ticket.**
/// Scrolling a pool and opening each ticket to find out whether it is free is the work the flag
/// exists to save; `can_accept` is read off the payload and never inferred, so an administrator
/// — who may hand work out rather than draw it — sees no button here either.
class DesignTicketCard extends StatelessWidget {
  const DesignTicketCard({
    required this.ticket,
    required this.onTap,
    this.onAccept,
    this.isAccepting = false,
    super.key,
  });

  final DesignTicket ticket;
  final VoidCallback onTap;

  /// Null on a screen that does not offer taking work from the list at all. The button is drawn
  /// only when this is given **and** the ticket says the reader may take it.
  final VoidCallback? onAccept;

  /// True while this row's own acceptance is in flight — the spinner belongs to the row, not to
  /// the list, because the other rows are still perfectly tappable.
  final bool isAccepting;

  @override
  Widget build(BuildContext context) {
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
              // `IntrinsicHeight` so the picture is as tall as the words beside it rather than a
              // fixed square floating against them. It measures its children twice, which is
              // why it is wrapped around this row alone and not the whole card.
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _Details(ticket: ticket)),
                    // **The newest design at the far edge, and only when there is one.** A queue
                    // of artwork read as a wall of text; the thing a reviewer scrolling it
                    // recognises is the picture. Newest rather than approved, because a ticket
                    // sitting in «تعديل مطلوب» has no approved version and is exactly the row
                    // somebody is looking for.
                    if (ticket.newestVersion case final version?) ...[
                      SizedBox(width: 12.w),
                      SizedBox(
                        width: 64.w,
                        child: InkWell(
                          // Opens the picture rather than the ticket: somebody who taps the
                          // artwork wants to see the artwork, and the rest of the row still
                          // opens the ticket.
                          onTap: () => unawaited(
                            openImageViewer(
                              context,
                              urls: [?version.thumbnailUrl ?? version.fileUrl],
                              cacheKeys: ['design-ticket-file-${version.id}'],
                            ),
                          ),
                          child: DesignTicketFileThumbnail(file: version),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onAccept != null && ticket.canAccept) ...[
                SizedBox(height: 10.h),
                // **Full width, like every other action in this app.** A button that shrinks to
                // its label on a card reads as a chip, and a chip reads as a filter.
                AppButton(label: 'قبول', isLoading: isAccepting, onPressed: onAccept),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The words on the row: what was asked, for whom, and who is drawing it.
class _Details extends StatelessWidget {
  const _Details({required this.ticket});

  final DesignTicket ticket;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;
    final designer = ticket.workingDesigner;

    return Column(
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
              // **Both rows are named.** They were two lines each behind the same person icon —
              // «اسامة حماد» over «محمد علي» — and nothing on the card said which of the two
              // was the customer and which was drawing it.
              Row(
                children: [
                  Icon(AppIcons.customers, size: 14.sp, color: scheme.onSurfaceVariant),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Text(
                      // **The code, not the name.** «A713» is what somebody says on the
                      // telephone and what the search box takes; the name is the long half of
                      // the row and the half that gets edited. It falls back to the name only
                      // where the server sent no code — an older payload, not an ordinary one.
                      'العميل: ${ticket.customerCode ?? ticket.customerName}',
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
                    ticket.isInSharedPool ? AppIcons.employees : AppIcons.designs,
                    size: 14.sp,
                    color: scheme.onSurfaceVariant,
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Text(
                      ticket.isInSharedPool
                          ? 'المصمم: الطابور المشترك'
                          : 'المصمم: ${designer?.name ?? 'غير مُسنَد'}',
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
    );
  }
}
