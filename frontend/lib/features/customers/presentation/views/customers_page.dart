import 'dart:async';

import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
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
/// A body, not a screen: the app bar and the tabs belong to the shell above it. What is left
/// here is the search box, the list, and the button that adds one — the three things this tab
/// is for. Everything about *paging* is in [PagedListView] and `PagedCubit`.
class CustomersPage extends StatelessWidget {
  const CustomersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CustomersCubit>(
      create: (_) => sl<CustomersCubit>()..load(),
      child: const _CustomersView(),
    );
  }
}

class _CustomersView extends StatefulWidget {
  const _CustomersView();

  @override
  State<_CustomersView> createState() => _CustomersViewState();
}

class _CustomersViewState extends State<_CustomersView> {
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

    return Scaffold(
      // Transparent: the shell's Scaffold underneath already paints the background, and a second
      // opaque one here would hide it.
      backgroundColor: Colors.transparent,
      body: Column(
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
      ),
      floatingActionButton: FloatingActionButton.extended(
                              // Unique per screen, because the shell keeps every tab alive in an IndexedStack:
                              // two default-tagged FABs in one subtree is the «multiple heroes» assertion.
                              heroTag: 'fab-customers',
        // The registered customer goes straight to the top of this list, out of what the form
        // handed back — where the user just put them, without a second reading of a page they
        // are already looking at.
        onPressed: () async {
          final created = await context.push<Customer>(Routes.addCustomer);
          if (created != null) cubit.insert(created);
        },
        icon: Icon(AppIcons.addCustomer),
        label: const Text('عميل جديد'),
      ),
    );
  }
}
