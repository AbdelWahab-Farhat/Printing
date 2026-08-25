import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/stock_items/presentation/widgets/stock_item_picker_sheet.dart';
import 'package:dayaa/features/warehouses/models/stock_movement.dart';
import 'package:dayaa/features/warehouses/models/warehouse.dart';
import 'package:dayaa/features/warehouses/presentation/viewmodel/record_movement_cubit.dart';
import 'package:dayaa/features/warehouses/presentation/widgets/warehouse_picker_sheet.dart';
import 'package:dayaa/features/warehouses/usecases/record_stock_movement.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Writing one line into the ledger — a delivery arriving, stock moving between our own places,
/// or a count that disagreed with the record.
///
/// **One sheet for all four kinds**, because the questions are the same three: which shelf, how
/// much, and where. Only the *where* differs — a transfer asks for both ends, everything else
/// for one — so the kind is a row of chips at the top rather than four separate screens.
///
/// **The first question is a صنف مخزني, and it used to be a product's size.** The picker no
/// longer walks the catalogue: «كيس شحن سادة» and «كيس شحن مطبوع» at 25*35 are one pile, so
/// asking which *product* is being moved would have made a storekeeper answer a question the
/// shelf cannot tell apart — and whichever of the two they picked, the same bags would move.
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
  int? _stockItemId;
  String? _stockItemLabel;

  /// What this shelf is counted in — «قطعة» or «كيلوغرام», the server's own word for it.
  ///
  /// Held so the quantity field can say which unit it is asking for. **It belongs to the shelf
  /// and to nothing else**: `products.stock_unit` was dropped precisely because two products
  /// sharing one pile cannot be allowed to disagree about how it is counted, and a product's
  /// `pricing_unit` — what the customer is charged by — never governed this field.
  String? _unitLabel;
  late Warehouse? _warehouse = widget.warehouse;
  Warehouse? _source;

  @override
  void dispose() {
    _quantity.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickStockItem() async {
    final picked = await showStockItemPicker(context: context);
    if (picked == null) return;

    setState(() {
      _stockItemId = picked.id;
      // The server's own composition of name and size. Never rebuilt from the parts: the
      // shortfall an order is refused with quotes this exact string.
      _stockItemLabel = picked.displayName;
      _unitLabel = picked.unitLabel;
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
    if (_stockItemId == null) {
      context.showError('اختر المادة');

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
      stockItemId: _stockItemId!,
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
                    style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
                    caption: 'المادة',
                    value: _stockItemLabel ?? 'اختر المادة',
                    isChosen: _stockItemId != null,
                    // Not [AppIcons.warehouse], which the two boxes under this one already
                    // wear: three identical glyphs down one form stop distinguishing anything.
                    icon: AppIcons.tag,
                    errorText: state.stockItemError,
                    onTap: _pickStockItem,
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
                    // **Names the unit once a shelf is chosen.** «الكمية» alone asks for a number
                    // without saying of what, and the answer differs by shelf now that a bag
                    // sold by the piece can be stocked by the kilo — typing 200 meaning bags into
                    // a field that records kilograms is a mistake the form should not allow to be
                    // made silently. Plain «الكمية» until something is picked, because until then
                    // there is no unit to name.
                    label: _unitLabel == null ? 'الكمية' : 'الكمية ($_unitLabel)',
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
                        ? Validators.compose([Validators.required, Validators.minLength(3)])
                        : null,
                    errorText: state.notesError,
                    onChanged: (_) => context.read<RecordMovementCubit>().clearFailure(),
                  ),
                  SizedBox(height: 20.h),
                  AppButton(label: 'تسجيل', isLoading: state.isSubmitting, onPressed: _submit),
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
            side: BorderSide(color: kind == value ? Colors.transparent : scheme.outlineVariant),
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
                border: Border.all(color: errorText == null ? scheme.outlineVariant : scheme.error),
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
          Text(errorText!, style: context.textTheme.bodySmall?.copyWith(color: scheme.error)),
        ],
      ],
    );
  }
}
