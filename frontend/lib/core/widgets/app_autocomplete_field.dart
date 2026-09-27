import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/arabic_search.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A search box that suggests from a list it already holds, and picks rather than filters.
///
/// Typing «سعر» offers «سعر البيع» and «سعر الوحدة» under the box; tapping one — or pressing
/// search, which takes the first — hands it to [onSelected] and empties the box. Nothing is
/// sent anywhere while typing: the list is local, and it is the pick that the caller acts on.
///
/// **Matching is [ArabicSearch.matchesSearch]**: every typed word, anywhere in the label, with
/// hamza, ta marbuta, alef maqsura and the vowel marks folded away on both sides. «اسعار» finds
/// «أسعار», and «بيع» finds «سعر البيع». [detailOf] is searched too, so «بند» finds every field
/// of an order line.
///
/// Built on [RawAutocomplete] with [AppTextField] as the box, so it looks like every other input
/// in the app and the suggestion panel follows the box's width.
class AppAutocompleteField<T extends Object> extends StatefulWidget {
  const AppAutocompleteField({
    required this.options,
    required this.labelOf,
    required this.onSelected,
    this.detailOf,
    this.hint = 'ابحث',
    this.maxOptions = 8,
    super.key,
  });

  final List<T> options;

  /// What an option is called — shown, and searched.
  final String Function(T option) labelOf;

  /// A second, quieter line under the label — shown, and searched as well.
  final String? Function(T option)? detailOf;

  final ValueChanged<T> onSelected;

  final String hint;

  /// How many suggestions at most. A panel taller than the screen above the keyboard is a panel
  /// whose last rows nobody reaches; typing one more letter is the better way down the list.
  final int maxOptions;

  @override
  State<AppAutocompleteField<T>> createState() => _AppAutocompleteFieldState<T>();
}

class _AppAutocompleteFieldState<T extends Object> extends State<AppAutocompleteField<T>> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Iterable<T> _suggest(TextEditingValue value) {
    // Nothing until something is typed: a panel that opens on focus with every option in it is
    // a dropdown, and the box would then be hiding the list it sits above.
    if (value.text.trim().isEmpty) return const [];

    return widget.options
        .where(
          (option) =>
              widget.labelOf(option).matchesSearch(value.text) ||
              (widget.detailOf?.call(option)?.matchesSearch(value.text) ?? false),
        )
        .take(widget.maxOptions);
  }

  void _select(T option) {
    // [RawAutocomplete] has just written the label into the box; the pick is what matters now,
    // and the box goes back to empty for the next search.
    _controller.clear();
    _focusNode.unfocus();
    widget.onSelected(option);
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<T>(
      textEditingController: _controller,
      focusNode: _focusNode,
      optionsBuilder: _suggest,
      displayStringForOption: widget.labelOf,
      onSelected: _select,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) =>
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) => AppTextField(
              controller: controller,
              focusNode: focusNode,
              hint: widget.hint,
              prefixIcon: AppIcons.search,
              textInputAction: TextInputAction.search,
              // Search on the keyboard takes the first suggestion — the one on top of the panel.
              onSubmitted: (_) => onFieldSubmitted(),
              suffix: value.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: controller.clear,
                      icon: Icon(AppIcons.clear, size: 20.sp),
                      tooltip: 'مسح البحث',
                    ),
            ),
          ),
      optionsViewBuilder: (context, onSelected, options) => _Options<T>(
        options: options.toList(),
        labelOf: widget.labelOf,
        detailOf: widget.detailOf,
        onSelected: onSelected,
      ),
    );
  }
}

class _Options<T extends Object> extends StatelessWidget {
  const _Options({
    required this.options,
    required this.labelOf,
    required this.detailOf,
    required this.onSelected,
  });

  final List<T> options;
  final String Function(T option) labelOf;
  final String? Function(T option)? detailOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Align(
      alignment: AlignmentDirectional.topStart,
      child: Padding(
        padding: EdgeInsets.only(top: 4.h),
        child: Material(
          elevation: 4,
          color: scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12.r),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 280.h),
            child: ListView.separated(
              padding: EdgeInsets.symmetric(vertical: 4.h),
              shrinkWrap: true,
              itemCount: options.length,
              separatorBuilder: (_, _) =>
                  Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.4)),
              itemBuilder: (context, index) {
                final option = options[index];
                final detail = detailOf?.call(option);

                return InkWell(
                  onTap: () => onSelected(option),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            labelOf(option),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (detail != null) ...[
                          SizedBox(width: 8.w),
                          Text(
                            detail,
                            style: context.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
