import 'dart:async';

import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/orders/models/order_payment.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/order_payments_cubit.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_money_row.dart';
import 'package:dayaa/features/orders/presentation/widgets/receipt_viewer.dart';
import 'package:dayaa/features/orders/presentation/widgets/record_payment_sheet.dart';
import 'package:dayaa/features/orders/presentation/widgets/write_off_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// One order's money, on a screen of its own.
///
/// **A page rather than a section on the order.** It was a block under «الحساب» first, and it
/// did not survive the ledger getting long: an order paid in three instalments with a correction
/// among them is six rows, each carrying a method, a reference, a date and a name, and that is a
/// screen's worth of reading pushed under everything else the order says. Here the numbers are
/// at the top, the history fills the page, and the two ways of writing to it are buttons rather
/// than something to scroll past.
///
/// **Nothing is edited and nothing is deleted, here or anywhere.** The API has no such route: a
/// mistake is undone by writing a second entry beside the wrong one, and both stay on screen —
/// which is the whole reason this is a ledger and not a total that goes up and down.
///
/// Pops `true` when anything was written, so the order behind re-reads: `paid_amount` and the
/// three numbers in its header are the *order's* payload, not this one's.
class OrderPaymentsPage extends StatelessWidget {
  const OrderPaymentsPage({required this.orderId, required this.orderCode, super.key});

  final int orderId;

  /// What the order is called out loud. Passed in rather than fetched: this screen would
  /// otherwise load a whole order to put four characters in a title.
  final String orderCode;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrderPaymentsCubit>(
      create: (_) => sl<OrderPaymentsCubit>(param1: orderId)..load(),
      child: _OrderPaymentsView(orderCode: orderCode),
    );
  }
}

class _OrderPaymentsView extends StatefulWidget {
  const _OrderPaymentsView({required this.orderCode});

  final String orderCode;

  @override
  State<_OrderPaymentsView> createState() => _OrderPaymentsViewState();
}

