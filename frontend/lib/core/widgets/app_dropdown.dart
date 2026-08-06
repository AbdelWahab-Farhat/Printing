import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/utils/context_extensions.dart';

/// The one dropdown in the app, and it takes **any** model.
///
/// Every screen that needed a picker used to write its own `DropdownButtonFormField` plus an
/// `InputDecoration`, which is how two forms end up with different corner radii, different focus
/// colours and — the one that actually costs something — different error behaviour. This is the
/// same argument [AppTextField] settles for inputs, settled once more for choices, and the two
/// are drawn to match on purpose: a form whose text field and whose picker disagree about their
/// own border reads as two forms.
///
/// **Generic over the item, not over an id.** `AppDropdown<PaymentMethod>`, `AppDropdown<City>`,
/// `AppDropdown<BusinessField>` — the caller says how to draw one ([labelOf]) and, when the
/// model has no useful `==`, how to tell two apart ([keyOf]). Nothing here knows what a payment
/// method is, which is the whole point: the next picker is a type argument, not a new file.
///
/// **What it decides, so callers do not:** the border that thickens and takes the primary colour
/// on focus and the error colour when something is wrong; the prefix icon tracking those same
/// three states; the rounded menu; and that the field is always full width, because a dropdown
/// that shrinks to its longest label makes a form's edges ragged.
///
/// **What it does not decide:** what is valid. That stays with the caller's [validator], and the
/// server's own complaint arrives through [errorText] — both render in the same slot, because
/// the user does not care which side said no.
class AppDropdown<T> extends StatefulWidget {
  const AppDropdown({
    required this.items,
    required this.labelOf,
    required this.onChanged,
    super.key,
    this.value,
    this.keyOf,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.iconOf,
    this.subtitleOf,
    this.validator,
    this.enabled = true,
    this.placeholder,
  });

  final List<T> items;

  /// What to write on the row. The **only** thing this widget knows about the model.
  final String Function(T item) labelOf;

  /// An optional second line — «موقوف», a price, a code. Drawn muted under the label.
  final String Function(T item)? subtitleOf;

  /// An optional glyph per row, for lists where the icon is read before the word.
  final IconData Function(T item)? iconOf;

  /// Identity, when the model's own `==` is not the answer.
  ///
  /// A Freezed model compares by value and needs nothing here. A model rebuilt from JSON on
  /// every refresh does: without it, the selected item stops matching the item in the list and
  /// the field silently blanks itself — which is the one thing a form must never do to a value
  /// it was only asked to display.
  final Object Function(T item)? keyOf;

  final T? value;
  final ValueChanged<T?> onChanged;

  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final IconData? prefixIcon;
  final String? Function(T? value)? validator;
  final bool enabled;

  /// A first row meaning "not chosen", when the answer is genuinely optional.
  ///
  /// Absent by default: a picker that offers a blank when the field is required teaches people
  /// to leave it blank. Pass «غير محدد» only where nothing is a real answer.
  final String? placeholder;

  @override
  State<AppDropdown<T>> createState() => _AppDropdownState<T>();
}

