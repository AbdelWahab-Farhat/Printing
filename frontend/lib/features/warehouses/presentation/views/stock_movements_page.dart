import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/theme/app_tones.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/widgets/paged_list_view.dart';
import 'package:dayaa/features/warehouses/models/stock_batch.dart';
import 'package:dayaa/features/warehouses/models/stock_movement.dart';
import 'package:dayaa/features/warehouses/models/warehouse_stock.dart';
import 'package:dayaa/features/warehouses/presentation/viewmodel/stock_batches_cubit.dart';
import 'package:dayaa/features/warehouses/presentation/viewmodel/stock_movements_cubit.dart';
import 'package:dayaa/features/warehouses/presentation/views/record_movement_page.dart';
import 'package:dayaa/features/warehouses/presentation/widgets/day_header.dart';
import 'package:dayaa/features/warehouses/presentation/widgets/ledger_row.dart';
import 'package:dayaa/features/warehouses/presentation/widgets/movement_row.dart';
import 'package:dayaa/features/warehouses/presentation/widgets/stock_batch_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// The ledger, at one of three zoom levels: the whole workshop, one warehouse, or one shelf in
/// one warehouse.
///
/// **The last is a different screen.** With a [stock] in hand this is a storekeeper's paper
/// book for that shelf — every row signed, carrying the balance it left behind, grouped by
/// day, with a header that says what the shelf holds and (to a reader allowed to know) what it
/// is worth, and a second tab over the cost layers the next issue will draw from. Without one
/// it is the feed it always was, with the sign added.
class StockMovementsPage extends StatelessWidget {
  const StockMovementsPage({this.warehouseId, this.warehouseName, this.stock, super.key});

  final int? warehouseId;

  final String? warehouseName;

  final WarehouseStock? stock;

  @override
  Widget build(BuildContext context) {
    final shelf = stock;
    final warehouse = warehouseId;
    final showCost = shelf != null && warehouse != null && sl<Session>().can(AppPermission.viewStockCost);

    return MultiBlocProvider(
      providers: [
        BlocProvider<StockMovementsCubit>(
          create: (_) => sl<StockMovementsCubit>(param1: warehouseId, param2: shelf?.stockItemId)..load(),
        ),
        // The layers are only fetched for someone who may see them: they are money, and a
        // request whose answer is never drawn is a request that should not be made.
        if (showCost)
          BlocProvider<StockBatchesCubit>(
            create: (_) => sl<StockBatchesCubit>(
              param1: (warehouseId: warehouse, stockItemId: shelf.stockItemId),
              param2: true,
            )..load(),
          ),
      ],
      child: shelf != null && warehouse != null
          ? _ShelfLedgerView(
              stock: shelf,
              warehouseId: warehouse,
              warehouseName: warehouseName,
              showCost: showCost,
            )
          : _FeedView(warehouseName: warehouseName),
    );
  }
}

// ── the feed: the workshop, or one warehouse ────────────────────────────────────────────

class _FeedView extends StatelessWidget {
  const _FeedView({this.warehouseName});

  final String? warehouseName;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<StockMovementsCubit>();

