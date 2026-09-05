import 'dart:async';

import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/widgets/paged_list_view.dart';
import 'package:dayaa/core/widgets/search_field.dart';
import 'package:dayaa/features/customers/models/customer.dart';
import 'package:dayaa/features/customers/models/customers_filter.dart';
import 'package:dayaa/features/customers/presentation/viewmodel/customers_cubit.dart';
import 'package:dayaa/features/customers/presentation/widgets/customer_card.dart';
import 'package:dayaa/features/customers/presentation/widgets/customers_filter_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// العملاء — the customer list, searchable by name, code or phone.
///
/// **A body, not a screen.** The app bar, the tab it sits under and the button that adds one all
/// belong to [PartiesPage] above it — the three registers share one «إضافة» dial, so the button
/// cannot live on any one of them. What is left here is the search box and the list.
///
/// Its `CustomersCubit` is provided above too, for the same reason: the dial has to insert the
/// registered customer into *this* list, and a Cubit created inside the tab is out of its reach.
class CustomersBody extends StatefulWidget {
  const CustomersBody({super.key});

  @override
  State<CustomersBody> createState() => _CustomersBodyState();
}

class _CustomersBodyState extends State<CustomersBody> {
  /// The sheet's answers, held here rather than in the state the list emits.
  ///
  /// **Screen state, not list state.** `PagedState` is the answer to a question; this is the
  /// question, and it has to survive the skeleton that replaces the answer while the filtered
  /// page is in flight — the button must not flick back to neutral for the length of a request.
  /// The Cubit holds it too, because it is what the *request* is made of; this copy is what the
  /// button is drawn from.
  CustomersFilter _filter = CustomersFilter.none;

  /// Both filters are computed from the orders and the server refuses either with a 403 to a
  /// reader who may not see them — so the button is absent rather than disabled, the same way
  /// «إدارة الطلبات» is absent from the customer's own screen.
  final bool _maySeeOrders = sl<Session>().can(AppPermission.viewOrders);

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CustomersCubit>();

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
          child: Row(
            children: [
              Expanded(
                child: SearchField(
                  hint: 'ابحث بالاسم أو الكود أو الهاتف',
                  onChanged: cubit.search,
                ),
              ),
              if (_maySeeOrders) ...[
                SizedBox(width: 8.w),
                CustomersFilterButton(
                  filter: _filter,
                  onApplied: (filter) {
                    setState(() => _filter = filter);
                    unawaited(cubit.applyFilter(filter));
                  },
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: BlocBuilder<CustomersCubit, CustomersState>(
            builder: (context, state) => PagedListView<Customer>(
              state: state,
              // «لا يوجد عملاء بعد» about a *narrowed* list would say the register is empty
              // when it is the question that came back empty — and «لا أحد بلا طلبات» is good
              // news somebody should be told in those words.
              emptyMessage: _filter.isNarrowed
                  ? 'لا يوجد عملاء بهذه التصفية'
                  : 'لا يوجد عملاء بعد',
              skeletonHeight: 216.h,
              onLoadMore: cubit.loadMore,
              onRefresh: cubit.refresh,
              itemBuilder: (context, customer, index) => CustomerCard(
                key: ValueKey(customer.id),
                customer: customer,
                // The detail screen hands the customer back when it renamed, edited or
                // deactivated them, so the row redraws itself with no request — and nothing
                // happens at all when the screen was only read. Re-fetching page one instead
                // threw a scrolled list back to the top to redraw one card.
                onTap: () async {
                  final changed = await context.push<Customer>(Routes.customer(customer.id));
                  if (changed != null) cubit.replace(changed);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
