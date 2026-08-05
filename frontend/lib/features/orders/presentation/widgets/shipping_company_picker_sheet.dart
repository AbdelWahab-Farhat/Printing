import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/di/injector.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/core/widgets/paged_list_view.dart';
import 'package:printing/core/widgets/search_field.dart';
import 'package:printing/features/shipping_companies/models/shipping_company.dart';
import 'package:printing/features/shipping_companies/presentation/viewmodel/shipping_companies_cubit.dart';

/// Choosing who takes the parcel.
///
/// **Only the carriers still in use.** A company we stopped dealing with is never the answer to
/// «من سيأخذها», and the server refuses one anyway — so offering it would be a tap that ends in
/// a 422.
///
/// Returns the chosen company, or null when the sheet is dismissed.
Future<ShippingCompany?> showShippingCompanyPicker({
  required BuildContext context,
  ShippingCompany? selected,
}) {
  return showModalBottomSheet<ShippingCompany>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => BlocProvider<ShippingCompaniesCubit>(
      create: (_) => sl<ShippingCompaniesCubit>(instanceName: 'active-only')..load(),
      child: _ShippingCompanyPicker(selected: selected),
    ),
  );
}

class _ShippingCompanyPicker extends StatelessWidget {
  const _ShippingCompanyPicker({this.selected});

  final ShippingCompany? selected;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ShippingCompaniesCubit>();
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
              'اختيار شركة التوصيل',
              style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
            child: SearchField(hint: 'ابحث باسم الشركة', onChanged: cubit.search),
          ),
          Expanded(
            child: BlocBuilder<ShippingCompaniesCubit, ShippingCompaniesState>(
              builder: (context, state) => PagedListView<ShippingCompany>(
                state: state,
                // Said plainly rather than as an empty list: somebody has to add one before a
                // parcel can go out, and this is where they find that out.
                emptyMessage: 'لا توجد شركة توصيل مفعّلة — أضفها من «شركات التوصيل»',
                onLoadMore: cubit.loadMore,
                onRefresh: cubit.refresh,
                skeletonHeight: 60.h,
                itemBuilder: (context, company, index) => ListTile(
                  title: Text(company.name),
                  subtitle: Text(company.subtitle),
                  trailing: company.id == selected?.id
                      ? Icon(Icons.check_rounded, color: scheme.primary)
                      : null,
                  onTap: () => Navigator.of(context).pop(company),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
