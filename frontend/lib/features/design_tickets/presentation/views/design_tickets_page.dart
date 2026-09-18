import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_dialog.dart';
import 'package:dayaa/core/widgets/app_dropdown.dart';
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
/// Two blocks down one column: the band — search and one status picker beside it — and the rows.
///
/// **One filter, and it is a dropdown rather than a chip row.** This shipped with two rows of
/// chips above the list: the designer's three queues («الكل», «شغلي», «الطابور المشترك») and the
/// six statuses on a sideways scroller. Both are gone. The queues are not a question anybody was
/// asking of this screen, and six statuses do not fit a phone's width — half the options sat off
/// the edge, which is a filter that hides its own choices. The dropdown names all six in one
/// place, carries the same counts, and gives the list back the two rows of height.
///
/// The designer filter is still the server's to answer and still reachable through
/// [DesignTicketsFilter] — what went is the row on this screen, not the capability.
///
/// **Newest first, and closed tickets are not buried.** Within a month «مكتمل» will be most of
/// the table, and a list that hid it would make the record of what was agreed reachable only by
/// filtering — which is why «الكل» is what the picker opens on.
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

class _DesignTicketsView extends StatefulWidget {
  const _DesignTicketsView({required this.title});

  final String title;

  @override
  State<_DesignTicketsView> createState() => _DesignTicketsViewState();
}

class _DesignTicketsViewState extends State<_DesignTicketsView> {
  /// The row whose acceptance is in flight, so the spinner sits on that card and every other
  /// row stays tappable.
  int? _accepting;

  /// Taking a ticket from the list, without opening it.
  ///
  /// **Asked first.** Accepting is the one step in this flow that cannot be undone by the person
  /// doing it: it locks every other designer out and makes this account the only one allowed to
  /// upload. That is too much to hang on a mis-tap while scrolling a queue.
  Future<void> _accept(BuildContext context, DesignTicket ticket) async {
    final cubit = context.read<DesignTicketsCubit>();

    final confirmed = await showCustomDialog(
      context: context,
      // A question mark, because the confirm button beside it says «قبول الطلب» and a dialog
      // whose heading and whose button read identically tells the reader nothing.
      title: 'قبول الطلب؟',
      // What the tap actually does, in the words somebody would use about it afterwards.
      description: 'ستصبح أنت المصمم المسؤول عن «${ticket.title}»، ولن يستطيع مصمم آخر أخذها.',
      confirmLabel: 'قبول الطلب',
    );

    if (!(confirmed ?? false) || !context.mounted) return;

    setState(() => _accepting = ticket.id);

    final failure = await cubit.accept(ticket.id);

    if (!mounted) return;

    setState(() => _accepting = null);

    if (failure != null) {
      this.context.showFailure(failure);

      return;
    }

    this.context.showSuccess('تم قبول الطلب');
  }

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

    final customer = await showCustomerPicker(
      context: context,
      title: 'لمن هذا التصميم؟',
    );

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

    // **Whether this screen is somebody's whole app.**
    //
    // The router sends an account that may take design work and cannot read orders straight
    // here from `/`, so a designer never reaches the home shell — and the drawer, which is the
    // only door to «الإعدادات» and therefore the only door to «تسجيل الخروج», lives on that
    // shell. A designer had no way to sign out at all. The same condition the redirect uses,
    // because it is the same question asked from the other side.
    final isTheirWholeApp =
        session.can(AppPermission.acceptDesignTickets) && !session.can(AppPermission.viewOrders);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          // Not drawn for staff: they arrived by pushing this route, so they have a back arrow
          // and the drawer behind it, and a second way in would be clutter.
          if (isTheirWholeApp)
            IconButton(
              icon: Icon(AppIcons.settings),
              tooltip: 'الإعدادات',
              onPressed: () => context.push(Routes.settings),
            ),
        ],
      ),
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SearchField(
                    // Shorter than the three things the server actually matches — the title, the
                    // code and the customer — because the box is no longer the width of the
                    // screen. The code is the one a hint can afford to drop: somebody typing
                    // «D12» is not wondering whether it will work.
                    hint: 'ابحث بالعنوان أو الزبون',
                    onChanged: cubit.search,
                  ),
                ),
                SizedBox(width: 8.w),
                // **The whole filter, in the width a chip row used to need two lines for.**
                // `BlocBuilder` for the chosen value, `ValueListenableBuilder` for the numbers:
                // the counts arrive from a second request that does not move the list's state.
                SizedBox(
                  width: 132.w,
                  child: BlocBuilder<DesignTicketsCubit, DesignTicketsState>(
                    builder: (context, _) => ValueListenableBuilder<DesignTicketCounts>(
                      valueListenable: cubit.counts,
                      builder: (context, counts, _) => AppDropdown<DesignTicketStatus?>(
                        value: cubit.status,
                        // **«الكل» is a row in the list, not a `placeholder`.** The placeholder
                        // slot takes a bare string, and this row has to carry a number like
                        // every other one — and it is a real answer, not the absence of one.
                        items: [null, ...DesignTicketStatus.offered],
                        labelOf: (status) => switch (status) {
                          null => 'الكل (${counts.total})',
                          final chosen => '${chosen.label} (${counts.forStatus(chosen)})',
                        },
                        // Every status is offered, zeros included, so the list does not reorder
                        // itself as work moves — «مكتمل (0)» today is where «مكتمل» will be
                        // tomorrow.
                        onChanged: cubit.showStatus,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
                  onAccept: () => _accept(context, ticket),
                  isAccepting: _accepting == ticket.id,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
