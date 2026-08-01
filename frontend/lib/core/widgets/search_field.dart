import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/core/widgets/app_text_field.dart';

/// The search box that sits above a list.
///
/// It is [AppTextField] with the three details a search box always needs and a form field never
/// does: the magnifier, a clear button that appears once there is something to clear, and a
/// keyboard whose return key says "search". Written once so every list's box behaves the same —
/// including the clear button, which is the one people miss when they hand-roll this.
///
/// **The debounce is not here.** It belongs to the ViewModel, next to the request it is
/// throttling — see `PagedCubit.search`. A widget that debounced would make a screen with no
/// Cubit impossible to search, and would put a network concern in the widget tree.
class SearchField extends StatefulWidget {
  const SearchField({
    required this.onChanged,
    this.hint = 'ابحث',
    this.controller,
    this.autofocus = false,
    super.key,
  });

  /// Called on every keystroke, and once more with `''` when the box is cleared.
  final ValueChanged<String> onChanged;

  final String hint;

  /// Supply one to read or set the term from outside; otherwise this widget owns it.
  final TextEditingController? controller;

  final bool autofocus;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  /// Owned only when the caller did not bring its own — disposing someone else's controller
  /// breaks them the moment they use it again.
  TextEditingController? _owned;

  bool _hasText = false;

  TextEditingController get _controller =>
      widget.controller ?? (_owned ??= TextEditingController());

  @override
  void initState() {
    super.initState();
    _hasText = _controller.text.isNotEmpty;
  }

  @override
  void dispose() {
    _owned?.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    final hasText = value.isNotEmpty;

    // Rebuilds only when the button actually appears or disappears — not on every keystroke.
    if (hasText != _hasText) setState(() => _hasText = hasText);

    widget.onChanged(value);
  }

  void _clear() {
    _controller.clear();
    setState(() => _hasText = false);
    // The list must go back to showing everything: clearing the box is a search for nothing in
    // particular, and saying so is this widget's job, not the user's.
    widget.onChanged('');
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: _controller,
      hint: widget.hint,
      prefixIcon: AppIcons.search,
      textInputAction: TextInputAction.search,
      autofocus: widget.autofocus,
      onChanged: _onChanged,
      suffix: _hasText
          ? IconButton(
              onPressed: _clear,
              icon: Icon(AppIcons.clear, size: 20.sp),
              tooltip: 'مسح البحث',
            )
          : null,
    );
  }
}
