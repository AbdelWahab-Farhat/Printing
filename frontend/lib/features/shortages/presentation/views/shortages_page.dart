import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/router/pop_result.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
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
/// Down one column: the band — a search box and the filter button — المصدر, the assignment tabs,
/// and the rows.
///
/// **The status chips are gone, and that was a correction.** This opened with a scrolling status
/// row *and* a second row for the two queues: a hundred points of every screen spent saying
/// «الكل», «مكتمل» off the edge of a row nothing suggested continued, and two rows disagreeing
/// about which of them was «the» filter. The status went into the sheet, with the counts — the
/// one thing the row was good for.
///
/// **What came back out is الإسناد, as tabs.** «مَن يلاحق ماذا» turned out to be the question a
/// supervisor opens this screen to flip between — the unassigned queue is a pile of work and the
/// reader's own is their day — and a question asked that often is worth a tap rather than two and
/// an «تطبيق». Tabs and not a third chip row, because it is not a filter among filters: it is
/// which slice of the section you are standing in, and the app draws that distinction this way
/// already.
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
                        source: cubit.source,
                      ),
                      counts: counts,
                      onApplied: (picked) => cubit.applyFilters(
                        status: picked.status,
                        // Not the sheet's to answer any more — the tabs below own it, and
                        // sending anything else here would undo whichever one is open.
                        assignedTo: cubit.assignedTo,
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
          // **الإسناد, on the page and not in the sheet.** «مَن يلاحق ماذا» is what a supervisor
          // opens this screen to flip between — the unassigned queue is a pile of work, and the
          // reader's own is their day — and a question asked that often does not belong behind a
          // button, two taps and an «تطبيق» away.
          //
          // Tabs rather than a second row of chips: the row above is a filter and these are which
          // slice of the section you are standing in, and the app already draws that distinction
          // this way — see the deal screen. It also keeps the correction this list was built on:
          // two chip rows that disagreed about which of them was «the» filter.
          const _AssignmentTabs(),
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

/// الكل · مسندة · غير مسندة — the assignment axis, above the rows it narrows.
///
/// **No `TabBarView` under it.** There is one list and three questions about it, so the tabs set
/// the filter and the list below re-reads; three page views would be three copies of the same
/// screen holding three positions in three scrolls of the same table.
///
/// «مسندة» is the reader's own work, which the server knows only from the bearer token — hence
/// the word `me` rather than an id. «غير مسندة» is `none`: a queue somebody works from, not the
/// absence of an answer.
class _AssignmentTabs extends StatelessWidget {
  const _AssignmentTabs();

  static const _axis = [('الكل', null), ('مسندة', 'me'), ('غير مسندة', 'none')];

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ShortagesCubit>();
    final scheme = context.colorScheme;

    return DefaultTabController(
      length: _axis.length,
      initialIndex: _axis.indexWhere((tab) => tab.$2 == cubit.assignedTo).clamp(0, _axis.length - 1),
      child: TabBar(
        // Three short words fit the screen; a bar that scrolls hides its last tab from anybody
        // who never drags it.
        isScrollable: false,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: scheme.outlineVariant.withValues(alpha: 0.5),
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        labelStyle: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
        unselectedLabelStyle: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        onTap: (index) => cubit.showAssignment(_axis[index].$2),
        tabs: [for (final (label, _) in _axis) Tab(height: 44.h, text: label)],
      ),
    );
  }
}
