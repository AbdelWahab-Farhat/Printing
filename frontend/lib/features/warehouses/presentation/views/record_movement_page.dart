import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/stock_items/presentation/widgets/stock_item_picker_sheet.dart';
import 'package:dayaa/features/warehouses/models/warehouse.dart';
import 'package:dayaa/features/warehouses/presentation/viewmodel/record_movement_cubit.dart';
import 'package:dayaa/features/warehouses/presentation/widgets/warehouse_picker_sheet.dart';
import 'package:dayaa/features/warehouses/usecases/record_stock_movement.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Where a movement is being recorded, when the screen already knows.
///
/// **Opened from a shelf, the shelf is not a question.** A storekeeper standing on «اكياس سادة ·
/// المخزن الرئيسي» has already answered both, and offering them as pickers invites the one
/// mistake this form cannot catch — a quantity written off the wrong pile. So they are drawn as
/// a heading and cannot be changed; recording against something else means going there.
class MovementContext {
  const MovementContext({
    required this.stockItemId,
    required this.stockItemName,
    required this.warehouseId,
    required this.warehouseName,
    this.unitLabel,
  });

  final int stockItemId;
  final String stockItemName;
  final int warehouseId;
  final String warehouseName;

  /// What the shelf is counted in, so the quantity box can say it.
  final String? unitLabel;
}

/// Writing one line into the ledger — a delivery arriving, stock moving between our own places,
/// or a count that disagreed with the record.
///
/// **One page for all four kinds**, because the questions are the same three: which shelf, how
/// much, and where. Only the *where* differs — a transfer asks for both ends, everything else
/// for one — so the kind is a row of chips at the top rather than four separate screens.
///
/// **A page rather than a sheet.** The form grew a reason, a cost and a note; a sheet holding
/// three pickers of its own leaves the fields being typed into under the keyboard, which is
/// where they were.
///
/// **The first question is a صنف مخزني, and it used to be a product's size.** The picker no
/// longer walks the catalogue: «كيس شحن سادة» and «كيس شحن مطبوع» at 25*35 are one pile, so
/// asking which *product* is being moved would have made a storekeeper answer a question the
/// shelf cannot tell apart — and whichever of the two they picked, the same bags would move.
///
/// Pops with the movement the server wrote, so the screen behind can re-read the balance it
/// moved rather than compute one.
class RecordMovementPage extends StatelessWidget {
  const RecordMovementPage({super.key, this.warehouse, this.context});

  /// Pre-filled and still editable — opened from a warehouse's own balances.
  final Warehouse? warehouse;

  /// Fixed and not editable — opened from one shelf inside one warehouse.
  final MovementContext? context;

  @override
  Widget build(BuildContext ctx) {
    return BlocProvider<RecordMovementCubit>(
      create: (_) => sl<RecordMovementCubit>(),
      child: _RecordMovementForm(warehouse: warehouse, fixed: context),
    );
  }
}

class _RecordMovementForm extends StatefulWidget {
  const _RecordMovementForm({this.warehouse, this.fixed});

  /// The warehouse this was opened from, pre-filled as the place being moved into or corrected.
  final Warehouse? warehouse;

  /// The shelf and warehouse this was opened from, when both are already settled.
  final MovementContext? fixed;

  @override
  State<_RecordMovementForm> createState() => _RecordMovementFormState();
}

class _RecordMovementFormState extends State<_RecordMovementForm> {
  final _formKey = GlobalKey<FormState>();
  final _quantity = TextEditingController();
  final _unitCost = TextEditingController();
  final _notes = TextEditingController();

  /// Why the stock went, on a decrease. **Not defaulted to «هالك»**: a pre-picked answer is the
  /// one that gets recorded, and «كم هالك هذا الشهر؟» is the question this field exists to make
  /// answerable.
  ShortfallReason? _shortfallReason;

  MovementKind _kind = MovementKind.arrival;
  late int? _stockItemId = widget.fixed?.stockItemId;
  late String? _stockItemLabel = widget.fixed?.stockItemName;

  /// Whether the shelf and the warehouse were settled before this screen opened.
  bool get _isFixed => widget.fixed != null;

  /// What this shelf is counted in — «قطعة» or «كيلوغرام», the server's own word for it.
  ///
  /// Held so the quantity field can say which unit it is asking for. **It belongs to the shelf
  /// and to nothing else**: `products.stock_unit` was dropped precisely because two products
  /// sharing one pile cannot be allowed to disagree about how it is counted, and a product's
  /// `pricing_unit` — what the customer is charged by — never governed this field.
  late String? _unitLabel = widget.fixed?.unitLabel;
  late Warehouse? _warehouse = widget.warehouse;
  Warehouse? _source;

