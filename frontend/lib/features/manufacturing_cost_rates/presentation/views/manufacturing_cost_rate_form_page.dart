import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/core/di/injector.dart';
import 'package:printing/core/permissions/app_permission.dart';
import 'package:printing/core/router/app_router.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/core/utils/validators.dart';
import 'package:printing/core/widgets/app_button.dart';
import 'package:printing/core/widgets/app_dropdown.dart';
import 'package:printing/core/widgets/app_text_field.dart';
import 'package:printing/core/widgets/permission_gate.dart';
import 'package:printing/features/audit/models/audit_subject.dart';
import 'package:printing/features/manufacturing_cost_rates/models/manufacturing_cost_rate.dart';
import 'package:printing/features/manufacturing_cost_rates/presentation/viewmodel/save_manufacturing_cost_rate_cubit.dart';
import 'package:printing/features/manufacturing_cost_rates/presentation/widgets/rate_product_picker_sheet.dart';
import 'package:printing/features/warehouses/presentation/widgets/variant_picker_sheet.dart';

/// Adding a manufacturing cost rate, or correcting one.
///
/// **One screen for both**, because it is one form: the only difference is whether a rate arrived
/// with it.
///
/// **The rung is a single choice, and that is the whole shape of this form.** The API takes a
/// `product_id` and a `product_variant_id` and the table refuses a row that sets both — a form
/// with two pickers would let somebody fill in each and learn about the constraint from a 422
/// pointing at a field they thought they had answered. Three chips make the illegal state
/// unreachable, and the id that travels is chosen from the tapped chip rather than from whichever
/// picker was touched last.
///
/// **A rung with nothing picked is refused here rather than sent.** Both ids absent is a legal
/// body — it means the default rate — so «منتج بأكمله» with no product chosen would silently
/// write a workshop-wide rate, which is the one mistake on this screen nobody would notice.
class ManufacturingCostRateFormPage extends StatelessWidget {
  const ManufacturingCostRateFormPage({this.rate, super.key});

  /// Null adds a new rate; anything else corrects that one.
  final ManufacturingCostRate? rate;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SaveManufacturingCostRateCubit>(
      create: (_) => sl<SaveManufacturingCostRateCubit>(),
      child: _ManufacturingCostRateFormView(rate: rate),
    );
  }
}

class _ManufacturingCostRateFormView extends StatefulWidget {
  const _ManufacturingCostRateFormView({this.rate});

  final ManufacturingCostRate? rate;

  @override
  State<_ManufacturingCostRateFormView> createState() =>
      _ManufacturingCostRateFormViewState();
}

