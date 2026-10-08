import 'dart:async';

import 'package:dayaa/core/theme/app_tones.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/receipt_viewer.dart';
import 'package:dayaa/features/orders/models/order_payment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// قيدٌ واحد من سجلّ «دفعات الطلبية» في بطاقته — التصميم «ب» الذي اختاره المالك من لوحة
/// ٢٠٢٦-١٠-٠٨.
///
/// **رأسٌ يقول المال، ومربّعان يقولان ما بقي عليه.** في الرأس النوع والطريقة والتاريخ ومن سجّل،
/// والمبلغ بإشارته ووحدته أكبرُ ما في البطاقة. وتحته مربّعا «المراجعة» و«المبلغ في»، كلٌّ بحالته
/// وزرِّه: الزرّ بجانب الحالة التي يغيّرها. وهما متجاوران لا متتاليان، لأن المراجعة لا توقف
/// التسوية. وما انتهى منهما يخضرّ ويسقط زرّه، فنظرةٌ واحدة تقول إن كانت الدفعة قد اكتملت.
///
/// **التصحيحات خلف «⋯»** — «إلغاء المراجعة» و«التراجع عن التسوية» و«إلغاء الدفعة». ما يعكس
/// عملاً سابقاً لا يقف بجانب ما يُنجز عملاً جديداً، والضغط على البطاقة نفسها لا يعدّل شيئاً.
///
/// **كل قرارٍ هنا قرارُ الخادم** (`can_review` و`can_settle` و`can_unsettle` و`is_reversible`)،
/// إلا صلاحيةَ الإلغاء: تسألها الصفحةُ الجلسةَ وتمرّرها في [mayReverse].
class PaymentEntryCard extends StatelessWidget {
  const PaymentEntryCard({
    required this.payment,
    required this.isBusy,
    required this.mayReverse,
    required this.onReview,
    required this.onSettle,
    required this.onUnsettle,
    required this.onReverse,
    super.key,
  });

  final OrderPayment payment;

  /// الصفحة تكتب شيئاً الآن. يُمرَّر إلى الأزرار `isLoading` لا تعطيلاً — RULES §٧.
  final bool isBusy;

  /// هل يملك المستخدم «إلغاء الدفعة». الخادم يقول هل القيد يُلغى، والجلسة تقول هل هذا الشخص يلغيه.
  final bool mayReverse;

  /// `true` للمراجعة، و`false` لسحبها.
  final void Function(bool reviewed) onReview;
  final VoidCallback onSettle;
  final VoidCallback onUnsettle;
  final VoidCallback onReverse;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final offers = _offersOf(payment, mayReverse: mayReverse);

    final tiles = <Widget>[
      if (payment.showsReview) _ReviewTile(payment: payment, isBusy: isBusy, onReview: onReview),
      if (_showsPlace(payment)) _PlaceTile(payment: payment, isBusy: isBusy, onSettle: onSettle),
    ];

    final chips = <Widget>[
      // الجزءُ فوق الدَّين، على الدفعة التي حملته: إيرادٌ للمحلّ منذ ٢٠٢٦-١٠-٠٧، لا يُدان به
      // للزبون — وعلى الردّ لا يقال شيء.
      if (payment.hasExcess && payment.isIncoming)
        _Chip(
          label: 'منها زائد ${payment.excessAmount.grouped} د.ل · إيراد',
          fill: scheme.tertiaryContainer,
          ink: scheme.onTertiaryContainer,
        ),
      if (payment.hasReceipt) _ReceiptChip(payment: payment),
    ];

