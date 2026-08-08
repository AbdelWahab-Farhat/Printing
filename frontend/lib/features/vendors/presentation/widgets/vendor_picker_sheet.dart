import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/di/injector.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/core/widgets/paged_list_view.dart';
import 'package:printing/core/widgets/search_field.dart';
import 'package:printing/features/vendors/models/vendor.dart';
import 'package:printing/features/vendors/presentation/viewmodel/vendors_cubit.dart';

/// Choosing who an order is raised against.
///
/// **Only the suppliers we still deal with.** The management screen lists every one of them,
/// because it is the record; this asks a narrower question, and a retired supplier is never the
/// answer to «من نشتري منه». The instance it resolves is registered for exactly that.
///
/// Returns null when the user backs out — an ordinary ending, reported nowhere.
Future<Vendor?> showVendorPicker({required BuildContext context}) {
  return showModalBottomSheet<Vendor>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (_) => BlocProvider<VendorsCubit>(
      create: (_) => sl<VendorsCubit>(instanceName: Injector.activeVendorsCubit)..load(),
      child: const _VendorPicker(),
    ),
  );
}

class _VendorPicker extends StatelessWidget {
  const _VendorPicker();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<VendorsCubit>();
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
              'اختيار المورد',
              style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
            child: SearchField(
              hint: 'ابحث بالاسم أو المسؤول أو الهاتف',
              onChanged: cubit.search,
            ),
          ),
          Expanded(
            child: BlocBuilder<VendorsCubit, VendorsState>(
              builder: (context, state) => PagedListView<Vendor>(
                state: state,
                // Named for the narrower question this list asks, so an empty sheet is not read
                // as «there are no suppliers» by somebody who has just added one and switched
                // it off.
                emptyMessage: 'لا يوجد مورد نتعامل معه حالياً',
                onLoadMore: cubit.loadMore,
                onRefresh: cubit.refresh,
                skeletonHeight: 60.h,
                itemBuilder: (context, vendor, index) => ListTile(
                  title: Text(vendor.name),
                  subtitle: Text(vendor.contactLine),
                  onTap: () => Navigator.of(context).pop(vendor),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
