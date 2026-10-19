import 'package:dayaa_client/core/theme/app_tones.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/utils/fixed_point.dart';
import 'package:dayaa_client/core/widgets/app_card.dart';
import 'package:dayaa_client/core/widgets/app_text_field.dart';
import 'package:dayaa_client/features/orders/models/basket_quote.dart';
import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:dayaa_client/features/wallet/models/online_top_up_models.dart';
import 'package:dayaa_client/features/wallet/models/top_up_catalog.dart';
import 'package:dayaa_client/features/wallet/presentation/views/top_up_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// اختيار العربون — **على نسق بريمولا** (`order_info_page.dart` و`payment_method_page.dart` هناك)،
/// ومرسومٌ مرّةً هنا لموضعين: خطوة «العربون» في السلة، وورقة الطلبية التي قبلها المتجر بعد المراجعة
/// (صاحب العمل، 2026-10-19). الشكل واحد لأن السؤال واحد.
///
/// **المبلغ أولاً، بالدينار الكامل**: حقلٌ واحد يبدأ بأقلّ عربون — ربع البضاعة مقرَّباً لأعلى —
/// وتحته «ادفع كامل القيمة» يصير تأكيداً أخضر حين يساويها. ثم **«حدد طريقة الدفع»** صفوفاً بدائرة
/// اختيار، بلا اختيارٍ مسبق — مالٌ يُدفع يختاره صاحبه:
///
/// - **في المكتب** — تنتظر الطلبية العربون، ويُدفع نقداً عند المكتب.
/// - **من المحفظة** — رصيدها داخل الصفّ بزرّ تحديث؛ معطّلٌ حين لا يكفي، ويدلّ على ما تحته.
/// - **«أو عبّئ محفظتك وادفع مباشرة»** — كلُّ طريقة شحنٍ صفٌّ بشعارها، معطّلةً حين لا يتّسع حدّها
///   للعربون. **تُشحن المحفظة بالعربون نفسه أولاً، ولا يُرسل شيءٌ إلا حين ينجح الشحن** — على من
///   يرسم هذا أن يفعل ذلك.
///
/// **بلا حالة**: ما اختير وما كُتب في من يرسمه، وهذا يرسمه ويُبلغ بما لُمس.
class DepositChooser extends StatelessWidget {
  const DepositChooser({
    required this.offer,
    required this.amount,
    required this.chosenAmount,
    required this.amountError,
    required this.payment,
    required this.onlineMethodId,
    required this.onlineMethods,
    required this.walletBalance,
    required this.walletCovers,
    required this.onAmountChanged,
    required this.onPayFull,
    required this.onPayment,
    required this.onOnline,
    required this.onRefreshWallet,
    this.serverError,
    super.key,
  });

  final DepositOffer offer;

  /// الحقل نفسه — يملكه من يرسم هذا، ليكتب فيه «ادفع كامل القيمة».
  final TextEditingController amount;

  /// المبلغ كما فهمه الـ Cubit — لإبطال الطرق التي لا تتّسع له.
  final String? chosenAmount;

  final String? amountError;
  final CheckoutPayment? payment;
  final int? onlineMethodId;
  final List<TopUpMethod> onlineMethods;
  final String? walletBalance;
  final bool walletCovers;

  /// رفض الخادم للطريق أو للعربون كلّه — تحت الطرق.
  final String? serverError;

  final ValueChanged<String> onAmountChanged;
  final VoidCallback onPayFull;
  final ValueChanged<CheckoutPayment> onPayment;
  final ValueChanged<int> onOnline;
  final VoidCallback onRefreshWallet;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final full = offer.maxAmount!.asPlainNumber;
    final isFull = chosenAmount != null && chosenAmount == full;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          key: const ValueKey('deposit-amount'),
          controller: amount,
          label: 'العربون',
          hint: 'قيمة العربون ضرورية',
          keyboardType: TextInputType.number,
          textDirection: TextDirection.ltr,
          // بالدينار الكامل: لا فاصلة ولا كسور.
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9٠-٩]'))],
          helperText:
              'أقل عربون ${offer.minAmount!.asPlainNumber} د.ل (${offer.minPercent}٪ من قيمة الطلبية)',
          errorText: amountError,
          onChanged: onAmountChanged,
        ),
        SizedBox(height: 10.h),
        _PayFullAction(fullAmount: full, isFull: isFull, onPressed: onPayFull),

        SizedBox(height: 24.h),
        Text(
          'حدد طريقة الدفع',
          style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 12.h),
        _PaymentRow(
          key: const ValueKey('pay-office'),
          leading: _IconBox(icon: AppIcons.officePickup, color: scheme.primary),
          title: 'نقداً في المكتب',
          subtitle: 'ادفع قيمة العربون في المكتب، ونبدأ العمل حين يصلنا',
          selected: payment == CheckoutPayment.office,
          onTap: () => onPayment(CheckoutPayment.office),
        ),
        SizedBox(height: 10.h),
        _PaymentRow(
          key: const ValueKey('pay-wallet'),
          leading: _IconBox(icon: AppIcons.wallet, color: scheme.primary),
          title: 'الدفع من المحفظة',
          belowTitle: _InlineBalance(balance: walletBalance, onRefresh: onRefreshWallet),
          subtitle: switch (walletBalance) {
            null => null,
            _ when walletCovers => 'رصيدك يكفي لدفع العربون',
            _ => onlineMethods.isEmpty
                ? 'رصيدك لا يكفي هذا العربون'
                : 'رصيدك لا يكفي — اختر طريقة تعبئة بالأسفل',
          },
          selected: payment == CheckoutPayment.wallet,
          // رصيدٌ لا يكفي لا يُختار: الخادم سيرفضه.
          onTap: walletCovers ? () => onPayment(CheckoutPayment.wallet) : null,
        ),

        if (onlineMethods.isNotEmpty) ...[
          SizedBox(height: 20.h),
          Text(
            'أو عبّئ محفظتك وادفع مباشرة',
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface.withValues(alpha: .6),
            ),
          ),
          SizedBox(height: 10.h),
          for (final method in onlineMethods) ...[
            _onlineRow(method),
            SizedBox(height: 10.h),
          ],
        ],

        if (serverError case final error?) ...[
          SizedBox(height: 12.h),
          Text(error, style: context.textTheme.bodySmall?.copyWith(color: scheme.error)),
        ],
      ],
    );
  }

  /// صفُّ طريقة شحن. **المبلغ ثابت** — العربون — فالطريقة تُختار حين يتّسع حدّها له وحده.
  Widget _onlineRow(TopUpMethod method) {
    final brand = brandOf(method.id);
    final chosen = chosenAmount;
    final fits = chosen == null || chosen.isEmpty || method.canFund(chosen);

    return _PaymentRow(
      key: ValueKey('pay-online-${method.id}'),
      leading: TopUpLogo(brand: brand, box: 46.w, image: 30.w, radius: 12.r),
      title: method.label,
      subtitle: fits
          ? (brand.subtitle ?? 'تعبئة ودفع عبر ${method.label}')
          : 'المتبقّي لا يكفي (${method.cap!.asMoney} د.ل)',
      selected: payment == CheckoutPayment.online && onlineMethodId == method.id,
      onTap: fits ? () => onOnline(method.id) : null,
    );
  }
}

