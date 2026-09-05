import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/warehouses/models/warehouse.dart';
import 'package:dayaa/features/warehouses/presentation/viewmodel/save_warehouse_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Adds a warehouse, or edits one.
///
/// Returns the warehouse the **server** stored, or null when the sheet was dismissed — so the
/// list behind it refreshes only when there is something to refresh for.
///
/// [onDelete] is the list's own delete, handed in rather than performed here: removing a place
/// is the list's operation, and this sheet has nothing left to show afterwards.
Future<Warehouse?> showWarehouseSheet({
  required BuildContext context,
  Warehouse? warehouse,
  Future<bool> Function()? onDelete,
}) {
  return showModalBottomSheet<Warehouse>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => BlocProvider<SaveWarehouseCubit>(
      create: (_) => sl<SaveWarehouseCubit>(),
      child: _WarehouseForm(warehouse: warehouse, onDelete: onDelete),
    ),
  );
}

class _WarehouseForm extends StatefulWidget {
  const _WarehouseForm({required this.warehouse, this.onDelete});

  final Warehouse? warehouse;
  final Future<bool> Function()? onDelete;

  @override
  State<_WarehouseForm> createState() => _WarehouseFormState();
}

class _WarehouseFormState extends State<_WarehouseForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(
    text: widget.warehouse?.name ?? '',
  );
  late final TextEditingController _location = TextEditingController(
    text: widget.warehouse?.location ?? '',
  );

  /// An unknown kind — one the server grew after this build — falls back to the commonest, so
  /// the picker always has a selection rather than an empty slot.
  late WarehouseType _type = switch (widget.warehouse?.type) {
    final type? when type != WarehouseType.unknown => type,
    _ => WarehouseType.operational,
  };

  bool get _isEditing => widget.warehouse != null;

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    context.read<SaveWarehouseCubit>().submit(
      warehouseId: widget.warehouse?.id,
      name: _name.text,
      type: _type,
      location: _location.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SaveWarehouseCubit, SaveWarehouseState>(
      listener: (context, state) {
        switch (state) {
          case SaveWarehouseSuccess(:final warehouse):
            context.showSuccess(_isEditing ? 'تم تحديث المخزن' : 'تم إضافة المخزن');
            Navigator.of(context).pop(warehouse);
          case SaveWarehouseFailure(:final failure):
            // A complaint about a field is already under its box; anything else is a sentence
            // about the request as a whole.
            if (state.nameError == null && state.locationError == null) {
              context.showFailure(failure);
            }
          case _:
            break;
        }
      },
      builder: (context, state) {
        return Padding(
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
                Center(
                  child: Container(
                    height: 4.h,
                    width: 40.w,
                    decoration: BoxDecoration(
                      color: context.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  _isEditing ? 'تعديل المخزن' : 'مخزن جديد',
                  style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 16.h),
                AppTextField(
                  controller: _name,
                  label: 'اسم المخزن',
                  hint: 'مثال: المخزن الرئيسي',
                  validator: Validators.compose([
                    Validators.required,
                    Validators.minLength(2),
                  ]),
                  errorText: state.nameError,
                  onChanged: (_) => context.read<SaveWarehouseCubit>().clearFailure(),
                ),
                SizedBox(height: 14.h),
                _TypeChoice(
                  value: _type,
                  onChanged: (type) => setState(() => _type = type),
                ),
                SizedBox(height: 14.h),
                AppTextField(
                  controller: _location,
                  label: 'الموقع (اختياري)',
                  hint: 'مثال: ورشة الظهرة',
                  textInputAction: TextInputAction.done,
                  errorText: state.locationError,
                  onChanged: (_) => context.read<SaveWarehouseCubit>().clearFailure(),
                  onSubmitted: (_) => _submit(),
                ),
                SizedBox(height: 20.h),
                AppButton(
                  label: _isEditing ? 'حفظ' : 'إضافة',
                  isLoading: state.isSubmitting,
                  onPressed: _submit,
                ),
                if (_isEditing && widget.onDelete != null) ...[
                  SizedBox(height: 8.h),
                  _DeleteRow(warehouse: widget.warehouse!, onDelete: widget.onDelete!),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The three kinds the server knows, as one row of chips.
///
/// A chip row rather than a dropdown: there are two of them, they are short, and which one a
/// place is decides where stock is expected to sit — a fact worth reading without a tap.
class _TypeChoice extends StatelessWidget {
  const _TypeChoice({required this.value, required this.onChanged});

  final WarehouseType value;
  final ValueChanged<WarehouseType> onChanged;

  static const Map<WarehouseType, String> _labels = {
    WarehouseType.main: 'المخزن الرئيسي',
    WarehouseType.operational: 'مخزن التشغيل',
  };

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'النوع',
          style: context.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        SizedBox(height: 6.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            for (final entry in _labels.entries)
              ChoiceChip(
                label: Text(entry.value),
                selected: entry.key == value,
                showCheckmark: false,
                onSelected: (_) => onChanged(entry.key),
                backgroundColor: scheme.surfaceContainerLowest,
                selectedColor: scheme.primaryContainer,
                labelStyle: context.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: entry.key == value
                      ? scheme.onPrimaryContainer
                      : scheme.onSurfaceVariant,
                ),
                side: BorderSide(
                  color: entry.key == value ? Colors.transparent : scheme.outlineVariant,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
          ],
        ),
      ],
    );
  }
}

/// Removing a place — and, far more often, saying why that is not what is wanted.
class _DeleteRow extends StatelessWidget {
  const _DeleteRow({required this.warehouse, required this.onDelete});

  final Warehouse warehouse;
  final Future<bool> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    if (warehouse.holdsStock) {
      return Padding(
        padding: EdgeInsets.only(top: 4.h),
        child: Text(
          'لا يمكن حذف مخزن ما زال يحتوي على مخزون. حوّل ما فيه إلى مخزن آخر أولاً.',
          textAlign: TextAlign.center,
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return AppButton.outlined(
      label: 'حذف المخزن',
      onPressed: () async {
        final deleted = await onDelete();

        if (deleted && context.mounted) Navigator.of(context).pop();
      },
    );
  }
}
