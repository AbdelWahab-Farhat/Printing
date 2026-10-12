import 'dart:async';

import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/filter_option_chip.dart';
import 'package:dayaa/core/widgets/paged_list_view.dart';
import 'package:dayaa/core/widgets/search_field.dart';
import 'package:dayaa/features/investment_fund/presentation/widgets/fund_detail_body.dart';
import 'package:dayaa/features/investors/presentation/widgets/investor_money_tile.dart';
import 'package:dayaa/features/online_payments/models/online_payment_models.dart';
import 'package:dayaa/features/online_payments/presentation/viewmodel/online_payments_cubit.dart';
import 'package:dayaa/features/online_payments/presentation/widgets/ezone_payout_sheet.dart';
import 'package:dayaa/features/online_payments/presentation/widgets/payment_intent_row.dart';
import 'package:dayaa/features/online_payments/presentation/widgets/payment_intent_sheet.dart';
import 'package:dayaa/features/online_payments/usecases/online_payment_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// «المدفوعات الإلكترونية» — كل محاولة شحن محفظةٍ عبر EzonePay، الأحدث أولاً.
/// Docs/payments/CUSTOMER-WALLET.md §٥.
///
/// في رأسها رصيد «Ezone» — ما تحمله EzonePay للمحلّ — و«تحويل إلى المصرف» لمن يسجّل عمليات
/// الحسابات (الخطوة ٦). اللمسةُ تفتح المحاولة، و«إعادة التحقق» فيها.
class OnlinePaymentsPage extends StatelessWidget {
  const OnlinePaymentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OnlinePaymentsCubit>()..load(),
      child: const _PaymentsView(),
    );
  }
}

class _PaymentsView extends StatelessWidget {
  const _PaymentsView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnlinePaymentsCubit>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('المدفوعات الإلكترونية'),
        actions: [
          IconButton(
            tooltip: 'طرق الدفع وحدودها',
            icon: Icon(AppIcons.settings),
            onPressed: () => context.push(Routes.onlinePaymentMethods),
          ),
        ],
      ),
      body: Column(
        children: [
          BlocBuilder<OnlinePaymentsCubit, OnlinePaymentsState>(
            builder: (context, _) => _Header(enabled: cubit.enabled, ezoneBalance: cubit.ezoneBalance),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
            child: SearchField(hint: 'ابحث بالمرجع أو اسم الزبون أو هاتفه', onChanged: cubit.search),
          ),
          BlocBuilder<OnlinePaymentsCubit, OnlinePaymentsState>(
            builder: (context, _) => Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 4.h),
              child: Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  for (final filter in IntentFilter.values)
                    FilterOptionChip(
                      label: filter.label,
                      isSelected: cubit.filter == filter,
                      onTap: () => unawaited(cubit.narrowTo(filter)),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<OnlinePaymentsCubit, OnlinePaymentsState>(
              builder: (context, state) => PagedListView<PaymentIntent>(
                state: state,
                emptyMessage: 'لا محاولات شحن',
                onLoadMore: cubit.loadMore,
                onRefresh: cubit.refresh,
                skeletonHeight: 96.h,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                separatorBuilder: (context, index) => const FundHairline(),
                itemBuilder: (context, intent, index) => PaymentIntentRow(
                  key: ValueKey(intent.id),
                  intent: intent,
                  onTap: () => showPaymentIntentSheet(
                    context: context,
                    intent: intent,
                    onRecheck: cubit.recheck,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// رصيد «Ezone»، وهل الدفع الإلكتروني مفعّل، و«تحويل إلى المصرف».
class _Header extends StatelessWidget {
  const _Header({required this.enabled, required this.ezoneBalance});

  final bool? enabled;
  final String? ezoneBalance;

  @override
  Widget build(BuildContext context) {
    final balance = ezoneBalance;

    if (balance == null) return const SizedBox.shrink();

    final mayRecord = sl<Session>().can(AppPermission.recordTreasuryOperations);

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 4.h),
      child: InvestorMoneyTile(
        label: 'في Ezone',
        amount: balance,
        icon: AppIcons.mobileWallet,
        caption: enabled == true
            ? 'الدفع الإلكتروني مفعّل — ما شحنه الزبائن ولم يُحوَّل بعد إلى المصرف'
            : 'الدفع الإلكتروني مطفأ — لا يرى الزبائن زرّ الشحن',
        footer: mayRecord
            ? Padding(
                padding: EdgeInsets.only(top: 12.h),
                child: AppButton.tonal(
                  label: 'تحويل إلى المصرف',
                  icon: AppIcons.transfer,
                  height: 42.h,
                  onPressed: () => _payout(context, balance),
                ),
              )
            : null,
      ),
    );
  }

  Future<void> _payout(BuildContext context, String balance) async {
    final cubit = context.read<OnlinePaymentsCubit>();
    final payout = await showEzonePayoutSheet(
      context: context,
      ezoneBalance: balance,
      onSubmit: sl<RecordEzonePayout>().call,
    );

    if (payout == null || !context.mounted) return;

    context.showSuccess('تم تسجيل التحويل');
    await cubit.refresh();
  }
}
