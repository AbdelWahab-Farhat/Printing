import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/paged_list_view.dart';
import 'package:dayaa/core/widgets/search_field.dart';
import 'package:dayaa/features/warehouses/models/warehouse.dart';
import 'package:dayaa/features/warehouses/presentation/viewmodel/warehouses_cubit.dart';
import 'package:dayaa/features/warehouses/presentation/widgets/warehouse_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Which place — one end of a movement.
///
/// A sheet rather than a dropdown: a warehouse is picked by name from a searchable list, and
/// the same list is what the screen behind is already showing.
Future<Warehouse?> showWarehousePicker({required BuildContext context}) {
  return showModalBottomSheet<Warehouse>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => BlocProvider<WarehousesCubit>(
      create: (_) => sl<WarehousesCubit>()..load(),
      child: const _WarehousePicker(),
    ),
  );
}

class _WarehousePicker extends StatelessWidget {
  const _WarehousePicker();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<WarehousesCubit>();
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
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
            child: SearchField(hint: 'ابحث عن مخزن', onChanged: cubit.search),
          ),
          Expanded(
            child: BlocBuilder<WarehousesCubit, WarehousesState>(
              builder: (context, state) => PagedListView<Warehouse>(
                state: state,
                emptyMessage: 'لا توجد مخازن',
                onLoadMore: cubit.loadMore,
                onRefresh: cubit.refresh,
                skeletonHeight: 62.h,
                itemBuilder: (context, warehouse, index) => WarehouseCard(
                  key: ValueKey(warehouse.id),
                  warehouse: warehouse,
                  onTap: () => Navigator.of(context).pop(warehouse),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
