import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/theme/app_tones.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/paged_list_view.dart';
import 'package:dayaa/features/warehouses/models/stock_group.dart';
import 'package:dayaa/features/warehouses/models/warehouse.dart';
import 'package:dayaa/features/warehouses/models/warehouse_stock.dart';
import 'package:dayaa/features/warehouses/presentation/viewmodel/stock_summary_cubit.dart';
import 'package:dayaa/features/warehouses/presentation/viewmodel/warehouse_stocks_cubit.dart';
import 'package:dayaa/features/warehouses/presentation/widgets/record_movement_sheet.dart';
import 'package:dayaa/features/warehouses/presentation/widgets/stock_material_card.dart';
import 'package:dayaa/features/warehouses/presentation/widgets/stock_row.dart';
import 'package:dayaa/features/warehouses/presentation/widgets/stock_summary_card.dart';
import 'package:dayaa/features/warehouses/presentation/widgets/threshold_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// What is on one warehouse's shelves.
///
/// **Nothing here writes a quantity**, and that is the context's whole rule: a balance moves
/// because a movement explains it, in the same transaction. So the button records a *movement*
/// and the list re-reads — the only field this screen edits is the level at which a shelf
/// starts asking to be refilled.
///
/// **Two Cubits, not one.** The list is a page and narrows with the filter; the card above it is
/// the whole warehouse and must not. Everything that moves stock refreshes both, in the one
/// place that knows both exist.
class WarehouseStocksPage extends StatelessWidget {
  const WarehouseStocksPage({required this.warehouseId, this.warehouse, super.key});

  final int warehouseId;

  /// Passed from the list so the bar can name the place without a second request; null on a
  /// cold deep link, where the heading stands alone.
  final Warehouse? warehouse;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<WarehouseStocksCubit>(
          create: (_) => sl<WarehouseStocksCubit>(param1: warehouseId)..load(),
        ),
        BlocProvider<StockSummaryCubit>(
          create: (_) => sl<StockSummaryCubit>(param1: warehouseId)..load(),
        ),
      ],
      child: _StocksView(warehouseId: warehouseId, warehouse: warehouse),
    );
  }
}

class _StocksView extends StatefulWidget {
  const _StocksView({required this.warehouseId, this.warehouse});

  final int warehouseId;
  final Warehouse? warehouse;

  @override
  State<_StocksView> createState() => _StocksViewState();
}

/// Stateful for one reason: it remembers whether a movement or an alert level was written here,
/// so `pop` can tell the warehouses list whether its counts are worth re-reading.
///
/// **A bool rather than the warehouse itself**, and this is the one screen where that is the
/// honest answer: the count on the row behind is the server's arithmetic over every shelf, and
/// this screen never holds it. So the list is told *that* it moved and re-reads once — instead
/// of re-reading after every visit, including the ones that only looked.
class _StocksViewState extends State<_StocksView> {
  bool _changed = false;

  int get warehouseId => widget.warehouseId;

