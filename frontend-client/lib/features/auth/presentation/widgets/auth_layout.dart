import 'dart:math' as math;

import 'package:dayaa_client/core/theme/app_tones.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/widgets/app_text_link.dart';
import 'package:dayaa_client/features/auth/presentation/views/brand_mark.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// هيكل شاشتي الدخول وإنشاء الحساب كما رسمه التصميم: ترويسةٌ كحلية فيها الشعار والعنوان، وبطاقةٌ
/// بيضاء عائمة فوق طرفها السفلي، وتحت البطاقة الطريقُ إلى الشاشة الأخرى، وفي أسفل الشاشة سطرُ
/// الشروط.
///
/// **الشاشتان تتقاسمانه كي لا تفترقا.** ما يختلف بينهما هو ما يُمرَّر هنا: العنوان، والسطر تحته،
/// ومحتوى البطاقة، والرابط تحتها. أما الترويسة والبطاقة والشروط فمكتوبةٌ مرةً واحدة.
///
/// **المقاسات من تصميمٍ مرسومٍ على عرض ٣٩٠**، ومحوَّلة إلى المقاس المرجعي ٤٣٠ (×١٫١) كي تطابقه
/// على هاتفٍ بذلك العرض وتحفظ نسبه على غيره.
///
/// **لا `AppBar`.** الترويسة تمتدّ تحت شريط الحالة، وأيقوناته فوقها بيضاء في الوضعين لأنها كحليةٌ
/// في الوضعين. وسهم الرجوع يظهر فيها وحدها حين يكون خلف الشاشة ما يُرجع إليه — لا على شاشة الدخول
/// التي هي أول ما يُفتح.
class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.prompt,
    required this.promptAction,
    required this.onPromptAction,
    required this.child,
  });

  final String title;
  final String subtitle;

  /// السؤال تحت البطاقة — «ليس لديك حساب؟».
  final String prompt;

  /// جوابه رابطاً — «إنشاء حساب جديد».
  final String promptAction;
  final VoidCallback onPromptAction;

  /// محتوى البطاقة: الحقول والزرّ.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, viewport) => SingleChildScrollView(
            child: ConstrainedBox(
              // الشاشة كلها على الأقل، فيستقرّ سطر الشروط في أسفلها حين يقصر المحتوى، ويُمرَّر
              // إليه حين يطول — بطاقة إنشاء الحساب بحقولها الأربعة تتجاوز الشاشة.
              constraints: BoxConstraints(minHeight: viewport.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Header(title: title, subtitle: subtitle),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: _Card(child: child),
                      ),
                      SizedBox(height: 26.h),
                      _Prompt(prompt: prompt, action: promptAction, onAction: onPromptAction),
                    ],
                  ),
                  Padding(
                    // فوق المؤشر السفلي مباشرةً كما في التصميم، لا فوق حدّ المنطقة الآمنة بكامله —
                    // ذلك الحدّ في الآيفون أعلى من المؤشر بعشرين نقطة. ولهاتفٍ بلا مؤشر هامشٌ أدنى.
                    padding: EdgeInsets.fromLTRB(
                      24.w,
                      28.h,
                      24.w,
                      math.max(bottomInset - 4.h, 12.h),
                    ),
                    child: const _Terms(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// كم يمتدّ الكحلي تحت الحافة العليا للبطاقة.
double get _overlap => 135.h;

/// الشعار والعنوان والسطر تحته على الكحلي، والكحلي نفسه ممتدٌّ خلف أعلى البطاقة.
class _Header extends StatelessWidget {
  const _Header({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final top = MediaQuery.paddingOf(context).top;
    final canGoBack = ModalRoute.of(context)?.canPop ?? false;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // **خارج حدود الترويسة إلى الأسفل، عن قصد.** البطاقة تأتي بعدها في العمود فتُرسم فوقها،
        // ويبقى الكحلي ظاهراً على جانبيها حتى ينحني تحتها.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: -_overlap,
          child: ClipRRect(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(44.r)),
            child: ColoredBox(
              color: scheme.header,
              child: Stack(
                children: [
                  PositionedDirectional(
                    end: -51.w,
                    bottom: -116.w,
                    width: 221.w,
                    height: 308.w,
                    child: CustomPaint(
                      painter: _WatermarkPainter(scheme.primary.withValues(alpha: 0.13)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          // مع سهم الرجوع ينزل المحتوى بارتفاعه، فلا يقع الشعار تحته.
          padding: EdgeInsets.fromLTRB(30.w, top + (canGoBack ? 52.h : 32.h), 30.w, 34.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BrandMark(),
              SizedBox(height: 23.5.h),
              Text(
                title,
                style: context.textTheme.headlineMedium?.copyWith(
                  fontSize: 30.sp,
                  fontWeight: FontWeight.w800,
                  color: scheme.onHeader,
                ),
              ),
              SizedBox(height: 4.5.h),
              Text(
                subtitle,
                style: context.textTheme.bodyLarge?.copyWith(
                  fontSize: 15.5.sp,
                  color: scheme.onHeaderVariant,
                ),
              ),
            ],
          ),
        ),
        if (canGoBack)
          PositionedDirectional(
            top: top + 4.h,
            start: 8.w,
            child: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: Icon(AppIcons.back, color: scheme.onHeader),
              tooltip: 'رجوع',
            ),
          ),
      ],
    );
  }
}

/// حرف X كبير بلون العلامة الخافت خلف طرف الترويسة، يقطعه حدّها السفلي.
///
/// **ذراعان بطرفين مستويين، مرسومان مرةً واحدة.** كل ذراعٍ متوازي أضلاع؛ واتحادهما مسارٌ واحد
/// يُرسم مرة، وإلا تضاعفت الشفافية حيث يتقاطعان فاسودّ وسط الحرف.
class _WatermarkPainter extends CustomPainter {
  const _WatermarkPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // عرض الذراع أفقياً: ٥٧ من ٢٠٠٫٥ في التصميم.
    final arm = w * 0.284;

    final falling = Path()
      ..moveTo(0, 0)
      ..lineTo(arm, 0)
      ..lineTo(w, h)
      ..lineTo(w - arm, h)
      ..close();
    final rising = Path()
      ..moveTo(w - arm, 0)
      ..lineTo(w, 0)
      ..lineTo(arm, h)
      ..lineTo(0, h)
      ..close();

    canvas.drawPath(
      Path.combine(PathOperation.union, falling, rising),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_WatermarkPainter oldDelegate) => oldDelegate.color != color;
}

/// البطاقة البيضاء العائمة. في الوضع الداكن يحدّها خيطٌ رفيع، لأن الظل لا يُرى على الكحلي.
class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final corners = BorderRadius.circular(26.r);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: corners,
        boxShadow: [
          // ظلٌّ ليّن منزاحٌ إلى الأسفل ومنكمشٌ عن الجانبين: داكنٌ تحت البطاقة، خفيفٌ على جانبيها.
          BoxShadow(
            color: scheme.header.withValues(alpha: 0.15),
            blurRadius: 37.r,
            spreadRadius: -4.4.r,
            offset: Offset(0, 22.h),
          ),
        ],
      ),
      child: Material(
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: corners,
          side: context.isDarkMode ? BorderSide(color: scheme.outlineVariant) : BorderSide.none,
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(22.w, 30.h, 22.w, 26.h),
          child: child,
        ),
      ),
    );
  }
}

