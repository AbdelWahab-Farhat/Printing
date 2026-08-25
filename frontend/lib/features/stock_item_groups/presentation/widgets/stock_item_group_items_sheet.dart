import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/features/stock_item_groups/models/stock_item_group.dart';
import 'package:dayaa/features/stock_item_groups/presentation/viewmodel/stock_item_group_items_cubit.dart';
import 'package:dayaa/features/stock_items/models/stock_item.dart' show StockItem;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// What a material actually contains: its sizes, smallest first.
///
/// **A sheet rather than a screen, and a single call rather than a page.** The sizes of a
/// material arrive only as `items[]` on `GET /stock-item-groups/{id}` — `/stock-items` cannot be
/// narrowed to a material, deliberately — so there is nothing to scroll toward and nothing to
/// search: what comes back is all of it, already ordered by width then height.
///
/// [group] is handed in so the header draws from the row that was tapped rather than from the
/// request. The material's name and unit are on screen while the sizes are still loading, and
/// stay on screen if the request fails.
Future<void> showStockItemGroupItemsSheet({
  required BuildContext context,
  required StockItemGroup group,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => BlocProvider<StockItemGroupItemsCubit>(
      create: (_) => sl<StockItemGroupItemsCubit>(param1: group.id)..load(),
      child: _StockItemGroupItems(group: group),
    ),
  );
}

class _StockItemGroupItems extends StatelessWidget {
  const _StockItemGroupItems({required this.group});

  final StockItemGroup group;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final cubit = context.read<StockItemGroupItemsCubit>();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (context, controller) => Column(
        children: [
          SizedBox(height: 8.h),
          Container(
            height: 4.h,
            width: 40.w,
            decoration: BoxDecoration(
              color: scheme.outlineVariant,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
            child: _Header(group: group),
          ),
          Expanded(
            child: BlocBuilder<StockItemGroupItemsCubit, StockItemGroupItemsState>(
              builder: (context, state) => switch (state) {
                StockItemGroupItemsInitial() ||
                StockItemGroupItemsLoading() => const Center(
                  child: CircularProgressIndicator(),
                ),
                StockItemGroupItemsFailure(:final failure) => _FailureView(
                  message: failure.message,
                  onRetry: cubit.load,
                ),
                // The freshly read material, not the row that was tapped: `items` exists only
                // on this response, and the counts on the tapped row may be a page old.
                StockItemGroupItemsLoaded(:final group) => _Items(
                  items: group.items,
                  controller: controller,
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// The material itself, and the one sentence that explains why the list underneath matters.
class _Header extends StatelessWidget {
  const _Header({required this.group});

  final StockItemGroup group;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          group.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 2.h),
        Text(
          // The server's own Arabic for the unit — «G3 · قطعة».
          '${group.code} · ${group.defaultUnitLabel}',
          style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        SizedBox(height: 8.h),
        Text(
          // Two products at one size share one of these rows, which is the entire reason the
          // material exists — and the reason nothing here names a product.
          'كل مقاس هنا رصيد واحد في المخازن، مهما بلغ عدد المنتجات التي تسحب منه. '
          'تغيير اسم المادة يُعيد تسمية هذه المقاسات كلها.',
          style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// The sizes, or the sentence that says why there are none.
class _Items extends StatelessWidget {
  const _Items({required this.items, required this.controller});

  final List<StockItem> items;

  /// The sheet's own controller. Handed to the list rather than left to its default, or the
  /// drag that resizes the sheet and the drag that scrolls it fight over the same gesture.
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
        child: Text(
          // Not «لا يوجد», because nothing is wrong: a material with no sizes is a material no
          // product has claimed yet, and the sizes appear by themselves when one does.
          'لا مقاسات تحت هذه المادة بعد. يُنشأ المقاس تلقائياً حين يختار منتج هذه المادة '
          'عند مقاس ما.',
          textAlign: TextAlign.center,
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.separated(
      controller: controller,
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 16.h),
      itemCount: items.length,
      separatorBuilder: (context, index) => SizedBox(height: 8.h),
      itemBuilder: (context, index) => _ItemRow(item: items[index]),
    );
  }
}

/// One shelf.
///
/// **The `display_name` is rendered exactly as it arrived** — «كيس شحن 25*35», composed by the
/// server out of the material's name and the size. Rebuilding it here would put a second
/// spelling of every shelf into the app, and the shortfall message an order is refused with
/// quotes the server's; two spellings of one pile is how somebody concludes there are two piles.
///
/// **No product named and no picture drawn**, which is not an omission. «كيس شحن سادة» and «كيس
/// شحن مطبوع» both draw on this row, so naming either would be picking one arbitrarily and
/// telling the storekeeper the wrong thing. The code and the display name are what identify it.
class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final StockItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 2.h),
          Text(
            // A size may be counted differently from its material's default — the material's
            // unit is only what it *started* with — so the shelf's own label is what is shown.
            [item.code, item.unitLabel, if (!item.isActive) 'موقوف'].join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// The server's own Arabic, with a way to ask again.
class _FailureView extends StatelessWidget {
  const _FailureView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.error, size: 40.sp, color: scheme.error),
            SizedBox(height: 16.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 20.h),
            AppButton.outlined(label: 'إعادة المحاولة', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
