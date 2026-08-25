import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/stock_items/models/stock_item.dart';
import 'package:dayaa/features/stock_items/models/stock_unit.dart';
import 'package:dayaa/features/stock_items/presentation/viewmodel/save_stock_item_cubit.dart';
import 'package:dayaa/features/stock_items/presentation/widgets/stock_unit_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// What the form is opened on: an existing shelf, a material to file a new one under, or neither.
///
/// One record rather than two `extra` values, because GoRouter carries exactly one — and the two
/// are mutually exclusive in practice: a shelf that exists already knows its material, and the
/// server refuses to move it to another one.
typedef StockItemFormArgs = ({StockItem? item, StockItemGroupChoice? group});

/// Opens the form on [item], or on a new shelf — under [group] when one was named.
///
/// Answers `true` when something was saved, so the list behind refreshes only when there is
/// something to refresh for. A dismissed form answers null.
///
/// **The path is written here rather than read from `Routes`**, and that is temporary: this
/// feature was built alongside the router change rather than after it, and `core/router/` is
/// owned elsewhere. It is one function so that wiring it up is one edit — replace the literal
/// with `Routes.stockItemForm` and delete this paragraph.
Future<bool?> openStockItemForm(
  BuildContext context, {
  StockItem? item,
  StockItemGroupChoice? group,
}) {
  const path = '/stock-items/form';
  final StockItemFormArgs args = (item: item, group: group);

  return context.push<bool>(path, extra: args);
}

/// Opening a shelf, or correcting one.
///
/// **One screen for both**, because it is one form: the only difference is whether a stock item
/// arrived with it.
///
/// Three fields on it are not what they look like, and each is a rule the server owns:
///
///   * **the unit cannot be saved.** `PUT /stock-items/{id}` carries no rule for it, so sending
///     one is silently ignored. Moving it is `PATCH …/unit`, which **empties every warehouse
///     holding the shelf** — so it is a tile with its own action rather than a field on this
///     form, and it goes through [showStockUnitSheet], which refuses to answer until somebody has
///     agreed to that in writing;
///   * **a grouped shelf's name belongs to its material.** Every size of «كيس شحن» is called
///     «كيس شحن» — that is what keeps `(name, size)` able to identify one pile — so renaming one
///     size alone would quietly split the material in two. The box is read-only and points at the
///     material's own screen, where a rename covers every size in one transaction;
///   * **`sort_order` has no control and is still sent.** The update is a full replacement: an
///     absent `sort_order` renumbers the shelf to zero and an absent `is_active` re-offers one
///     somebody stopped. The first is round-tripped from what was loaded, the second has a
///     switch — and only while editing, because a new shelf is always created showing.
class StockItemFormPage extends StatelessWidget {
  const StockItemFormPage({this.item, this.group, super.key});

  /// Null opens a new shelf; anything else corrects that one.
  final StockItem? item;

  /// The material a **new** shelf is being filed under. Ignored while editing: the server carries
  /// no rule for changing a stock item's group, because re-filing a size under another material
  /// would rename it, and a rename is the one edit that can collide with a shelf that exists.
  final StockItemGroupChoice? group;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SaveStockItemCubit>(
      create: (_) => sl<SaveStockItemCubit>(),
      child: _StockItemFormView(item: item, group: group),
    );
  }
}

class _StockItemFormView extends StatefulWidget {
  const _StockItemFormView({this.item, this.group});

  final StockItem? item;
  final StockItemGroupChoice? group;

  @override
  State<_StockItemFormView> createState() => _StockItemFormViewState();
}

class _StockItemFormViewState extends State<_StockItemFormView> {
  final _formKey = GlobalKey<FormState>();

  /// The shelf as the **server** last described it.
  ///
  /// Mutable, and that is the point: changing the unit is a write that does not close this screen
  /// — it empties the balances instead — so the tile has to redraw from the answer rather than
  /// from what was tapped.
  late StockItem? _item = widget.item;

  late final TextEditingController _name = TextEditingController(
    text: widget.item?.name ?? widget.group?.name ?? '',
  );
  late final TextEditingController _width = TextEditingController(
    text: widget.item?.widthCm?.toString() ?? '',
  );
  late final TextEditingController _height = TextEditingController(
    text: widget.item?.heightCm?.toString() ?? '',
  );
  late final TextEditingController _description = TextEditingController(
    text: widget.item?.description ?? '',
  );

