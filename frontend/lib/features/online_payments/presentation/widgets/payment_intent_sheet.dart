import 'package:dartz/dartz.dart' show Either;
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/features/online_payments/models/online_payment_models.dart';
import 'package:dayaa/features/online_payments/presentation/widgets/payment_intent_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// تفاصيل محاولة شحن: المال (ما خُصم، والعمولة، وما وصل المحفظة)، والمراجع، والحالة — و«إعادة
/// التحقق» حين يقول الخادم إنها تجوز.
///
/// تُرسم من جديد بما عاد من «إعادة التحقق»، فيرى الموظف أثرها في مكانها.
Future<void> showPaymentIntentSheet({
  required BuildContext context,
  required PaymentIntent intent,
  required Future<Either<Failure, PaymentIntent>> Function(PaymentIntent intent) onRecheck,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _IntentSheet(intent: intent, onRecheck: onRecheck),
  );
}

class _IntentSheet extends StatefulWidget {
  const _IntentSheet({required this.intent, required this.onRecheck});

  final PaymentIntent intent;
  final Future<Either<Failure, PaymentIntent>> Function(PaymentIntent intent) onRecheck;

  @override
  State<_IntentSheet> createState() => _IntentSheetState();
}

class _IntentSheetState extends State<_IntentSheet> {
  late PaymentIntent _intent = widget.intent;
  bool _isChecking = false;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final intent = _intent;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 20.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Icon(statusIcon(intent.status), color: statusTone(context, intent.status)),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  intent.statusLabel,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: statusTone(context, intent.status),
                  ),
                ),
              ),
            ],
          ),
          if (intent.failureReason case final reason? when reason.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Text(reason, style: context.textTheme.bodyMedium?.copyWith(color: scheme.error)),
          ],
          SizedBox(height: 16.h),
          _Line('الزبون', [intent.customerName, intent.customerPhone].nonNulls.join(' · ')),
          _Line('الطريقة', intent.methodLabel),
          if (intent.orderId case final order?) _Line('اشحن وادفع', 'الطلبية #$order'),
          const Divider(),
          _Line('خُصم من الزبون', '${intent.grossAmount.grouped} د.ل'),
          _Line('العمولة على الزبون', '${intent.customerFee.grouped} د.ل'),
          _Line('يصل المحفظة', '${intent.netAmount.grouped} د.ل', strong: true),
          if (intent.providerFee case final fee?) _Line('أخذت EzonePay', '${fee.grouped} د.ل'),
          _Line('العمولة على', intent.feePayerLabel),
          const Divider(),
          _Line('مرجعنا', intent.reference),
          if (intent.providerTransactionId case final id?) _Line('رقم EzonePay', id),
          if (intent.otpAttempts > 0) _Line('محاولات الرمز', '${intent.otpAttempts}'),
          if (intent.createdAt case final at?) _Line('بدأت', at.stampLabel),
          if (intent.succeededAt case final at?) _Line('شُحنت', at.stampLabel),
          if (intent.status.isOpen)
            if (intent.expiresAt case final at?) _Line('تنتهي', at.stampLabel),
          if (intent.status == IntentStatus.needsReview) ...[
            SizedBox(height: 12.h),
            Text(
              'المبلغ الذي قالته EzonePay لا يطابق المحاولة — لم يُشحن شيء. راجع المعاملة في لوحة '
              'EzonePay قبل أي إجراء.',
              style: context.textTheme.bodySmall?.copyWith(color: scheme.error),
            ),
          ],
          if (intent.canRecheck) ...[
            SizedBox(height: 20.h),
            AppButton.tonal(
              label: 'إعادة التحقق من EzonePay',
              icon: AppIcons.refresh,
              isLoading: _isChecking,
              onPressed: _recheck,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _recheck() async {
    if (_isChecking) return;

    setState(() => _isChecking = true);

    final result = await widget.onRecheck(_intent);

    if (!mounted) return;

    setState(() => _isChecking = false);

    result.fold(context.showFailure, (fresh) {
      setState(() => _intent = fresh);
      context.showSuccess(fresh.statusLabel);
    });
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value, {this.strong = false});

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: context.textTheme.bodyMedium?.copyWith(color: context.colorScheme.onSurfaceVariant),
            ),
          ),
          SizedBox(width: 12.w),
          Flexible(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: context.textTheme.bodyMedium?.copyWith(fontWeight: strong ? FontWeight.w800 : FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
