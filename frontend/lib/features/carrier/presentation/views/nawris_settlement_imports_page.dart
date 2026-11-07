import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/paged_list_view.dart';
import 'package:dayaa/features/carrier/models/nawris_settlement.dart';
import 'package:dayaa/features/carrier/presentation/viewmodel/nawris_settlement_imports_cubit.dart';
import 'package:dayaa/features/carrier/presentation/widgets/nawris_settlement_line_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// الدفعات السابقة: مَن سوّى ماذا، ومن أي ملف، وكم وصل.
class NawrisSettlementImportsPage extends StatelessWidget {
  const NawrisSettlementImportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NawrisSettlementImportsCubit>(
      create: (_) => sl<NawrisSettlementImportsCubit>()..load(),
      child: Scaffold(
        appBar: AppBar(title: const Text('دفعات تسوية النورس')),
        body: BlocBuilder<NawrisSettlementImportsCubit, PagedState<NawrisSettlementImport>>(
          builder: (context, state) {
            final cubit = context.read<NawrisSettlementImportsCubit>();

            return PagedListView<NawrisSettlementImport>(
              state: state,
              emptyMessage: 'لا دفعات بعد',
              onLoadMore: cubit.loadMore,
              onRefresh: cubit.refresh,
              padding: EdgeInsets.all(16.w),
              separatorBuilder: (_, _) => SizedBox(height: 8.h),
              itemBuilder: (context, batch, _) => _BatchTile(batch: batch),
            );
          },
        ),
      ),
    );
  }
}

class _BatchTile extends StatelessWidget {
  const _BatchTile({required this.batch});

  final NawrisSettlementImport batch;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;
    final summary = batch.summary;

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: () => context.push(Routes.nawrisSettlementImport(batch.id)),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(batch.fileName, style: text.titleSmall, overflow: TextOverflow.ellipsis),
              SizedBox(height: 4.h),
              Text(
                [
                  if (batch.createdAt case final at?) AppDates.day(at),
                  if (batch.importedBy case final person?) person.name,
                ].join(' · '),
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              SizedBox(height: 6.h),
              Text(
                [
                  'سُوّيت ${summary.settledCount.grouped}',
                  if (summary.leftOutCount > 0) 'تُركت ${summary.leftOutCount.grouped}',
                  'لم تتحرك ${summary.rejectedCount.grouped}',
                  'استُلم ${batch.receivedAmount.grouped} د.ل',
                ].join(' · '),
                style: text.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// دفعة بأسطرها: لماذا لم تتحرك هذه الطلبية؟
class NawrisSettlementImportPage extends StatelessWidget {
  const NawrisSettlementImportPage({required this.importId, super.key});

  final int importId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NawrisSettlementImportCubit>(
      create: (_) => sl<NawrisSettlementImportCubit>()..load(importId),
      child: Scaffold(
        appBar: AppBar(title: Text('دفعة النورس #$importId')),
        body: BlocBuilder<NawrisSettlementImportCubit, NawrisSettlementImportState>(
          builder: (context, state) => switch (state) {
            NawrisSettlementImportLoading() => const Center(child: CircularProgressIndicator()),
            NawrisSettlementImportFailure(:final failure) => Center(
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(failure.message, textAlign: TextAlign.center),
                    SizedBox(height: 12.h),
                    AppButton.tonal(
                      label: 'إعادة المحاولة',
                      onPressed: () => context.read<NawrisSettlementImportCubit>().load(importId),
                    ),
                  ],
                ),
              ),
            ),
            NawrisSettlementImportLoaded(:final batch) => _Lines(batch: batch),
          },
        ),
      ),
    );
  }
}

class _Lines extends StatelessWidget {
  const _Lines({required this.batch});

  final NawrisSettlementImport batch;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;

    return ListView.separated(
      padding: EdgeInsets.all(16.w),
      itemCount: batch.items.length + 1,
      separatorBuilder: (_, _) => SizedBox(height: 8.h),
      itemBuilder: (context, index) {
        if (index > 0) return NawrisSettlementLineTile(line: batch.items[index - 1]);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(batch.fileName, style: text.titleMedium),
            SizedBox(height: 6.h),
            Text('عند النورس ${batch.totalHeld.grouped} د.ل'),
            Text('المستلم ${batch.receivedAmount.grouped} د.ل'),
            if (batch.feeTotal.grouped != '0')
              Text('ما احتفظ به النورس ${batch.feeTotal.grouped} د.ل'),
            if (batch.differenceReason case final reason?) Text('السبب: $reason'),
          ],
        );
      },
    );
  }
}
