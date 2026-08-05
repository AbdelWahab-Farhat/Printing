import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/di/injector.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/core/utils/validators.dart';
import 'package:printing/core/widgets/app_button.dart';
import 'package:printing/core/widgets/app_text_field.dart';
import 'package:printing/features/business_fields/models/business_field.dart';
import 'package:printing/features/business_fields/presentation/viewmodel/save_business_field_cubit.dart';

/// Adds a trade to the list, or renames one already on it.
///
/// A sheet rather than a screen: it is one question with a one-line answer, and a page for it
/// would put a navigation step either side of a single text box.
///
/// Returns the field the **server** stored, or null when the sheet was dismissed — so the list
/// behind it refreshes only when there is something to refresh for.
///
/// [nextSortOrder] is where a *new* field lands in the picker. The screen passes the end of the
/// list, so a trade added today appears after the ones already there instead of jumping to the
/// top of a form nobody was asked to fill in. Renaming keeps whatever order the field had.
///
/// [onDelete] is the list's own delete, handed in rather than performed here: removing a row is
/// the *list's* operation — the answer is a list with one row fewer, and this sheet has nothing
/// left to show afterwards. It answers `true` when the field is gone, and the sheet closes.
Future<BusinessField?> showBusinessFieldSheet({
  required BuildContext context,
  BusinessField? field,
  int nextSortOrder = 0,
  Future<bool> Function()? onDelete,
}) {
  return showModalBottomSheet<BusinessField>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => BlocProvider<SaveBusinessFieldCubit>(
      create: (_) => sl<SaveBusinessFieldCubit>(),
      child: _BusinessFieldForm(
        field: field,
        nextSortOrder: nextSortOrder,
        onDelete: onDelete,
      ),
    ),
  );
}

class _BusinessFieldForm extends StatefulWidget {
  const _BusinessFieldForm({
    required this.field,
    required this.nextSortOrder,
    this.onDelete,
  });

  final BusinessField? field;
  final int nextSortOrder;
  final Future<bool> Function()? onDelete;

  @override
  State<_BusinessFieldForm> createState() => _BusinessFieldFormState();
}

class _BusinessFieldFormState extends State<_BusinessFieldForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(text: widget.field?.name ?? '');

  bool get _isEditing => widget.field != null;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    context.read<SaveBusinessFieldCubit>().submit(
      fieldId: widget.field?.id,
      name: _name.text,
      // A rename must not silently re-offer a field somebody stopped, and must not reshuffle
      // the picker: both travel back exactly as they were.
      sortOrder: widget.field?.sortOrder ?? widget.nextSortOrder,
      isActive: widget.field?.isActive ?? true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SaveBusinessFieldCubit, SaveBusinessFieldState>(
      listener: (context, state) {
        switch (state) {
          case SaveBusinessFieldSuccess(:final field):
            context.showSuccess(_isEditing ? 'تم تحديث مجال العمل' : 'تم إضافة مجال العمل');
            Navigator.of(context).pop(field);
          case SaveBusinessFieldFailure(:final failure):
            // A complaint about the name is already under the box; anything else is a sentence
            // about the request as a whole and belongs in a snackbar.
            if (state.nameError == null) context.showFailure(failure);
          case _:
            break;
        }
      },
      builder: (context, state) {
        return Padding(
          // The keyboard's inset, so the one field on this sheet is never behind it.
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
                  _isEditing ? 'تعديل مجال العمل' : 'مجال عمل جديد',
                  style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 4.h),
                Text(
                  'ما الذي يبيعه محل الزبون — شحن، بيع ملابس، مطاعم…',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 16.h),
                AppTextField(
                  controller: _name,
                  label: 'اسم مجال العمل',
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => context.read<SaveBusinessFieldCubit>().clearFailure(),
                  onSubmitted: (_) => _submit(),
                  validator: Validators.compose([
                    Validators.required,
                    Validators.minLength(2),
                  ]),
                  // The server's own complaint — «مجال العمل مسجّل مسبقاً» — under the box
                  // holding the name it is about.
                  errorText: state.nameError,
                ),
                SizedBox(height: 20.h),
                AppButton(
                  label: _isEditing ? 'حفظ' : 'إضافة',
                  isLoading: state.isSubmitting,
                  onPressed: _submit,
                ),
                if (_isEditing) ...[
                  SizedBox(height: 8.h),
                  _DeleteRow(field: widget.field!, onDelete: widget.onDelete),
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

/// Removing a trade, and — far more often — saying why that is not what is wanted.
///
/// A field with shops in it is not deletable, and this is where that is explained: both the
/// name and the count are already on screen here, so the rule is read before the button is
/// pressed rather than discovered from a 422 afterwards.
class _DeleteRow extends StatelessWidget {
  const _DeleteRow({required this.field, this.onDelete});

  final BusinessField field;
  final Future<bool> Function()? onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    if (onDelete == null) return const SizedBox.shrink();

    if (field.isInUse) {
      return Padding(
        padding: EdgeInsets.only(top: 4.h),
        child: Text(
          'لا يمكن حذف مجال مرتبط بمحلات. أوقفه من القائمة ليختفي من الاختيارات، وتبقى المحلات '
          'المسجّلة عليه كما هي.',
          textAlign: TextAlign.center,
          style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      );
    }

    return AppButton.outlined(
      label: 'حذف المجال',
      onPressed: () async {
        final deleted = await onDelete!();

        if (deleted && context.mounted) Navigator.of(context).pop();
      },
    );
  }
}
