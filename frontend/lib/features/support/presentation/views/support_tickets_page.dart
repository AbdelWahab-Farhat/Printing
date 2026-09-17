import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/core/widgets/filter_option_chip.dart';
import 'package:dayaa/core/widgets/paged_list_view.dart';
import 'package:dayaa/features/support/models/support_ticket.dart';
import 'package:dayaa/features/support/presentation/viewmodel/support_tickets_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// تذاكر الدعم — what customers are asking from their own app.
///
/// **The queue the customer app has had nobody reading.** The backend has answered
/// `support/tickets` since the customer app shipped and this screen did not exist, so a customer
/// could open a thread that no employee could see. That is the gap this closes.
///
/// **No «تذكرة جديدة».** A ticket is a customer beginning a conversation; the shop opening one
/// on somebody's behalf would be a thread the customer never asked for and cannot recognise.
/// `SupportTicketController` has no `store` for the same reason.
class SupportTicketsPage extends StatelessWidget {
  const SupportTicketsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SupportTicketsCubit>(
      create: (_) => sl<SupportTicketsCubit>()..load(),
      child: const _SupportTicketsView(),
    );
  }
}

class _SupportTicketsView extends StatelessWidget {
  const _SupportTicketsView();

  /// The chips, and the state each one asks the server for.
  ///
  /// «الكل» is null — a real answer, not the absence of one — and it includes closed tickets,
  /// because «ماذا قلنا لهم آخر مرة؟» is half of what the desk is for.
  ///
  /// **The other three are derived from the enum** rather than typed out, so a status added to
  /// [TicketStatus] appears here without anybody remembering this list. Their Arabic comes from
  /// [TicketStatusX.label], which `ticket_status_contract_test` pins to the server's own.
  static List<(String, TicketStatus?)> get _filters => [
    ('الكل', null),
    for (final status in offerableTicketStatuses) (status.label, status),
  ];

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SupportTicketsCubit>();

    return Scaffold(
      appBar: AppBar(title: const Text('تذاكر الدعم')),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
              child: BlocBuilder<SupportTicketsCubit, SupportTicketsState>(
                builder: (context, state) => SizedBox(
                  height: 44.h,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    separatorBuilder: (context, index) => SizedBox(width: 8.w),
                    itemBuilder: (context, index) {
                      final (label, status) = _filters[index];

                      return Center(
                        child: FilterOptionChip(
                          label: label,
                          isSelected: cubit.status == status,
                          onTap: () => cubit.narrowTo(status),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            Expanded(
              child: BlocBuilder<SupportTicketsCubit, SupportTicketsState>(
                builder: (context, state) => PagedListView<SupportTicket>(
                  state: state,
                  onLoadMore: cubit.loadMore,
                  onRefresh: cubit.refresh,
                  emptyMessage: cubit.status == null
                      ? 'لا توجد تذاكر'
                      : 'لا توجد تذاكر بهذه الحالة',
                  padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h),
                  itemBuilder: (context, ticket, index) => _TicketCard(
                    ticket: ticket,
                    onOpen: () async {
                      final updated = await context.push<SupportTicket>(
                        Routes.supportTicket(ticket.id),
                      );

                      // Patched from what the thread screen was holding — no refetch, and the
                      // scroll position survives. It comes back at minimum with its unread
                      // count cleared, because opening it marks the desk's side read.
                      if (updated != null) cubit.absorb(updated);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket, required this.onOpen});

  final SupportTicket ticket;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final unread = ticket.unreadCount;

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Material(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14.r),
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(14.r),
          child: Opacity(
            // A closed thread is still readable, and still quieter than a live one.
            opacity: ticket.status.isClosed ? 0.6 : 1,
            child: Padding(
              padding: EdgeInsets.all(14.w),
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
                          style: context.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      // **Derived on the server from a read cursor**, never a stored counter, so
                      // it cannot drift out of step with what the desk has actually read.
                      if (unread > 0)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: scheme.error,
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            '$unread',
                            style: context.textTheme.labelSmall?.copyWith(
                              color: scheme.onError,
                            ),
                          ),
                        ),
                    ],
                  ),

                  SizedBox(height: 6.h),
                  // Who is asking, and the number whoever answers reaches for next.
                  Row(
                    children: [
                      Icon(AppIcons.customers, size: 14.sp, color: scheme.onSurfaceVariant),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          [
                            ?ticket.customer?.name,
                            ?ticket.customer?.phone,
                          ].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (ticket.order case final order?) ...[
                    SizedBox(height: 4.h),
                    Text(
                      'بخصوص الطلبية #${order.code}',
                      style: context.textTheme.bodySmall?.copyWith(color: scheme.primary),
                    ),
                  ],

                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      // The Arabic the server sent, so a status added to the business appears
                      // without an app release.
                      Text(
                        ticket.statusLabel,
                        style: context.textTheme.labelSmall?.copyWith(
                          color: ticket.status.isClosed
                              ? scheme.onSurfaceVariant
                              : scheme.primary,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      // Whose desk it is — the question the queue is read to answer.
                      Text(
                        ticket.assignee?.name ?? 'غير مُسندة',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: ticket.assignee == null
                              ? scheme.error
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      if (ticket.lastMessageAt case final at?)
                        Text(
                          at.relativeDayLabel,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