class _OrderPaymentsViewState extends State<_OrderPaymentsView> {
  /// Whether anything was written. Screen lifecycle, not business state — the Cubit owns the
  /// ledger itself.
  bool _changed = false;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OrderPaymentsCubit>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // Always through here, so the back button and the app bar's arrow return the same thing.
        context.pop(_changed);
      },
      child: Scaffold(
        appBar: AppBar(title: Text('دفعات الطلبية #${widget.orderCode}')),
        body: BlocConsumer<OrderPaymentsCubit, OrderPaymentsState>(
          listener: (context, state) {
            // Only when there is still a ledger underneath: with nothing to fall back to, the
            // body already shows the failure and a snackbar would say it twice.
            if (state case OrderPaymentsFailure(:final failure)) {
              if (state.ledger != null) context.showFailure(failure);
            }
          },
          builder: (context, state) => switch (state) {
            OrderPaymentsLoading() => const Center(child: CircularProgressIndicator()),
            OrderPaymentsFailure(:final failure) when state.ledger == null => _FailureView(
              message: failure.message,
              onRetry: cubit.load,
            ),
            _ => RefreshIndicator(
              onRefresh: cubit.load,
              child: _Body(
                summary: state.summary!,
                payments: state.payments,
                isWorking: state.isWorking,
                onRecord: () => _write(PaymentDirection.incoming),
                onRefund: () => _write(PaymentDirection.outgoing),
                onWriteOff: _writeOff,
                onReverse: _reverse,
              ),
            ),
          },
        ),
      ),
    );
  }

  /// Opens the form, sends whatever it came back with, and reports what the server said.
  Future<void> _write(PaymentDirection direction) async {
    final cubit = context.read<OrderPaymentsCubit>();
    final summary = cubit.state.summary;
    if (summary == null) return;

    final draft = await showRecordPaymentSheet(
      context: context,
      direction: direction,
      remainingAmount: summary.remainingAmount,
      paidAmount: summary.paidAmount,
    );

    if (draft == null || !mounted) return;

    final failure = direction == PaymentDirection.incoming
        ? await cubit.record(
            amount: draft.amount,
            method: draft.method,
            reference: draft.reference,
            notes: draft.notes,
            receiptPath: draft.receipt?.path,
            receiptFilename: draft.receipt?.name,
          )
        : await cubit.refund(
            amount: draft.amount,
            method: draft.method,
            reference: draft.reference,
            notes: draft.notes,
            receiptPath: draft.receipt?.path,
            receiptFilename: draft.receipt?.name,
          );

    if (!mounted) return;

    if (failure != null) {
      context.showFailure(failure);

      return;
    }

    setState(() => _changed = true);
    context.showSuccess(
      direction == PaymentDirection.incoming ? 'تم تسجيل الدفعة' : 'تم تسجيل الردّ',
    );
  }

  /// Closes what is left of the debt without recording a payment.
  ///
  /// **The five dinars that never came back.** The order keeps its price, «المدفوع» keeps
  /// meaning cash, and «تم التسوية» stops being refused — see the server's `WriteOffOrderBalance`
  /// for why that is three separate facts and not one.
  Future<void> _writeOff() async {
    final cubit = context.read<OrderPaymentsCubit>();
    final summary = cubit.state.summary;
    if (summary == null) return;

    final draft = await showWriteOffDialog(context: context, summary: summary);

    if (draft == null || !mounted) return;

    final failure = await cubit.writeOff(amount: draft.amount, reason: draft.reason);

    if (!mounted) return;

    if (failure != null) {
      context.showFailure(failure);

      return;
    }

    setState(() => _changed = true);
    context.showSuccess('تم شطب الفرق');
  }

  /// Cancels an entry, behind a confirmation and a required reason.
  ///
  /// **Two steps rather than one, and neither is ceremony.** This is money coming back off an
  /// order, it cannot be undone by pressing the button again, and the sentence typed here is
  /// what the next person reads instead of guessing.
  Future<void> _reverse(OrderPayment payment) async {
    final cubit = context.read<OrderPaymentsCubit>();

    final reason = await _askForReason(payment);

    if (reason == null || !mounted) return;

    final failure = await cubit.reverse(payment.id, reason: reason);

    if (!mounted) return;

    if (failure != null) {
      context.showFailure(failure);

      return;
    }

    setState(() => _changed = true);
    context.showSuccess('تم إلغاء الدفعة');
  }

  Future<String?> _askForReason(OrderPayment payment) {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إلغاء الدفعة'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الدفعة تبقى في السجل مشطوبة، ويُكتب بجانبها قيدُ إلغائها — '
                'المبلغ ${payment.amount.grouped}.',
                style: dialogContext.textTheme.bodyMedium?.copyWith(
                  color: dialogContext.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 16.h),
              AppTextField(
                controller: controller,
                label: 'السبب',
                autofocus: true,
                maxLines: 2,
                validator: (value) => (value ?? '').trim().length < 3 ? 'السبب مطلوب' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('تراجع'),
          ),
          TextButton(
            onPressed: () {
              if (!(formKey.currentState?.validate() ?? false)) return;

              Navigator.of(dialogContext).pop(controller.text.trim());
            },
            child: Text('إلغاء الدفعة', style: TextStyle(color: dialogContext.colorScheme.error)),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.summary,
    required this.payments,
    required this.isWorking,
    required this.onRecord,
    required this.onRefund,
    required this.onWriteOff,
    required this.onReverse,
  });

  final PaymentSummary summary;
  final List<OrderPayment> payments;
  final bool isWorking;
  final Future<void> Function() onRecord;
  final Future<void> Function() onRefund;
  final Future<void> Function() onWriteOff;
  final Future<void> Function(OrderPayment payment) onReverse;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return ListView(
      // Scrollable even when short, so pull-to-refresh works on every state.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 32.h),
      children: [
        // The three numbers first, because they are what somebody opens this screen to check.
        _Card(child: OrderMoneyRow(summary: summary)),
        SizedBox(height: 16.h),

        _Actions(
          isWorking: isWorking,
          summary: summary,
          onRecord: onRecord,
          onRefund: onRefund,
          onWriteOff: onWriteOff,
        ),
        SizedBox(height: 16.h),

        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'السجل',
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 12.h),
              if (payments.isEmpty)
                Text(
                  'لم تُسجَّل أي دفعة على هذه الطلبية',
                  style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                )
              else
                for (final payment in payments)
                  _Entry(payment: payment, isBusy: isWorking, onReverse: () => onReverse(payment)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: child,
    );
  }
}

