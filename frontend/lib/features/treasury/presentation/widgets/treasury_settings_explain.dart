import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// ما يشرحه زرُّ ⓘ في «إعدادات المالية»: قسمٌ كامل، أو إعدادٌ واحد فيه.
enum TreasuryExplain { payment, settlement, pick, settler, collect }

/// ورقةُ الشرح — قصيرة، والصفحةُ نفسها بلا جملٍ تحت مفاتيحها. القواعدُ مرتّبةٌ كما يجرّبها
/// الخادم (TREASURY-DESIGN §٥ و§١٩ و§١٨ و§٢٢ و§٢٤)، فأوّلُ ما ينطبق هو ما يحدث.
Future<void> showTreasuryExplain(BuildContext context, TreasuryExplain topic) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: switch (topic) {
            TreasuryExplain.payment => const [
              _Title('أين تنزل الدفعة؟', caption: 'أول حالة تنطبق من الأعلى'),
              _Step('1', 'اخترت الحساب بنفسك', result: 'الحساب الذي اخترته'),
              _Step('2', 'كاش، والطلبية «استلام مكتب»', result: 'كاش ذلك المكتب'),
              _Step(
                '3',
                'لمن سجّلها حساب من نوعها',
                result: 'حسابه',
                note: 'إن كان «الحساب الشخصي أولاً» مفعّلاً',
              ),
              _Step('4', 'غير ذلك', result: 'الافتراضي لطريقة الدفع'),
              _Group('لا تدخل كاش المكتب'),
              _Excluded('بطاقة أو حوالة في المكتب'),
              _Excluded('عربون قبل وصول الطلبية للمكتب'),
            ],
            TreasuryExplain.settlement => const [
              _Title('التسوية', caption: 'أول حالة تنطبق من الأعلى'),
              _Step(
                '1',
                'اختيار الحساب عند التغيير لحالة التسوية',
                result: 'الحساب الذي تختاره',
              ),
              _Step('2', 'إلى حساب المسوّي تلقائياً', result: 'حساب من يسوّي، من نوع المال'),
              _Step('3', 'اجمع', result: 'حساب «في:»'),
              _Step('–', 'غير ذلك', result: 'يبقى المال مكانه'),
              _Group('العهدة تلقائياً'),
              _Pair('النورس', 'المصرف'),
              _Pair('المندوب', 'الكاش'),
            ],
            TreasuryExplain.pick => const [
              _Title('اختيار الحساب عند التغيير لحالة التسوية'),
              _Line(
                'مفعّل: شاشة «تم التسوية» تسألك لكل نوع في الطلبية: الكاش إلى أي حساب؟ '
                'المصرف؟ ليبيانا؟',
              ),
              _Line('اختيارك يغلب «حساب المسوّي» و«اجمع».'),
              _Line('مطفأ: لا سؤال، والقواعد التي تحته تقرّر.', muted: true),
              _Example([
                ('طلبية فيها 100 كاش و50 حوالة', null),
                ('الشاشة تسأل: الكاش إلى أي حساب؟ والحوالة؟', null),
              ]),
            ],
            TreasuryExplain.settler => const [
              _Title('إلى حساب المسوّي تلقائياً'),
              _Line(
                'المال يذهب إلى حساب من يضغط «تم التسوية»، من نفس النوع: الكاش لكاشه، '
                'والمصرف لمصرفه.',
              ),
              _Line('له حسابان من النوع؟ تسأله الشاشة أيّهما.'),
              _Line('ليس له حساب من النوع؟ يشتغل «اجمع».', muted: true),
              _Example([('100 كاش، سوّاها علي', 'كاش علي')]),
              _Compare(),
            ],
            TreasuryExplain.collect => const [
              _Title('اجمع'),
              _Line('عند «تم التسوية» يذهب المال إلى حساب «في:»، نفس الحساب مهما كان من يسوّي.'),
              _Line('«من:» الحسابات التي يُسحب منها. حساب ليس فيها يبقى ماله مكانه.'),
              _Line('يشتغل فقط إن لم يأخذ المالَ «حساب المسوّي».'),
              _Line('مطفأ: يبقى المال حيث سُجّل.', muted: true),
              _Example([('سوّاها علي أو سارة', 'حساب «في:» نفسه')]),
              _Compare(),
            ],
          },
        ),
      ),
    ),
  );
}