class _ManufacturingCostRateFormViewState
    extends State<_ManufacturingCostRateFormView> {
  final _formKey = GlobalKey<FormState>();

  /// Prefilled from what the server stored, trimmed of the three decimals it pads with — an
  /// editor that opened on `3.500` would have somebody deleting zeros before every correction.
  late final TextEditingController _rate =
      TextEditingController(text: widget.rate?.rateLabel ?? '');
  late final TextEditingController _notes =
      TextEditingController(text: widget.rate?.notes ?? '');

  late RateScope _scope = widget.rate?.scope ?? RateScope.standard;

  /// Held apart so that narrowing from «منتج بأكمله» to «مقاس واحد» and back does not lose
  /// either answer. Only the one the chosen rung names is ever sent.
  late ({int id, String name})? _product = switch (widget.rate?.product) {
    final product? => (id: product.id, name: product.name),
    _ => null,
  };
  late ({int id, String label})? _variant = switch (widget.rate?.productVariant) {
    final variant? => (id: variant.id, label: variant.label),
    _ => null,
  };

  /// Null rather than [ManufacturingCostType.unknown] for a kind this build cannot name: the
  /// dropdown would show an empty row, and saving it would post an empty `cost_type`.
  late ManufacturingCostType? _costType = switch (widget.rate?.costType) {
    null || ManufacturingCostType.unknown => null,
    final type => type,
  };

  late bool _isActive = widget.rate?.isActive ?? true;

  bool get _isEditing => widget.rate != null;

  /// What the dropdown offers: the three kinds that are actually consulted, plus — while editing
  /// — this rate's own kind when it is not one of them. A «خسارة تلف» row written before this
  /// screen existed has to stay editable without silently turning into a labour cost on save.
  late final List<ManufacturingCostType> _costTypes = [
    ...ManufacturingCostType.offered,
    if (widget.rate?.costType case final type?
        when type != ManufacturingCostType.unknown && !type.isRateDriven)
      type,
  ];

  @override
  void dispose() {
    _rate.dispose();
    _notes.dispose();
    super.dispose();
  }

  /// The id the chosen rung names, or null on the default rung.
  int? get _scopeId => switch (_scope) {
    RateScope.standard => null,
    RateScope.product => _product?.id,
    RateScope.variant => _variant?.id,
  };

  /// What the picker tile shows once something has been chosen.
  String? get _scopeValue => switch (_scope) {
    RateScope.standard => null,
    RateScope.product => _product?.name,
    RateScope.variant => _variant?.label,
  };

  Future<void> _pickProduct() async {
    final picked = await showRateProductPicker(context: context);
    if (picked == null) return;

    setState(() => _product = (id: picked.id, name: picked.name));
  }

  Future<void> _pickVariant() async {
    final picked = await showVariantPicker(context: context);
    if (picked == null) return;

    // Named with its product while the form is open, which the payload cannot do on its own:
    // the API sends a size back as the bare dimensions, with nothing to say whose they are.
    setState(
      () => _variant = (
        id: picked.variant.id,
        label: '${picked.product.name} · ${picked.variant.label}',
      ),
    );
  }

  void _submit() {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final costType = _costType;
    // The dropdown's own validator has already said so; this is what makes the type non-null.
    if (costType == null) return;

    if (_scope != RateScope.standard && _scopeId == null) {
      context.showInfo(
        _scope == RateScope.product
            ? 'اختر المنتج الذي يسري عليه المعدل'
            : 'اختر المقاس الذي يسري عليه المعدل',
      );

      return;
    }

    context.read<SaveManufacturingCostRateCubit>().submit(
      id: widget.rate?.id,
      scope: _scope,
      scopeId: _scopeId,
      costType: costType,
      ratePerUnit: _rate.text,
      notes: _notes.text,
      isActive: _isActive,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SaveManufacturingCostRateCubit, SaveManufacturingCostRateState>(
      listener: (context, state) {
        switch (state) {
          case SaveManufacturingCostRateSuccess(:final rate):
            // True says the list behind should refresh; a dismissed form returns nothing.
            Navigator.of(context).pop(true);
            context.showSuccess(
              _isEditing
                  ? 'تم تحديث معدل ${rate.costTypeLabel}'
                  : 'تمت إضافة معدل ${rate.costTypeLabel}',
            );
          case SaveManufacturingCostRateFailure(:final failure)
              when state.hasUnrenderedErrors:
            context.showFailure(failure);
          case _:
            break;
        }
      },
      builder: (context, state) {
        final cubit = context.read<SaveManufacturingCostRateCubit>();

        return Scaffold(
          appBar: AppBar(
            title: Text(_isEditing ? 'تعديل المعدل' : 'معدل تكلفة جديد'),
            actions: [
              // «منذ متى ونحن نحسب العمالة بهذا الرقم؟» is a question no order can answer: an
              // order keeps the amount it was charged, never the rate that produced it.
              //
              // Gated on the log permission rather than on this screen's, and gated rather than
              // greyed: a button that only ever leads somewhere this account cannot read is a
              // button to leave out. The route guards it again — this is the courtesy.
              if (widget.rate case final rate?)
                PermissionGate(
                  permission: AppPermission.viewActivityLogs,
                  child: IconButton(
                    tooltip: 'سجل التعديلات',
                    onPressed: () => context.push(
                      Routes.activityLog(AuditSubject.manufacturingCostRate, rate.id),
                      extra: '${rate.costTypeLabel} · ${rate.scopeLabel}',
                    ),
                    icon: Icon(AppIcons.history),
                  ),
                ),
            ],
          ),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
                children: [
                  _ScopeField(
                    scope: _scope,
                    value: _scopeValue,
                    error: state.scopeError,
                    onScopeChanged: (scope) {
                      cubit.clearFailure();
                      setState(() => _scope = scope);
                    },
                    onPick: switch (_scope) {
                      RateScope.standard => null,
                      RateScope.product => _pickProduct,
                      RateScope.variant => _pickVariant,
                    },
                  ),
                  SizedBox(height: 20.h),

                  AppDropdown<ManufacturingCostType>(
                    items: _costTypes,
                    value: _costType,
                    labelOf: (type) => type.label,
                    label: 'نوع التكلفة',
                    hint: 'اختر نوع التكلفة',
                    prefixIcon: AppIcons.settled,
                    errorText: state.costTypeError,
                    validator: (value) => value == null ? 'اختر نوع التكلفة' : null,
                    onChanged: (value) {
                      cubit.clearFailure();
                      setState(() => _costType = value);
                    },
                  ),
                  SizedBox(height: 16.h),

                  AppTextField(
                    controller: _rate,
                    label: 'المعدل للوحدة (د.ل)',
                    hint: 'مثال: 3.5',
                    prefixIcon: AppIcons.payment,
                    helperText: 'يُضرب في كمية السطر عند دخول الطلبية مرحلة الطباعة',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    // «٫» belongs here, and leaving it out was not cosmetic: the formatter drops
                    // any character it does not list, so «٣٫٥» arrived as «٣٥» and a rate of
                    // three and a half dinars was saved as thirty-five — silently, with the
                    // validator below none the wiser because it never saw the separator.
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹.,٫]')),
                    ],
                    validator: (value) {
                      final parsed = double.tryParse(
                        Validators.toWesternDigits(value ?? '').replaceAll(',', '.').trim(),
                      );

                      // **Zero passes**, because the server's rule is `gte:0`: a cost the
                      // workshop deliberately does not charge is a real answer, and refusing it
                      // would have people typing «0.001» to get past the form.
                      if (parsed == null) return 'أدخل المعدل';

                      return parsed < 0 ? 'المعدل لا يمكن أن يكون سالباً' : null;
                    },
                    errorText: state.rateError,
                    onChanged: (_) => cubit.clearFailure(),
                  ),
                  SizedBox(height: 16.h),

                  AppTextField(
                    controller: _notes,
                    label: 'ملاحظات (اختياري)',
                    hint: 'كيف حُسب هذا الرقم، ومتى يُراجع',
                    prefixIcon: AppIcons.edit,
                    maxLines: 3,
                    errorText: state.notesError,
                    onChanged: (_) => cubit.clearFailure(),
                  ),
                  SizedBox(height: 8.h),

                  SwitchListTile.adaptive(
                    value: _isActive,
                    onChanged: (value) => setState(() => _isActive = value),
                    title: const Text('يُطبَّق على الطلبيات'),
                    // Said out loud, because "off" is not "deleted" and the difference is the
                    // whole reason this switch exists rather than a bin: a stopped rate lets the
                    // rung under it answer instead, and the orders it already priced keep their
                    // numbers.
                    subtitle: const Text(
                      'إن أُطفئ لم يُحتسب في الطلبيات الجديدة، وتبقى تكاليف الطلبيات '
                      'السابقة كما سُجّلت',
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SizedBox(height: 28.h),

                  AppButton(
                    label: _isEditing ? 'حفظ التعديلات' : 'إضافة المعدل',
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

/// The rung: three chips, the sentence that explains the chosen one, and — on the two narrow
/// rungs — what it is pinned to.
///
/// The note under the chips is not decoration. «افتراضي», «منتج بأكمله» and «مقاس واحد» are three
/// words for a rule nobody has been told; the sentence is where the ladder gets explained, on the
/// screen where the choice is actually made.
class _ScopeField extends StatelessWidget {
  const _ScopeField({
    required this.scope,
    required this.value,
    required this.onScopeChanged,
    required this.onPick,
    this.error,
  });

  final RateScope scope;

  /// What has been picked for the current rung, or null when nothing has.
  final String? value;

  final ValueChanged<RateScope> onScopeChanged;

  /// Null on [RateScope.standard], which is the rung with nothing to pick.
  final VoidCallback? onPick;

  final String? error;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ما الذي يسري عليه المعدل؟',
          style: context.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: scheme.primary,
          ),
        ),
        SizedBox(height: 10.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            for (final option in RateScope.values)
              ChoiceChip(
                label: Text(option.label),
                selected: option == scope,
                showCheckmark: false,
                onSelected: (_) => onScopeChanged(option),
                backgroundColor: scheme.surfaceContainerLowest,
                selectedColor: scheme.primaryContainer,
                labelStyle: context.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: option == scope
                      ? scheme.onPrimaryContainer
                      : scheme.onSurfaceVariant,
                ),
                side: BorderSide(
                  color: option == scope ? Colors.transparent : scheme.outlineVariant,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
          ],
        ),
        SizedBox(height: 8.h),
        Text(
          scope.note,
          style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        if (onPick != null) ...[
          SizedBox(height: 12.h),
          _PickerTile(
            icon: scope == RateScope.product ? AppIcons.products : AppIcons.tag,
            label: scope == RateScope.product ? 'المنتج' : 'المقاس',
            hint: scope == RateScope.product ? 'اختر المنتج' : 'اختر المقاس',
            value: value,
            error: error,
            onTap: onPick,
          ),
        ] else if (error case final message?) ...[
          SizedBox(height: 8.h),
          Text(
            message,
            style: context.textTheme.bodySmall?.copyWith(color: scheme.error),
          ),
        ],
      ],
    );
  }
}

/// A row that opens a picker and shows what came back.
class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.hint,
    this.value,
    this.error,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String hint;
  final String? value;
  final String? error;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isEmpty = value == null || value!.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16.r),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: error == null
                      ? scheme.outlineVariant.withValues(alpha: 0.7)
                      : scheme.error,
                ),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 20.sp, color: scheme.onSurfaceVariant),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          isEmpty ? hint : value!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isEmpty ? scheme.outline : scheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onTap != null)
                    Icon(AppIcons.forward, size: 18.sp, color: scheme.outline),
                ],
              ),
            ),
          ),
        ),
        if (error case final message?) ...[
          SizedBox(height: 4.h),
          Text(
            message,
            style: context.textTheme.bodySmall?.copyWith(color: scheme.error),
          ),
        ],
      ],
    );
  }
}
