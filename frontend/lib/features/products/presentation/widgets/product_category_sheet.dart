import 'dart:async';
import 'dart:io';

import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/files/attachment_picker.dart';
import 'package:dayaa/core/files/picked_file.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/core/widgets/attachment_sheet.dart';
import 'package:dayaa/features/products/models/product_category.dart';
import 'package:dayaa/features/products/models/production_mode.dart';
import 'package:dayaa/features/products/presentation/viewmodel/save_product_category_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Adds a heading to the catalogue, or renames one already on it.
///
/// A sheet rather than a screen: a name and a line of description, and a page for it would put
/// a navigation step either side of two text boxes.
///
/// Returns the category the **server** stored, or null when the sheet was dismissed — so the
/// list behind it refreshes only when there is something to refresh for.
///
/// [nextSortOrder] is where a *new* category lands in the catalogue. The screen passes the end
/// of the list, so a heading added today appears after the ones already there instead of
/// jumping to the top of a form nobody was asked to fill in. Renaming keeps the order it had.
///
/// [onDelete] is the list's own delete, handed in rather than performed here: removing a row is
/// the *list's* operation — the answer is a list with one row fewer, and this sheet has nothing
/// left to show afterwards. It answers `true` when the category is gone, and the sheet closes.
Future<ProductCategory?> showProductCategorySheet({
  required BuildContext context,
  ProductCategory? category,
  int nextSortOrder = 0,
  Future<bool> Function()? onDelete,
}) {
  return showModalBottomSheet<ProductCategory>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => BlocProvider<SaveProductCategoryCubit>(
      create: (_) => sl<SaveProductCategoryCubit>(),
      child: _ProductCategoryForm(
        category: category,
        nextSortOrder: nextSortOrder,
        onDelete: onDelete,
      ),
    ),
  );
}

class _ProductCategoryForm extends StatefulWidget {
  const _ProductCategoryForm({
    required this.category,
    required this.nextSortOrder,
    this.onDelete,
  });

  final ProductCategory? category;
  final int nextSortOrder;
  final Future<bool> Function()? onDelete;

  @override
  State<_ProductCategoryForm> createState() => _ProductCategoryFormState();
}

