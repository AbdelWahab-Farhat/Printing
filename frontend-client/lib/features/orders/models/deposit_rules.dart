import 'package:dayaa_client/core/utils/fixed_point.dart';
import 'package:dayaa_client/features/orders/models/basket_quote.dart';
import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:dayaa_client/features/wallet/models/online_top_up_models.dart';

/// قواعد العربون الذي يختاره العميل — **في مكانٍ واحد**، تقرؤها خطوة السلة وورقة الطلبية المقبولة
/// كلتاهما (صاحب العمل، 2026-10-19). الحدّان من الخادم ([DepositOffer])، والخادم يفحصهما ثانيةً.

/// رفض المبلغ قبل الإرسال: فارغ، أو بكسور، أو أقلّ من الأدنى، أو أكثر من الأعلى. `null` حين يصلح.
String? depositAmountError(DepositOffer offer, String? amount) {
  if (amount == null || amount.isEmpty) return 'اكتب قيمة العربون';

  // **بالدينار الكامل** (صاحب العمل، 2026-10-19): لا كسور في العربون.
  if (int.tryParse(amount) == null) return 'العربون بالدينار الكامل، بلا كسور';

  final value = thousandths(amount);

  if (value < thousandths(offer.minAmount!)) {
    return 'أقل عربون ${offer.minAmount!.asMoney} د.ل (${offer.minPercent}٪ من قيمة الطلبية)';
  }

  if (value > thousandths(offer.maxAmount!)) {
    return 'العربون لا يتجاوز قيمة الطلبية (${offer.maxAmount!.asMoney} د.ل)';
  }

  return null;
}

/// المحفظة تكفي [amount]. رصيدٌ لم يصل لا يكفي شيئاً.
bool walletCoversDeposit(String? balance, String? amount) =>
    balance != null &&
    amount != null &&
    amount.isNotEmpty &&
    thousandths(balance) >= thousandths(amount);

/// اختير الطريق، والمبلغ بين الحدّين، والمحفظة تكفي إن كانت هي، والطريقة الإلكترونية تتّسع للمبلغ إن
/// كانت هي.
bool depositChoiceIsReady({
  required DepositOffer offer,
  required CheckoutPayment? payment,
  required String? amount,
  required String? walletBalance,
  required TopUpMethod? onlineMethod,
}) {
  if (payment == null || depositAmountError(offer, amount) != null) return false;

  return switch (payment) {
    CheckoutPayment.office => true,
    CheckoutPayment.wallet => walletCoversDeposit(walletBalance, amount),
    CheckoutPayment.online => onlineMethod != null && onlineMethod.canFund(amount!),
  };
}
