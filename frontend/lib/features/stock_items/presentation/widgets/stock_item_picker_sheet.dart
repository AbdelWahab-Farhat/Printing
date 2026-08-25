import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/filter_option_chip.dart';
import 'package:dayaa/core/widgets/paged_list_view.dart';
import 'package:dayaa/core/widgets/search_field.dart';
import 'package:dayaa/features/stock_items/models/stock_item.dart';
import 'package:dayaa/features/stock_items/presentation/viewmodel/stock_items_cubit.dart';
import 'package:dayaa/features/stock_items/presentation/widgets/stock_item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Which shelf — the picker every screen that moves, buys or books in stock now opens.
///
/// **It replaces the product-and-size picker.** A warehouse holds a stock item, not a product's
/// size: «كيس شحن سادة 25*35» and «كيس شحن مطبوع 25*35» draw on one pile, so asking «أي منتج؟»
/// then «أي مقاس؟» asked two questions to reach a thing that has one name. This asks once.
///
/// **[widthCm] and [heightCm] pre-narrow it, and are the whole reason this takes arguments.**
/// Opened from a 25*35 variant it offers the 25*35 shelves first, which is almost always the
/// right answer and saves a search. It is deliberately **not** a constraint: a 25*35 bag can
/// legitimately be cut from a wider sheet, so «كل المقاسات» sits at the top of the list and is
/// one tap. Opened with neither — from a purchase order line, say — it simply starts wide.
///
/// Only the shelves still offered are listed. Recording a movement against one somebody stopped
/// is how a balance nobody can explain appears; the management screen is where a stopped shelf is
/// found again.
///
/// It returns the [StockItem] itself rather than an id, because every caller needs the
/// `display_name` to show what was chosen — and rebuilding that string from the parts is exactly
/// what the server composes it to prevent.
Future<StockItem?> showStockItemPicker({
  required BuildContext context,
  int? widthCm,
  int? heightCm,
}) {
  return showModalBottomSheet<StockItem>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => BlocProvider<StockItemsCubit>(
      create: (_) => sl<StockItemsCubit>()..loadForSize(widthCm: widthCm, heightCm: heightCm),
      child: const _StockItemPicker(),
    ),
  );
}

class _StockItemPicker extends StatelessWidget {
  const _StockItemPicker();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<StockItemsCubit>();
    final scheme = context.colorScheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
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
            child: SearchField(
              // Named after what the server actually matches: `search` is an ILIKE on the
              // material's name — not the code, and not the composed display name — so somebody
              // typing «S7» here would conclude the shelf had been deleted.
              hint: 'ابحث باسم الصنف',
              onChanged: cubit.search,
            ),
          ),
          // Rebuilt with the list, so the size chip and the rows it produced can never disagree.
          BlocBuilder<StockItemsCubit, StockItemsState>(
            builder: (context, state) => _SizeNarrowing(
              widthCm: cubit.widthCm,
              heightCm: cubit.heightCm,
              onClear: cubit.clearSizeFilter,
            ),
          ),
          Expanded(
            child: BlocBuilder<StockItemsCubit, StockItemsState>(
              builder: (context, state) => PagedListView<StockItem>(
                state: state,
                emptyMessage: cubit.hasSizeFilter
                    ? 'لا يوجد صنف بهذا المقاس — جرّب «كل المقاسات»'
                    : 'لا توجد أصناف مخزنية',
                onLoadMore: cubit.loadMore,
                onRefresh: cubit.refresh,
                // One row measured: a 38 code tile with two lines beside it.
                skeletonHeight: 62.h,
                itemBuilder: (context, item, index) => StockItemCard(
                  key: ValueKey(item.id),
                  item: item,
                  onTap: () => Navigator.of(context).pop(item),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// What the list is narrowed to, and the way out of it.
///
/// Drawn only while a size is being filtered on: a chip reading «كل المقاسات» above an unfiltered
/// list would be a control that does nothing, and the sheet is already sharing the screen with a
/// keyboard.
class _SizeNarrowing extends StatelessWidget {
  const _SizeNarrowing({required this.widthCm, required this.heightCm, required this.onClear});

  final int? widthCm;
  final int? heightCm;
  final Future<void> Function() onClear;

  @override
  Widget build(BuildContext context) {
    if (widthCm == null && heightCm == null) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              // The size as the person picking it knows it — «25*35», or one half of it when
              // only one was given.
              'معروض مقاس ${[?widthCm, ?heightCm].join('*')} فقط',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          FilterOptionChip(label: 'كل المقاسات', isSelected: false, onTap: () => onClear()),
        ],
      ),
    );
  }
}