    // تحت الرأس، على حافّة نصّه لا على حافّة البطاقة: الأيقونة ٤٤ وبعدها ١٢.
    final indent = EdgeInsetsDirectional.only(start: 56.w);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            payment: payment,
            // أثناء الكتابة يبقى «⋯» ظاهراً ولا يفتح شيئاً، كما يرفض `AppButton` النقر وهو مشغول.
            onOptions: offers.isEmpty
                ? null
                : () {
                    if (!isBusy) unawaited(_correct(context, offers));
                  },
          ),

          if (chips.isNotEmpty)
            Padding(
              padding: indent.add(EdgeInsets.only(top: 8.h)),
              child: Wrap(spacing: 6.w, runSpacing: 6.h, children: chips),
            ),

          if (payment.notes case final notes? when notes.isNotEmpty)
            Padding(
              padding: indent.add(EdgeInsets.only(top: 6.h)),
              child: Text(
                notes,
                style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),

          // سببُ الإلغاء على القيد الذي أُلغي، فيُقرأ المشطوبُ وتفسيره معاً.
          if (payment.reversal case final reversal?)
            Padding(
              padding: indent.add(EdgeInsets.only(top: 8.h)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 2.h),
                    child: Icon(AppIcons.reversePayment, size: 16.sp, color: scheme.error),
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      'أُلغيت: ${reversal.reason ?? 'بدون سبب'}',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: scheme.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (tiles.isNotEmpty) ...[
            SizedBox(height: 14.h),
            if (tiles.length == 1)
              tiles.single
            else
              // **بطولٍ واحد.** المربّع الذي سقط زرّه يبقى بطول جاره، فيقرأ السطرُ مربّعين لا درجاً.
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: tiles.first),
                    SizedBox(width: 10.w),
                    Expanded(child: tiles.last),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  /// يفتح «⋯» وينفّذ ما اختير. الصفحة هي التي تسأل عن السبب وتكتب — البطاقة تمرّر الاختيار فقط.
  Future<void> _correct(BuildContext context, List<_Offer> offers) async {
    final choice = await _askCorrection(context, payment, offers);

    switch (choice) {
      case _Correction.unreview:
        onReview(false);
      case _Correction.unsettle:
        onUnsettle();
      case _Correction.reverse:
        onReverse();
      case null:
        break;
    }
  }
}

/// ما يقع خلف «⋯».
enum _Correction { unreview, unsettle, reverse }

/// تصحيحٌ معروض، و[blockedReason] حين يرفضه الخادم: يبقى الصفّ ظاهراً وسببه تحته، ولا يُختار.
/// والخادم لا يرسل السبب إلا لمن يملك الصلاحية، فلا يرى غيرُه صفّاً ليس له.
typedef _Offer = ({_Correction kind, String? blockedReason});

List<_Offer> _offersOf(OrderPayment payment, {required bool mayReverse}) => [
  if (payment.canUnreview) (kind: _Correction.unreview, blockedReason: null),
  if (payment.canUnsettle)
    (kind: _Correction.unsettle, blockedReason: null)
  else if (payment.isSettled && payment.unsettleBlockedReason != null)
    (kind: _Correction.unsettle, blockedReason: payment.unsettleBlockedReason),
  if (payment.isReversible && mayReverse) (kind: _Correction.reverse, blockedReason: null),
];

/// هل للقيد مكانٌ يُقال: ما حرّك مالاً إلى حسابٍ معروف أو منه. لا على شطبٍ ولا على قيدٍ ملغى،
/// ولا على دفعةٍ من قبل الخزينة.
bool _showsPlace(OrderPayment payment) =>
    !payment.isVoid && (payment.isSettled || payment.treasuryAccount != null);

/// الطريقة والمرجع ومتى تحرّك المال ومن أخذه — الحقائق الأربع التي يقرؤها معاً من يطابق واصلاً.
String _subtitleOf(OrderPayment payment) => [
  if (payment.methodLabel case final label? when label.isNotEmpty) label,
  if (payment.reference case final reference? when reference.isNotEmpty) reference,
  if (payment.paidAt case final paidAt?) paidAt.dayLabel,
  if (payment.recordedBy case final recorder?) recorder.name,
].join(' · ');

/// مَن ومتى، كلٌّ في سطره: «سارة» ثم «7 أكتوبر 2026 · 10:30 ص». في مربّعٍ ضيّق كان السطر
/// الواحد يلتفّ فتتدلّى نقطةٌ في آخره. وبالتاريخ والساعة لا «منذ ساعتين»: يُقرأ بعد أسابيع، ممن
/// يسأل من شهد للمال.
List<Widget> _whoAndWhen(BuildContext context, PaymentRecorder? who, DateTime? at) {
  final style = context.textTheme.bodyMedium?.copyWith(color: context.colorScheme.onSurfaceVariant);

  return [
    if (who != null) Text(who.name, style: style),
    if (at != null) Text(at.stampLabel, style: style),
  ];
}

/// إشارةُ القيد، وهي اتجاهه: «+» لما دخل، و«−» لما خرج أو أُلغي. الخادم يرسل كل مبلغٍ موجباً
/// لئلا يخطئ مجموعٌ بسالبٍ شارد، فالإشارة تُقال هنا مرةً ولا تُخزَّن.
///
/// **ولا إشارة لما لم يتحرّك**: الشطب لم يُخرج من الدرج شيئاً، والسالب عليه يُقرأ مالاً خرج.
/// **ولا لنوعٍ لا تعرفه هذه النسخة** — «سُدِّدت لدى الناقل» مثلاً، مالٌ وصل الناقل لا الدرج: لا
/// يُدّعى عليه اتجاه، وعربيّةُ الخادم تقول ما هو.
String _signOf(OrderPayment payment) => switch (payment.type) {
  OrderPaymentType.payment => '+',
  OrderPaymentType.refund || OrderPaymentType.reversal => '−',
  OrderPaymentType.writeOff || OrderPaymentType.excessKept || OrderPaymentType.unknown => '',
};

/// لونُ القيد: الداخل بلون العلامة، والخارج أحمر، وما لم يحرّك مالاً — أو لا يُعرف — محايد.
/// والملغى رماديّ مهما كان.
Color _toneOf(OrderPayment payment, ColorScheme scheme) {
  if (payment.isVoid) return scheme.onSurfaceVariant;

  return switch (payment.type) {
    OrderPaymentType.payment => scheme.primary,
    OrderPaymentType.refund || OrderPaymentType.reversal => scheme.error,
    OrderPaymentType.writeOff || OrderPaymentType.excessKept || OrderPaymentType.unknown =>
      scheme.onSurfaceVariant,
  };
}

/// لكل نوعٍ أيقونته: مالٌ دخل، ومالٌ خرج، وقيدٌ أُلغي، ومالٌ شُطب، وزائدٌ بقي للمحلّ.
IconData _glyphOf(OrderPayment payment) => switch (payment.type) {
  OrderPaymentType.payment || OrderPaymentType.unknown => AppIcons.payment,
  OrderPaymentType.refund => AppIcons.refund,
  OrderPaymentType.reversal => AppIcons.reversePayment,
  OrderPaymentType.writeOff => AppIcons.writeOff,
  OrderPaymentType.excessKept => AppIcons.excessKept,
};

/// النوع وما تحته، والمبلغ، و«⋯» حين يكون خلفه شيء.
class _Header extends StatelessWidget {
  const _Header({required this.payment, required this.onOptions});

  final OrderPayment payment;

  /// null: لا تصحيح يُعرض، فلا «⋯».
  final VoidCallback? onOptions;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final subtitle = _subtitleOf(payment);

    return Row(
      children: [
        _Glyph(payment: payment),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                // عربيّة الخادم، فيُقرأ نوعٌ أضيف بعد هذه النسخة صحيحاً.
                payment.typeLabel,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: payment.isVoid ? scheme.onSurfaceVariant : scheme.onSurface,
                  decoration: payment.isVoid ? TextDecoration.lineThrough : null,
                ),
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
            ],
          ),
        ),
        SizedBox(width: 8.w),
        _Amount(payment: payment),
        if (onOptions != null)
          IconButton(
            key: ValueKey('options-${payment.id}'),
            tooltip: payment.movesNoCash ? 'خيارات القيد' : 'خيارات الدفعة',
            visualDensity: VisualDensity.compact,
            onPressed: onOptions,
            icon: Icon(AppIcons.more, color: scheme.onSurfaceVariant),
          ),
      ],
    );
  }
}