/// «ادفع كامل القيمة» — اختصارٌ يملأ العربون بكامل البضاعة، ويصير تأكيداً أخضر هادئاً متى ساواها
/// (كـ`_PayFullDepositAction` في بريمولا).
class _PayFullAction extends StatelessWidget {
  const _PayFullAction({required this.fullAmount, required this.isFull, required this.onPressed});

  final String fullAmount;
  final bool isFull;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final tone = isFull ? scheme.paid : scheme.primary;

    return AppCard(
      key: const ValueKey('deposit-pay-full'),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      onTap: isFull ? null : onPressed,
      child: Row(
        children: [
          Icon(isFull ? AppIcons.check : AppIcons.wallet, size: 22.sp, color: tone),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isFull ? 'أنت تدفع كامل قيمة الطلبية' : 'ادفع كامل القيمة ($fullAmount د.ل)',
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: tone,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  isFull ? 'لا يتبقى عليك شيء عند الاستلام' : 'بدل العربون — ولا يتبقى عليك شيء',
                  style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// صفٌّ من صفوف «حدد طريقة الدفع»: مربّع الأيقونة أو الشعار، والاسم وما تحته، ودائرة الاختيار —
/// كـ`PaymentRow` في بريمولا. **معطّلٌ بلا [onTap]**، باهتاً.
class _PaymentRow extends StatelessWidget {
  const _PaymentRow({
    required this.leading,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.belowTitle,
    super.key,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? belowTitle;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final enabled = onTap != null;

    return Opacity(
      opacity: enabled ? 1 : .5,
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: onTap,
        child: Ink(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: selected
                ? scheme.primary.withValues(alpha: .08)
                : scheme.surfaceContainerHighest.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: selected ? scheme.primary.withValues(alpha: .7) : scheme.outlineVariant.withValues(alpha: .35),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              leading,
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    ?belowTitle,
                    if (subtitle case final text?) ...[
                      SizedBox(height: 2.h),
                      Text(
                        text,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: .55),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                color: selected ? scheme.primary : scheme.onSurface.withValues(alpha: .35),
                size: 22.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// مربّع أيقونةٍ ملوّنٌ باهت لصفوف المكتب والمحفظة.
class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 46.w,
    height: 46.w,
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(12.r),
    ),
    child: Icon(icon, color: color, size: 24.sp),
  );
}

/// رصيد المحفظة داخل صفّها، بزرّ تحديثٍ صغير — **لا صفرَ حين لم يصل**: «تعذّر تحميل الرصيد».
class _InlineBalance extends StatelessWidget {
  const _InlineBalance({required this.balance, required this.onRefresh});

  final String? balance;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final color = balance == null ? scheme.error : scheme.primary;

    return Padding(
      padding: EdgeInsets.only(top: 4.h, bottom: 1.h),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.wallet, size: 15.sp, color: color),
          SizedBox(width: 5.w),
          Flexible(
            child: Text(
              balance == null ? 'تعذّر تحميل الرصيد' : 'الرصيد: ${balance!.asMoney} د.ل',
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800, color: color),
            ),
          ),
          SizedBox(width: 4.w),
          InkWell(
            key: const ValueKey('wallet-refresh'),
            onTap: onRefresh,
            borderRadius: BorderRadius.circular(20.r),
            child: Padding(
              padding: EdgeInsets.all(3.w),
              child: Icon(Icons.refresh_rounded, size: 16.sp, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
