import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/core/utils/validators.dart';

/// The one text input in the app.
///
/// Every screen used to write its own `TextFormField` plus an `InputDecoration`, which is how
/// two forms end up with different corner radii, different focus colours and — the one that
/// actually costs something — different error behaviour. The decoration lives here now, so a
/// change to the input look is one edit rather than a search.
///
/// **What it decides, so callers do not:**
///   * an outlined border that thickens and takes the primary colour on focus, the error colour
///     when something is wrong — the field says which of the three states it is in without a
///     label,
///   * the prefix icon tracks the same three states, so the eye is drawn to the field being
///     typed into,
///   * the password eye toggle is built in ([AppTextField.password]); no screen re-implements it.
///
/// **What it does not decide:** what is valid. That stays with [Validators] at the call site,
/// and the server's own complaint arrives through [errorText] — both render in the same place.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.initialValue,
    this.label,
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
    this.maxLines = 1,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.autofillHints,
    this.focusNode,
  }) : obscureText = false;

  /// A password field: obscured, with the show/hide toggle already wired.
  ///
  /// The toggle is [State] inside this widget and nothing above it ever hears about it —
  /// whether a character is masked is a rendering detail, not something a ViewModel should
  /// carry in every emission.
  const AppTextField.password({
    super.key,
    this.controller,
    this.label = 'كلمة المرور',
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
       maxLines = 1,
       onTap = null;

  final TextEditingController? controller;
  final String? initialValue;
  final String? label;
  final String? hint;
  final String? helperText;

  /// An error raised from outside the form — a Laravel `errors` entry, typically. Shown in the
  /// same slot as the [validator]'s message, because the user does not care which side said no.
  final String? errorText;

  final IconData? prefixIcon;
  final Widget? suffix;
  final Validator? validator;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final List<TextInputFormatter>? inputFormatters;

  /// Forced to [TextDirection.ltr] for anything Latin inside this right-to-left app — a phone
  /// number or an email reads backwards otherwise.
  final TextDirection? textDirection;

  final bool obscureText;
  final bool enabled;
  final bool autofocus;
  final bool readOnly;
  final int? maxLength;
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
  /// Owned only when the caller did not bring its own — disposing someone else's [FocusNode]
  /// breaks them the moment they reuse it.
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

    // Purely visual: which colour the border and the icon are drawn in. Nothing here belongs
    // to the ViewModel.
    setState(() => _isFocused = _node.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final textTheme = context.textTheme;

    final hasError = widget.errorText != null;
    final radius = BorderRadius.circular(14.r);

    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: color, width: width),
    );

    // Three states, one colour: idle, focused, wrong. The icon and the border always agree.
    final accent = !widget.enabled
        ? scheme.onSurfaceVariant.withValues(alpha: 0.45)
        : hasError
        ? scheme.error
        : _isFocused
        ? scheme.primary
        : scheme.onSurfaceVariant;

    // A fixed slot on both sides so the text starts at the same offset in every field, whether
    // or not that field happens to carry an icon.
    final slot = BoxConstraints(minWidth: 48.w, minHeight: 48.w);

    // A password field carries the lock without being asked; anything else shows what the
    // caller gave it, if it gave one.
    final leadingIcon = widget.prefixIcon ?? (widget.obscureText ? AppIcons.password : null);

    return TextFormField(
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
      maxLines: widget.maxLines,
      autofillHints: widget.autofillHints,
      cursorColor: scheme.primary,
      cursorRadius: const Radius.circular(2),
      style: textTheme.bodyLarge?.copyWith(
        color: widget.enabled ? scheme.onSurface : scheme.onSurfaceVariant,
        fontWeight: FontWeight.w500,
        // Masked characters are unreadable when they sit shoulder to shoulder.
        letterSpacing: widget.obscureText && _isObscured ? 2.5 : null,
      ),
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      onTap: widget.onTap,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        helperText: widget.helperText,
        errorText: widget.errorText,
        // A hint is a sample of what goes in the field; a Latin sample reads left-to-right even
        // here.
        hintTextDirection: widget.textDirection,
        // The count under a field the formatter already caps is noise.
        counterText: '',
        filled: true,
        fillColor: !widget.enabled
            ? scheme.surfaceContainerHigh.withValues(alpha: 0.4)
            : _isFocused
            ? scheme.surfaceContainerLowest
            : scheme.surfaceContainerLow,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
        alignLabelWithHint: (widget.maxLines ?? 1) > 1,
        labelStyle: textTheme.bodyMedium?.copyWith(color: accent),
        floatingLabelStyle: textTheme.bodySmall?.copyWith(
          color: accent,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
          fontWeight: FontWeight.w400,
        ),
        helperStyle: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        errorStyle: textTheme.bodySmall?.copyWith(color: scheme.error, height: 1.4),
        errorMaxLines: 2,
        prefixIcon: leadingIcon == null
            ? null
            : Icon(leadingIcon, size: 22.sp, color: accent),
        prefixIconConstraints: slot,
        suffixIcon: _buildSuffix(accent),
        suffixIconConstraints: slot,
        border: border(scheme.outlineVariant, 1),
        enabledBorder: border(scheme.outlineVariant, 1),
        focusedBorder: border(scheme.primary, 1.8),
        errorBorder: border(scheme.error, 1),
        focusedErrorBorder: border(scheme.error, 1.8),
        disabledBorder: border(scheme.outlineVariant.withValues(alpha: 0.5), 1),
      ),
    );
  }

  Widget? _buildSuffix(Color accent) {
    if (widget.obscureText) {
      return IconButton(
        onPressed: () => setState(() => _isObscured = !_isObscured),
        icon: Icon(
          _isObscured ? AppIcons.passwordVisible : AppIcons.passwordHidden,
          size: 22.sp,
          color: accent,
        ),
        tooltip: _isObscured ? 'إظهار كلمة المرور' : 'إخفاء كلمة المرور',
      );
    }

    return widget.suffix;
  }
}
