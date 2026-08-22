import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/warehouses/models/stock_movement.dart';
import 'package:dayaa/features/warehouses/models/warehouse.dart';
import 'package:dayaa/features/warehouses/presentation/viewmodel/record_movement_cubit.dart';
import 'package:dayaa/features/warehouses/presentation/widgets/variant_picker_sheet.dart';
import 'package:dayaa/features/warehouses/presentation/widgets/warehouse_picker_sheet.dart';
import 'package:dayaa/features/warehouses/usecases/record_stock_movement.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Writing one line into the ledger — a delivery arriving, stock moving between our own places,
/// or a count that disagreed with the record.
///
/// **One sheet for all four kinds**, because the questions are the same three: which size, how
/// much, and where. Only the *where* differs — a transfer asks for both ends, everything else
/// for one — so the kind is a row of chips at the top rather than four separate screens.
///
/// Returns the movement the server wrote, so the screen behind can re-read the balance it
/// moved rather than compute one.
Future<StockMovement?> showRecordMovementSheet({
  required BuildContext context,
  Warehouse? warehouse,
}) {
  return showModalBottomSheet<StockMovement>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => BlocProvider<RecordMovementCubit>(
      create: (_) => sl<RecordMovementCubit>(),
      child: _RecordMovementForm(warehouse: warehouse),
    ),
  );
}

class _RecordMovementForm extends StatefulWidget {
  const _RecordMovementForm({this.warehouse});

  /// The warehouse this was opened from, pre-filled as the place being moved into or corrected.
  final Warehouse? warehouse;

  @override
  State<_RecordMovementForm> createState() => _RecordMovementFormState();
}

class _RecordMovementFormState extends State<_RecordMovementForm> {
  final _formKey = GlobalKey<FormState>();
  final _quantity = TextEditingController();
  final _notes = TextEditingController();

  MovementKind _kind = MovementKind.arrival;
  int? _variantId;
  String? _variantLabel;

  /// What the shelf counts this size in — «قطعة» or «كيلوغرام», the server's own word.
  ///
  /// Held so the quantity field can say which unit it is asking for. It is the *stock* unit and
  /// not the pricing one: a bag sold by the piece may still be weighed onto the shelf, and this
  /// sheet writes to the shelf.
  String? _stockUnitLabel;
  late Warehouse? _warehouse = widget.warehouse;
  Warehouse? _source;

