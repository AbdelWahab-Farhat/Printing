import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/filter_option_chip.dart';
import 'package:dayaa/core/widgets/paged_list_view.dart';
import 'package:dayaa/features/support/models/support_ticket.dart';
import 'package:dayaa/features/support/presentation/viewmodel/support_tickets_cubit.dart';
import 'package:dayaa/features/support/presentation/widgets/support_ticket_card.dart';
import 'package:dayaa/features/support/presentation/widgets/ticket_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// تذاكر الدعم — what customers are asking from their own app.
///
/// **حيّة**: تذكرةٌ جديدة تظهر ساعةَ يفتحها العميل، ومحادثةٌ جاءتها رسالةٌ تصعد إلى الأعلى
/// بشارتها — من المقبس لا بسحبٍ ولا طلب. انظر [SupportTicketsCubit].
///
/// **The queue the customer app has had nobody reading.** The backend has answered
/// `support/tickets` since the customer app shipped and this screen did not exist, so a customer
/// could open a thread that no employee could see. That is the gap this closes.
///
/// **No «تذكرة جديدة».** A ticket is a customer beginning a conversation; the shop opening one
/// on somebody's behalf would be a thread the customer never asked for and cannot recognise.
/// `SupportTicketController` has no `store` for the same reason.
class SupportTicketsPage extends StatelessWidget {
  const SupportTicketsPage({this.embedded = false, super.key});

  /// داخلَ تبويبَي صفحة «التذاكر»: شريطُها فوقه، فلا شريطَ ثانياً هنا.
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SupportTicketsCubit>(
      create: (_) => sl<SupportTicketsCubit>()..load(),
      child: _SupportTicketsView(embedded: embedded),
    );
  }
}

class _SupportTicketsView extends StatelessWidget {
  const _SupportTicketsView({required this.embedded});

  final bool embedded;

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
    final me = sl<Session>().user?.id;

    return Scaffold(
      appBar: embedded ? null : AppBar(title: const Text('تذاكر الدعم')),
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
                    // الحالاتُ، ثم «المسندة إليّ» آخراً — حين يُعرف من أنا.
                    itemCount: _filters.length + (me == null ? 0 : 1),
                    separatorBuilder: (context, index) => SizedBox(width: 8.w),
                    itemBuilder: (context, index) {
                      if (index == _filters.length) {
                        // **مربّعٌ لا نقطة** ([FilterOptionChip.isTicked]): يُضاف إلى الحالة
                        // المختارة ولا يحلّ محلّها — «المفتوحة» التي على مكتبي.
                        return Center(
                          child: FilterOptionChip(
                            label: 'المسندة إليّ',
                            isTicked: true,
                            isSelected: cubit.assignedTo == me,
                            onTap: () => cubit.showDeskOf(cubit.assignedTo == me ? null : me),
                          ),
                        );
                      }

                      final (label, status) = _filters[index];

                      return Center(
                        child: FilterOptionChip(
                          label: label,
                          // نقطةُ الحالة بلون شريحتها على البطاقة — مفتاحٌ واحد للقائمة.
                          dot: status == null
                              ? null
                              : ticketStatusHue(context.colorScheme, status),
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
                  emptyMessage: cubit.status == null && cubit.assignedTo == null
                      ? 'لا توجد تذاكر'
                      : 'لا توجد تذاكر بهذا الاختيار',
                  // فسحةٌ فوق البطاقة الأولى لشارة غير المقروء المعلّقة على زاويتها.
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
                  itemBuilder: (context, ticket, index) => SupportTicketCard(
                    ticket: ticket,
                    me: me,
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
