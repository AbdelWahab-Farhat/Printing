import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/utils/validators.dart';
import 'package:dayaa_client/core/widgets/field_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// حقل الإدخال الوحيد في التطبيق.
///
/// كانت كل شاشةٍ تكتب `TextFormField` و`InputDecoration` بنفسها، وهكذا ينتهي نموذجان بنصفَي
/// قطرٍ مختلفين وألوانِ تركيزٍ مختلفة، و— وهذا ما يكلّف فعلاً — سلوكِ خطأٍ مختلف. الهيئة هنا الآن
/// وفي [FieldFrame]، فتغيير شكل الحقول تعديلٌ واحد لا بحث.
///
/// **الهيئة من تصميم شاشة الدخول («حقول معنونة»):** العنوان فوق الصندوق ([LabelledField])،
/// والصندوق هادئ اللون بحدٍّ رفيع، والنص يبدأ من حافة القراءة. لا أيقونةَ إلا حيث يطلبها المستدعي.
///
/// **ما يقرّره كي لا يقرّره المستدعي:**
///   * حدٌّ يأخذ لون العلامة عند التركيز ولون الخطأ حين يخطئ — فيقول الحقل في أيّ الحالات الثلاث
///     هو بلا كلمة،
///   * الأيقونة، إن وُجدت، تتبع الحالات الثلاث نفسها،
///   * زرّ إظهار كلمة المرور مبنيٌّ فيه ([AppTextField.password])، ولا شاشةَ تعيد كتابته.
///
/// **ما لا يقرّره:** ما الصحيح. ذلك يبقى مع [Validators] عند الاستدعاء، وشكوى الخادم تصل عبر
/// [errorText] — وكلاهما يُرسم في المكان نفسه.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.initialValue,
    this.label,
    this.labelAction,
    this.hint,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffix,
    this.validator,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.inputFormatters,
    this.textDirection,
    this.enabled = true,
    this.autofocus = false,
    this.readOnly = false,
    this.maxLength,
    this.minLines,
    this.maxLines = 1,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.autofillHints,
    this.focusNode,
    this.style,
  }) : obscureText = false;

  /// حقل كلمة مرور: مقنَّع، وزرّ الإظهار والإخفاء موصولٌ فيه.
  ///
  /// الزرّ حالةٌ داخل هذا الويدجت ولا يسمع بها أحدٌ فوقه — إخفاء المحارف تفصيلُ رسمٍ، لا شيءٌ
  /// يحمله الـ ViewModel في كل إصدار.
  ///
  /// **بلا قفلٍ من تلقاء نفسه.** كان يضع أيقونة قفلٍ أمام كل كلمة مرور؛ والعنوان فوقه يقول
  /// «كلمة المرور» الآن، فصار القفل تكراراً لما كُتب.
  const AppTextField.password({
    super.key,
    this.controller,
    this.label = 'كلمة المرور',
    this.labelAction,
    this.hint,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.validator,
    this.textInputAction = TextInputAction.done,
    this.enabled = true,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
    this.autofillHints,
    this.focusNode,
  }) : obscureText = true,
       initialValue = null,
       suffix = null,
       keyboardType = TextInputType.visiblePassword,
       inputFormatters = null,
       textDirection = null,
       readOnly = false,
       maxLength = null,
       minLines = null,
       maxLines = 1,
       onTap = null,
       style = null;

  final TextEditingController? controller;
  final String? initialValue;

  /// يُدمج فوق نصّ الحقل المعتاد ولا يحلّ محلّه: ما لم يذكره يبقى كما هو، واللون أوّله. لرقمٍ
  /// يجب أن يُقرأ من بعيد — الكمية في صفحة المنتج — داخل الصندوق نفسه الذي يحمله كل حقل.
  final TextStyle? style;

  /// يُكتب فوق الصندوق. بلا عنوان يُرسم الصندوق وحده.
  final String? label;

  /// إجراءٌ صغير في طرف سطر العنوان الآخر — «نسيتها؟» بجانب «كلمة المرور».
  final Widget? labelAction;

  final String? hint;
  final String? helperText;

  /// خطأٌ آتٍ من خارج النموذج — مدخلٌ من `errors` في ردّ Laravel عادةً. يُرسم في خانة رسالة
  /// [validator] نفسها، فالمستخدم لا يعنيه أيّ الطرفين رفض.
  final String? errorText;

  final IconData? prefixIcon;
  final Widget? suffix;
  final Validator? validator;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final List<TextInputFormatter>? inputFormatters;

  /// `TextDirection.ltr` لما يُكتب لاتينياً ويجب أن يُقرأ من اليسار داخل هذا التطبيق العربي.
  final TextDirection? textDirection;

  final bool obscureText;
  final bool enabled;
  final bool autofocus;
  final bool readOnly;
  final int? maxLength;

  /// أقلّ ارتفاعٍ للحقل بالأسطر. مع [maxLines] أكبر منه يبدأ الحقل بهذا الارتفاع ويطول مع
  /// الكلام حتى [maxLines] ثم يمرّر — كصندوق الرسالة في المحادثة. بدونه يُحجز [maxLines]
  /// كاملاً من البداية.
  final int? minLines;

  final int? maxLines;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final Iterable<String>? autofillHints;
  final FocusNode? focusNode;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  /// يُملك فقط حين لم يأتِ المستدعي بواحد — التخلّص من [FocusNode] يملكه غيرك يكسره لحظة يعيد
  /// استعماله.
  FocusNode? _ownedNode;
  bool _isFocused = false;
  bool _isObscured = true;

  FocusNode get _node => widget.focusNode ?? (_ownedNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _node.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(covariant AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_onFocusChanged);
      _ownedNode?.removeListener(_onFocusChanged);
      _node.addListener(_onFocusChanged);
      _onFocusChanged();
    }
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_onFocusChanged);
    _ownedNode?.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!mounted || _isFocused == _node.hasFocus) return;

    // بصريٌّ بحت: بأيّ لونٍ يُرسم الحدّ والأيقونة. لا شيء هنا يخصّ الـ ViewModel.
    setState(() => _isFocused = _node.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final accent = FieldFrame.accent(
      context.colorScheme,
      isEnabled: widget.enabled,
      isFocused: _isFocused,
      hasError: widget.errorText != null,
    );

    final field = TextFormField(
      controller: widget.controller,
      initialValue: widget.controller == null ? widget.initialValue : null,
      focusNode: _node,
      validator: widget.validator,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      autofocus: widget.autofocus,
      obscureText: widget.obscureText && _isObscured,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      inputFormatters: widget.inputFormatters,
      textDirection: widget.textDirection,
      textAlignVertical: TextAlignVertical.center,
      maxLength: widget.maxLength,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      autofillHints: widget.autofillHints,
      cursorColor: context.colorScheme.primary,
      cursorRadius: const Radius.circular(2),
      style: FieldFrame.textStyle(context, isEnabled: widget.enabled)?.merge(widget.style).copyWith(
        // المحارف المقنّعة لا تُقرأ وهي متلاصقة.
        letterSpacing: widget.obscureText && _isObscured ? 2.5 : null,
      ),
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      onTap: widget.onTap,
      decoration: FieldFrame.decoration(
        context,
        isEnabled: widget.enabled,
        isFocused: _isFocused,
        hint: widget.hint,
        hintDirection: widget.textDirection,
        helperText: widget.helperText,
        errorText: widget.errorText,
        prefix: widget.prefixIcon == null
            ? null
            : Icon(widget.prefixIcon, size: 22.sp, color: accent),
        suffix: _buildSuffix(accent),
      ),
    );

    return LabelledField(label: widget.label, action: widget.labelAction, field: field);
  }

  Widget? _buildSuffix(Color accent) {
    if (widget.obscureText) {
      return IconButton(
        onPressed: () => setState(() => _isObscured = !_isObscured),
        icon: Icon(
          _isObscured ? AppIcons.passwordVisible : AppIcons.passwordHidden,
          size: 24.sp,
          color: accent,
        ),
        tooltip: _isObscured ? 'إظهار كلمة المرور' : 'إخفاء كلمة المرور',
      );
    }

    return widget.suffix;
  }
}
