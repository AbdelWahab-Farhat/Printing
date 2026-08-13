import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/di/injector.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/core/utils/validators.dart';
import 'package:printing/core/widgets/app_button.dart';
import 'package:printing/core/widgets/app_text_field.dart';
import 'package:printing/features/products/models/product_category.dart';
import 'package:printing/features/products/presentation/viewmodel/save_product_category_cubit.dart';

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

  bool get _isEditing => widget.category != null;

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
