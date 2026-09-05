import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/paged_list_view.dart';
import 'package:dayaa/core/widgets/search_field.dart';
import 'package:dayaa/features/investors/models/investor.dart';
import 'package:dayaa/features/investors/presentation/viewmodel/investors_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Which investor — one partner in a deal.
///
/// A sheet rather than a dropdown, and the same one the list screen draws: the register grows,
/// and a picker that had loaded the first hundred would quietly stop offering the hundred and
/// first. Searching and paging are the list's own, so there is one behaviour to keep right.
Future<Investor?> showInvestorPicker({required BuildContext context}) {
  return showModalBottomSheet<Investor>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => BlocProvider<InvestorsCubit>(
      // Active only: a stopped investor is somebody the business is not taking money from, and
      // offering him for a new deal is offering a refusal. `filter` loads page one itself.
      create: (_) => sl<InvestorsCubit>()..filter(isActive: true),
      child: const _InvestorPicker(),
    ),
  );
}

class _InvestorPicker extends StatelessWidget {
  const _InvestorPicker();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<InvestorsCubit>();
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
            child: SearchField(
              hint: 'ابحث بالاسم أو الرمز أو الهاتف',
              onChanged: cubit.search,
            ),
          ),
          Expanded(
            child: BlocBuilder<InvestorsCubit, PagedState<Investor>>(
              builder: (context, state) => PagedListView<Investor>(
                state: state,
                emptyMessage: 'لا يوجد مستثمرون',
                onLoadMore: cubit.loadMore,
                onRefresh: cubit.refresh,
                skeletonHeight: 60.h,
                // A plain row rather than [InvestorCard], the same way the suppliers' picker
                // does it: a register card is 216 tall, and a picker asking for one name out of
                // a list should show as many of them at once as it can.
                itemBuilder: (context, investor, index) => ListTile(
                  key: ValueKey(investor.id),
                  title: Text(investor.name),
                  subtitle: Text(investor.code, textDirection: TextDirection.ltr),
                  onTap: () => Navigator.of(context).pop(investor),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