  /// Only ever chosen while creating a standalone shelf. Under a material it is the material's,
  /// and on an existing shelf it is whatever the last unit change left — never this field.
  late StockUnit _unit = widget.item?.unit ?? widget.group?.defaultUnit ?? StockUnit.piece;

  late bool _isActive = widget.item?.isActive ?? true;

  /// Round-tripped, never edited. See the note on [StockItemFormPage].
  late final int _sortOrder = widget.item?.sortOrder ?? 0;

  bool get _isEditing => _item != null;

  /// Whether a material decides the name — the one being created under, or the one an existing
  /// shelf is already filed under.
  bool get _nameBelongsToMaterial => widget.group != null || (_item?.belongsToGroup ?? false);

  @override
  void dispose() {
    _name.dispose();
    _width.dispose();
    _height.dispose();
    _description.dispose();
    super.dispose();
  }

  /// One validator for both halves of a size, closing over the other box.
  ///
  /// **Both or neither**: the server refuses a width with no height — half a size is not a size,
  /// and it would produce a shelf nobody could name. Empty on both sides is a real answer, for a
  /// thing counted without dimensions: a roll, an ink.
  Validator _sizeValidator(TextEditingController other) {
    return (String? value) {
      final mine = value?.trim() ?? '';
      final theirs = other.text.trim();

      if (mine.isEmpty && theirs.isEmpty) return null;
      if (mine.isEmpty) return 'العرض والطول يجب أن يُدخلا معاً';

      return Validators.integer(allowZero: false, min: 1, max: 1000)(mine);
    };
  }

  Future<void> _changeUnit() async {
    final item = _item;
    if (item == null) return;

    final picked = await showStockUnitSheet(context: context, item: item);

    // Null covers all three ways out: dismissed, the confirmation declined, and the unit it
    // already has — none of which is a request.
    if (picked == null || !mounted) return;

    await context.read<SaveStockItemCubit>().changeUnit(item.id, unit: picked);
  }

