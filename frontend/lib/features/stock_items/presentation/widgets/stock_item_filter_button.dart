import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/core/widgets/filter_option_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Every axis of the shelf filter, answered together.
typedef StockItemFilterChoice = ({bool? isActive, int? widthCm, int? heightCm});

/// Narrowing «أصناف المخزون».
///
/// **A round button opening a sheet, not a row of chips on the page.** Two of the three axes are
/// numbers somebody types, and a chip row cannot hold a text field without becoming a form the
/// list has to make room for on every screen.
///
/// **Filled when something is picked**, so whether the list is narrowed is answered before the
/// sheet is opened — which matters here because a narrowed shelf list looks exactly like a
/// workshop that has fewer materials than it does, and «الصنف غير موجود» is the conclusion
/// somebody draws before creating a duplicate of a shelf that was there all along.
class StockItemFilterButton extends StatelessWidget {
  const StockItemFilterButton({
    required this.isActive,
    required this.widthCm,
    required this.heightCm,
    required this.onApplied,
    super.key,
  });

  /// Whether the list is narrowed to the shelves still offered. Null shows the stopped ones too.
  final bool? isActive;

  /// The two halves of a size. Independent — everything 25 wide is as answerable a question as
  /// one exact shelf, and the API filters them separately for exactly that reason.
  final int? widthCm;
  final int? heightCm;

  /// One callback rather than three, because the sheet answers every axis at once and three
  /// would fetch the list three times for a single tap on «تطبيق».
  final ValueChanged<StockItemFilterChoice> onApplied;

  Future<void> _open(BuildContext context) async {
    final picked = await showModalBottomSheet<StockItemFilterChoice>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _FilterSheet(isActive: isActive, widthCm: widthCm, heightCm: heightCm),
    );

    if (picked != null) onApplied(picked);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isFiltered = isActive != null || widthCm != null || heightCm != null;

    return Material(
      color: isFiltered ? scheme.primaryContainer : scheme.surfaceContainerLowest,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: () => _open(context),
        customBorder: const CircleBorder(),
        child: Padding(
          padding: EdgeInsets.all(13.w),
          child: Icon(
            AppIcons.filter,
            size: 22.sp,
            color: isFiltered ? scheme.onPrimaryContainer : scheme.onSurface,
          ),
        ),
      ),
    );
  }
}

/// Two questions on one sheet: whether a shelf is still offered, and what size it is.
class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.isActive, required this.widthCm, required this.heightCm});

  final bool? isActive;
  final int? widthCm;
  final int? heightCm;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late bool? _isActive = widget.isActive;

  late final TextEditingController _width = TextEditingController(
    text: widget.widthCm?.toString() ?? '',
  );
  late final TextEditingController _height = TextEditingController(
    text: widget.heightCm?.toString() ?? '',
  );

  @override
  void dispose() {
    _width.dispose();
    _height.dispose();
    super.dispose();
  }

  /// Whatever is in the box, as the integer the API wants — or null for «كل المقاسات».
  ///
  /// `toWesternDigits` because ٢٥ is what a Libyan keyboard produces, and a size typed correctly
  /// that quietly filtered nothing would be a bug nobody could diagnose from the screen.
  int? _size(TextEditingController controller) {
    final trimmed = controller.text.trim();
    if (trimmed.isEmpty) return null;

    return int.tryParse(Validators.toWesternDigits(trimmed));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
        child: Padding(
          // The keyboard is up while the two size boxes are being filled, so the sheet has to
          // lift with it rather than hide the button under it.
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 0, 8.w, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'تصفية المواد',
                        style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      onPressed: () => setState(() {
                        _isActive = null;
                        _width.clear();
                        _height.clear();
                      }),
                      child: const Text('مسح الفلاتر'),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 4.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FilterSectionTitle(title: 'الحالة'),
                      SizedBox(height: 10.h),
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: [
                          for (final (label, value) in const [
                            ('الكل', null),
                            ('يُعرض', true),
                            ('موقوف', false),
                          ])
                            FilterOptionChip(
                              label: label,
                              isSelected: _isActive == value,
                              onTap: () => setState(() => _isActive = value),
                            ),
                        ],
                      ),
                      SizedBox(height: 18.h),
                      const FilterSectionTitle(title: 'المقاس (سم)'),
                      SizedBox(height: 6.h),
                      Text(
                        // Said out loud, because a form with two boxes reads as «both or
                        // neither» and the API is deliberately looser than that.
                        'يمكن ملء أحدهما وحده — «كل ما عرضه 25» سؤال مشروع.',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Row(
                        children: [
                          Expanded(
                            child: _SizeField(controller: _width, label: 'العرض'),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: _SizeField(controller: _height, label: 'الطول'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 12.h),
                child: AppButton(
                  label: 'تطبيق',
                  onPressed: () => Navigator.of(
                    context,
                  ).pop((isActive: _isActive, widthCm: _size(_width), heightCm: _size(_height))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One half of a size. Digits only — including the Arabic-Indic ones a Libyan keyboard offers
/// first — so nothing that cannot be a measurement can be typed into it in the first place.
class _SizeField extends StatelessWidget {
  const _SizeField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: label,
      hint: 'الكل',
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹]'))],
      textInputAction: TextInputAction.done,
    );
  }
}
