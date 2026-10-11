import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/utils/fixed_point.dart';
import 'package:dayaa_client/core/utils/uuid.dart';
import 'package:dayaa_client/core/widgets/app_button.dart';
import 'package:dayaa_client/core/widgets/app_card.dart';
import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:dayaa_client/features/wallet/usecases/wallet_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// «ادفع من المحفظة» تحت مال الطلبية — Docs/payments/CUSTOMER-WALLET.md.
///
/// **لا يُرسم إلا حين ينفع**: في المحفظة مال، وعلى الطلبية متبقٍّ، والمتجر قبلها وسعّرها. ما سواه
/// زرٌّ يرفضه الخادم، والزرّ الذي لا يفعل إلا الفشل أسوأ من غيابه.
///
/// يقرأ الرصيد بنفسه، بلا Cubit — كـ«حسابي»: رقمٌ واحد لا يتغيّر إلا بالدفع من هنا. والدفعُ
/// بأكثر ما يسمح به الاثنان، بعد تأكيدٍ يقول المبلغ؛ ثم تُقرأ الطلبية من جديد ([onPaid]).
class PayFromWalletCard extends StatefulWidget {
  const PayFromWalletCard({required this.order, required this.onPaid, super.key});

  final CustomerOrderDetail order;

  /// يقرأ الطلبية من جديد: المدفوع والمتبقي — وربما مرحلتها، إن كان هذا عربونها.
  final Future<void> Function() onPaid;

  @override
  State<PayFromWalletCard> createState() => _PayFromWalletCardState();
}

class _PayFromWalletCardState extends State<PayFromWalletCard> {
  String? _balance;
  bool _isPaying = false;

  /// **مفتاحُ هذا الدفع حتى ينجح.** اتصالٌ انقطع بعد أن دفع الخادمُ يُعاد بالمفتاح نفسه، فيجيب
  /// الخادمُ بالدفعة الأولى ولا يدفع ثانية. ولا يُترك إلا بعد دفعٍ نجح.
  String? _token;

  @override
  void initState() {
    super.initState();
    _read();
  }

  Future<void> _read() async {
    final result = await sl<GetWalletBalance>()();

    if (!mounted) return;

    result.fold((_) {}, (balance) => setState(() => _balance = balance));
  }

  /// هل في الطلبية ما يُدفع من المحفظة الآن.
  bool get _orderTakesPayment {
    final order = widget.order;
    final owed = order.balance;

    return order.isOpen &&
        !order.isAwaitingQuote &&
        order.stage != OrderStage.underReview &&
        order.stage != OrderStage.rejected &&
        order.stage != OrderStage.cancelled &&
        owed != null &&
        thousandths(owed) > BigInt.zero;
  }

  /// الأصغر من الرصيد والمتبقي — ما سيُدفع.
  String get _amount {
    final balance = _balance!;
    final owed = widget.order.balance!;

    return thousandths(balance) <= thousandths(owed) ? balance : owed;
  }

  Future<void> _pay() async {
    final amount = _amount;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('الدفع من المحفظة'),
        content: Text('يُدفع ${amount.asMoney} د.ل من محفظتك لهذه الطلبية.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('تراجع')),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('ادفع')),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isPaying = true);

    // بلا مبلغ: الخادم يأخذ أكثر ما يسمح به الاثنان ساعتَها — رصيدٌ تغيّر منذ قُرئ لا يُرفض.
    final token = _token ??= uuidV4();
    final result = await sl<PayOrderFromWallet>()(widget.order.id, clientToken: token);

    if (!mounted) return;

    await result.fold(
      (failure) async {
        setState(() => _isPaying = false);
        context.showFailure(failure);
      },
      (balance) async {
        setState(() {
          _isPaying = false;
          _balance = balance;
          _token = null;
        });
        context.showSuccess('تم الدفع من المحفظة');
        await widget.onPaid();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final balance = _balance;

    if (balance == null || thousandths(balance) <= BigInt.zero || !_orderTakesPayment) {
      return const SizedBox.shrink();
    }

    final scheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.only(top: 12.h),
      child: AppCard.accent(
        padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
        child: Row(
          children: [
            Icon(AppIcons.wallet, size: 26.sp, color: scheme.primary),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                'في محفظتك ${balance.asMoney} د.ل',
                style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            SizedBox(width: 8.w),
            AppButton(
              label: 'ادفع ${_amount.asMoney}',
              isLoading: _isPaying,
              // In a row: as wide as its label, not the screen.
              expands: false,
              onPressed: _pay,
            ),
          ],
        ),
      ),
    );
  }
}
