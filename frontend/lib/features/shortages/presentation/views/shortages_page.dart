import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/router/pop_result.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/widgets/filter_option_chip.dart';
import 'package:dayaa/core/widgets/paged_list_view.dart';
import 'package:dayaa/core/widgets/search_field.dart';
import 'package:dayaa/features/shortages/models/shortage.dart';
import 'package:dayaa/features/shortages/models/shortage_counts.dart';
import 'package:dayaa/features/shortages/models/shortages_filter.dart';
import 'package:dayaa/features/shortages/presentation/viewmodel/shortages_cubit.dart';
import 'package:dayaa/features/shortages/presentation/widgets/shortage_card.dart';
import 'package:dayaa/features/shortages/presentation/widgets/shortage_filter_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// النواقص — what the shop is short of, and the chase to get it.
///
/// Two blocks down one column: the band — a search box and the filter button — and the rows.
///
/// **The chips are gone, and that was a correction.** This opened with a scrolling status row
/// *and* a second row for the two queues: a hundred points of every screen spent saying «الكل»,
/// «مكتمل» off the edge of a row nothing suggested continued, and two rows disagreeing about
/// which of them was «the» filter. Everything they did is in the sheet now — status, assignment
/// and source, in one answer applied in one request — and the counts went in with the statuses,
/// which is the one thing the row was good for.
///
/// **Newest first, and completed rows are not buried.** Within a month of shipping «مكتمل» will
/// be most of the table, and a list that hid it would make the historical record reachable only
/// by filtering — the filter is what narrows it when somebody wants that.
class ShortagesPage extends StatelessWidget {
  const ShortagesPage({this.filter, super.key});

  /// A question settled before the screen opened — «نواقص الطلبية #1204», reached from that
  /// order. Null on the section's own door, where the list opens on everything.
  final ShortagesFilter? filter;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ShortagesCubit>(
      create: (_) => sl<ShortagesCubit>()..start(filter),
      child: _ShortagesView(title: filter?.title ?? 'النواقص'),
    );
  }
}

class _ShortagesView extends StatelessWidget {
  const _ShortagesView({required this.title});

  final String title;

  Future<void> _open(BuildContext context, Shortage shortage) async {
    final cubit = context.read<ShortagesCubit>();

    final changed = await context.pushForResult<Shortage>(
      Routes.shortage(shortage.id),
      extra: shortage,
    );

    // The row redraws from what came back — and drops out of the list when the change took it
    // out of the status on screen. Nothing is re-fetched: see `ShortagesCubit`.
    if (changed != null) cubit.replace(changed);
  }

  Future<void> _add(BuildContext context) async {
    final cubit = context.read<ShortagesCubit>();

    final saved = await context.push<Shortage>(Routes.shortageForm);

    if (saved != null) cubit.insert(saved);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ShortagesCubit>();
    final mayManage = sl<Session>().can(AppPermission.manageShortages);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      floatingActionButton: mayManage
          ? FloatingActionButton.extended(
              heroTag: 'fab-shortages',
              onPressed: () => _add(context),
              icon: Icon(AppIcons.add),
              label: const Text('نقص'),
            )
          : null,
      body: Column(
        children: [
          // The same band every list in this app opens with: a box to type in, and every way of
          // narrowing the list behind the round button beside it.
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
            child: Row(
              children: [
                Expanded(
                  child: SearchField(
                    // The server matches all three, so the hint says all three rather than
                    // leaving somebody to discover that an order's number works here.
                    hint: 'ابحث بالاسم أو رقم النقص أو رقم الطلبية',
                    onChanged: cubit.search,
                  ),
                ),
                SizedBox(width: 8.w),
                // Rebuilt from the cubit rather than from a field on this widget, so the
                // button's filled state and the list it describes cannot disagree.
                BlocBuilder<ShortagesCubit, ShortagesState>(
                  builder: (context, _) => ValueListenableBuilder<ShortageCounts>(
                    valueListenable: cubit.counts,
                    builder: (context, counts, _) => ShortageFilterButton(
                      selection: ShortageFilterSelection(
                        status: cubit.status,
                        assignedTo: cubit.assignedTo,
                        source: cubit.source,
                      ),
                      counts: counts,
                      onApplied: (picked) => cubit.applyFilters(
                        status: picked.status,
                        assignedTo: picked.assignedTo,
                        productId: cubit.productId,
                        source: picked.source,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // **المصدر, on the page rather than in the sheet.** It is the split somebody flips
          // between while reading — what the shop wants against what a customer is waiting on —
          // and two words wide; a question like that is worth a tap, not two.
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
            child: BlocBuilder<ShortagesCubit, ShortagesState>(
              builder: (context, _) => Row(
                children: [
                  for (final (label, value) in const [
                    ('الكل', null),
                    ('من طلبية', 'order'),
                    ('يدوي', 'manual'),
                  ]) ...[
                    FilterOptionChip(
                      label: label,
                      isSelected: cubit.source == value,
                      onTap: () => cubit.showSource(value),
                    ),
                    SizedBox(width: 8.w),
                  ],
                ],
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<ShortagesCubit, ShortagesState>(
              builder: (context, state) => PagedListView<Shortage>(
                state: state,
                // «لا توجد نواقص» about a *narrowed* list would say the section is empty when it
                // is the question that came back empty.
                emptyMessage: switch ((cubit.currentSearch, cubit.status, cubit.assignedTo)) {
                  (final search?, _, _) when search.isNotEmpty => 'لا توجد نواقص تطابق «$search»',
                  (_, _, 'me') => 'لا نواقص مسندة إليك',
                  (_, _, 'none') => 'كل النواقص مسندة إلى أحد',
                  (_, final status?, _) => 'لا توجد نواقص في «${status.label}»',
                  _ => 'لا توجد نواقص',
                },
                onLoadMore: cubit.loadMore,
                onRefresh: cubit.refresh,
                skeletonHeight: 112.h,
                itemBuilder: (context, shortage, index) => ShortageCard(
                  key: ValueKey(shortage.id),
                  shortage: shortage,
                  onTap: () => _open(context, shortage),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