class _ProductCategoryFormState extends State<_ProductCategoryForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(
    text: widget.category?.name ?? '',
  );
  late final TextEditingController _description = TextEditingController(
    text: widget.category?.description ?? '',
  );

  /// A file chosen on this sheet and not yet sent. Null means «اترك الصورة كما هي».
  PickedFile? _image;

  /// True once somebody taps «حذف الصورة» — distinct from [_image] being null, which only says
  /// nothing new was picked.
  bool _removeImage = false;

  /// How goods under this heading come to exist — مطبوعة، سادة، أو وسيط — which is the road
  /// orders made only of them take.
  ///
  /// Seeded from the category being edited, and printed for a new one — a heading nobody has
  /// thought about sends its orders down the road every order took before this choice existed.
  /// A mode this build has never heard of is seeded as printed too, and the sheet says so below
  /// the picker rather than silently offering to overwrite it.
  late ProductionMode _productionMode = switch (widget.category?.productionMode) {
    null || ProductionMode.unknown => ProductionMode.inHouse,
    final ProductionMode mode => mode,
  };

  /// Whether the row arrived with a mode this build cannot name — see [_productionMode].
  bool get _modeIsUnknown => widget.category?.productionMode == ProductionMode.unknown;

  bool get _isEditing => widget.category != null;

  /// What the row should look like right now: the file just picked, else what the server has,
  /// unless it has been asked to go.
  bool get _showsExistingImage =>
      _image == null && !_removeImage && (widget.category?.hasImage ?? false);

  Future<void> _pickImage() async {
    final source = await showAttachmentSheet(context: context, title: 'صورة التصنيف');
    if (source == null || !mounted) return;

    final files = await sl<AttachmentPicker>().pick(source);
    // Cancelling a picker is not a failure and nothing is said about it.
    if (files.isEmpty || !mounted) return;

    setState(() {
      _image = files.first;
      _removeImage = false;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    context.read<SaveProductCategoryCubit>().submit(
      categoryId: widget.category?.id,
      name: _name.text,
      description: _description.text,
      // A rename must not silently re-offer a category somebody stopped, and must not reshuffle
      // the catalogue: both travel back exactly as they were.
      sortOrder: widget.category?.sortOrder ?? widget.nextSortOrder,
      isActive: widget.category?.isActive ?? true,
      productionMode: _productionMode,
      image: _image,
      removeImage: _removeImage,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SaveProductCategoryCubit, SaveProductCategoryState>(
      listener: (context, state) {
        switch (state) {
          case SaveProductCategorySuccess(:final category):
            context.showSuccess(_isEditing ? 'تم تحديث التصنيف' : 'تم إضافة التصنيف');
            Navigator.of(context).pop(category);
          case SaveProductCategoryFailure(:final failure):
            // A complaint about the name is already under the box; anything else is a sentence
            // about the request as a whole and belongs in a snackbar.
            if (state.nameError == null) context.showFailure(failure);
          case _:
            break;
        }
      },
      builder: (context, state) {
        return Padding(
          // The keyboard's inset, so the fields on this sheet are never behind it.
          padding: EdgeInsets.only(
            left: 16.w,
            right: 16.w,
            top: 8.h,
            bottom: MediaQuery.viewInsetsOf(context).bottom + 16.h,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _Handle(),
                SizedBox(height: 12.h),
                Text(
                  _isEditing ? 'تعديل التصنيف' : 'تصنيف جديد',
                  style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 4.h),
                Text(
                  'العنوان الذي تُعرض تحته المنتجات — أكياس، علب وكراتين، ستيكرات…',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 16.h),
                AppTextField(
                  controller: _name,
                  label: 'اسم التصنيف',
                  onChanged: (_) => context.read<SaveProductCategoryCubit>().clearFailure(),
                  validator: Validators.compose([
                    Validators.required,
                    Validators.minLength(2),
                  ]),
                  // The server's own complaint — «التصنيف مسجّل مسبقاً» — under the box holding
                  // the name it is about.
                  errorText: state.nameError,
                ),
                SizedBox(height: 12.h),
                AppTextField(
                  controller: _description,
                  label: 'الوصف (اختياري)',
                  hint: 'السطر الذي يظهر تحت العنوان في الكتالوج',
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                ),
                SizedBox(height: 12.h),
                // **Offered when adding as well as when editing**, unlike «يُعرض في قوائم
                // الاختيار» on the sibling sheets: a category is created to be used, so its
                // activation switch has one answer and is a row to read past — but «أكياس سادة»
                // is created *because* it is not printed, and «كروت بزنس» *because* a vendor
                // makes them; asking on the second visit would put the first orders under
                // either through a designer and a press nobody meant to involve.
                _ProductionModeField(
                  value: _productionMode,
                  isUnknown: _modeIsUnknown,
                  onChanged: (mode) => setState(() => _productionMode = mode),
                ),
                SizedBox(height: 12.h),
                _ImageRow(
                  picked: _image,
                  existingUrl: _showsExistingImage ? widget.category!.imageUrl : null,
                  onPick: () => unawaited(_pickImage()),
                  onClear: () => setState(() {
                    _image = null;
                    // Only a picture the *server* holds needs removing; discarding one picked a
                    // moment ago is just putting the sheet back where it was.
                    _removeImage = widget.category?.hasImage ?? false;
                  }),
                ),
                SizedBox(height: 20.h),
                AppButton(
                  label: _isEditing ? 'حفظ' : 'إضافة',
                  isLoading: state.isSubmitting,
                  onPressed: _submit,
                ),
                if (_isEditing) ...[
                  SizedBox(height: 8.h),
                  _DeleteRow(category: widget.category!, onDelete: widget.onDelete),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// «طريقة التنفيذ» — the three roads, and what choosing each one does to an order.
///
/// **Three segments where a switch used to be.** The switch asked «هل يُطبع؟» and the shop has
/// three kinds of work: printed here, picked off a shelf, or made by a vendor. The last two both
/// answer «لا» to the old question and take different roads, which is why the boolean went.
///
/// The line under the segments is the consequence, not a restatement of the label: what the
/// choice changes is which buttons the order screen offers and whether a warehouse is asked
/// for, and that is what somebody standing over this form is deciding about.
class _ProductionModeField extends StatelessWidget {
  const _ProductionModeField({
    required this.value,
    required this.isUnknown,
    required this.onChanged,
  });

  final ProductionMode value;

  /// The row came with a mode this build has no word for. Said out loud, because saving would
  /// overwrite it with whichever segment is lit.
  final bool isUnknown;

  final ValueChanged<ProductionMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'طريقة التنفيذ',
          style: context.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        SizedBox(height: 6.h),
        SegmentedButton<ProductionMode>(
          segments: [
            for (final mode in ProductionMode.choices)
              ButtonSegment<ProductionMode>(value: mode, label: Text(_shortLabel(mode))),
          ],
          selected: {value},
          showSelectedIcon: false,
          onSelectionChanged: (choice) => onChanged(choice.first),
        ),
        SizedBox(height: 6.h),
        Text(
          isUnknown
              ? 'هذا التصنيف بطريقة تنفيذ لا يعرفها هذا الإصدار من التطبيق — الحفظ سيستبدلها '
                    'بالخيار المحدد.'
              : _consequence(value),
          style: context.textTheme.bodySmall?.copyWith(
            color: isUnknown ? scheme.error : scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// One word per segment — three of them have to share a phone's width. The server's own
  /// longer label is what the card prints.
  static String _shortLabel(ProductionMode mode) => switch (mode) {
    ProductionMode.inHouse => 'مطبوعة',
    ProductionMode.none => 'سادة',
    ProductionMode.outsourced => 'وسيط',
    ProductionMode.unknown => mode.label,
  };

  static String _consequence(ProductionMode mode) => switch (mode) {
    ProductionMode.inHouse =>
      'نصمّمها ونطبعها هنا — الطلب يمرّ بالتصميم والطباعة، ويُخصم من المخزون عند «جاهزة».',
    ProductionMode.none =>
      'جاهزة من الرفّ — الطلب المكوّن كلّه من منتجات هذا التصنيف ينتقل من «جديدة» إلى '
          '«جاهزة» مباشرة، ويُخصم من المخزون عندها كأي طلب.',
    ProductionMode.outsourced =>
      'يصنعها مورد خارجي — لكل مقاس سعر تكلفة، ويُختار المورد عند أخذ الطلب، ويمرّ الطلب '
          'بـ«قيد التصنيع» دون أن يلمس أي مخزن.',
    ProductionMode.unknown => '',
  };
}

/// The picture the catalogue prints above the heading — pick one, replace it, or take it off.
///
/// **Optional, and it says so.** A heading is useful the moment it has a name; the picture is
/// for the catalogue page, and a required one would stop somebody adding «ستيكرات» at speed
/// because they have no artwork to hand.
class _ImageRow extends StatelessWidget {
  const _ImageRow({
    required this.picked,
    required this.existingUrl,
    required this.onPick,
    required this.onClear,
  });

  /// Chosen on this sheet and not yet sent.
  final PickedFile? picked;

  /// What the server already holds, unless it has been asked to go.
  final String? existingUrl;

  final VoidCallback onPick;
  final VoidCallback onClear;

  bool get _hasSomething => picked != null || existingUrl != null;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final corner = BorderRadius.circular(12.r);

    return InkWell(
      onTap: onPick,
      borderRadius: corner,
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          borderRadius: corner,
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          children: [
            _Preview(picked: picked, existingUrl: existingUrl, corner: corner),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    picked?.name ?? 'صورة التصنيف',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    _hasSomething ? 'اضغط للاستبدال' : 'اختيارية — اضغط للاختيار',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // Absent until there is something to take off: a clear button over an empty slot is
            // a control that does nothing.
            if (_hasSomething)
              IconButton(
                onPressed: onClear,
                icon: Icon(AppIcons.clear, color: scheme.onSurfaceVariant),
                tooltip: 'حذف الصورة',
              ),
          ],
        ),
      ),
    );
  }
}

/// The thumbnail, or the glyph that stands in for one.
class _Preview extends StatelessWidget {
  const _Preview({required this.picked, required this.existingUrl, required this.corner});

  final PickedFile? picked;
  final String? existingUrl;
  final BorderRadius corner;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final size = 52.w;

    final child = switch ((picked, existingUrl)) {
      (final PickedFile file, _) => Image.file(File(file.path), fit: BoxFit.cover),
      (_, final String url) => Image.network(
        url,
        fit: BoxFit.cover,
        // A signed link that has expired, or a phone with no connection: the glyph is what the
        // row looks like anyway, so a broken-image icon would say nothing extra.
        errorBuilder: (context, _, _) => Icon(AppIcons.productCategory, color: scheme.outline),
      ),
      _ => Icon(AppIcons.productCategory, color: scheme.outline),
    };

    return ClipRRect(
      borderRadius: corner,
      child: Container(
        height: size,
        width: size,
        color: scheme.surfaceContainerHighest,
        child: child,
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        height: 4.h,
        width: 40.w,
        decoration: BoxDecoration(
          color: context.colorScheme.outlineVariant,
          borderRadius: BorderRadius.circular(2.r),
        ),
      ),
    );
  }
}

/// Removing a heading, and — far more often — saying why that is not what is wanted.
///
/// A category with products in it is not deletable, and this is where that is explained: both
/// the name and the count are already on screen here, so the rule is read before the button is
/// pressed rather than discovered from a 422 afterwards.
class _DeleteRow extends StatelessWidget {
  const _DeleteRow({required this.category, this.onDelete});

  final ProductCategory category;
  final Future<bool> Function()? onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    if (onDelete == null) return const SizedBox.shrink();

    if (category.isInUse) {
      return Padding(
        padding: EdgeInsets.only(top: 4.h),
        child: Text(
          'لا يمكن حذف تصنيف مرتبط بمنتجات. أوقفه من القائمة ليختفي من الاختيارات، وتبقى '
          'المنتجات المسجّلة تحته كما هي.',
          textAlign: TextAlign.center,
          style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      );
    }

    return AppButton.outlined(
      label: 'حذف التصنيف',
      onPressed: () async {
        final deleted = await onDelete!();

        if (deleted && context.mounted) Navigator.of(context).pop();
      },
    );
  }
}
