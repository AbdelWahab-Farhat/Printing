import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/utils/fixed_point.dart';
import 'package:dayaa_client/core/widgets/app_button.dart';
import 'package:dayaa_client/core/widgets/app_card.dart';
import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:dayaa_client/features/orders/presentation/viewmodel/order_deposit_cubit.dart';
import 'package:dayaa_client/features/orders/presentation/widgets/deposit_chooser.dart';
import 'package:dayaa_client/features/orders/usecases/choose_order_deposit.dart';
import 'package:dayaa_client/features/wallet/presentation/viewmodel/wallet_balance_cubit.dart';
import 'package:dayaa_client/features/wallet/presentation/views/top_up_sheet.dart';
import 'package:dayaa_client/features/wallet/usecases/top_up_usecases.dart';
import 'package:dayaa_client/features/wallet/usecases/wallet_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// «قبلنا طلبيتك — ادفع العربون لنبدأ» على طلبيةٍ قبلها المتجر بعد المراجعة (صاحب العمل، 2026-10-19).
///
/// **لا يُرسم إلا حين يعرضه الخادم** ([CustomerOrderDetail.depositOffer]): «جديدة»، قُبلت من
/// «بانتظار المراجعة»، بلا عربونٍ ولا دفعة. لمسُه يفتح [showOrderDepositSheet]، وما يعود منه هو
/// الطلبية كما صارت — فتُقرأ الصفحة من جديد ([onChosen]).
class DepositOfferCard extends StatelessWidget {
  const DepositOfferCard({required this.order, required this.onChosen, super.key});

  final CustomerOrderDetail order;
  final Future<void> Function() onChosen;

  @override
  Widget build(BuildContext context) {
    final offer = order.depositOffer;
    if (offer == null) return const SizedBox.shrink();

    final scheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.only(top: 12.h),
      child: AppCard.accent(
        key: const ValueKey('deposit-offer-card'),
        padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(AppIcons.awaitingDeposit, size: 26.sp, color: scheme.primary),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'قبلنا طلبيتك — ادفع العربون لنبدأ',
                        style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'أقل عربون ${offer.minAmount!.asPlainNumber} د.ل — في المكتب أو من محفظتك',
                        style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            AppButton(
              label: 'اختر العربون',
              onPressed: () async {
                final message = await showOrderDepositSheet(context, order);

                if (message == null || !context.mounted) return;

                context.showSuccess(message);
                await onChosen();
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// الورقة نفسها: [DepositChooser] وزرّ الإرسال. تعود برسالة النجاح حين اختير العربون، و`null` حين
/// أُغلقت بلا شيء.
Future<String?> showOrderDepositSheet(BuildContext context, CustomerOrderDetail order) {
  final media = MediaQuery.of(context);
  final maxHeight = (media.size.height - media.padding.top - 12.h).clamp(420.0, media.size.height);

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    constraints: BoxConstraints(maxWidth: double.infinity, maxHeight: maxHeight),
    backgroundColor: context.colorScheme.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (_) => BlocProvider<OrderDepositCubit>(
      create: (_) => OrderDepositCubit(
        order: order,
        choose: sl<ChooseOrderDeposit>(),
        walletBalance: sl.isRegistered<GetWalletBalance>() ? sl<GetWalletBalance>() : null,
        topUpMethods: sl.isRegistered<GetTopUpMethods>() ? sl<GetTopUpMethods>() : null,
      )..load(),
      child: const _OrderDepositSheet(),
    ),
  );
}

class _OrderDepositSheet extends StatefulWidget {
  const _OrderDepositSheet();

  @override
  State<_OrderDepositSheet> createState() => _OrderDepositSheetState();
}

class _OrderDepositSheetState extends State<_OrderDepositSheet> {
  /// يملكه الورقة ويُتلفه هنا، لا من فتحها — انظر «Dispose controllers in the dialog».
  late final _amount = TextEditingController(text: context.read<OrderDepositCubit>().state.amount);

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _payFull() {
    final cubit = context.read<OrderDepositCubit>()..payFull();
    final amount = cubit.state.amount ?? '';

    _amount
      ..text = amount
      ..selection = TextSelection.collapsed(offset: amount.length);
  }

  /// **الإلكتروني أولاً، ثم الاختيار** — كالسلة: الشحن بمبلغ العربون مقفلاً، ولا يُرسل شيءٌ إلا حين
  /// يعود بنجاح.
  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final cubit = context.read<OrderDepositCubit>();
    final state = cubit.state;

    if (state case OrderDepositState(payment: CheckoutPayment.online, :final onlineMethodId?, :final amount?)) {
      final paid = await showTopUpSheet(
        context,
        args: TopUpArgs(methodId: onlineMethodId, amount: amount, lockAmount: true),
      );

      if (paid != true || !mounted) return;

      await cubit.toppedUp();

      if (!mounted) return;
    }

    final chosen = cubit.state;
    final order = await cubit.submit();

    if (order == null || !mounted) return;

    final atOffice = chosen.payment == CheckoutPayment.office;

    // الشريط العلوي يرسم الرصيد الجديد بعد الرجوع.
    if (!atOffice && sl.isRegistered<WalletBalanceCubit>()) {
      await sl<WalletBalanceCubit>().refresh();
    }

    if (!mounted) return;

    Navigator.of(context).pop(
      atOffice
          ? 'ادفع العربون ${chosen.amount} د.ل في المكتب لنبدأ العمل على طلبيتك'
          : 'دُفع العربون من محفظتك، ونبدأ العمل على طلبيتك',
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderDepositCubit, OrderDepositState>(
      builder: (context, state) {
        final cubit = context.read<OrderDepositCubit>();

        return Padding(
          padding: EdgeInsets.only(bottom: context.keyboardInset),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Text(
                  'ادفع العربون لنبدأ',
                  style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 8.h),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
                    children: [
                      DepositChooser(
                        offer: state.offer,
                        amount: _amount,
                        chosenAmount: state.amount,
                        amountError: state.amountError ?? state.amountServerError,
                        payment: state.payment,
                        onlineMethodId: state.onlineMethodId,
                        onlineMethods: state.onlineMethods,
                        walletBalance: state.walletBalance,
                        walletCovers: state.walletCovers,
                        serverError: state.otherServerError,
                        onAmountChanged: cubit.chooseAmount,
                        onPayFull: _payFull,
                        onPayment: cubit.choosePayment,
                        onOnline: cubit.chooseOnline,
                        onRefreshWallet: cubit.refreshWallet,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
                  child: AppButton(
                    label: switch (state.payment) {
                      CheckoutPayment.wallet => 'ادفع العربون',
                      // الدفع أولاً، والعربون يُسجَّل حين ينجح.
                      CheckoutPayment.online => 'ادفع العربون إلكترونياً',
                      CheckoutPayment.office || null => 'تأكيد العربون',
                    },
                    isLoading: state.isSubmitting,
                    onPressed: state.isReady ? _submit : null,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
