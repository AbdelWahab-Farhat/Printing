import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_dialog.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/stock_item_groups/models/stock_item_group.dart';
import 'package:dayaa/features/stock_item_groups/presentation/viewmodel/save_stock_item_group_cubit.dart';
import 'package:dayaa/features/stock_items/models/stock_unit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Adds a material, or edits one.
///
/// Returns the material the **server** stored, or null when the sheet was dismissed — so the
/// list behind it refreshes only when there is something to refresh for.
///
/// [onDelete] is the list's own delete, handed in rather than performed here: removing a
/// material is the list's operation, and this sheet has nothing left to show afterwards.
Future<StockItemGroup?> showStockItemGroupSheet({
  required BuildContext context,
  StockItemGroup? group,
  Future<bool> Function()? onDelete,
}) {
  return showModalBottomSheet<StockItemGroup>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => BlocProvider<SaveStockItemGroupCubit>(
      create: (_) => sl<SaveStockItemGroupCubit>(),
      child: _StockItemGroupForm(group: group, onDelete: onDelete),
    ),
  );
}

/// **The two sentences on this form are the whole point of it.**
///
/// A material looks like a lookup row — a name and a unit — and it is not. Saving a new name
/// rewrites the name of every shelf filed under it, in one transaction on the server, because a
/// grouped item *carries* its material's name and that is what keeps `(name, width, height)`
/// naming one pile. And the unit here, which reads like the field that decides how stock is
/// counted, decides nothing about any stock that already exists: it is the default handed to a
/// size created *later*.
///
/// Both were learned by reading the server's actions rather than its docblocks, and neither is
/// visible from the form's shape, so each is said where the finger is: the rename in a dialog
/// that has to be dismissed, the unit under its own chips.
class _StockItemGroupForm extends StatefulWidget {
  const _StockItemGroupForm({required this.group, this.onDelete});

  final StockItemGroup? group;
  final Future<bool> Function()? onDelete;

  @override
  State<_StockItemGroupForm> createState() => _StockItemGroupFormState();
}