/// «ليس لديك حساب؟ إنشاء حساب جديد» — السؤال بلونٍ هادئ، وجوابه رابطٌ برتقالي.
class _Prompt extends StatelessWidget {
  const _Prompt({required this.prompt, required this.action, required this.onAction});

  final String prompt;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final style = context.textTheme.bodyLarge?.copyWith(fontSize: 15.5.sp);

    // `Wrap` لا `Row`: بخطٍّ مكبَّر من إعدادات الهاتف يلتفّ السطر إلى سطرين بدل أن يفيض خارج
    // الشاشة ويأخذ الرابط معه. والجزءان بحجمٍ واحد، فيستقرّان على خطٍّ واحد بلا محاذاة أساس.
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6.w,
      children: [
        Text(prompt, style: style?.copyWith(color: context.colorScheme.onSurfaceVariant)),
        AppTextLink(label: action, onPressed: onAction, style: style),
      ],
    );
  }
}

/// «بالمتابعة أنت توافق على شروط الاستخدام وسياسة الخصوصية».
///
/// **الوثيقتان لم تُكتبا بعد**، فالرابطان يقولان ذلك كما تقوله «سياسة الخصوصية» في «حسابي»،
/// بدل أن يفتحا لا شيء. وهما داخل الجملة نفسها لا بجانبها، فتلتفّ السطور كما تلتفّ الجملة.
class _Terms extends StatefulWidget {
  const _Terms();

  @override
  State<_Terms> createState() => _TermsState();
}

class _TermsState extends State<_Terms> {
  late final TapGestureRecognizer _terms = TapGestureRecognizer()..onTap = _soon;
  late final TapGestureRecognizer _privacy = TapGestureRecognizer()..onTap = _soon;

  void _soon() => context.showInfo('ستتوفر قريباً');

  @override
  void dispose() {
    _terms.dispose();
    _privacy.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final link = TextStyle(
      color: scheme.onSurfaceVariant,
      decoration: TextDecoration.underline,
      decorationColor: scheme.onSurfaceVariant,
    );

    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(text: 'بالمتابعة أنت توافق على '),
          TextSpan(text: 'شروط الاستخدام', style: link, recognizer: _terms),
          const TextSpan(text: ' و'),
          TextSpan(text: 'سياسة الخصوصية', style: link, recognizer: _privacy),
        ],
      ),
      textAlign: TextAlign.center,
      style: context.textTheme.bodySmall?.copyWith(
        fontSize: 14.sp,
        color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
      ),
    );
  }
}
