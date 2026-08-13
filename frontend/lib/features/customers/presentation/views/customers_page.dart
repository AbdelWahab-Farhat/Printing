import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/core/di/injector.dart';
import 'package:printing/core/permissions/app_permission.dart';
import 'package:printing/core/router/app_router.dart';
import 'package:printing/core/session/session.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/core/widgets/paged_list_view.dart';
import 'package:printing/core/widgets/search_field.dart';
import 'package:printing/features/customers/models/customer.dart';
import 'package:printing/features/customers/models/customers_filter.dart';
import 'package:printing/features/customers/presentation/viewmodel/customers_cubit.dart';
import 'package:printing/features/customers/presentation/widgets/customer_card.dart';
import 'package:printing/features/customers/presentation/widgets/customers_filter_button.dart';

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
                skeletonHeight: 88.h,
                onLoadMore: cubit.loadMore,
                onRefresh: cubit.refresh,
                itemBuilder: (context, customer, index) => CustomerCard(
                  customer: customer,
                  // Reloaded on the way back: the detail screen can rename, deactivate or edit,
                  // and a list still showing the old row is a list nobody trusts.
                  onTap: () async {
                    await context.push(Routes.customer(customer.id));
                    await cubit.refresh();
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
        // Refreshes on the way back: a customer registered on that form belongs at the top of
        // this list without the user having to think about pulling down.
        onPressed: () async {
          await context.push(Routes.addCustomer);
          await cubit.refresh();
        },
        icon: Icon(AppIcons.addCustomer),
        label: const Text('عميل جديد'),
      ),
    );
  }
}