class _StockItemGroupFormState extends State<_StockItemGroupForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name = TextEditingController(
    text: widget.group?.name ?? '',
  );
  late final TextEditingController _description = TextEditingController(
    text: widget.group?.description ?? '',
  );

  /// A unit this build has never heard of falls back to the commoner one rather than leaving
  /// the row unselected — an empty choice would be saved as a silent change to the material.
  late StockUnit _unit = switch (widget.group?.defaultUnit) {
    final unit? when unit != StockUnit.unknown => unit,
    _ => StockUnit.piece,
  };

  late bool _isActive = widget.group?.isActive ?? true;

  bool get _isEditing => widget.group != null;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  /// Asks before a rename, and only before a rename.
  ///
  /// Fired on the name having actually changed, because re-saving a form without touching the
  /// name is not a rename and a dialog on every save is a dialog people learn to tap through.
  /// `renamesItems` is fail-closed on an unknown count — a sheet opened on a material the list
  /// did not count is asked anyway, which costs a tap and prevents the one mistake here nobody
  /// would notice until an order failed at «جاهزة».
  Future<bool> _confirmRename(StockItemGroup group) async {
    final count = group.itemsCount;

    final confirmed = await showCustomDialog(
      context: context,
      title: 'إعادة تسمية «${group.name}»؟',
      description:
          'المادة تحمل اسم تصنيفها، فتغيير الاسم هنا يُعيد تسمية '
          '${count == null ? 'كل مادة مسجّلة تحته' : '${count.grouped} مادةً مسجّلةً تحته'} '
          'في نفس اللحظة. الأرصدة وطبقات التكلفة لا تتغيّر، لكن الاسم القديم يختفي من كل شاشة.',
      severity: DialogSeverity.warning,
      confirmLabel: 'إعادة التسمية',
    );

    return confirmed ?? false;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Read before the first await: the sheet may be gone by the time the dialog answers.
    final cubit = context.read<SaveStockItemGroupCubit>();
    final group = widget.group;
    final name = _name.text.trim();

    if (group != null && name != group.name && group.renamesItems) {
      final confirmed = await _confirmRename(group);

      if (!confirmed || !mounted) return;
    }

    await cubit.submit(
      groupId: group?.id,
      name: name,
      defaultUnit: _unit,
      description: _description.text,
      isActive: _isActive,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SaveStockItemGroupCubit, SaveStockItemGroupState>(
      listener: (context, state) {
        switch (state) {
          case SaveStockItemGroupSuccess(:final group):
            context.showSuccess(
              _isEditing ? 'تم تحديث التصنيف' : 'تم إضافة التصنيف',
            );
            Navigator.of(context).pop(group);
          case SaveStockItemGroupFailure(:final failure):
            // A complaint about a field is already under its box; anything else is a sentence
            // about the request as a whole.
            if (state.nameError == null &&
                state.defaultUnitError == null &&
                state.descriptionError == null) {
              context.showFailure(failure);
            }
          case _:
            break;
        }
      },
      builder: (context, state) {
        final cubit = context.read<SaveStockItemGroupCubit>();

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
                    _isEditing ? 'تعديل التصنيف' : 'تصنيف جديد',
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  AppTextField(
                    controller: _name,
                    label: 'اسم التصنيف',
                    hint: 'مثال: كيس شحن',
                    validator: Validators.compose([
                      Validators.required,
                      Validators.minLength(2, label: 'اسم التصنيف'),
                      Validators.maxLength(255, label: 'اسم التصنيف'),
                    ]),
                    errorText: state.nameError,
                    onChanged: (_) => cubit.clearFailure(),
                  ),
                  SizedBox(height: 14.h),
                  _UnitChoice(
                    value: _unit,
                    isEditing: _isEditing,
                    errorText: state.defaultUnitError,
                    onChanged: (unit) => setState(() => _unit = unit),
                  ),
                  SizedBox(height: 14.h),
                  AppTextField(
                    controller: _description,
                    label: 'الوصف (اختياري)',
                    hint: 'ما يميّز هذا التصنيف عن غيره',
                    maxLines: 3,
                    validator: Validators.maxLength(500, label: 'الوصف'),
                    errorText: state.descriptionError,
                    onChanged: (_) => cubit.clearFailure(),
                  ),
                  // Kept off the new-material form for the reason the sibling صنف form keeps
                  // it off its own: a material is created to be used, and a switch whose answer
                  // is always the same is a row to read past.
                  //
                  // The label is word-for-word that form's, deliberately: it is the same column
                  // on two screens, and calling it two things would teach that it is two things.
                  if (_isEditing) ...[
                    SizedBox(height: 4.h),
                    SwitchListTile.adaptive(
                      value: _isActive,
                      onChanged: (value) => setState(() => _isActive = value),
                      title: const Text('يُعرض في قوائم الاختيار'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                  SizedBox(height: 20.h),
                  AppButton(
                    label: _isEditing ? 'حفظ' : 'إضافة',
                    isLoading: state.isSubmitting,
                    onPressed: _submit,
                  ),
                  // **Nothing at all when the server would refuse.** No button, and no
                  // paragraph in its place: «4 أصنافاً و1 منتجاً» is already printed on the row
                  // this sheet opened from, so a note here re-states what the person just read
                  // and turns the bottom of a form into an explanation of a button that is not
                  // there.
                  if (_isEditing && widget.onDelete != null && !widget.group!.isInUse) ...[
                    SizedBox(height: 8.h),
                    _DeleteRow(group: widget.group!, onDelete: widget.onDelete!),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The two units the server knows, as one row of chips — and the sentence that says what picking
/// one actually does.
///
/// A chip row rather than a dropdown: there are two of them, they are one word each, and what a
/// material is counted in is a fact worth reading without a tap.
///
/// **The labels come from the enum here, and only here.** Everywhere a response carries a
/// `default_unit_label` the app renders that instead; this row has to name *both* units, and one
/// of them belongs to no loaded record — on a brand-new material, neither does.
class _UnitChoice extends StatelessWidget {
  const _UnitChoice({
    required this.value,
    required this.isEditing,
    required this.onChanged,
    this.errorText,
  });

  final StockUnit value;
  final bool isEditing;
  final ValueChanged<StockUnit> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'وحدة التخزين الافتراضية',
          style: context.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        SizedBox(height: 6.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            for (final unit in StockUnit.choices)
              ChoiceChip(
                label: Text(unit.label),
                selected: unit == value,
                showCheckmark: false,
                onSelected: (_) => onChanged(unit),
                backgroundColor: scheme.surfaceContainerLowest,
                selectedColor: scheme.primaryContainer,
                labelStyle: context.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: unit == value ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
                ),
                side: BorderSide(
                  color: unit == value ? Colors.transparent : scheme.outlineVariant,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
          ],
        ),
        // **No paragraph under the chips.** The label says «الافتراضية», which is the whole
        // point of the field, and the one warning that used to live here — that changing a
        // live صنف's unit zeroes its balance — belongs at the moment somebody does it. It is
        // said there, in the confirm dialog on the صنف itself, where it can still stop them.
        if (errorText case final error?) ...[
          SizedBox(height: 4.h),
          Text(
            error,
            style: context.textTheme.bodySmall?.copyWith(color: scheme.error),
          ),
        ],
      ],
    );
  }
}

/// Removing a material.
///
/// **Only ever built for one the server would actually delete** — see the guard at the call site,
/// which is also why there is no refusal branch here. Fail-closed lives in
/// [StockItemGroup.isInUse]: a material whose counts never arrived is treated as in use, so an
/// unknown answer hides the button rather than offering one that 422s.
class _DeleteRow extends StatelessWidget {
  const _DeleteRow({required this.group, required this.onDelete});

  final StockItemGroup group;
  final Future<bool> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    return AppButton.outlined(
      label: 'حذف التصنيف',
      onPressed: () async {
        final deleted = await onDelete();

        if (deleted && context.mounted) Navigator.of(context).pop();
      },
    );
  }
}