  void _submit() {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    context.read<SaveStockItemCubit>().submit(
      stockItemId: _item?.id,
      // Only ever on creation; the server ignores it on an update and the form does not offer it.
      stockItemGroupId: _isEditing ? null : widget.group?.id,
      name: _name.text,
      widthCm: _width.text,
      heightCm: _height.text,
      unit: _unit,
      description: _description.text,
      isActive: _isActive,
      sortOrder: _sortOrder,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SaveStockItemCubit, SaveStockItemState>(
      listener: (context, state) {
        switch (state) {
          case SaveStockItemSuccess(:final item):
            // True says the list behind should refresh; a dismissed form returns nothing.
            Navigator.of(context).pop(true);
            context.showSuccess(
              _isEditing ? 'تم تحديث ${item.displayName}' : 'تم إضافة ${item.displayName}',
            );

          // **The screen stays open.** What just happened is that every warehouse holding this
          // shelf was taken to zero; closing on that would be the app's last word on it, and the
          // person needs to see the tile now say the new unit.
          case SaveStockItemUnitChanged(:final item):
            setState(() {
              _item = item;
              _unit = item.unit;
            });
            context.showSuccess(
              'تم تحديث وحدة التخزين إلى «${item.unitLabel}»',
              details: 'صُفِّر الرصيد في كل مخزن يحتوي الصنف — أعد الجرد بالوحدة الجديدة.',
            );

          case SaveStockItemFailure(:final failure) when state.hasUnrenderedErrors:
            context.showFailure(failure);

          case _:
            break;
        }
      },
      builder: (context, state) {
        final cubit = context.read<SaveStockItemCubit>();

        // Only for a shelf the endpoint counted *and* that something draws on — a row that
        // arrived without `variants_count` says nothing rather than «لا مقاس يسحب منه».
        final sharedNotice = switch (_item) {
          final item? when item.isDrawnFrom => item.sharedByLabel,
          _ => null,
        };

        return Scaffold(
          appBar: AppBar(title: Text(_isEditing ? 'تعديل الصنف المخزني' : 'صنف مخزني جديد')),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
                children: [
                  if (sharedNotice case final shared?) ...[
                    _Notice(
                      icon: AppIcons.products,
                      // Said before anything is typed: renaming or resizing a shared shelf
                      // changes what every one of those sizes reads, and detaches none of them.
                      message:
                          '$shared. تغيير الاسم أو المقاس يغيّر ما تراه تلك المقاسات، ولا '
                          'يفصلها عن هذا الصنف.',
                    ),
                    SizedBox(height: 16.h),
                  ],

                  if (widget.group case final material? when !_isEditing) ...[
                    _MaterialTile(name: material.name, error: state.groupError),
                    SizedBox(height: 16.h),
                  ],

                  AppTextField(
                    controller: _name,
                    label: 'اسم الصنف',
                    hint: 'مثال: كيس شحن',
                    // Read-only under a material rather than absent, because the name is what
                    // the row will be called and hiding it would make the form unreadable.
                    readOnly: _nameBelongsToMaterial,
                    // Kept only where the box is read-only: a field somebody cannot type in
                    // owes them a reason. The free one needs no lecture — «اسم الصنف» over an
                    // empty box is the whole instruction.
                    helperText: _nameBelongsToMaterial
                        ? 'الاسم يأتي من المادة — يُغيَّر من شاشة المجموعة'
                        : null,
                    validator: Validators.compose([
                      Validators.required,
                      Validators.minLength(2, label: 'اسم الصنف'),
                    ]),
                    errorText: state.nameError,
                    onChanged: (_) => cubit.clearFailure(),
                  ),
                  SizedBox(height: 16.h),

                  _SizeRow(
                    width: _width,
                    height: _height,
                    widthValidator: _sizeValidator(_height),
                    heightValidator: _sizeValidator(_width),
                    error: state.sizeError,
                    onChanged: cubit.clearFailure,
                  ),
                  SizedBox(height: 16.h),

                  if (_item case final item?)
                    _UnitTile(
                      item: item,
                      isBusy: state.isChangingUnit,
                      error: state.unitError,
                      onChange: _changeUnit,
                    )
                  else
                    _UnitChoice(
                      value: _unit,
                      // Under a material the server takes the unit from its `default_unit`
                      // whatever is sent, so offering a choice here would be offering one that
                      // gets overruled on save.
                      isFixedByMaterial: widget.group != null,
                      error: state.unitError,
                      onChanged: (unit) {
                        cubit.clearFailure();
                        setState(() => _unit = unit);
                      },
                    ),
                  SizedBox(height: 16.h),

                  AppTextField(
                    controller: _description,
                    label: 'الوصف (اختياري)',
                    hint: 'ما يميّز هذه المادة، ومن أين تُشترى عادةً',
                    prefixIcon: AppIcons.edit,
                    maxLines: 3,
                    errorText: state.descriptionError,
                    onChanged: (_) => cubit.clearFailure(),
                  ),
                  // **Only on a shelf that already exists.** Nobody opens this form to add
                  // something they want hidden, so on the way in it is a question with one
                  // answer — [_isActive] starts true and is sent as true without being asked.
                  // Stopping a shelf is a real decision, and it belongs where it is taken.
                  if (_isEditing) ...[
                    SizedBox(height: 8.h),
                    SwitchListTile.adaptive(
                      value: _isActive,
                      onChanged: (value) => setState(() => _isActive = value),
                      title: const Text('يُعرض في قوائم الاختيار'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                  SizedBox(height: 28.h),

                  AppButton(
                    label: _isEditing ? 'حفظ التعديلات' : 'إضافة الصنف',
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

/// The two halves of a size, side by side.
///
/// One row rather than two stacked fields, because they are one answer: «25*35» is read as a
/// pair, and a form that stacked them would invite filling in one and moving on.
class _SizeRow extends StatelessWidget {
  const _SizeRow({
    required this.width,
    required this.height,
    required this.widthValidator,
    required this.heightValidator,
    required this.onChanged,
    this.error,
  });

  final TextEditingController width;
  final TextEditingController height;
  final Validator widthValidator;
  final Validator heightValidator;
  final VoidCallback onChanged;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppTextField(
                controller: width,
                label: 'العرض (سم)',
                keyboardType: TextInputType.number,
                // Digits only, the Arabic-Indic ones included: they are what the keyboard puts
                // under the thumb, and the use case converts them on the way out.
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹]'))],
                validator: widthValidator,
                onChanged: (_) => onChanged(),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: AppTextField(
                controller: height,
                label: 'الطول (سم)',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹]'))],
                validator: heightValidator,
                onChanged: (_) => onChanged(),
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        Text(
          error ?? 'اتركهما فارغين لشيء يُعدّ بلا مقاس — بكرة، حبر.',
          style: context.textTheme.bodySmall?.copyWith(
            color: error == null ? scheme.onSurfaceVariant : scheme.error,
          ),
        ),
      ],
    );
  }
}

/// What a **new** shelf will be counted in.
///
/// Two chips rather than a dropdown: there are two of them, they are one word each, and which
/// one a pile is counted in decides what every number about it means afterwards — a fact worth
/// reading without a tap.
class _UnitChoice extends StatelessWidget {
  const _UnitChoice({
    required this.value,
    required this.isFixedByMaterial,
    required this.onChanged,
    this.error,
  });

  final StockUnit value;
  final bool isFixedByMaterial;
  final ValueChanged<StockUnit> onChanged;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'وحدة التخزين',
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
                onSelected: isFixedByMaterial ? null : (_) => onChanged(unit),
                backgroundColor: scheme.surfaceContainerLowest,
                selectedColor: scheme.primaryContainer,
                labelStyle: context.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: unit == value ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
                ),
                side: BorderSide(color: unit == value ? Colors.transparent : scheme.outlineVariant),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
          ],
        ),
        // A line only when there is something the person cannot see for themselves: a refusal,
        // or a box they are not allowed to touch. The «what a unit is» paragraph went — and the
        // «changing it later zeroes the balance» half of it is said by the confirm dialog that
        // actually does it, where it can still stop somebody.
        if (error != null || isFixedByMaterial) ...[
          SizedBox(height: 6.h),
          Text(
            error ?? 'تأتي من المادة',
            style: context.textTheme.bodySmall?.copyWith(
              color: error == null ? scheme.onSurfaceVariant : scheme.error,
            ),
          ),
        ],
      ],
    );
  }
}

/// What an **existing** shelf is counted in — and the one way to move it.
///
/// A tile with its own action rather than a field, because the change does not belong to this
/// form's save button: it goes to its own endpoint, it takes effect immediately, and it empties
/// every warehouse holding the item on the way. A chip row here would let somebody change it by
/// tapping and then abandon the form believing nothing happened.
class _UnitTile extends StatelessWidget {
  const _UnitTile({required this.item, required this.isBusy, required this.onChange, this.error});

  final StockItem item;
  final bool isBusy;
  final VoidCallback onChange;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final radius = BorderRadius.circular(16.r);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(14.w, 12.h, 8.w, 12.h),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest,
            borderRadius: radius,
            border: Border.all(
              color: error == null ? scheme.outlineVariant.withValues(alpha: 0.7) : scheme.error,
            ),
          ),
          child: Row(
            children: [
              Icon(AppIcons.warehouse, size: 20.sp, color: scheme.onSurfaceVariant),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'وحدة التخزين',
                      style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      // The server's own Arabic for this shelf's unit, so a unit added to the
                      // backend tomorrow still reads right.
                      item.unitLabel,
                      style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              if (isBusy)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  child: SizedBox(
                    height: 18.w,
                    width: 18.w,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                TextButton(onPressed: onChange, child: const Text('تغيير')),
            ],
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          error ?? 'تغييرها يصفّر رصيد الصنف في كل المخازن عبر تسوية مسجَّلة — لا يحوّل الكمية.',
          style: context.textTheme.bodySmall?.copyWith(
            color: error == null ? scheme.onSurfaceVariant : scheme.error,
          ),
        ),
      ],
    );
  }
}

/// The material a new shelf is being filed under. Read-only: it is set at creation and the server
/// carries no rule for moving it afterwards.
class _MaterialTile extends StatelessWidget {
  const _MaterialTile({required this.name, this.error});

  final String name;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Row(
            children: [
              Icon(AppIcons.productCategory, size: 20.sp, color: scheme.onPrimaryContainer),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المادة',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: scheme.onPrimaryContainer.withValues(alpha: 0.8),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (error case final message?) ...[
          SizedBox(height: 4.h),
          Text(message, style: context.textTheme.bodySmall?.copyWith(color: scheme.error)),
        ],
      ],
    );
  }
}

/// A fact about this shelf that has to be read before the form is touched.
class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18.sp, color: scheme.onSecondaryContainer),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              message,
              style: context.textTheme.bodySmall?.copyWith(
                height: 1.5,
                color: scheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
