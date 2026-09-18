import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/paged_list_view.dart';
import 'package:dayaa/core/widgets/search_field.dart';
import 'package:dayaa/features/customers/models/customer.dart';
import 'package:dayaa/features/customers/presentation/viewmodel/customers_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Naming the customer something is being raised for — an order, or a design request.
///
/// **Asked before the form opens, never inside it.** `customer_id` is read on create and ignored
/// afterwards, so an order cannot change hands — which is why «طلبية جديدة» on a customer's own
/// screen names them by *being on that screen* and the form has no such field. The home shortcut
/// has no screen behind it to do that naming, so it asks here first and then opens the very same
/// route. What the form cannot name, it still cannot name wrongly.
///
/// **Only the customers still being sold to.** The العملاء tab is the record and lists everyone;
/// a deactivated customer is not an answer to «لمن هذه الطلبية», and `CreateOrder` refuses the
/// request in any case.
///
/// **[title] is the caller's, because the sheet does not know what it is naming somebody for.**
/// It opened on «لمن هذه الطلبية؟» from the design tickets screen, which is the wrong noun —
/// nothing is being sold there. The default is the older caller's question, so only the new one
/// has to say anything.
///
/// Returns null when the user backs out — an ordinary ending, reported nowhere.
Future<Customer?> showCustomerPicker({
  required BuildContext context,
  String title = 'لمن هذه الطلبية؟',
}) {
  return showModalBottomSheet<Customer>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (_) => BlocProvider<CustomersCubit>(
      create: (_) => sl<CustomersCubit>(instanceName: Injector.activeCustomersCubit)..load(),
      child: _CustomerPicker(title: title),
    ),
  );
}

class _CustomerPicker extends StatelessWidget {
  const _CustomerPicker({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CustomersCubit>();
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
              hint: 'ابحث بالاسم أو الكود أو الهاتف',
              onChanged: cubit.search,
            ),
          ),
          Expanded(
            child: BlocBuilder<CustomersCubit, CustomersState>(
              builder: (context, state) => PagedListView<Customer>(
                state: state,
                // Named for the narrower question this list asks, so an empty sheet is not read
                // as «there are no customers» by somebody who has just deactivated one.
                emptyMessage: 'لا يوجد عميل نتعامل معه حالياً',
                onLoadMore: cubit.loadMore,
                onRefresh: cubit.refresh,
                skeletonHeight: 60.h,
                itemBuilder: (context, customer, index) => ListTile(
                  title: Text(customer.name),
                  subtitle: Text(
                    '${customer.code} · ${customer.phone}',
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.right,
                  ),
                  onTap: () => Navigator.of(context).pop(customer),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