    return Scaffold(
      appBar: AppBar(title: _Title(subtitle: warehouseName)),
      body: BlocBuilder<StockMovementsCubit, StockMovementsState>(
        builder: (context, state) {
          final items = state is StockMovementsLoaded ? state.page.items : const <StockMovement>[];

          // Read like the shelf's ledger below: grouped by day with a hairline between rows,
          // because the feed is the same book at a wider zoom and a list of cards had lost
          // the one thing a ledger is for — the order things happened in.
          return PagedListView<StockMovement>(
            state: state,
            emptyMessage: 'لا توجد حركات مسجّلة بعد',
            onLoadMore: cubit.loadMore,
            onRefresh: cubit.refresh,
            skeletonHeight: 84.h,
            separatorBuilder: (context, index) => const _Hairline(),
            itemBuilder: (context, movement, index) => _groupedByDay(
              items: items,
              index: index,
              movement: movement,
              row: MovementRow(
                key: ValueKey(movement.id),
                movement: movement,
                onOpenOrder: (id) => context.push(Routes.order(id)),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── the ledger: one shelf in one warehouse ──────────────────────────────────────────────

class _ShelfLedgerView extends StatefulWidget {
  const _ShelfLedgerView({
    required this.stock,
    required this.warehouseId,
    required this.showCost,
    this.warehouseName,
  });

  final WarehouseStock stock;
  final int warehouseId;
  final bool showCost;
  final String? warehouseName;

  @override
  State<_ShelfLedgerView> createState() => _ShelfLedgerViewState();
}

class _ShelfLedgerViewState extends State<_ShelfLedgerView>
    with SingleTickerProviderStateMixin {
  static const _segments = ['الحركات', 'الدفعات'];

  late final TabController _tabs = TabController(length: _segments.length, vsync: this)
    ..addListener(() {
      // The stack follows the bar, including the half-way point of a swipe — without this the
      // list would only change when the animation ended.
      if (_tabs.index != _segment) setState(() => _segment = _tabs.index);
    });

  var _segment = 0;

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = [widget.stock.title, ?widget.warehouseName].join(' · ');

    return Scaffold(
      appBar: AppBar(title: _Title(subtitle: subtitle)),
      // **Recording is done from where the shelf already is.** Opened here, the material and the
      // warehouse are settled — the page draws them as a heading and asks neither, which is the
      // one mistake a movement form cannot catch: a quantity written off the wrong pile.
      floatingActionButton: sl<Session>().can(AppPermission.manageInventory)
          ? FloatingActionButton.extended(
              heroTag: 'fab-shelf-ledger',
              onPressed: () async {
                final movement = await context.push<StockMovement>(
                  Routes.recordStockMovement,
                  extra: MovementContext(
                    stockItemId: widget.stock.stockItemId,
                    stockItemName: widget.stock.title,
                    warehouseId: widget.warehouseId,
                    warehouseName: widget.warehouseName ?? '',
                    unitLabel: widget.stock.unitLabel,
                  ),
                );

                if (movement != null && mounted) setState(() {});
              },
              icon: Icon(AppIcons.statusChange),
              label: const Text('تسجيل حركة'),
            )
          : null,
      body: Column(
        children: [
          _ShelfHeader(stock: widget.stock, showCost: widget.showCost),
          // **The registers' own bar**, so a switch between two lists reads the same here as it
          // does on «الجهات» — one shape for one gesture, rather than a pill on one screen and
          // an underline on the next.
          if (widget.showCost)
            TabBar(
              controller: _tabs,
              isScrollable: false,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: context.colorScheme.outlineVariant.withValues(alpha: 0.5),
              labelColor: context.colorScheme.primary,
              unselectedLabelColor: context.colorScheme.onSurfaceVariant,
              labelStyle: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
              unselectedLabelStyle: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              tabs: [for (final label in _segments) Tab(height: 44.h, text: label)],
            ),
          Expanded(
            // IndexedStack, so switching tabs keeps each list's scroll position and pages.
            child: IndexedStack(
              index: _segment,
              children: [
                _LedgerTab(
                  stock: widget.stock,
                  warehouseId: widget.warehouseId,
                  showCost: widget.showCost,
                ),
                if (widget.showCost)
                  _BatchesTab(warehouseId: widget.warehouseId, stockItemId: widget.stock.stockItemId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title({this.subtitle});

  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('سجل الحركات'),
        if (subtitle case final text? when text.isNotEmpty)
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.labelSmall?.copyWith(color: context.colorScheme.onSurfaceVariant),
          ),
      ],
    );
  }
}

/// The shelf: code, name, the balance as the one big number, and — for a reader who may know —
/// what it is worth and how many layers it is made of.
class _ShelfHeader extends StatelessWidget {
  const _ShelfHeader({required this.stock, required this.showCost});

  final WarehouseStock stock;
  final bool showCost;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 6.h),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16.r),
        ),
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (stock.code case final code?) ...[
                  Text(
                    code,
                    textDirection: TextDirection.ltr,
                    style: context.textTheme.titleMedium?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: 8.w),
                ],
                Flexible(
                  child: Text(
                    stock.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  'الرصيد',
                  style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
                SizedBox(width: 10.w),
                Text(
                  stock.quantityLabel,
                  textDirection: TextDirection.ltr,
                  style: context.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: stock.isOutOfStock
                        ? scheme.error
                        : stock.isLowStock
                        ? scheme.warn
                        : scheme.onSurface,
                  ),
                ),
                SizedBox(width: 6.w),
                Text(
                  stock.unitLabel,
                  style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
            if (showCost) _Valuation(unitLabel: stock.unitLabel),
          ],
        ),
      ),
    );
  }
}

/// «القيمة 1,050 د.ل · 3.500 د.ل/قطعة» and «دفعتان متبقيتان · الأقدم 31 أغسطس», read off the
/// remaining layers. The five states of INVENTORY-STOCK-SCREEN.md §٦.٢: nothing at all while
/// the layers load or fail (the balance above still works), a word for unpriced stock, and the
/// average dropped when any of it is unpriced.
class _Valuation extends StatelessWidget {
  const _Valuation({required this.unitLabel});

  final String unitLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return BlocBuilder<StockBatchesCubit, StockBatchesState>(
      builder: (context, state) {
        if (state is! StockBatchesLoaded) return const SizedBox.shrink();

        final valuation = ShelfValuation.of(state.page.items);
        if (valuation.isEmpty) return const SizedBox.shrink();

        final quiet = context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant);
        final warn = quiet?.copyWith(color: scheme.warn, fontWeight: FontWeight.w700);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 8.h),
            Row(
              children: [
                Text('القيمة', style: quiet),
                SizedBox(width: 8.w),
                Flexible(
                  child: valuation.isWhollyUncosted
                      ? Text('بلا تكلفة', style: warn)
                      : Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${groupedDecimal(valuation.totalValue)} د.ل',
                                style: quiet?.copyWith(
                                  color: scheme.onSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (valuation.averageUnitCost case final average?)
                                TextSpan(text: ' · ${groupedDecimal(average)} د.ل/$unitLabel')
                              else if (valuation.hasUncosted)
                                TextSpan(
                                  text: ' · ${groupedDecimal(valuation.uncostedQuantity)} $unitLabel بلا تكلفة',
                                  style: warn,
                                ),
                            ],
                          ),
                          style: quiet,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Text(_layers(valuation), style: quiet),
          ],
        );
      },
    );
  }

  /// «دفعة واحدة متبقية» / «دفعتان متبقيتان» / «3 دفعات متبقية», with the oldest one's date —
  /// because the oldest is what the next issue will be costed at.
  String _layers(ShelfValuation valuation) {
    final count = switch (valuation.layerCount) {
      1 => 'دفعة واحدة متبقية',
      2 => 'دفعتان متبقيتان',
      final n when n <= 10 => '$n دفعات متبقية',
      final n => '$n دفعة متبقية',
    };

    return [count, if (valuation.oldestReceivedAt case final at?) 'الأقدم ${at.shortDayLabel}'].join(' · ');
  }
}

/// The rows, grouped by day, with a hairline between them instead of card gaps.
class _LedgerTab extends StatelessWidget {
  const _LedgerTab({required this.stock, required this.warehouseId, required this.showCost});