  @override
  void dispose() {
    _quantity.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickVariant() async {
    final picked = await showVariantPicker(context: context);
    if (picked == null) return;

    setState(() {
      _variantId = picked.variant.id;
      _variantLabel = '${picked.product.name} · ${picked.variant.label}';
      _stockUnitLabel = picked.product.stockUnitLabel;
    });
  }

  Future<void> _pickWarehouse({required bool isSource}) async {
    final picked = await showWarehousePicker(context: context);
    if (picked == null) return;

    setState(() => isSource ? _source = picked : _warehouse = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    // Said here rather than by the validators, because neither box holds text: an untouched
    // picker has nothing to mark red, so the sheet says what is missing instead.
    if (_variantId == null) {
      context.showError('اختر المقاس');

      return;
    }

    if (_warehouse == null) {
      context.showError('اختر ${_kind.destinationLabel}');

      return;
    }

    if (_kind.needsSource && _source == null) {
      context.showError('اختر المخزن المصدر');

      return;
    }

    context.read<RecordMovementCubit>().submit(
      kind: _kind,
      productVariantId: _variantId!,
      warehouseId: _warehouse!.id,
      fromWarehouseId: _source?.id,
      quantity: _quantity.text,
      notes: _notes.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RecordMovementCubit, RecordMovementState>(
      listener: (context, state) {
        switch (state) {
          case RecordMovementSuccess(:final movement):
            context.showSuccess('تم تسجيل الحركة');
            Navigator.of(context).pop(movement);
          case RecordMovementFailure(:final failure):
            if (state.mayHaveLanded) {
              // The one form in this app that must not say «أعد المحاولة»: a movement carries
              // no unique key, so a request that landed before the line dropped and is sent
              // again moves the stock twice.
              context.showError(
                'انقطع الاتصال ولا نعرف إن كانت الحركة قد سُجّلت. راجع سجل الحركات قبل إعادة '
                'التسجيل.',
              );
            } else if (!state.hasFieldErrors) {
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
          child: SingleChildScrollView(
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
                    'تسجيل حركة مخزون',
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  _KindChoice(
                    value: _kind,
                    onChanged: (kind) => setState(() {
                      _kind = kind;
                      // A source belongs to a transfer alone; leaving a stale one selected
                      // would send it with an adjustment the next time the chip changed.
                      if (!kind.needsSource) _source = null;
                    }),
                  ),
                  SizedBox(height: 14.h),
                  _PickerField(
                    caption: 'المقاس',
                    value: _variantLabel ?? 'اختر المنتج والمقاس',
                    isChosen: _variantId != null,
                    icon: AppIcons.products,
                    errorText: state.variantError,
                    onTap: _pickVariant,
                  ),
                  if (_kind.needsSource) ...[
                    SizedBox(height: 10.h),
                    _PickerField(
                      caption: 'المخزن المصدر',
                      value: _source?.name ?? 'اختر المخزن',
                      isChosen: _source != null,
                      icon: AppIcons.warehouse,
                      errorText: state.sourceError,
                      onTap: () => _pickWarehouse(isSource: true),
                    ),
                  ],
                  SizedBox(height: 10.h),
                  _PickerField(
                    caption: _kind.destinationLabel,
                    value: _warehouse?.name ?? 'اختر المخزن',
                    isChosen: _warehouse != null,
                    icon: AppIcons.warehouse,
                    errorText: state.warehouseError,
                    onTap: () => _pickWarehouse(isSource: false),
                  ),
                  SizedBox(height: 14.h),
                  AppTextField(
                    controller: _quantity,
                    // **Names the unit once a size is chosen.** «الكمية» alone asks for a number
                    // without saying of what, and the answer differs by product now that a bag
                    // sold by the piece can be stocked by the kilo — typing 200 meaning bags into
                    // a field that records kilograms is a mistake the form should not allow to be
                    // made silently. Plain «الكمية» until something is picked, because until then
                    // there is no unit to name.
                    label: _stockUnitLabel == null
                        ? 'الكمية'
                        : 'الكمية ($_stockUnitLabel)',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textDirection: TextDirection.ltr,
                    validator: Validators.compose([
                      Validators.required,
                      Validators.decimal(min: 0.001),
                    ]),
                    errorText: state.quantityError,
                    onChanged: (_) => context.read<RecordMovementCubit>().clearFailure(),
                  ),
                  SizedBox(height: 14.h),
                  AppTextField(
                    controller: _notes,
                    // Required on an adjustment and on nothing else, exactly as the API has it:
                    // «وجدنا أقل مما في السجل» records nothing until it says why.
                    label: _kind.isAdjustment ? 'سبب التسوية' : 'ملاحظات (اختياري)',
                    hint: _kind.isAdjustment ? 'مثال: تلف أثناء التخزين' : null,
                    maxLines: 2,
                    textInputAction: TextInputAction.done,
                    validator: _kind.isAdjustment
                        ? Validators.compose([
                            Validators.required,
                            Validators.minLength(3),
                          ])
                        : null,
                    errorText: state.notesError,
                    onChanged: (_) => context.read<RecordMovementCubit>().clearFailure(),
                  ),
                  SizedBox(height: 20.h),
                  AppButton(
                    label: 'تسجيل',
                    isLoading: state.isSubmitting,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The four kinds, as chips. Two of them are the same adjustment in opposite directions, and
/// they are separate chips rather than a switch beside one, because «نقص» is the one a
/// storekeeper must not choose by accident.
class _KindChoice extends StatelessWidget {
  const _KindChoice({required this.value, required this.onChanged});

  final MovementKind value;
  final ValueChanged<MovementKind> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: [
        for (final kind in MovementKind.values)
          ChoiceChip(
            label: Text(kind.label),
            selected: kind == value,
            showCheckmark: false,
            onSelected: (_) => onChanged(kind),
            backgroundColor: scheme.surfaceContainerLowest,
            selectedColor: kind == MovementKind.decrease
                ? scheme.errorContainer
                : scheme.primaryContainer,
            labelStyle: context.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: kind != value
                  ? scheme.onSurfaceVariant
                  : kind == MovementKind.decrease
                  ? scheme.onErrorContainer
                  : scheme.onPrimaryContainer,
            ),
            side: BorderSide(
              color: kind == value ? Colors.transparent : scheme.outlineVariant,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          ),
      ],
    );
  }
}

/// A box that is filled by a sheet rather than by typing.
class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.caption,
    required this.value,
    required this.isChosen,
    required this.icon,
    required this.onTap,
    this.errorText,
  });

  final String caption;
  final String value;
  final bool isChosen;
  final IconData icon;
  final VoidCallback onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final radius = BorderRadius.circular(12.r);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: scheme.surfaceContainerLow,
          borderRadius: radius,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(
                  color: errorText == null ? scheme.outlineVariant : scheme.error,
                ),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 18.sp, color: scheme.onSurfaceVariant),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          caption,
                          style: context.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isChosen ? scheme.onSurface : scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(AppIcons.forward, size: 16.sp, color: scheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          SizedBox(height: 4.h),
          Text(
            errorText!,
            style: context.textTheme.bodySmall?.copyWith(color: scheme.error),
          ),
        ],
      ],
    );
  }
}