/// «+226 د.ل» — الإشارة ملاصقةٌ للرقم من جهتها، والوحدة بعده. والإشارة من [_signOf].
///
/// **الرقم في سطرٍ من اليسار إلى اليمين.** «+ 226» داخل سطرٍ عربي تُرسم «226 +»: الإشارة
/// المحايدة تأخذ اتجاه السطر فتقفز إلى الجهة الأخرى. والوحدة نصٌّ منفصل بجانبه، فتقع بعده في
/// قراءة العربي.
class _Amount extends StatelessWidget {
  const _Amount({required this.payment, this.compact = false});

  final OrderPayment payment;

  /// في رأس ورقة «⋯»، حيث المبلغ تذكيرٌ لا الرقمُ الأهمّ.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tone = _toneOf(payment, context.colorScheme);
    final decoration = payment.isVoid ? TextDecoration.lineThrough : null;
    final figure = '${_signOf(payment)}${payment.amount.grouped}';
    final figureStyle = compact ? context.textTheme.titleMedium : context.textTheme.titleLarge;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          figure,
          textDirection: TextDirection.ltr,
          maxLines: 1,
          style: figureStyle?.copyWith(
            fontWeight: FontWeight.w800,
            color: tone,
            decoration: decoration,
          ),
        ),
        SizedBox(width: 4.w),
        Text(
          'د.ل',
          style: context.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: tone,
            decoration: decoration,
          ),
        ),
      ],
    );
  }
}

/// أيقونة القيد على مربّعٍ بلونه الباهت — والملغى على رماديّ.
class _Glyph extends StatelessWidget {
  const _Glyph({required this.payment});

  final OrderPayment payment;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final tone = _toneOf(payment, scheme);

