import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/core/di/injector.dart';
import 'package:printing/core/router/app_router.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/core/widgets/paged_list_view.dart';
import 'package:printing/core/widgets/search_field.dart';
import 'package:printing/features/customers/models/customer.dart';
import 'package:printing/features/customers/presentation/viewmodel/customers_cubit.dart';
import 'package:printing/features/customers/presentation/widgets/customer_card.dart';

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

class _CustomersView extends StatelessWidget {
  const _CustomersView();

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
            child: SearchField(hint: 'ابحث بالاسم أو الكود أو الهاتف', onChanged: cubit.search),
          ),
          Expanded(
            child: BlocBuilder<CustomersCubit, CustomersState>(
              builder: (context, state) => PagedListView<Customer>(
                state: state,
                emptyMessage: 'لا يوجد عملاء بعد',
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
