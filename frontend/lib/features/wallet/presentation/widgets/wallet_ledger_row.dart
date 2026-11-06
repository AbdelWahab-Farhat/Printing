import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// شكلُ سطرٍ في محفظة — **على شكل سطر محفظة المستثمر** (`investors/…/wallet_entry_row.dart`)،
/// بطلب صاحب العمل (٢٠٢٦-١٠-١١): أيقونةُ النوع، ثم **ماذا حدث وأين**، ثم **كم بإشارته**، وتحته
/// «إلغاء الحركة» حين يجوز، ومن سجّلها ومتى.
///
/// **واحدٌ لمحفظة العميل ومحفظة الموظف**، فلا يختلف شكلاهما: كلٌّ يقول ما يعرفه عن سطره، وهذا
/// يرسمه.
///
/// **الملغى يبقى ظاهراً مشطوباً**، هو وسطرُ عكسه — «ألم يشحن مئةً يوم الأحد؟» نعم، وأُلغيت.
class WalletLedgerRow extends StatelessWidget {
  const WalletLedgerRow({
    required this.icon,
    required this.title,
    required this.amount,
    required this.isIn,
    required this.footer,
    this.where,
    this.notes,
    this.isReversed = false,
    this.isReversal = false,
    this.reversalReason,
    this.onTap,
    this.onReverse,
    super.key,
  });

  /// ما يُعرَف به نوعُ الحركة قبل أن يُقرأ.
  final IconData icon;
  final String title;

  /// موجبٌ دائماً كما قاله الخادم — الاتجاه في [isIn].
  final String amount;
  final bool isIn;

  /// من سجّلها ومتى.
  final String footer;

  /// لمن وكيف، تحت العنوان.
  final String? where;
  final String? notes;

  final bool isReversed;
  final bool isReversal;

  /// سببُ العكس، تحت السطر المشطوب.
  final String? reversalReason;

  final VoidCallback? onTap;

  /// يعكس الحركة. `null` حين لا يجوز — والخادمُ هو من يقول إن كان يجوز.
  final VoidCallback? onReverse;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final tone = isReversed || isReversal
        ? scheme.onSurfaceVariant
        : isIn
        ? scheme.primary
        : scheme.error;
    final quiet = context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant);
    final struck = isReversed ? TextDecoration.lineThrough : null;

    final row = Padding(
      padding: EdgeInsets.symmetric(vertical: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 4.h),
                child: Icon(icon, size: 20.sp, color: tone),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        decoration: struck,
                      ),
                    ),
                    if (where case final where?) ...[
                      SizedBox(height: 4.h),
                      Text(where, style: quiet),
                    ],
                    if (notes case final notes? when notes.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Text(notes, style: quiet?.copyWith(fontStyle: FontStyle.italic)),
                    ],
                    if (isReversed) ...[
                      SizedBox(height: 4.h),
                      Text(
                        reversalReason == null ? 'أُلغيت' : 'أُلغيت — $reversalReason',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: scheme.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                '$_amount د.ل',
                textDirection: TextDirection.ltr,
                style: context.textTheme.titleLarge?.copyWith(
                  color: tone,
                  fontWeight: FontWeight.w800,
                  decoration: struck,
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(top: 6.h),
            child: Row(
              children: [
                if (onReverse != null)
                  TextButton.icon(
                    onPressed: onReverse,
                    icon: Icon(AppIcons.reversePayment, size: 16.sp),
                    label: const Text('إلغاء الحركة'),
                    style: TextButton.styleFrom(
                      foregroundColor: scheme.error,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                const Spacer(),
                // يفسح للزرّ على هاتفٍ ضيّق: الاسمُ والوقت يحتملان النقاط الثلاث، والفعلُ لا.
                Flexible(
                  child: Text(
                    footer,
                    style: quiet,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return onTap == null ? row : InkWell(onTap: onTap, child: row);
  }

  /// `+100` / `−80` — **الإشارةُ لا تسقط أبداً**، وبعلامة الناقص الطباعية.
  String get _amount => isIn ? '+${amount.grouped}' : '−${amount.grouped}';
}