  @override
  void dispose() {
    _quantity.dispose();
    _unitCost.dispose();
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

    // The API refuses the movement without it, and a chip row has nothing to mark red.
    if (_kind == MovementKind.decrease && _shortfallReason == null) {
      context.showError('اختر نوع النقص: هالك أم عجز أم فرق جرد');

      return;
    }

    context.read<RecordMovementCubit>().submit(
      kind: _kind,
      stockItemId: _stockItemId!,
      warehouseId: _warehouse!.id,
      fromWarehouseId: _source?.id,
      quantity: _quantity.text,
      unitCost: _unitCost.text,
      shortfallReason: _shortfallReason,
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
        return Scaffold(
          appBar: AppBar(
            title: Column(
              children: [
                const Text('تسجيل حركة مخزون'),
                if (widget.fixed case final fixed?)
                  Text(
                    '${fixed.stockItemName} · ${fixed.warehouseName}',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                16.w,
                16.h,
                16.w,
                MediaQuery.viewInsetsOf(context).bottom + 24.h,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  _KindChoice(
                    value: _kind,
                    onChanged: (kind) => setState(() {
                      _kind = kind;
                      // A source belongs to a transfer alone; leaving a stale one selected
                      // would send it with an adjustment the next time the chip changed.
                      if (!kind.needsSource) _source = null;
                      // Cleared for the same reason, though nothing depends on it: the use case
                      // drops a cost this kind cannot carry. This is so a figure that vanished
                      // when the chip moved does not reappear when it moves back — the box was
                      // emptied, not merely hidden.
                      if (!kind.opensCostLayer) _unitCost.clear();
                    }),
                  ),
                  // **Opened from a shelf, the shelf is not a question.** Both answers are
                  // already on the screen behind, and offering them again invites the one
                  // mistake this form cannot catch — a quantity written off the wrong pile.
                  if (!_isFixed) ...[
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
                  ],
                  // The source is asked for even on a fixed shelf: a transfer's other end is a
                  // real question, and the fixed warehouse is the destination.
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
                  if (!_isFixed) ...[
                    SizedBox(height: 10.h),
                    _PickerField(
                      caption: _kind.destinationLabel,
                      value: _warehouse?.name ?? 'اختر المخزن',
                      isChosen: _warehouse != null,
                      icon: AppIcons.warehouse,
                      errorText: state.warehouseError,
                      onTap: () => _pickWarehouse(isSource: false),
                    ),
                  ],
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
                  if (_kind.opensCostLayer) ...[
                    SizedBox(height: 14.h),
                    AppTextField(
                      controller: _unitCost,
                      // **Per unit, said out loud.** «التكلفة» alone reads as the price of the
                      // whole delivery on a form whose previous question was a quantity — and the
                      // two are three digits apart. The unit is the shelf's own, exactly as the
                      // quantity box above states it.
                      label: _unitLabel == null
                          ? 'تكلفة الوحدة'
                          : 'تكلفة الوحدة (لكل $_unitLabel)',
                      // Optional on an arrival whose invoice has not turned up yet: the layer
                      // opens at zero and waits in the uncosted queue. The stocktake that found
                      // more than the book said has no such document to wait for, and the API
                      // refuses it without a price.
                      hint: _kind.requiresCost ? null : 'اتركها فارغة إن لم يُسجَّل السعر بعد',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textDirection: TextDirection.ltr,
                      validator: _kind.requiresCost
                          ? Validators.decimal(min: 0)
                          // Zero is allowed where it is typed deliberately — «مجانية» is a real
                          // claim. What must not happen is an untouched box becoming one.
                          : Validators.optional(Validators.decimal(min: 0)),
                      errorText: state.unitCostError,
                      onChanged: (_) => context.read<RecordMovementCubit>().clearFailure(),
                    ),
                  ],
                  // **Required on a decrease and refused on an increase**, exactly as the API
                  // has it: finding more than the book said is not a loss and has no word in
                  // this vocabulary. Placed above the notes, because the note explains the
                  // occasion and this names the kind.
                  if (_kind == MovementKind.decrease) ...[
                    SizedBox(height: 14.h),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        'نوع النقص',
                        style: context.textTheme.labelLarge?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    _ShortfallChoice(
                      value: _shortfallReason,
                      onChanged: (reason) {
                        setState(() => _shortfallReason = reason);
                        context.read<RecordMovementCubit>().clearFailure();
                      },
                    ),
                  ],
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
                  SizedBox(height: 24.h),
                  AppButton(label: 'تسجيل', isLoading: state.isSubmitting, onPressed: _submit),
                  ],
                ),
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

/// «هالك · عجز · فرق جرد», as chips — the same shape the kind above uses, because they are the
/// same kind of answer: a closed list a thumb picks from, not prose.
///
/// Nothing is selected until somebody selects it. The whole point of the field is that «نقص»
/// stopped being the answer, so a default would put the old answer back under a new name.
class _ShortfallChoice extends StatelessWidget {
  const _ShortfallChoice({required this.value, required this.onChanged});

  final ShortfallReason? value;
  final ValueChanged<ShortfallReason> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: [
        for (final reason in ShortfallReason.values)
          ChoiceChip(
            label: Text(reason.label),
            selected: reason == value,
            showCheckmark: false,
            onSelected: (_) => onChanged(reason),
            backgroundColor: scheme.surfaceContainerLowest,
            selectedColor: scheme.errorContainer,
            labelStyle: context.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: reason == value ? scheme.onErrorContainer : scheme.onSurfaceVariant,
            ),
            side: BorderSide(
              color: reason == value ? Colors.transparent : scheme.outlineVariant,
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
