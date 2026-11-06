import 'dart:async';

import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/filter_option_chip.dart';
import 'package:dayaa/core/widgets/paged_list_view.dart';
import 'package:dayaa/features/employee_wallet/models/employee_wallet_models.dart';
import 'package:dayaa/features/employee_wallet/presentation/viewmodel/employee_wallet_entries_cubit.dart';
import 'package:dayaa/features/employee_wallet/presentation/widgets/employee_wallet_entry_row.dart';
import 'package:dayaa/features/investment_fund/presentation/widgets/fund_detail_body.dart';
import 'package:dayaa/features/warehouses/presentation/widgets/day_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// زرُّ مدى الأيام في شريط الشاشة، كسجلّ محفظة العميل.
class EmployeeWalletRangeButton extends StatelessWidget {
  const EmployeeWalletRangeButton({super.key});

  Future<void> _pick(BuildContext context) async {
    final entries = context.read<EmployeeWalletEntriesCubit>();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: entries.from != null && entries.to != null
          ? DateTimeRange(start: entries.from!, end: entries.to!)
          : null,
    );

    if (picked == null) return;

    await entries.between(picked.start, picked.end);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'حسب التاريخ',
      icon: Icon(AppIcons.periods),
      onPressed: () => _pick(context),
    );
  }
}

/// الكلُّ ثم الأنواع — **تلتفّ ولا تُمرَّر**، كرقائق محفظة العميل: فلترٌ لا يُرى لا يُسأل. وتحتها
/// المدى المختار، يُزال من مكانه.
class EmployeeWalletFilters extends StatelessWidget {
  const EmployeeWalletFilters({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = context.read<EmployeeWalletEntriesCubit>();

    return BlocBuilder<EmployeeWalletEntriesCubit, EmployeeWalletEntriesState>(
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 6.h),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  for (final filter in EmployeeWalletEntryFilter.values)
                    FilterOptionChip(
                      label: filter.label,
                      isSelected: filter == entries.filter,
                      onTap: () => unawaited(entries.narrowTo(filter)),
                    ),
                ],
              ),
            ),
          ),
          if (entries.from case final from?)
            if (entries.to case final to?)
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 4.h),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: InputChip(
                    label: Text(AppDates.span(from, to)),
                    onDeleted: () => unawaited(entries.between(null, null)),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

/// السجلّ بأيامه. الأحدث أولاً، وما يُفعل بالسطر قرارُ الشاشة.
class EmployeeWalletEntryList extends StatelessWidget {
  const EmployeeWalletEntryList({
    required this.emptyMessage,
    required this.onRefresh,
    this.showEmployee = false,
    this.onOpen,
    this.onReverse,
    super.key,
  });

  /// حين لا فلتر ولا مدى — وإلا فهو سؤالٌ عاد فارغاً لا سجلٌّ فارغ.
  final String emptyMessage;
  final Future<void> Function() onRefresh;

  final bool showEmployee;
  final void Function(BuildContext context, EmployeeWalletEntry entry)? onOpen;
  final void Function(BuildContext context, EmployeeWalletEntry entry)? onReverse;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EmployeeWalletEntriesCubit>();

    return BlocBuilder<EmployeeWalletEntriesCubit, EmployeeWalletEntriesState>(
      builder: (context, state) {
        final items = state is PagedLoaded<EmployeeWalletEntry>
            ? state.page.items
            : const <EmployeeWalletEntry>[];

        return PagedListView<EmployeeWalletEntry>(
          state: state,
          emptyMessage: cubit.filter == EmployeeWalletEntryFilter.all && cubit.from == null
              ? emptyMessage
              : 'لا حركات تطابق هذا الفلتر',
          onLoadMore: cubit.loadMore,
          onRefresh: onRefresh,
          skeletonHeight: 96.h,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          separatorBuilder: (context, index) => const FundHairline(),
          itemBuilder: (context, entry, index) {
            final previous = index > 0 && index - 1 < items.length ? items[index - 1] : null;
            final row = EmployeeWalletEntryRow(
              key: ValueKey(entry.id),
              entry: entry,
              showEmployee: showEmployee,
              onTap: switch (onOpen) {
                final open? => () => open(context, entry),
                null => null,
              },
              onReverse: switch (onReverse) {
                final reverse? when entry.canReverse && !entry.isReversed => () =>
                    reverse(context, entry),
                _ => null,
              },
            );

            if (entry.occurredAt case final at? when startsNewDay(previous?.occurredAt, at)) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [DayHeader(at: at, first: index == 0), row],
              );
            }

            return row;
          },
        );
      },
    );
  }
}

/// أول قراءةٍ فشلت ولا شيء يُعرض — برسالة الخادم وزرّ إعادة المحاولة.
class EmployeeWalletFailedView extends StatelessWidget {
  const EmployeeWalletFailedView({required this.failure, required this.onRetry, super.key});

  final Failure failure;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(failure.message, textAlign: TextAlign.center),
            SizedBox(height: 16.h),
            AppButton.tonal(label: 'إعادة المحاولة', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
