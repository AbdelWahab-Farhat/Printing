import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/paged_list_view.dart';
import 'package:dayaa/core/widgets/search_field.dart';
import 'package:dayaa/features/stock_item_groups/models/stock_item_group.dart';
import 'package:dayaa/features/stock_item_groups/presentation/viewmodel/stock_item_groups_cubit.dart';
import 'package:dayaa/features/stock_item_groups/presentation/widgets/stock_item_group_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Which material a product is cut from.
///
/// **This one choice is what files every size of the product onto a shelf.** On each save the
/// server walks the product's sizes and, for any without a shelf of its own, finds the size of
/// this material at those dimensions — creating it if it does not exist yet, with the material's
/// name and its default unit. Nobody points a size at a pile by hand any more, and the wrong tap
/// that used to split a heap in two is gone with it.
///
/// **Only the active materials are offered.** Filing a new size under a material the shop
/// stopped buying is a shelf nothing will ever arrive on.
///
/// It answers with the whole model. `features/stock_items/` asks for a
/// `({int id, String name, StockUnit defaultUnit})` record instead, and builds it from an answer
/// like this one in a line — that module imports nothing from this one on purpose, and a picker
/// that returned its record would reverse the dependency for no gain.
///
/// Returns null when the sheet was dismissed. There is deliberately **no «بلا مادة» row**: a
/// product's material cannot be cleared through `PUT /products` — omitting it keeps the current
/// one, and clearing it would detach every size from its shelf on that very save. Answering
/// «none» is a thing this picker cannot say, so it does not pretend to offer it.
Future<StockItemGroup?> showStockItemGroupPicker({required BuildContext context}) {
  return showModalBottomSheet<StockItemGroup>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => BlocProvider<StockItemGroupsCubit>(
      create: (_) => sl<StockItemGroupsCubit>()..loadActiveOnly(),
      child: const _StockItemGroupPicker(),
    ),
  );
}

class _StockItemGroupPicker extends StatelessWidget {
  const _StockItemGroupPicker();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<StockItemGroupsCubit>();
    final scheme = context.colorScheme;

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
          // No sentence over the list: the field that opened this sheet is already labelled
          // «المادة», and a picker that explains itself every time is one to scroll past.
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
            // «عن مادة», not «عن مجموعة»: the endpoint matches the name only — not the code and
            // not a size — so the box has to invite the one thing it can find.
            child: SearchField(hint: 'ابحث عن تصنيف', onChanged: cubit.search),
          ),
          Expanded(
            child: BlocBuilder<StockItemGroupsCubit, StockItemGroupsState>(
              builder: (context, state) => PagedListView<StockItemGroup>(
                state: state,
                emptyMessage: 'لا توجد تصنيفات مفعّلة',
                onLoadMore: cubit.loadMore,
                onRefresh: cubit.refresh,
                // One row measured: a 38 tile with two lines beside it.
                skeletonHeight: 62.h,
                itemBuilder: (context, group, index) => StockItemGroupCard(
                  key: ValueKey(group.id),
                  group: group,
                  onTap: () => Navigator.of(context).pop(group),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