    return Container(
      width: 44.r,
      height: 44.r,
      decoration: BoxDecoration(
        color: payment.isVoid ? scheme.surfaceContainerHigh : tone.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Icon(_glyphOf(payment), size: 24.sp, color: tone),
    );
  }
}

/// إطار المربّعين: أيقونةٌ وعنوانٌ صغير، ثم الحالة، ثم الزرّ في الأسفل إن بقي ما يُفعل.
///
/// [done] يخضرّه: أخضرُ «مدفوعة بالكامل» باهتاً — لونُ «انتهى» في هذا التطبيق.
class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.iconTone,
    required this.label,
    required this.done,
    required this.lines,
    this.action,
  });

  final IconData icon;
  final Color iconTone;
  final String label;
  final bool done;
  final List<Widget> lines;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: done ? scheme.paidContainer.withValues(alpha: 0.5) : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        // الزرّ إلى قاع المربّع حين يكون جاره أطول، ولا مرونة هنا تطلب ارتفاعاً محدوداً: المربّع
        // الوحيد يُرسم في عمودٍ لا حدّ لطوله.
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18.sp, color: iconTone),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      label,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              ...lines,
            ],
          ),
          if (action case final button?) Padding(padding: EdgeInsets.only(top: 12.h), child: button),
        ],
      ),
    );
  }
}

/// «المراجعة»: «غير مراجَعة» وزرّ «مراجعة» لمن يراجع، أو «تمت المراجعة» ومن شهد ومتى.
///
/// لا يُرسم على قيدٍ لم يُطلب فحصه — انظر [OrderPayment.showsReview].
class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.payment, required this.isBusy, required this.onReview});

  final OrderPayment payment;
  final bool isBusy;
  final void Function(bool reviewed) onReview;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final reviewed = payment.isReviewed;
    final tone = reviewed ? scheme.paid : scheme.tertiary;

    return _Tile(
      icon: reviewed ? AppIcons.paymentReviewed : AppIcons.awaitingReview,
      iconTone: tone,
      label: 'المراجعة',
      done: reviewed,
      lines: [
        Text(
          reviewed ? 'تمت المراجعة' : 'غير مراجَعة',
          style: context.textTheme.titleMedium?.copyWith(color: tone, fontWeight: FontWeight.w700),
        ),
        if (reviewed) ..._whoAndWhen(context, payment.reviewedBy, payment.reviewedAt),
      ],
      action: payment.canReview
          ? AppButton.tonal(
              key: ValueKey('review-${payment.id}'),
              label: 'مراجعة',
              icon: AppIcons.paymentReviewed,
              height: 42.h,
              isLoading: isBusy,
              onPressed: () => onReview(true),
            )
          : null,
    );
  }
}

/// «المبلغ في»: الحساب الذي فيه المال **الآن** — قبل التسوية حيث نزل، وبعدها حيث وصل، ومن أين
/// جاء وكم احتفظ الناقل. وعلى الردّ «خرج من». TREASURY-DESIGN §٢٣.
///
/// زرّ «تسوية» حين يقول الخادم إن هذا الشخص يسوّي هذه الدفعة. والمال الذي نزل في حسابه الأخير
/// يُقال مكانه بلا زرّ.
class _PlaceTile extends StatelessWidget {
  const _PlaceTile({required this.payment, required this.isBusy, required this.onSettle});

  final OrderPayment payment;
  final bool isBusy;
  final VoidCallback onSettle;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final value = context.textTheme.titleMedium?.copyWith(
      color: scheme.onSurface,
      fontWeight: FontWeight.w700,
    );