class _AppDropdownState<T> extends State<AppDropdown<T>> {
  final FocusNode _node = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _node.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _node
      ..removeListener(_onFocusChanged)
      ..dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!mounted || _isFocused == _node.hasFocus) return;

    setState(() => _isFocused = _node.hasFocus);
  }

  /// The item to hand the field, or null.
  ///
  /// **Matched through [AppDropdown.keyOf] rather than by identity**, so a list that was
  /// re-fetched since the value was chosen still shows the choice. A dropdown handed a value
  /// that is not `==` to anything in its items renders empty, and the user sees their answer
  /// disappear for no reason they could act on.
  T? get _selected {
    final value = widget.value;
    if (value == null) return null;

    final key = widget.keyOf;

    for (final item in widget.items) {
      final matches = key == null ? item == value : key(item) == key(value);
      if (matches) return item;
    }

    return null;
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

    // Three states, one colour: idle, focused, wrong. The icon and the border always agree —
    // the same rule AppTextField follows, so the two sit together without arguing.
    final accent = !widget.enabled
        ? scheme.onSurfaceVariant.withValues(alpha: 0.45)
        : hasError
        ? scheme.error
        : _isFocused
        ? scheme.primary
        : scheme.onSurfaceVariant;

    final slot = BoxConstraints(minWidth: 48.w, minHeight: 48.w);

    final hasSubtitle = widget.subtitleOf != null;

    return DropdownButtonFormField<T>(
      initialValue: _selected,
      focusNode: _node,
      isExpanded: true,
      borderRadius: radius,
      // A two-line row does not fit the default row height, and the overflow is drawn as
      // Flutter's yellow-and-black stripes rather than merely looking cramped. Only raised when
      // there is a second line to make room for.
      //
      // Floored at `kMinInteractiveDimension`, which Flutter asserts on: `.h` scales with the
      // screen, and on a short one 60 scales *below* the minimum — an assertion in a debug
      // build and a crash the first tester on a small phone would find.
      itemHeight: hasSubtitle
          ? math.max(60.h, kMinInteractiveDimension)
          : kMinInteractiveDimension,
      // **The closed field shows the label alone.** The row in the menu carries the subtitle
      // because that is where somebody is choosing; repeating it in the field would spend two
      // lines of a form on a fact they have already acted on — and it is what overflowed.
      selectedItemBuilder: hasSubtitle
          ? (context) => [
              if (widget.placeholder != null) const SizedBox.shrink(),
              for (final item in widget.items)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    widget.labelOf(item),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ]
          : null,
      validator: widget.validator,
      // `null` rather than a disabled flag: Flutter reads a null callback as "cannot be
      // changed", which is also what greys the field.
      onChanged: widget.enabled ? widget.onChanged : null,
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: accent),
      style: textTheme.bodyLarge?.copyWith(
        color: widget.enabled ? scheme.onSurface : scheme.onSurfaceVariant,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        helperText: widget.helperText,
        errorText: widget.errorText,
        filled: true,
        fillColor: !widget.enabled
            ? scheme.surfaceContainerHigh.withValues(alpha: 0.4)
            : _isFocused
            ? scheme.surfaceContainerLowest
            : scheme.surfaceContainerLow,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        labelStyle: textTheme.bodyMedium?.copyWith(color: accent),
        floatingLabelStyle: textTheme.bodySmall?.copyWith(
          color: accent,
          fontWeight: FontWeight.w600,
        ),
        helperStyle: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        errorStyle: textTheme.bodySmall?.copyWith(color: scheme.error, height: 1.4),
        errorMaxLines: 2,
        prefixIcon: widget.prefixIcon == null
            ? null
            : Icon(widget.prefixIcon, size: 22.sp, color: accent),
        prefixIconConstraints: slot,
        border: border(scheme.outlineVariant, 1),
        enabledBorder: border(scheme.outlineVariant, 1),
        focusedBorder: border(scheme.primary, 1.8),
        errorBorder: border(scheme.error, 1),
        focusedErrorBorder: border(scheme.error, 1.8),
        disabledBorder: border(scheme.outlineVariant.withValues(alpha: 0.5), 1),
      ),
      items: [
        if (widget.placeholder case final placeholder?)
          DropdownMenuItem<T>(
            child: Text(
              placeholder,
              style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        for (final item in widget.items)
          DropdownMenuItem<T>(
            value: item,
            child: _Row(
              label: widget.labelOf(item),
              subtitle: widget.subtitleOf?.call(item),
              icon: widget.iconOf?.call(item),
            ),
          ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, this.subtitle, this.icon});

  final String label;
  final String? subtitle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Row(
      children: [
        if (icon case final glyph?) ...[
          Icon(glyph, size: 18.sp, color: scheme.onSurfaceVariant),
          SizedBox(width: 10.w),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
              if (subtitle case final line? when line.isNotEmpty)
                Text(
                  line,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
