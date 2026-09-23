import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/widgets/paged_list_view.dart';
import 'package:dayaa/features/investment_fund/models/fund_breakdown.dart';
import 'package:dayaa/features/investment_fund/presentation/viewmodel/fund_cash_cubit.dart';
import 'package:dayaa/features/investment_fund/presentation/widgets/fund_cash_row.dart';
import 'package:dayaa/features/investment_fund/presentation/widgets/fund_detail_body.dart';
import 'package:dayaa/features/investment_fund/presentation/widgets/fund_total_card.dart';
import 'package:dayaa/features/warehouses/presentation/widgets/day_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// سجلُّ خزينة الصندوق — «من أين أتى هذا النقد»، داخلاً وخارجاً.
///
/// طلبُ المالك 2026-09-24: «النقد في الخزينة أريد سجلّ عملياته عند الضغط عليه، بحيث أعرف من أين
/// أتى — سجلٌّ كامل حتى للاستهلاك». فوق القائمة نقدُ اللوحة بعينه، وتحته كلُّ حركةٍ ما زالت قائمة:
/// الأحدثُ أوّلاً، مجموعةً باليوم، وبما بقي في الخزينة بعد كلٍّ منها.
///
/// **والرصيدُ من الخادم لا من جمع الصفحة.** الصفحةُ الأولى ثلاثون صفّاً من دفترٍ قد يطول سنة.
class FundCashPage extends StatelessWidget {
  const FundCashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FundCashCubit(getCash: sl())..load(),
      child: Scaffold(
        appBar: AppBar(title: const Text('سجل الخزينة')),
        body: BlocBuilder<FundCashCubit, FundCashState>(
          builder: (context, state) {
            final cubit = context.read<FundCashCubit>();
            final items = state is FundCashLoaded ? state.page.items : const <FundCashEntry>[];

            return Column(
              children: [
                if (fundCashBalanceOf(state) case final balance?)
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 4.h),
                    child: FundTotalCard(label: 'نقد في الخزينة', amount: balance),
                  ),
                Expanded(
                  child: PagedListView<FundCashEntry>(
                    state: state,
                    emptyMessage: 'لم تتحرّك الخزينة بعد',
                    onLoadMore: cubit.loadMore,
                    onRefresh: cubit.refresh,
                    skeletonHeight: 84.h,
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    separatorBuilder: (context, index) => const FundHairline(),
                    itemBuilder: (context, entry, index) => _groupedByDay(
                      items: items,
                      index: index,
                      entry: entry,
                      row: FundCashRow(
                        key: ValueKey(entry.id),
                        entry: entry,
                        onTap: _doorOf(context, entry),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// ما جاء منه المال، إن كان له بابٌ في التطبيق — والطلبيةُ أوّلاً لأنها أكثرُ ما يُسأل عنه.
  VoidCallback? _doorOf(BuildContext context, FundCashEntry entry) {
    final path = switch (entry) {
      FundCashEntry(:final orderId?) => Routes.order(orderId),
      FundCashEntry(:final purchaseOrderId?) => Routes.purchaseOrder(purchaseOrderId),
      FundCashEntry(:final investorId?) => Routes.investor(investorId),
      _ => null,
    };

    return path == null ? null : () => context.push(path);
  }
}

/// [row]، وفوقه ترويسةُ اليوم إن كان أوّلَ يومه. الصفوفُ الأحدثُ أوّلاً، فيتغيّر اليومُ حين يخالف
/// يومُ هذا الصفّ يومَ الذي فوقه — القاعدةُ نفسُها في سجلّ المخزن.
Widget _groupedByDay({
  required List<FundCashEntry> items,
  required int index,
  required FundCashEntry entry,
  required Widget row,
}) {
  final previous = index > 0 && index - 1 < items.length ? items[index - 1] : null;

  if (entry.occurredAt case final at? when startsNewDay(previous?.occurredAt, at)) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [DayHeader(at: at, first: index == 0), row],
    );
  }

  return row;
}