    if (payment.settlement case final settlement?) {
      final from = payment.treasuryAccount?.name;

      return _Tile(
        icon: AppIcons.settled,
        iconTone: scheme.paid,
        label: 'المبلغ في',
        done: true,
        lines: [
          Text(settlement.toAccount?.name ?? 'حساب', style: value),
          Text(
            from == null ? 'سُوّيت' : 'سُوّيت من $from',
            style: context.textTheme.bodyMedium?.copyWith(
              color: scheme.paid,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (settlement.hasFee)
            Text(
              'وصل ${settlement.received.grouped} · الناقل ${settlement.fee.grouped}',
              style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
            ),
          ..._whoAndWhen(context, settlement.settledBy, settlement.settledAt),
        ],
      );
    }

    return _Tile(
      icon: AppIcons.treasury,
      iconTone: scheme.onSurfaceVariant,
      label: payment.type == OrderPaymentType.refund ? 'خرج من' : 'المبلغ في',
      done: false,
      lines: [Text(payment.treasuryAccount?.name ?? 'حساب', style: value)],
      action: payment.canSettle
          ? AppButton.tonal(
              key: ValueKey('settle-${payment.id}'),
              label: 'تسوية',
              icon: AppIcons.transfer,
              height: 42.h,
              isLoading: isBusy,
              onPressed: onSettle,
            )
          : null,
    );
  }
}

/// شارةٌ صغيرة تحت الرأس.
class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.fill, required this.ink, this.icon});

  final String label;
  final Color fill;
  final Color ink;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(999.r)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon case final glyph?) ...[
            Icon(glyph, size: 14.sp, color: ink),
            SizedBox(width: 6.w),
          ],
          Text(
            label,
            style: context.textTheme.bodySmall?.copyWith(color: ink, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// «الواصل مرفق» — والضغط عليه يفتح الورقة نفسها.
///
/// على أغلب القيود حقيقةٌ تُتجاوز، ولمن يطابق حوالةً مختلَفاً عليها هي الدليل: صورةٌ تُكبَّر في
/// التطبيق، أو PDF يُسلَّم للهاتف — انظر [showReceipt]. وأيّ أيقونة يلبس جوابُ الخادم
/// `receipt_is_image`.
class _ReceiptChip extends StatelessWidget {
  const _ReceiptChip({required this.payment});

  final OrderPayment payment;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return InkWell(
      onTap: () => unawaited(
        showReceipt(
          context,
          Receipt(
            cacheKey: 'payment-receipt-${payment.id}',
            url: payment.receiptUrl,
            isImage: payment.receiptIsImage,
            filename: payment.receiptFilename,
          ),
        ),
      ),
      borderRadius: BorderRadius.circular(999.r),
      child: _Chip(
        label: 'الواصل مرفق',
        icon: payment.receiptIsImage ? AppIcons.photos : AppIcons.pdf,
        fill: scheme.surfaceContainerHighest,
        ink: scheme.onSurfaceVariant,
      ),
    );
  }
}

/// ورقة «⋯»: القيد في رأسها ليُعرف أيّ قيدٍ يُصحَّح، ثم التصحيحات — والإلغاء آخرها وبالأحمر.
///
/// **تُمرَّر ولا تفيض**، كورقة خيارات التصاميم: هاتفٌ قصير أو خطٌّ مكبَّر يُسقط الصفّ الأخير
/// خارج ما يُرسم، وصفٌّ لا يُرى في ورقةٍ لا تُمرَّر لا يُوصَل إليه أصلاً.
Future<_Correction?> _askCorrection(
  BuildContext context,
  OrderPayment payment,
  List<_Offer> offers,
) {
  final subtitle = _subtitleOf(payment);

  return showModalBottomSheet<_Correction>(
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (sheetContext) {
      final scheme = sheetContext.colorScheme;

      return SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 8.h),
              ListTile(
                title: Text(
                  payment.typeLabel,
                  style: sheetContext.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                subtitle: subtitle.isEmpty ? null : Text(subtitle),
                trailing: _Amount(payment: payment, compact: true),
              ),
              const Divider(height: 1),
              for (final offer in offers)
                switch (offer.kind) {
                  _Correction.unreview => ListTile(
                    leading: Icon(AppIcons.undo),
                    title: const Text('إلغاء المراجعة'),
                    onTap: () => Navigator.of(sheetContext).pop(_Correction.unreview),
                  ),
                  // يرفضه الخادم حين تكون الطلبية «تم التسوية»: الصفّ يبقى وسببه تحته، ولا يُختار.
                  _Correction.unsettle => ListTile(
                    enabled: offer.blockedReason == null,
                    leading: Icon(AppIcons.undo),
                    title: const Text('التراجع عن التسوية'),
                    subtitle: switch (offer.blockedReason) {
                      final reason? => Text(
                        reason,
                        style: sheetContext.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      null => null,
                    },
                    onTap: () => Navigator.of(sheetContext).pop(_Correction.unsettle),
                  ),
                  // «القيد» على الشطب: تسميته دفعةً تخطئ في اسمه على الشاشة التي الأسماء فيها هي
                  // المقصود.
                  _Correction.reverse => ListTile(
                    leading: Icon(AppIcons.reversePayment, color: scheme.error),
                    title: Text(
                      payment.movesNoCash ? 'إلغاء القيد' : 'إلغاء الدفعة',
                      style: TextStyle(color: scheme.error),
                    ),
                    onTap: () => Navigator.of(sheetContext).pop(_Correction.reverse),
                  ),
                },
              SizedBox(height: 8.h),
            ],
          ),
        ),
      );
    },
  );
}