  Warehouse? get warehouse => widget.warehouse;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<WarehouseStocksCubit>();
    final summary = context.read<StockSummaryCubit>();
    final canManage = sl<Session>().can(AppPermission.manageInventory);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // Always through here, so the back button and the app bar's arrow return the same thing.
        context.pop(_changed);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            children: [
              const Text('الأرصدة'),
              if (warehouse != null)
                Text(
                  warehouse!.name,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'سجل حركات هذا المخزن',
              onPressed: () => context.push(Routes.warehouseMovements(warehouseId)),
              icon: Icon(AppIcons.history),
            ),
          ],
        ),
        floatingActionButton: canManage
            ? FloatingActionButton.extended(
                heroTag: 'fab-warehouse-stocks',
                onPressed: () async {
                  final movement = await showRecordMovementSheet(
                    context: context,
                    warehouse: warehouse,
                  );

                  // Re-read rather than patch: the new balance is the server's answer, and this
                  // screen has no business computing one. The header is re-read with it — a
                  // movement is exactly the thing that changes both.
                  if (movement != null) {
                    _changed = true;
                    await cubit.refresh();
                    await summary.refresh();
                  }
                },
                icon: Icon(AppIcons.statusChange),
                label: const Text('تسجيل حركة'),
              )
            : null,
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
              child: BlocBuilder<StockSummaryCubit, StockSummaryState>(
                builder: (context, state) => switch (state) {
                  StockSummaryLoaded(:final summary) => StockSummaryCard(summary: summary),
                  // Nothing at all while it loads and nothing if it failed: the card is a header
                  // over a list that works without it, and a skeleton that becomes an error
                  // message is worse than a screen that simply starts at the shelves.
                  _ => const SizedBox.shrink(),
                },
              ),
            ),
            BlocBuilder<WarehouseStocksCubit, WarehouseStocksState>(
              builder: (context, state) =>
                  _ShelfFilter(selected: cubit.filter, onSelected: cubit.filterBy),
            ),
            Expanded(
              child: BlocBuilder<WarehouseStocksCubit, WarehouseStocksState>(
                builder: (context, state) => PagedListView<StockGroup>(
                  state: _grouped(state),
                  emptyMessage: switch (cubit.filter) {
                    StockShelfFilter.low => 'لا توجد مواد تحت حد التنبيه',
                    StockShelfFilter.out => 'لا توجد مادة نافدة',
                    StockShelfFilter.all => 'لا توجد أرصدة في هذا المخزن بعد',
                  },
                  onLoadMore: cubit.loadMore,
                  onRefresh: () async {
                    // Pulled together, because the reader pulled the screen and not the list.
                    await Future.wait([cubit.refresh(), summary.refresh()]);
                  },
                  // Between a lone shelf and a material held in four sizes — the list is a mix of
                  // both, and a skeleton the height of the shorter one jumps under every card.
                  skeletonHeight: 96.h,
                  itemBuilder: (context, group, index) {
                    // Everyone who may read the shelf may read its history; only a manager sets
                    // the level at which it starts asking to be refilled.
                    void openHistory(WarehouseStock stock) => context.push(
                      Routes.warehouseMovements(warehouseId),
                      extra: (warehouse: warehouse, stock: stock),
                    );

                    // One size is a row, as it always was: a heading naming a material above a
                    // single line repeating it is a card that says everything twice.
                    return group.isSingle
                        ? StockRow(
                            key: ValueKey(group.first.id),
                            stock: group.first,
                            onTap: () => openHistory(group.first),
                            onEditThreshold: canManage
                                ? () => _editThreshold(context, cubit, summary, group.first)
                                : null,
                          )
                        : StockMaterialCard(
                            key: ValueKey(group.key),
                            group: group,
                            onTapShelf: openHistory,
                            onEditThreshold: canManage
                                ? (stock) => _editThreshold(context, cubit, summary, stock)
                                : null,
                          );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The same page, read as materials instead of as shelves.
  ///
  /// **The Cubit still pages shelves**, because that is what the endpoint returns and what "the
  /// next page" means to it. Only the drawing groups, and only here: `meta` is carried through
  /// untouched, so a page that collapses into two cards still knows there is a third page
  /// behind it.
  PagedState<StockGroup> _grouped(WarehouseStocksState state) => switch (state) {
    PagedLoaded<WarehouseStock>(:final page, :final isLoadingMore, :final search) =>
      PagedState<StockGroup>.loaded(
        page: Paginated<StockGroup>(
          items: StockGroup.from(page.items),
          meta: page.meta,
          extraMeta: page.extraMeta,
        ),
        isLoadingMore: isLoadingMore,
        search: search,
      ),
    PagedFailure<WarehouseStock>(:final failure) => PagedState<StockGroup>.failure(failure),
    PagedLoading<WarehouseStock>() => const PagedState<StockGroup>.loading(),
    PagedInitial<WarehouseStock>() => const PagedState<StockGroup>.initial(),
  };

  Future<void> _editThreshold(
    BuildContext context,
    WarehouseStocksCubit cubit,
    StockSummaryCubit summary,
    WarehouseStock stock,
  ) async {
    final threshold = await showThresholdSheet(context: context, stock: stock);

    // Null is a dismissed sheet; an empty string is «لا تنبهني», which is a decision.
    if (threshold == null || !context.mounted) return;

    final failure = await cubit.setThreshold(stock, threshold);

    if (!context.mounted) return;

    if (failure != null) {
      context.showFailure(failure);

      return;
    }

    _changed = true;

    // The counts above move with it: a shelf that was «تحت الحد» a second ago may not be one now.
    await summary.refresh();

    if (!context.mounted) return;

    context.showSuccess(threshold.isEmpty ? 'تم إلغاء التنبيه' : 'تم تحديث حد التنبيه');
  }
}

/// «الكل», «تحت الحد» or «نافد» — the questions this screen is opened for on a busy morning.
///
/// The counts are **not** on these buttons. They are on the card above, which is where the
/// numbers live; a count repeated in two places is a count that will disagree with itself the
/// first time one of them is refreshed and the other is not.
class _ShelfFilter extends StatelessWidget {
  const _ShelfFilter({required this.selected, required this.onSelected});

  final StockShelfFilter selected;
  final ValueChanged<StockShelfFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 10.h),
      child: Row(
        children: [
          for (final (label, value) in const [
            ('الكل', StockShelfFilter.all),
            ('تحت الحد', StockShelfFilter.low),
            ('نافد', StockShelfFilter.out),
          ]) ...[
            ChoiceChip(
              label: Text(label),
              selected: selected == value,
              showCheckmark: false,
              onSelected: (_) => onSelected(value),
              backgroundColor: scheme.surfaceContainerLowest,
              // The same three colours the bar above is drawn in, so a chosen chip and its
              // segment are recognisably the same state rather than two coincidences.
              selectedColor: switch (value) {
                StockShelfFilter.all => scheme.primaryContainer,
                StockShelfFilter.low => scheme.warnContainer,
                StockShelfFilter.out => scheme.errorContainer,
              },
              labelStyle: context.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: selected != value
                    ? scheme.onSurfaceVariant
                    : switch (value) {
                        StockShelfFilter.all => scheme.onPrimaryContainer,
                        StockShelfFilter.low => scheme.onWarnContainer,
                        StockShelfFilter.out => scheme.onErrorContainer,
                      },
              ),
              side: BorderSide(
                color: selected == value ? Colors.transparent : scheme.outlineVariant,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
            SizedBox(width: 8.w),
          ],
        ],
      ),
    );
  }
}