  final WarehouseStock stock;
  final int warehouseId;
  final bool showCost;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<StockMovementsCubit>();

    return BlocBuilder<StockMovementsCubit, StockMovementsState>(
      builder: (context, state) {
        final items = state is StockMovementsLoaded ? state.page.items : const <StockMovement>[];

        return PagedListView<StockMovement>(
          state: state,
          emptyMessage: 'لا توجد حركات على هذه المادة بعد',
          onLoadMore: cubit.loadMore,
          onRefresh: cubit.refresh,
          skeletonHeight: 72.h,
          separatorBuilder: (context, index) => const _Hairline(),
          itemBuilder: (context, movement, index) {
            final row = LedgerRow(
              key: ValueKey(movement.id),
              movement: movement,
              warehouseId: warehouseId,
              unitLabel: stock.unitLabel,
              showCost: showCost,
            );

            return _groupedByDay(items: items, index: index, movement: movement, row: row);
          },
        );
      },
    );
  }
}

/// [row], with a day header above it when it is the first of its day. Rows are newest first,
/// so the day changes when this row's day differs from the one above it.
Widget _groupedByDay({
  required List<StockMovement> items,
  required int index,
  required StockMovement movement,
  required Widget row,
}) {
  final previous = index > 0 && index - 1 < items.length ? items[index - 1] : null;
  if (movement.createdAt case final at? when startsNewDay(previous?.createdAt, at)) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [DayHeader(at: at, first: index == 0), row],
    );
  }

  return row;
}

