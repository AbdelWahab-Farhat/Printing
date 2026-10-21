import 'dart:async';

import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/widgets/filter_option_chip.dart';
import 'package:dayaa/core/widgets/paged_list_view.dart';
import 'package:dayaa/core/widgets/search_field.dart';
import 'package:dayaa/features/internal_tickets/models/internal_ticket.dart';
import 'package:dayaa/features/internal_tickets/models/internal_ticket_query.dart';
import 'package:dayaa/features/internal_tickets/presentation/viewmodel/internal_tickets_cubit.dart';
import 'package:dayaa/features/internal_tickets/presentation/widgets/internal_ticket_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// تذاكرُ الموظفين — تبويبُ «الموظفين» في «التذاكر»، كقائمة بريمولا الداخلية.
///
/// * **للمدير وحده**: «تذاكري / الكل». غيرُه لا يرى إلا ما هو طرفٌ فيه — والخادمُ هو الحدّ.
/// * **البحث** بكود التذكرة أو عنوانها أو اسم الموظف.
/// * **الرقاقتان** «قيد المعالجة» (تُفتح عليها) و«مغلقة» — بلا «الكل»، كبريمولا — و«غير المقروءة».
/// * **من صفحة طلبيةٍ أو عميل** ([subject]): مقصورةٌ عليها بعنوانها، و«تذكرة جديدة» تحملها.
///
/// **بلا صلاحية**: كلُّ موظفٍ يفتح تذكرةً إلى زميل.
class InternalTicketsPage extends StatelessWidget {
  const InternalTicketsPage({this.embedded = false, this.subject, super.key});

  /// داخلَ تبويبات «التذاكر»: شريطُها فوقه، فلا شريطَ ثانياً هنا.
  final bool embedded;

  final InternalTicketSubject? subject;

  @override
  Widget build(BuildContext context) {
    final query = InternalTicketQuery(orderId: subject?.orderId, customerId: subject?.customerId);

    return BlocProvider<InternalTicketsCubit>(
      create: (_) => sl<InternalTicketsCubit>(param1: query)..load(),
      child: _InternalTicketsView(embedded: embedded, subject: subject),
    );
  }
}

class _InternalTicketsView extends StatelessWidget {
  const _InternalTicketsView({required this.embedded, required this.subject});

  final bool embedded;
  final InternalTicketSubject? subject;

  Future<void> _open(BuildContext context, InternalTicket ticket) async {
    final cubit = context.read<InternalTicketsCubit>();
    final updated = await context.push<InternalTicket>(Routes.internalTicket(ticket.id));

    // من الخادم نفسه — شارتُها مطفأة على الأقل — فلا طلبَ ولا ضياعَ لموضع التمرير.
    if (updated != null) cubit.absorb(updated);
  }

  Future<void> _new(BuildContext context) async {
    final cubit = context.read<InternalTicketsCubit>();
    await context.push<InternalTicket>(Routes.newInternalTicket, extra: subject);

    // تذكرةٌ فُتحت من هنا تظهر في رأس القائمة حين يعود إليها.
    unawaited(cubit.refresh());
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<InternalTicketsCubit>();
    final session = sl<Session>();
    final me = session.user?.id;
    // «الكل» للمدير، وما لم تكن القائمةُ مقصورةً على طلبيةٍ أو عميل — هناك القصرُ هو السؤال.
    final offersAll = session.isAdmin && subject == null;

    return Scaffold(
      appBar: embedded ? null : AppBar(title: Text(subject?.listTitle ?? 'تذاكر الموظفين')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'internal-tickets-new',
        onPressed: () => unawaited(_new(context)),
        icon: Icon(AppIcons.add),
        label: const Text('تذكرة جديدة'),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
              child: SearchField(hint: 'كود التذكرة · عنوانها · الموظف', onChanged: cubit.search),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 6.h),
              child: BlocBuilder<InternalTicketsCubit, InternalTicketsState>(
                builder: (context, state) {
                  final query = cubit.query;

                  return SizedBox(
                    height: 44.h,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        if (offersAll) ...[
                          _Chip(
                            label: 'تذاكري',
                            selected: !query.allTickets,
                            onTap: () => cubit.narrow(query.copyWith(allTickets: false)),
                          ),
                          _Chip(
                            label: 'الكل',
                            selected: query.allTickets,
                            onTap: () => cubit.narrow(query.copyWith(allTickets: true)),
                          ),
                          const VerticalDivider(width: 16),
                        ],
                        for (final status in const [
                          InternalTicketStatus.inProgress,
                          InternalTicketStatus.closed,
                        ])
                          _Chip(
                            label: status.label,
                            selected: query.status == status,
                            onTap: () => cubit.narrow(query.copyWith(status: status)),
                          ),
                        Padding(
                          padding: EdgeInsetsDirectional.only(end: 8.w),
                          child: Center(
                            child: FilterOptionChip(
                              label: 'غير المقروءة',
                              isTicked: true,
                              isSelected: query.unreadOnly,
                              onTap: () =>
                                  cubit.narrow(query.copyWith(unreadOnly: !query.unreadOnly)),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsetsDirectional.only(end: 8.w),
                          child: Center(
                            child: FilterOptionChip(
                              label: 'الأقدم نشاطاً',
                              isTicked: true,
                              isSelected: query.oldestFirst,
                              onTap: () =>
                                  cubit.narrow(query.copyWith(oldestFirst: !query.oldestFirst)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: BlocBuilder<InternalTicketsCubit, InternalTicketsState>(
                builder: (context, state) => PagedListView<InternalTicket>(
                  state: state,
                  onLoadMore: cubit.loadMore,
                  onRefresh: cubit.refresh,
                  emptyMessage: cubit.query.status == InternalTicketStatus.closed
                      ? 'لا توجد تذاكر مغلقة'
                      : 'لا توجد تذاكر مفتوحة',
                  // فسحةٌ فوق البطاقة الأولى لشارة غير المقروء، وتحت الأخيرة للزرّ العائم.
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 96.h),
                  itemBuilder: (context, ticket, index) => InternalTicketCard(
                    ticket: ticket,
                    me: me,
                    onOpen: () => unawaited(_open(context, ticket)),
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

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(end: 8.w),
      child: Center(
        child: FilterOptionChip(label: label, isSelected: selected, onTap: onTap),
      ),
    );
  }
}