/// الرقمُ في دائرة: ترتيبُ القاعدة بين أخواتها — على الصفحة وفي الشرح بالشكل نفسه.
class TreasuryStepMark extends StatelessWidget {
  const TreasuryStepMark(this.step, {super.key});

  final String step;

  @override
  Widget build(BuildContext context) {
    final color = context.colorScheme.primary;

    return Container(
      width: 24.r,
      height: 24.r,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        step,
        style: context.textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text, {this.caption});

  final String text;
  final String? caption;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: 8.h),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          text,
          style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        if (caption case final caption?)
          Text(
            caption,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    ),
  );
}

/// حالةٌ ونتيجتُها: «كاش، والطلبية «استلام مكتب»» ← «كاش ذلك المكتب».
class _Step extends StatelessWidget {
  const _Step(this.step, this.text, {required this.result, this.note});

  final String step;
  final String text;
  final String result;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final resultStyle = context.textTheme.bodyMedium?.copyWith(
      color: scheme.primary,
      fontWeight: FontWeight.w600,
    );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TreasuryStepMark(step),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  text,
                  style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                Row(
                  children: [
                    const _Arrow(),
                    SizedBox(width: 4.w),
                    Flexible(child: Text(result, style: resultStyle)),
                  ],
                ),
                if (note case final note?)
                  Text(
                    note,
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

class _Group extends StatelessWidget {
  const _Group(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: 16.h, bottom: 4.h),
    child: Text(
      text,
      style: context.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: context.colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

class _Excluded extends StatelessWidget {
  const _Excluded(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: 6.h),
    child: Row(
      children: [
        Icon(AppIcons.excluded, size: 18.r, color: context.colorScheme.outline),
        SizedBox(width: 10.w),
        Expanded(child: Text(text, style: context.textTheme.bodyLarge)),
      ],
    ),
  );
}

class _Pair extends StatelessWidget {
  const _Pair(this.name, this.value);

  final String name;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: 6.h),
    child: Row(
      children: [
        Expanded(child: Text(name, style: context.textTheme.bodyLarge)),
        Text(
          value,
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}

class _Line extends StatelessWidget {
  const _Line(this.text, {this.muted = false});

  final String text;

  /// ما يحدث والإعدادُ مطفأ — نقطتُه رمادية.
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8.r,
            height: 8.r,
            margin: EdgeInsets.only(top: 9.h),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: muted ? scheme.outline : scheme.primary,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(child: Text(text, style: context.textTheme.bodyLarge)),
        ],
      ),
    );
  }
}

/// «يذهب إلى» — أيقونةٌ لا حرف: Cairo بلا «←» فيُرسم مربّعاً فارغاً.
class _Arrow extends StatelessWidget {
  const _Arrow();

  @override
  Widget build(BuildContext context) =>
      Icon(AppIcons.forward, size: 16.r, color: context.colorScheme.primary);
}

/// سطورُ المثال: ما حدث، وإلى أين ذهب المال إن كان للسطر وجهة.
class _Example extends StatelessWidget {
  const _Example(this.lines);

  final List<(String, String?)> lines;

  @override
  Widget build(BuildContext context) => Container(
    margin: EdgeInsets.only(top: 12.h),
    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
    decoration: BoxDecoration(
      color: context.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(14.r),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'مثال',
          style: context.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
        for (final (what, where) in lines)
          Row(
            children: [
              Flexible(child: Text(what, style: context.textTheme.bodyMedium)),
              if (where != null) ...[
                SizedBox(width: 6.w),
                const _Arrow(),
                SizedBox(width: 4.w),
                Text(
                  where,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
      ],
    ),
  );
}

/// الفرقُ في سطرين: «حساب المسوّي» يتبع من يسوّي، و«اجمع» حسابٌ لا يتغيّر.
class _Compare extends StatelessWidget {
  const _Compare();

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: 12.h),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _CompareBox('حساب المسوّي', 'يتبع الشخص')),
        SizedBox(width: 8),
        Expanded(child: _CompareBox('اجمع', 'حساب واحد ثابت')),
      ],
    ),
  );
}

class _CompareBox extends StatelessWidget {
  const _CompareBox(this.name, this.meaning);

  final String name;
  final String meaning;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12.r),
      border: Border.all(color: context.colorScheme.outlineVariant),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(name, style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        Text(
          meaning,
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}
