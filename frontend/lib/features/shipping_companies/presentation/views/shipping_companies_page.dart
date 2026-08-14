import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/widgets/paged_list_view.dart';
import 'package:dayaa/core/widgets/search_field.dart';
import 'package:dayaa/features/shipping_companies/models/shipping_company.dart';
import 'package:dayaa/features/shipping_companies/presentation/viewmodel/shipping_companies_cubit.dart';
import 'package:dayaa/features/shipping_companies/presentation/widgets/shipping_company_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// The carriers we deal with.
///
/// Every company, including the ones we have stopped using: this list is the record, and an
/// order from last year still names one of them. What retirement changes is that a company stops
/// being offered when a parcel goes out, which is the picker's business rather than this one's.
class ShippingCompaniesPage extends StatelessWidget {
  const ShippingCompaniesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ShippingCompaniesCubit>(
      create: (_) => sl<ShippingCompaniesCubit>()..load(),
      child: const _ShippingCompaniesView(),
    );
  }
}

class _ShippingCompaniesView extends StatelessWidget {
  const _ShippingCompaniesView();

  Future<void> _open(BuildContext context, ShippingCompany? company) async {
    final cubit = context.read<ShippingCompaniesCubit>();

    final saved = await context.push<bool>(
      Routes.shippingCompanyForm,
      extra: company,
    );

    // Only when something actually changed: a refresh after a dismissed form is a request
    // nobody asked for, and it flickers the list under the user's thumb.
    if (saved ?? false) await cubit.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ShippingCompaniesCubit>();
    final mayManage = sl<Session>().can(AppPermission.manageShippingCompanies);

    return Scaffold(
      appBar: AppBar(title: const Text('شركات التوصيل')),
      // A ternary rather than a PermissionGate: an empty widget in this slot still shifts the
      // bottom inset, so the button has to be absent rather than invisible.
      floatingActionButton: mayManage
          ? FloatingActionButton.extended(
              // Unique per screen, because the shell keeps every tab alive in an IndexedStack:
              // two default-tagged FABs in one subtree is the «multiple heroes» assertion.
              heroTag: 'fab-shipping-companies',
              onPressed: () => _open(context, null),
              icon: Icon(AppIcons.add),
              label: const Text('شركة جديدة'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
            child: SearchField(
              hint: 'ابحث باسم الشركة أو رقمها',
              onChanged: cubit.search,
            ),
          ),
          Expanded(
            child: BlocBuilder<ShippingCompaniesCubit, ShippingCompaniesState>(
              builder: (context, state) => PagedListView<ShippingCompany>(
                state: state,
                emptyMessage: 'لم تُضف شركة توصيل بعد',
                onLoadMore: cubit.loadMore,
                onRefresh: cubit.refresh,
                skeletonHeight: 68.h,
                itemBuilder: (context, company, index) => ShippingCompanyCard(
                  key: ValueKey(company.id),
                  company: company,
                  onTap: mayManage ? () => _open(context, company) : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
