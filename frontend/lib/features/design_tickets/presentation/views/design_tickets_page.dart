import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/widgets/filter_option_chip.dart';
import 'package:dayaa/core/widgets/paged_list_view.dart';
import 'package:dayaa/core/widgets/search_field.dart';
import 'package:dayaa/features/customers/presentation/widgets/customer_picker_sheet.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket_counts.dart';
import 'package:dayaa/features/design_tickets/models/design_tickets_filter.dart';
import 'package:dayaa/features/design_tickets/presentation/viewmodel/design_tickets_cubit.dart';
import 'package:dayaa/features/design_tickets/presentation/widgets/design_ticket_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// تذاكر التصميم — what has been asked for, who is drawing it, and what is waiting on a verdict.
///
/// Three blocks down one column: the search band, the queue row, and the rows themselves.
///
/// **The queue row is on the page rather than in a sheet**, unlike the shortages screen's
/// filters, and the reason is who reads this. «شغلي» and «الطابور المشترك» are the two things a
/// designer flips between all day — one is their work, the other is where they go to find more —
/// and a question asked that often is worth a tap rather than two. The status chips sit beside
/// them for the same reason: six words, and the counts are what say where the work is.
///
/// **Newest first, and closed tickets are not buried.** Within a month «مكتمل» will be most of
/// the table, and a list that hid it would make the record of what was agreed reachable only by
/// filtering.
class DesignTicketsPage extends StatelessWidget {
  const DesignTicketsPage({this.filter, super.key});

  /// A question settled before the screen opened — «تصاميم متجر إكس», reached from that customer.
  /// Null on the section's own door, where the list opens on everything the reader may see.
  final DesignTicketsFilter? filter;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DesignTicketsCubit>(
      create: (_) => sl<DesignTicketsCubit>()..start(filter),
      child: _DesignTicketsView(title: filter?.title ?? 'تذاكر التصميم'),
    );
  }
}

class _DesignTicketsView extends StatelessWidget {
  const _DesignTicketsView({required this.title});

  final String title;

  Future<void> _open(BuildContext context, DesignTicket ticket) async {
    final cubit = context.read<DesignTicketsCubit>();

    await context.push<void>(Routes.designTicket(ticket.id));

    // **Re-read rather than patch the row from a result.** Almost everything that happens on the
    // detail screen changes the ticket's status, and the chip counts beside this list describe
    // statuses — a row swapped in place would leave «جديد ٣» standing over a list with two.
    await cubit.refresh();
  }

  /// Raising one from the section's own door.
  ///
  /// **The customer is asked for first.** A ticket is always *for* somebody, and the form has no
  /// picker of its own — it is built to be opened from a customer's screen, where the customer is
  /// read rather than chosen and the wrong one is unnameable. Reached from here there is no such
  /// screen, so the picker stands in for it.
  Future<void> _add(BuildContext context) async {
    final cubit = context.read<DesignTicketsCubit>();

    final customer = await showCustomerPicker(context: context);

    // Backing out of the picker is the expected ending of that call, not a failure.
    if (customer == null || !context.mounted) return;

    final saved = await context.push<DesignTicket>(
      Routes.designTicketForm,
      extra: customer,
    );

    if (saved != null) await cubit.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DesignTicketsCubit>();
    final session = sl<Session>();
    final mayManage = session.can(AppPermission.manageDesignTickets);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      floatingActionButton: mayManage
          ? FloatingActionButton.extended(
              heroTag: 'fab-design-tickets',
              onPressed: () => _add(context),
              icon: Icon(AppIcons.add),
              label: const Text('طلب تصميم'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 10.h),
            child: SearchField(
              // The server matches all three, so the hint says all three rather than leaving
              // somebody to discover that a customer's name works here.
              hint: 'ابحث بالعنوان أو رقم التذكرة أو اسم الزبون',
              onChanged: cubit.search,
            ),
          ),
          // The two queues. Offered to everybody rather than only to designers: an employee
          // filtering to «الطابور المشترك» is asking «ما الذي لم يلتقطه أحد؟», which is exactly
          // the question they need before chasing somebody.
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
            child: BlocBuilder<DesignTicketsCubit, DesignTicketsState>(
              builder: (context, _) => Row(
                children: [
                  for (final (label, value) in const [
                    ('الكل', null),
                    ('شغلي', 'me'),
                    ('الطابور المشترك', 'none'),
                  ]) ...[
                    FilterOptionChip(
                      label: label,
                      isSelected: cubit.designer == value,
                      onTap: () => cubit.showDesigner(value),
                    ),
                    SizedBox(width: 8.w),
                  ],
                ],
              ),
            ),
          ),
          // The status row, with the server's counts on it. Scrolls, because six statuses do not
          // fit a phone — and every one is present, zeros included, so the row does not reflow as
          // work moves.
          SizedBox(
            height: 44.h,
            child: BlocBuilder<DesignTicketsCubit, DesignTicketsState>(
              builder: (context, _) => ValueListenableBuilder<DesignTicketCounts>(
                valueListenable: cubit.counts,
                builder: (context, counts, _) => ListView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  children: [
                    FilterOptionChip(
                      label: 'الكل (${counts.total})',
                      isSelected: cubit.status == null,
                      onTap: () => cubit.showStatus(null),
                    ),
                    SizedBox(width: 8.w),
                    for (final status in DesignTicketStatus.offered) ...[
                      FilterOptionChip(
                        label: '${status.label} (${counts.forStatus(status)})',
                        isSelected: cubit.status == status,
                        onTap: () => cubit.showStatus(status),
                      ),
                      SizedBox(width: 8.w),
                    ],
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Expanded(
            child: BlocBuilder<DesignTicketsCubit, DesignTicketsState>(
              builder: (context, state) => PagedListView<DesignTicket>(
                state: state,
                // «لا توجد تذاكر» about a *narrowed* list would say the section is empty when it
                // is the question that came back empty.
                emptyMessage: switch ((cubit.currentSearch, cubit.status, cubit.designer)) {
                  (final search?, _, _) when search.isNotEmpty =>
                    'لا توجد تذاكر تطابق «$search»',
                  (_, _, 'me') => 'لا تذاكر مسندة إليك',
                  (_, _, 'none') => 'لا يوجد عمل في الطابور المشترك',
                  (_, final status?, _) => 'لا توجد تذاكر في «${status.label}»',
                  _ => 'لا توجد تذاكر تصميم',
                },
                onLoadMore: cubit.loadMore,
                onRefresh: cubit.refresh,
                skeletonHeight: 112.h,
                itemBuilder: (context, ticket, index) => DesignTicketCard(
                  key: ValueKey(ticket.id),
                  ticket: ticket,
                  onTap: () => _open(context, ticket),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
