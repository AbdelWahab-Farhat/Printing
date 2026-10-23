import 'dart:async';

import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/filter_option_chip.dart';
import 'package:dayaa/core/widgets/paged_list_view.dart';
import 'package:dayaa/core/widgets/search_field.dart';
import 'package:dayaa/features/internal_tickets/models/internal_ticket.dart';
import 'package:dayaa/features/internal_tickets/models/internal_ticket_query.dart';
import 'package:dayaa/features/internal_tickets/presentation/viewmodel/internal_tickets_cubit.dart';
import 'package:dayaa/features/internal_tickets/presentation/widgets/internal_ticket_card.dart';
import 'package:dayaa/features/internal_tickets/presentation/widgets/internal_tickets_filter_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// تذاكرُ الموظفين — كقائمة بريمولا الداخلية. تُفتح من «عرض كل التذاكر» على بطاقة الموظف في الرئيسية،
/// ومن «تذاكر الموظفين» في صفحتي الطلبية والعميل.
///
/// * **البحث** بكود التذكرة أو عنوانها أو اسم الموظف، وبجانبه زرُّ التصفية.
/// * **الرقاقتان وحدهما على الصفحة**: «قيد المعالجة» (تُفتح عليها) و«مغلقة» — بلا «الكل»، كبريمولا.
/// * **وفي ورقة التصفية الباقي** ([InternalTicketsFilterButton]): «تذاكري / الكل» للمدير وحده وتُفتح
///   على «تذاكري» — غيرُه لا يرى إلا ما هو طرفٌ فيه، والخادمُ هو الحدّ — و«غير المقروءة»، ونوعُ
///   المشكلة، والترتيب.
/// * **من صفحة طلبيةٍ أو عميل** ([subject]): مقصورةٌ عليها بعنوانها.
///
/// **والصفحةُ كلُّها تُمرَّر، بلا «تذكرة جديدة»** (طلبُ المالك ٢٠٢٦-١٠-٢٣): البحثُ والرقاقتان فوق
/// الصفوف ويمرّان معها، والتذكرةُ الجديدة من بطاقة الموظف في الرئيسية. ولم تعد تبويباً في
/// «التذاكر».
///
/// **بلا صلاحية**: كلُّ موظفٍ يرى ما هو طرفٌ فيه.
class InternalTicketsPage extends StatelessWidget {
  const InternalTicketsPage({this.subject, super.key});

  final InternalTicketSubject? subject;

  @override
  Widget build(BuildContext context) {
    final query = InternalTicketQuery(orderId: subject?.orderId, customerId: subject?.customerId);

    return BlocProvider<InternalTicketsCubit>(
      create: (_) => sl<InternalTicketsCubit>(param1: query)..load(),
      child: _InternalTicketsView(subject: subject),
    );
  }
}

class _InternalTicketsView extends StatelessWidget {
  const _InternalTicketsView({required this.subject});

  final InternalTicketSubject? subject;

  Future<void> _open(BuildContext context, InternalTicket ticket) async {
    final cubit = context.read<InternalTicketsCubit>();
    final updated = await context.push<InternalTicket>(Routes.internalTicket(ticket.id));

    // من الخادم نفسه — شارتُها مطفأة على الأقل — فلا طلبَ ولا ضياعَ لموضع التمرير.
    if (updated != null) cubit.absorb(updated);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<InternalTicketsCubit>();
    final me = sl<Session>().user?.id;

    return Scaffold(
      appBar: AppBar(title: Text(subject?.listTitle ?? 'تذاكر الموظفين')),
      body: SafeArea(
        top: false,
        child: BlocBuilder<InternalTicketsCubit, InternalTicketsState>(
          builder: (context, state) => PagedListView<InternalTicket>(
            state: state,
            // فوق الصفوف ويمرّ معها، ويعود مع أوّل تمريرٍ إلى الأعلى.
            header: _Header(subject: subject),
            onLoadMore: cubit.loadMore,
            onRefresh: cubit.refresh,
            emptyMessage: cubit.query.status == InternalTicketStatus.closed
                ? 'لا توجد تذاكر مغلقة'
                : 'لا توجد تذاكر مفتوحة',
            // فسحةٌ فوق البطاقة الأولى لشارة غير المقروء.
            padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 24.h),
            itemBuilder: (context, ticket, index) => InternalTicketCard(
              ticket: ticket,
              me: me,
              onOpen: () => unawaited(_open(context, ticket)),
            ),
          ),
        ),
      ),
    );
  }
}

/// البحثُ وزرُّ التصفية، ثم الرقاقتان.
class _Header extends StatelessWidget {
  const _Header({required this.subject});

  final InternalTicketSubject? subject;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<InternalTicketsCubit>();
    // «الكل» للمدير، وما لم تكن القائمةُ مقصورةً على طلبيةٍ أو عميل — هناك القصرُ هو السؤال.
    final offersAll = sl<Session>().isAdmin && subject == null;

    // خلفيةٌ من الصفحة: الرأسُ يطفو فوق الصفوف حين يعود.
    return ColoredBox(
      color: context.colorScheme.surface,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 6.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: SearchField(
                    hint: 'كود التذكرة · عنوانها · الموظف',
                    onChanged: cubit.search,
                  ),
                ),
                SizedBox(width: 10.w),
                // يُعاد رسمه مع القائمة، فما تقوله الورقةُ مختاراً لا يخالف ما على الشاشة.
                BlocBuilder<InternalTicketsCubit, InternalTicketsState>(
                  builder: (context, state) => InternalTicketsFilterButton(
                    query: cubit.query,
                    offersAll: offersAll,
                    onApplied: (next) => unawaited(cubit.narrow(next)),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            // الحالتان وحدهما على الصفحة — ما يُبدَّل بينه وهو يقرأ. والباقي في الورقة.
            BlocBuilder<InternalTicketsCubit, InternalTicketsState>(
              builder: (context, state) => Row(
                children: [
                  for (final status in const [
                    InternalTicketStatus.inProgress,
                    InternalTicketStatus.closed,
                  ])
                    Padding(
                      padding: EdgeInsetsDirectional.only(end: 8.w),
                      child: FilterOptionChip(
                        label: status.label,
                        isSelected: cubit.query.status == status,
                        onTap: () => cubit.narrow(cubit.query.copyWith(status: status)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