class _Hairline extends StatelessWidget {
  const _Hairline();

  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, thickness: 1, color: context.colorScheme.outlineVariant.withValues(alpha: 0.5));
}

/// The cost layers still on the shelf, in the order they will be drawn, and — behind a fold —
/// the ones already spent.
class _BatchesTab extends StatefulWidget {
  const _BatchesTab({required this.warehouseId, required this.stockItemId});

  final int warehouseId;
  final int stockItemId;

  @override
  State<_BatchesTab> createState() => _BatchesTabState();
}

class _BatchesTabState extends State<_BatchesTab> {
  var _showSpent = false;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<StockBatchesCubit>();

    return BlocBuilder<StockBatchesCubit, StockBatchesState>(
      builder: (context, state) => Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 4.h),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                'الدفعات المتبقية · تُصرف من الأقدم',
                style: context.textTheme.titleSmall?.copyWith(
                  color: context.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Expanded(
            child: PagedListView<StockBatch>(
              state: state,
              emptyMessage: 'لا توجد دفعات على هذا الرفّ',
              onLoadMore: cubit.loadMore,
              onRefresh: cubit.refresh,
              skeletonHeight: 72.h,
              separatorBuilder: (context, index) => const _Hairline(),
              itemBuilder: (context, batch, index) => StockBatchRow(
                key: ValueKey(batch.id),
                batch: batch,
                position: index + 1,
                isNext: index == 0,
              ),
            ),
          ),
          if (_showSpent)
            Expanded(
              child: BlocProvider<StockBatchesCubit>(
                create: (_) => sl<StockBatchesCubit>(
                  param1: (warehouseId: widget.warehouseId, stockItemId: widget.stockItemId),
                  param2: false,
                )..load(),
                child: const _SpentBatches(),
              ),
            )
          else
            SafeArea(
              top: false,
              child: TextButton(
                onPressed: () => setState(() => _showSpent = true),
                child: const Text('عرض الدفعات المستهلكة'),
              ),
            ),
        ],
      ),
    );
  }
}

class _SpentBatches extends StatelessWidget {
  const _SpentBatches();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<StockBatchesCubit>();

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 4.h),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              'الدفعات المستهلكة',
              style: context.textTheme.titleSmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        Expanded(
          child: BlocBuilder<StockBatchesCubit, StockBatchesState>(
            builder: (context, state) => PagedListView<StockBatch>(
              state: state,
              emptyMessage: 'لم تُستهلك أي دفعة بعد',
              onLoadMore: cubit.loadMore,
              onRefresh: cubit.refresh,
              skeletonHeight: 72.h,
              separatorBuilder: (context, index) => const _Hairline(),
              itemBuilder: (context, batch, index) =>
                  StockBatchRow(key: ValueKey(batch.id), batch: batch, position: index + 1),
            ),
          ),
        ),
      ],
    );
  }
}