/// One entry in the ledger.
///
/// **A cancelled entry stays on screen, struck through, with its reason under it.** Hiding it
/// would make the ledger lie by omission: the row was written, somebody saw it, and the fact
/// that it was caught is the part worth reading.
class _Entry extends StatelessWidget {
  const _Entry({required this.payment, required this.isBusy, required this.onReverse});

  final OrderPayment payment;
  final bool isBusy;
  final VoidCallback onReverse;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    final decoration = payment.isVoid ? TextDecoration.lineThrough : null;
    final tone = switch (payment) {
      final p when p.isVoid => scheme.onSurfaceVariant,
      final p when p.isIncoming => scheme.primary,
      // Neutral, not the red of money leaving: a write-off closes a debt, and nothing left the
      // drawer for it. Painting it like a refund would put a cash event on screen that never
      // happened — the same confusion `paid_amount` is kept clean of.
      final p when p.isWriteOff => scheme.onSurfaceVariant,
      _ => scheme.error,
    };

    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_glyph(payment), size: 18.sp, color: tone),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      // The server's Arabic, so an entry type added after this release still
                      // reads correctly.
                      payment.typeLabel,
                      style: context.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        decoration: decoration,
                        color: payment.isVoid ? scheme.onSurfaceVariant : null,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      _subtitle(payment),
                      style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                // The sign is the direction, stated once and never stored: the API keeps every
                // amount positive precisely so a sum cannot be wrong by a stray minus.
                //
                // **A write-off carries no sign at all**, because it moved in neither direction.
                // A minus here would read as money going out to somebody scanning the column.
                payment.isWriteOff
                    ? payment.amount.grouped
                    : '${payment.isIncoming ? '+' : '−'} ${payment.amount.grouped}',
                style: context.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: tone,
                  decoration: decoration,
                ),
              ),
            ],
          ),

          if (payment.notes case final notes? when notes.isNotEmpty)
            Padding(
              padding: EdgeInsetsDirectional.only(start: 28.w, top: 4.h),
              child: Text(
                notes,
                style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),

          // Why it was cancelled, on the row it was cancelled from — so the struck-through
          // amount and its explanation are read together rather than paired up by eye.
          if (payment.reversal case final reversal?)
            Padding(
              padding: EdgeInsetsDirectional.only(start: 28.w, top: 4.h),
              child: Text(
                'أُلغيت: ${reversal.reason ?? 'بدون سبب'}',
                style: context.textTheme.bodySmall?.copyWith(
                  color: scheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

          Padding(
            padding: EdgeInsetsDirectional.only(start: 28.w, top: 6.h),
            child: Row(
              children: [
                if (payment.hasReceipt) _ReceiptChip(payment: payment),
                const Spacer(),
                // Only when the server says so. A refund and a reversal are never candidates,
                // and neither is an entry already cancelled — none of which this screen decides.
                if (payment.isReversible && sl<Session>().can(AppPermission.reverseOrderPayments))
                  TextButton.icon(
                    onPressed: isBusy ? null : onReverse,
                    icon: Icon(AppIcons.reversePayment, size: 16.sp),
                    // «القيد», not «الدفعة»: the same button now cancels a write-off, and
                    // calling that a payment would name the row wrongly on the one screen where
                    // the names are the point.
                    label: Text(payment.isWriteOff ? 'إلغاء القيد' : 'إلغاء الدفعة'),
                    style: TextButton.styleFrom(foregroundColor: scheme.error),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Which glyph the row wears.
  ///
  /// Three, for the three things a row can be: money in, money out, and money written off. The
  /// last is its own because it is neither of the other two — see [AppIcons.writeOff].
  IconData _glyph(OrderPayment payment) {
    if (payment.isWriteOff) return AppIcons.writeOff;

    return payment.isIncoming ? AppIcons.payment : AppIcons.refund;
  }

  /// The method, the reference, when the money moved and who took it — the four facts somebody
  /// checking a receipt reads together.
  String _subtitle(OrderPayment payment) {
    final parts = <String>[
      if (payment.methodLabel case final label? when label.isNotEmpty) label,
      if (payment.reference case final reference? when reference.isNotEmpty) reference,
      if (payment.paidAt case final paidAt?) _date(paidAt),
      if (payment.recordedBy case final recorder?) recorder.name,
    ];

    return parts.join(' · ');
  }

  String _date(DateTime value) => value.dayLabel;
}

/// «الواصل مرفق» — and pressing it shows the paper itself.
///
/// On most rows this is a fact to skim past; for the person checking a disputed transfer it is
/// the proof, so the fact opens it: an image full screen in the app, a PDF handed to the phone
/// — see [showReceipt]. Which glyph it wears is the server's `receipt_is_image` answer.
class _ReceiptChip extends StatelessWidget {
  const _ReceiptChip({required this.payment});

  final OrderPayment payment;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return InkWell(
      onTap: () => unawaited(showReceipt(context, payment)),
      borderRadius: BorderRadius.circular(999.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              payment.receiptIsImage ? AppIcons.photos : AppIcons.pdf,
              size: 14.sp,
              color: scheme.onSurfaceVariant,
            ),
            SizedBox(width: 6.w),
            Text(
              'الواصل مرفق',
              style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.isWorking,
    required this.summary,
    required this.onRecord,
    required this.onRefund,
    required this.onWriteOff,
  });

  final bool isWorking;
  final PaymentSummary summary;
  final Future<void> Function() onRecord;
  final Future<void> Function() onRefund;
  final Future<void> Function() onWriteOff;

  @override
  Widget build(BuildContext context) {
    final session = sl<Session>();
    final mayRecord = session.can(AppPermission.recordOrderPayments);
    // Offered only when there is something to give back. A refund on an order that has been
    // paid nothing is refused by the server, and a button that can only fail is worse than none.
    final mayRefund =
        session.can(AppPermission.reverseOrderPayments) && summary.paidAmount != '0.00';
    // And only when there is a debt to close. On an order that owes nothing the server refuses
    // it, and the button would be a door onto a 422.
    final mayWriteOff = session.can(AppPermission.writeOffOrderPayments) && summary.isOutstanding;

    // Nothing to offer, so nothing is drawn. A disabled row would advertise doors that open
    // onto a 403.
    if (!mayRecord && !mayRefund && !mayWriteOff) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (mayRecord || mayRefund)
          Row(
            children: [
              if (mayRecord)
                Expanded(
                  child: AppButton(
                    label: 'تسجيل دفعة',
                    icon: AppIcons.payment,
                    isLoading: isWorking,
                    height: 46.h,
                    onPressed: onRecord,
                  ),
                ),
              if (mayRecord && mayRefund) SizedBox(width: 10.w),
              if (mayRefund)
                Expanded(
                  child: AppButton.outlined(
                    label: 'ردّ مبلغ',
                    icon: AppIcons.refund,
                    isLoading: isWorking,
                    height: 46.h,
                    onPressed: onRefund,
                  ),
                ),
            ],
          ),

        // **On its own line, the full width of the screen**, rather than squeezed in as a third
        // Expanded beside the two above. It is the rarest of the three and the only one that
        // decides money will never arrive; three labels sharing one narrow row would shrink all
        // of them for it.
        if (mayWriteOff) ...[
          if (mayRecord || mayRefund) SizedBox(height: 10.h),
          AppButton.outlined(
            label: 'شطب الفرق',
            icon: AppIcons.writeOff,
            isLoading: isWorking,
            height: 46.h,
            onPressed: onWriteOff,
          ),
        ],
      ],
    );
  }
}

class _FailureView extends StatelessWidget {
  const _FailureView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.error, size: 48.sp, color: scheme.error),
            SizedBox(height: 16.h),
            Text(
              // The server's own Arabic: it usually says what to do about it.
              message,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
            ),
            SizedBox(height: 20.h),
            AppButton.tonal(label: 'إعادة المحاولة', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
