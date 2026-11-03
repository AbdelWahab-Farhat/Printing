import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/utils/fixed_point.dart';
import 'package:dayaa_client/core/utils/uuid.dart';
import 'package:dayaa_client/core/widgets/app_button.dart';
import 'package:dayaa_client/core/widgets/app_card.dart';
import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:dayaa_client/features/wallet/presentation/viewmodel/wallet_balance_cubit.dart';
import 'package:dayaa_client/features/wallet/presentation/views/top_up_sheet.dart';
import 'package:dayaa_client/features/wallet/usecases/top_up_usecases.dart';
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
///
/// **«اشحن وادفع»** حين يكون الشحن الإلكتروني مفعّلاً والمحفظة لا تكفي (CUSTOMER-WALLET §٥):
/// تُشحن المحفظة بما ينقصها، ثم يدفع الخادم منها ما على الطلبية. المالُ يمرّ بالمحفظة دائماً.
///
/// **«انتظار العربون»**: حين سمّى المتجر عربوناً ([CustomerOrderDetail.depositDue]) يُعرض خياران
/// متجاوران — «العربون» و«المبلغ كاملاً» — والزبون يضغط ما يريد، بلا اختيارٍ مسبق (صاحب العمل،
/// ٢٠٢٦-١٠-١٢). كلٌّ يدفع مبلغه من المحفظة، أو يشحن ما ينقصها له ثم يدفعه. ودفعُ العربون ينقل
/// الطلبية إلى «تم دفع العربون» من الخادم نفسه.
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

  /// الشحن الإلكتروني مفعّل — فيُعرض «اشحن وادفع».
  bool _canTopUp = false;

  /// **مفتاحُ هذا الدفع حتى ينجح.** اتصالٌ انقطع بعد أن دفع الخادمُ يُعاد بالمفتاح نفسه، فيجيب
  /// الخادمُ بالدفعة الأولى ولا يدفع ثانية. ولا يُترك إلا بعد دفعٍ نجح — أو حين يختار الزبون
  /// مبلغاً آخر ([_tokenFor]): العربونُ ثم الكاملُ دفعتان، لا إعادةُ واحدة.
  String? _token;
  String? _tokenFor;

  @override
  void initState() {
    super.initState();
    _read();
  }

  Future<void> _read() async {
    final result = await sl<GetWalletBalance>()();

    if (!mounted) return;

    result.fold((_) {}, (balance) {
      setState(() => _balance = balance);
      // والشريط العلوي يرسم الرقم نفسه بعد الرجوع، بلا سؤالٍ ثانٍ.
      sl<WalletBalanceCubit>().patch(balance);
    });

    // يُسأل مرّةً، وحين تقبل الطلبية دفعاً وحده.
    if (_canTopUp || !_orderTakesPayment || !sl.isRegistered<GetTopUpMethods>()) return;

    final methods = await sl<GetTopUpMethods>()();

    if (!mounted) return;

    methods.fold((_) {}, (m) => setState(() => _canTopUp = m.enabled));
  }

  /// ما ينقص المحفظةَ لتغطي [target] — المتبقي، أو العربون.
  String _shortfallFor(String target) => subtractDecimals(target, _balance!);

  /// تُشحن المحفظة بما ينقصها لـ[target]، فيدفع الخادمُ منها — ما فيها ساعتَها، وهو [target].
  /// والعربونُ بمبلغه ([deposit]): شحنٌ زاد عمّا نقص لا يُدفع منه أكثرُ من العربون.
  Future<void> _topUpAndPay(String target, {bool deposit = false}) async {
    final toppedUp = await showTopUpSheet(
      context,
      args: TopUpArgs(
        orderId: widget.order.id,
        orderAmount: deposit ? target : null,
        amount: _shortfallFor(target),
      ),
    );

    if (toppedUp != true || !mounted) return;

    await _read();
    await widget.onPaid();
  }

  /// هل في الطلبية ما يُدفع من المحفظة الآن.
  bool get _orderTakesPayment {
    final order = widget.order;
    final owed = order.balance;

    // «جديدة» «بانتظار المراجعة» عند العميل منذ 2026-10-23، وتقبل الدفع — فالخادم يقول
    // [CustomerOrderDetail.isReviewed]، والمرحلة جوابُ خادمٍ أقدم منه.
    return order.isOpen &&
        !order.isAwaitingQuote &&
        (order.isReviewed ?? order.stage != OrderStage.underReview) &&
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

  /// [deposit]: العربون بمبلغه بالضبط. بدونه: أكثر ما يسمح به الرصيد والمتبقي.
  Future<void> _pay({String? deposit}) async {
    final amount = deposit ?? _amount;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('الدفع من المحفظة'),
        content: Text(
          deposit == null
              ? 'يُدفع ${amount.asMoney} د.ل من محفظتك لهذه الطلبية.'
              : 'يُدفع العربون ${amount.asMoney} د.ل من محفظتك، وتبدأ المطبعة العمل على طلبيتك.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('تراجع')),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('ادفع')),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isPaying = true);

    // بلا مبلغ: الخادم يأخذ أكثر ما يسمح به الاثنان ساعتَها — رصيدٌ تغيّر منذ قُرئ لا يُرفض.
    // والعربونُ بمبلغه: هو ما طلبه المتجر، لا أقلّ ولا أكثر.
    final purpose = deposit ?? 'all';

    if (_tokenFor != purpose) _token = null;

    _tokenFor = purpose;
    final token = _token ??= uuidV4();
    final result = await sl<PayOrderFromWallet>()(widget.order.id, amount: deposit, clientToken: token);

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
        sl<WalletBalanceCubit>().patch(balance);
        context.showSuccess('تم الدفع من المحفظة');
        await widget.onPaid();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final balance = _balance;

    if (balance == null || !_orderTakesPayment) return const SizedBox.shrink();

    final owed = widget.order.balance!;
    final hasMoney = thousandths(balance) > BigInt.zero;
    final short = thousandths(balance) < thousandths(owed);

    if (!hasMoney && !_canTopUp) return const SizedBox.shrink();

    final scheme = context.colorScheme;
    final deposit = widget.order.depositDue;
    final choices = deposit != null && (_covers(deposit) || _canTopUp);

    return Padding(
      padding: EdgeInsets.only(top: 12.h),
      child: AppCard.accent(
        padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(AppIcons.wallet, size: 26.sp, color: scheme.primary),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    hasMoney ? 'في محفظتك ${balance.asMoney} د.ل' : 'اشحن محفظتك وادفع هذه الطلبية منها',
                    style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                if (!choices) ...[
                  SizedBox(width: 8.w),
                  if (hasMoney)
                    AppButton(
                      label: 'ادفع ${_amount.asMoney}',
                      isLoading: _isPaying,
                      // In a row: as wide as its label, not the screen.
                      expands: false,
                      onPressed: _pay,
                    )
                  else
                    AppButton(label: 'اشحن وادفع', expands: false, onPressed: () => _topUpAndPay(owed)),
                ],
              ],
            ),
            if (choices) ...[
              SizedBox(height: 8.h),
              Text(
                'طلبت المطبعة عربوناً لتبدأ العمل — ادفع العربون أو المبلغ كاملاً.',
                style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurface.withValues(alpha: .6)),
              ),
              SizedBox(height: 10.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _PayChoice(
                      key: const Key('pay-deposit'),
                      title: 'العربون',
                      amount: deposit,
                      hint: _hintFor(deposit),
                      onTap: _isPaying ? null : _tapFor(deposit, deposit: true),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _PayChoice(
                      key: const Key('pay-all'),
                      title: 'المبلغ كاملاً',
                      amount: owed,
                      hint: _hintFor(owed),
                      onTap: _isPaying ? null : _tapFor(owed),
                    ),
                  ),
                ],
              ),
            ] else if (hasMoney && short && _canTopUp)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: _isPaying ? null : () => _topUpAndPay(owed),
                  child: Text('اشحن ${_shortfallFor(owed).asMoney} د.ل وادفع الطلبية كاملة'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// المحفظة تكفي [target] وحدها.
  bool _covers(String target) => thousandths(_balance!) >= thousandths(target);

  /// ما يحدث عند الضغط، بكلمات — تحت المبلغ في الخيار.
  String? _hintFor(String target) {
    if (_covers(target)) return 'من محفظتك';

    if (_canTopUp) return 'اشحن ${_shortfallFor(target).asMoney} د.ل وادفع';

    return thousandths(_balance!) > BigInt.zero ? 'يُدفع ${_balance!.asMoney} د.ل الآن' : null;
  }

  /// يدفع [target] من المحفظة إن كفت، وإلا يشحنها بما ينقصها له. العربونُ لا يُدفع منه جزء —
  /// لا ينقل الطلبية — والمبلغ الكامل يُدفع منه ما في المحفظة إن لم يكن شحن.
  VoidCallback? _tapFor(String target, {bool deposit = false}) {
    if (_covers(target)) return () => _pay(deposit: deposit ? target : null);

    if (_canTopUp) return () => _topUpAndPay(target, deposit: deposit);

    return !deposit && thousandths(_balance!) > BigInt.zero ? _pay : null;
  }
}

/// خيارٌ من خيارَي «انتظار العربون»: اسمه، ومبلغه، وما يحدث عند الضغط.
class _PayChoice extends StatelessWidget {
  const _PayChoice({required this.title, required this.amount, required this.hint, required this.onTap, super.key});

  final String title;
  final String amount;
  final String? hint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final enabled = onTap != null;
    final tone = enabled ? scheme.primary : scheme.onSurface.withValues(alpha: .35);

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: tone.withValues(alpha: .5), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurface.withValues(alpha: .65))),
              SizedBox(height: 2.h),
              Text(
                '${amount.asMoney} د.ل',
                style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: tone),
              ),
              if (hint != null) ...[
                SizedBox(height: 2.h),
                Text(hint!, style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurface.withValues(alpha: .55))),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
