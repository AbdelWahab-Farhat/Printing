import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/paged_list_view.dart';
import 'package:dayaa/core/widgets/search_field.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/orders_filter.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/filtered_orders_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// اختيارُ طلبيةٍ يُتحدّث عنها — أوّلُ من سأله «تذكرة جديدة» بين الموظفين (٢٠٢٦-١٠-٢٣).
///
/// **أخو [showCustomerPicker]** بشكله وسلوكه: ورقةٌ فيها بحثٌ وقائمة، والضغطةُ على الصف هي الجواب.
///
/// **ومع [customerId] لا يُعرض إلا طلبياتُ ذلك العميل**، كنموذج بريمولا: مَن سمّى العميلَ قبلها
/// يسأل عن واحدةٍ من طلبياته، فلا تُعطى قائمةٌ تخالفه. والقائمةُ هي «الطلبيات» نفسها، ببحثها.
///
/// Returns null when the user backs out.
Future<Order?> showOrderPicker({
  required BuildContext context,
  int? customerId,
  String title = 'أيّ طلبية؟',
}) {
  return showModalBottomSheet<Order>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (_) => BlocProvider<FilteredOrdersCubit>(
      create: (_) =>
          sl<FilteredOrdersCubit>(param1: OrdersFilter(title: title, customerId: customerId))
            ..load(),
      child: _OrderPicker(title: title),
    ),
  );
}

class _OrderPicker extends StatelessWidget {
  const _OrderPicker({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FilteredOrdersCubit>();
    final scheme = context.colorScheme;

    return FractionallySizedBox(
      heightFactor: 0.85,
      child: Column(
        children: [
          SizedBox(height: 12.h),
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: scheme.outlineVariant,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
            child: Text(
              title,
              style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
            child: SearchField(
              hint: 'رقم الطلبية · كود العميل · رقم الهاتف',
              onChanged: cubit.search,
            ),
          ),
          Expanded(
            child: BlocBuilder<FilteredOrdersCubit, FilteredOrdersState>(
              builder: (context, state) => PagedListView<Order>(
                state: state,
                emptyMessage: 'لا توجد طلبيات',
                onLoadMore: cubit.loadMore,
                onRefresh: cubit.refresh,
                skeletonHeight: 60.h,
                itemBuilder: (context, order, index) => ListTile(
                  title: Text(order.code),
                  subtitle: Text(
                    [?order.recipient, order.statusLabel].join(' · '),
                  ),
                  onTap: () => Navigator.of(context).pop(order),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
