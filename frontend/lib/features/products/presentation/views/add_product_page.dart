import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/core/di/injector.dart';
import 'package:printing/core/router/app_router.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/core/utils/validators.dart';
import 'package:printing/core/widgets/app_button.dart';
import 'package:printing/core/widgets/app_text_field.dart';
import 'package:printing/features/products/presentation/viewmodel/add_product_cubit.dart';
import 'package:printing/features/products/usecases/create_product.dart';

/// Add a bag to the catalogue.
///
/// The hard part is not the fields, it is the prices. A bag has sizes, and each size has
/// quantity breaks — the catalogue's real shape is four sizes by three breaks, twelve numbers.
///
/// **The breaks are shared across sizes, and that is a decision, not a simplification.** Every
/// printed product in the catalogue uses the same thresholds for every one of its sizes, and
/// the product card already renders them as shared columns: one header, `100+ · 300+ · 1000+`,
/// over all four rows. A form that let each size carry its own thresholds would let somebody
/// build a product the card cannot draw. The wire format still sends the tiers per variant, so
/// the day the restriction is lifted only this screen changes.
///
/// So the editor is a grid: thresholds along the top, sizes down the side, one price in each
/// cell — the same shape the user will see on the card afterwards.
class AddProductPage extends StatelessWidget {
  const AddProductPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Created here rather than injected app-wide: the Cubit belongs to this screen and is
    // closed with it.
    return BlocProvider<AddProductCubit>(
      create: (_) => sl<AddProductCubit>(),
      child: const _AddProductView(),
    );
  }
}

class _AddProductView extends StatefulWidget {
  const _AddProductView();

  @override
  State<_AddProductView> createState() => _AddProductViewState();
}

/// Stateful because it owns every controller on the screen, and controllers must be disposed.
///
/// Nothing here decides anything: the Cubit does that. What lives here is the draft — text the
/// user has typed and not yet sent — which is exactly the kind of thing a widget owns.
class _AddProductViewState extends State<_AddProductView> {
  final _formKey = GlobalKey<FormState>();

  final _slug = TextEditingController();
  final _name = TextEditingController();
  final _minimum = TextEditingController(text: '100');

  /// The quantity thresholds, shared by every size. One column each.
  final List<TextEditingController> _breaks = [
    TextEditingController(text: '1'),
    TextEditingController(text: '300'),
    TextEditingController(text: '1000'),
  ];

  final List<_SizeRow> _sizes = [];

  _Category _category = _Category.printed;
  _Unit _unit = _Unit.piece;

  /// Priced by the piece with a published list, which is nine bags in ten.
  bool _isQuoteOnly = false;

  /// A complaint about the grid as a whole — thresholds out of order, say. It has no single
  /// field to sit under, so it sits above the grid.
  String? _gridError;

  bool get _hasPrices => !_isQuoteOnly;

  @override
  void initState() {
    super.initState();
    _sizes.add(_SizeRow(columns: _breaks.length));
  }

  @override
  void dispose() {
    _slug.dispose();
    _name.dispose();
    _minimum.dispose();

    for (final column in _breaks) {
      column.dispose();
    }
    for (final size in _sizes) {
      size.dispose();
    }

    super.dispose();
  }

  // ── the grid ────────────────────────────────────────────────────────────────

  void _addSize() => setState(() => _sizes.add(_SizeRow(columns: _breaks.length)));

  void _removeSize(int index) {
    final removed = _sizes.removeAt(index);
    _rebuildThenDispose([removed.dispose]);
  }

  void _addBreak() {
    setState(() {
      _breaks.add(TextEditingController());
      for (final size in _sizes) {
        size.prices.add(TextEditingController());
      }
    });
  }

  void _removeBreak(int column) {
    final orphans = <TextEditingController>[
      _breaks.removeAt(column),
      for (final size in _sizes) size.prices.removeAt(column),
    ];

    _rebuildThenDispose([for (final orphan in orphans) orphan.dispose]);
  }

  /// Rebuilds now, disposes one frame later.
  ///
  /// The delay is the whole point. Disposing inside `setState` kills a controller a `TextField`
  /// is still holding; that field's own `dispose` then calls `removeListener` on a dead object
  /// and trips an assertion. After this frame the fields are gone.
  void _rebuildThenDispose(List<VoidCallback> disposers) {
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final dispose in disposers) {
        dispose();
      }
    });
  }

  /// Thresholds must climb. The form can say so before the server has to.
  String? _validateThresholds() {
    if (!_hasPrices) return null;

    var previous = -1.0;

    for (final column in _breaks) {
      final value = double.tryParse(
        Validators.toWesternDigits(column.text.trim()).replaceAll(',', '.'),
      );

      if (value == null) return 'كل حد كمية يجب أن يكون رقماً';
      if (value <= previous) return 'حدود الكمية يجب أن تتصاعد: 100 ثم 300 ثم 1000';

      previous = value;
    }

    return null;
  }

  void _submit() {
    // Dismissed first so the button the user just pressed is not hidden behind the keyboard
    // while the request runs.
    FocusScope.of(context).unfocus();

    final gridError = _validateThresholds();
    setState(() => _gridError = gridError);

    if (!_formKey.currentState!.validate() || gridError != null) return;

    context.read<AddProductCubit>().submit(
      slug: _slug.text,
      name: _name.text,
      category: _category.wire,
      pricingUnit: _unit.wire,
      pricingMode: _isQuoteOnly ? 'quote_on_request' : 'tiered',
      minOrderQuantity: _minimum.text,
      variants: [
        for (final size in _sizes)
          DraftVariant(
            label: size.label.text,
            widthCm: size.width.text,
            heightCm: size.height.text,
            // Branched on the *mode*, not on what is visible. A quote-only product must carry
            // no prices at all, and the server refuses the whole list if it does — an error
            // landing on a screen that is showing no prices is one nobody can act on.
            priceTiers: _hasPrices
                ? [
                    for (var column = 0; column < _breaks.length; column++)
                      DraftPriceTier(
                        minQuantity: _breaks[column].text,
                        unitPrice: size.prices[column].text,
                      ),
                  ]
                : const [],
          ),
      ],
    );
  }

  /// Back to wherever this was opened from. `canPop` because the screen has its own route: a
  /// deep link straight to it has nothing beneath to return to.
  void _leave(BuildContext context) =>
      context.canPop() ? context.pop() : context.go(Routes.products);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('منتج جديد')),
      body: SafeArea(
        child: BlocConsumer<AddProductCubit, AddProductState>(
          listener: (context, state) {
            switch (state) {
              case AddProductSuccess(:final product):
                // The code is the server's answer and what staff will call this bag from now
                // on, so it is read back rather than left to be discovered.
                context.showSuccess(
                  'تم إضافة ${product.name}',
                  details: 'رمز المنتج: ${product.code}',
                );
                _leave(context);

              case AddProductFailure(:final failure):
                // Only what the form has nowhere to paint. Everything else is already under
                // its own field, and saying it twice is worse than saying it once.
                if (state.hasUnrenderedErrors) context.showFailure(failure);

              default:
                break;
            }
          },
          builder: (context, state) {
            final cubit = context.read<AddProductCubit>();

            return AbsorbPointer(
              // Locks the whole form while the request is in flight, so what is on screen
              // always matches what was sent.
              absorbing: state.isSubmitting,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 32.h),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _SectionTitle('المنتج'),
                      SizedBox(height: 12.h),

                      AppTextField(
                        controller: _name,
                        label: 'اسم المنتج',
                        hint: 'مثال: أكياس الشحن',
                        prefixIcon: AppIcons.products,
                        autofocus: true,
                        validator: Validators.compose([
                          Validators.minLength(2, label: 'اسم المنتج'),
                          Validators.maxLength(255, label: 'اسم المنتج'),
                        ]),
                        errorText: state.nameError,
                        onChanged: (_) => cubit.clearFailure(),
                      ),
                      SizedBox(height: 16.h),

                      AppTextField(
                        controller: _slug,
                        label: 'المعرف',
                        hint: 'shipping-bag',
                        helperText: 'بالإنجليزية، لا يتكرر بين منتجين',
                        prefixIcon: AppIcons.tag,
                        // Typed, not derived from the name: every slug in the catalogue is an
                        // English *translation* (shipping-bag, outer-handle-bag), and no
                        // transliteration of أكياس الشحن produces any of them.
                        //
                        // The formatter makes the API's `^[a-z0-9-]+$` unfailable, which leaves
                        // uniqueness as the server's only remaining complaint about this field.
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9-]')),
                          LengthLimitingTextInputFormatter(80),
                        ],
                        textDirection: TextDirection.ltr,
                        validator: Validators.minLength(2, label: 'المعرف'),
                        errorText: state.slugError,
                        onChanged: (_) => cubit.clearFailure(),
                      ),
                      SizedBox(height: 16.h),

                      _ChoiceRow<_Category>(
                        label: 'التصنيف',
                        values: _Category.values,
                        selected: _category,
                        labelOf: (value) => value.label,
                        onSelected: (value) => setState(() => _category = value),
                      ),
                      SizedBox(height: 12.h),

                      _ChoiceRow<_Unit>(
                        label: 'وحدة التسعير',
                        values: _Unit.values,
                        selected: _unit,
                        labelOf: (value) => value.label,
                        onSelected: (value) => setState(() => _unit = value),
                      ),
                      SizedBox(height: 16.h),

                      AppTextField(
                        controller: _minimum,
                        label: 'أقل كمية للطلب',
                        prefixIcon: AppIcons.orders,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textDirection: TextDirection.ltr,
                        // Whole pieces, but a weight can be fractional — the API draws the same
                        // line and this asks earlier so the user is not told by a round trip.
                        validator: _unit == _Unit.piece
                            ? Validators.integer(allowZero: false)
                            : Validators.decimal(allowZero: false),
                        errorText: state.minimumError,
                        onChanged: (_) => cubit.clearFailure(),
                      ),
                      SizedBox(height: 20.h),

                      SwitchListTile.adaptive(
                        value: _isQuoteOnly,
                        onChanged: (value) => setState(() => _isQuoteOnly = value),
                        title: const Text('السعر حسب الطلب'),
                        subtitle: const Text('بدون قائمة أسعار — يُتفق على السعر مع الزبون'),
                        contentPadding: EdgeInsets.zero,
                      ),
                      SizedBox(height: 12.h),

                      const _SectionTitle('المقاسات والأسعار'),
                      SizedBox(height: 4.h),
                      Text(
                        _hasPrices
                            ? 'حدود الكمية مشتركة بين كل المقاسات، كما تظهر في بطاقة المنتج'
                            : 'لا أسعار لمنتج حسب الطلب — المقاسات فقط',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: 12.h),

                      if (_gridError != null) ...[
                        Text(
                          _gridError!,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colorScheme.error,
                          ),
                        ),
                        SizedBox(height: 8.h),
                      ],

                      if (_hasPrices) ...[
                        _BreakHeader(
                          columns: _breaks,
                          onAdd: _breaks.length >= 4 ? null : _addBreak,
                          onRemove: _breaks.length <= 1 ? null : _removeBreak,
                          onChanged: () => setState(() => _gridError = null),
                        ),
                        SizedBox(height: 12.h),
                      ],

                      for (var index = 0; index < _sizes.length; index++) ...[
                        _SizeCard(
                          // Keyed by the row object, not by its index: removing the second of
                          // three otherwise shifts every controller up one card and the text
                          // appears to move.
                          key: ObjectKey(_sizes[index]),
                          row: _sizes[index],
                          ordinal: index + 1,
                          showPrices: _hasPrices,
                          labelError: state.variantLabelError(index),
                          priceErrorOf: (column) => state.priceError(index, column),
                          onRemove: _sizes.length <= 1 ? null : () => _removeSize(index),
                          onChanged: cubit.clearFailure,
                        ),
                        SizedBox(height: 12.h),
                      ],

                      AppButton.outlined(
                        label: 'إضافة مقاس',
                        icon: AppIcons.add,
                        onPressed: _addSize,
                      ),
                      SizedBox(height: 28.h),

                      AppButton(
                        label: 'إضافة المنتج',
                        isLoading: state.isSubmitting,
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The quantity thresholds, shared by every size below them.
class _BreakHeader extends StatelessWidget {
  const _BreakHeader({
    required this.columns,
    required this.onAdd,
    required this.onRemove,
    required this.onChanged,
  });

  final List<TextEditingController> columns;
  final VoidCallback? onAdd;
  final void Function(int column)? onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'حدود الكمية',
                style: context.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              IconButton(
                onPressed: onAdd,
                icon: Icon(AppIcons.add),
                tooltip: 'إضافة حد',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              for (var column = 0; column < columns.length; column++)
                SizedBox(
                  width: 104.w,
                  child: TextFormField(
                    controller: columns[column],
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => onChanged(),
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: 'من',
                      suffixIcon: onRemove == null
                          ? null
                          : IconButton(
                              onPressed: () => onRemove!(column),
                              icon: Icon(AppIcons.clear, size: 16.sp),
                              tooltip: 'حذف الحد',
                              visualDensity: VisualDensity.compact,
                            ),
                      suffixIconConstraints: BoxConstraints(minWidth: 28.w, minHeight: 28.w),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One size: its name, its dimensions, and one price per threshold.
class _SizeCard extends StatelessWidget {
  const _SizeCard({
    required this.row,
    required this.ordinal,
    required this.showPrices,
    required this.labelError,
    required this.priceErrorOf,
    required this.onRemove,
    required this.onChanged,
    super.key,
  });

  final _SizeRow row;
  final int ordinal;
  final bool showPrices;
  final String? labelError;
  final String? Function(int column) priceErrorOf;
  final VoidCallback? onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'مقاس $ordinal',
                style: context.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              IconButton(
                onPressed: onRemove,
                icon: Icon(AppIcons.delete, size: 18.sp),
                tooltip: 'حذف المقاس',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          TextFormField(
            controller: row.label,
            textDirection: TextDirection.ltr,
            onChanged: (_) => onChanged(),
            validator: Validators.required,
            decoration: InputDecoration(
              isDense: true,
              labelText: 'المقاس',
              hintText: '25*35',
              errorText: labelError,
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(child: _Dimension(controller: row.width, label: 'العرض (سم)')),
              SizedBox(width: 10.w),
              Expanded(child: _Dimension(controller: row.height, label: 'الارتفاع (سم)')),
            ],
          ),
          if (showPrices) ...[
            SizedBox(height: 12.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                for (var column = 0; column < row.prices.length; column++)
                  SizedBox(
                    width: 104.w,
                    child: TextFormField(
                      controller: row.prices[column],
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.center,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => onChanged(),
                      validator: Validators.decimal(),
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: 'سعر ${column + 1}',
                        errorText: priceErrorOf(column),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Dimension extends StatelessWidget {
  const _Dimension({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      textDirection: TextDirection.ltr,
      keyboardType: TextInputType.number,
      // Optional — the catalogue's per-kilo bags have no dimensions at all — but a number when
      // present. `٢٥` is accepted here and converted in the use case.
      validator: Validators.optional(Validators.integer(allowZero: false)),
      decoration: InputDecoration(isDense: true, labelText: label),
    );
  }
}

/// The controllers for one size. Owned by the page's `State`, disposed with it.
class _SizeRow {
  _SizeRow({required int columns})
    : prices = List.generate(columns, (_) => TextEditingController(), growable: true);

  final TextEditingController label = TextEditingController();
  final TextEditingController width = TextEditingController();
  final TextEditingController height = TextEditingController();
  final List<TextEditingController> prices;

  void dispose() {
    label.dispose();
    width.dispose();
    height.dispose();

    for (final price in prices) {
      price.dispose();
    }
  }
}

/// A row of chips standing in for a dropdown — two or three options read faster as chips, and
/// the choice is visible without a tap.
class _ChoiceRow<T> extends StatelessWidget {
  const _ChoiceRow({
    required this.label,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
  });

  final String label;
  final List<T> values;
  final T selected;
  final String Function(T value) labelOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.textTheme.labelMedium?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 6.h),
        Wrap(
          spacing: 8.w,
          children: [
            for (final value in values)
              ChoiceChip(
                label: Text(labelOf(value)),
                selected: value == selected,
                showCheckmark: false,
                onSelected: (_) => onSelected(value),
              ),
          ],
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: context.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w800,
        color: context.colorScheme.primary,
      ),
    );
  }
}

/// The two values `ProductCategory` accepts, with the Arabic the catalogue uses.
///
/// Spelled out here rather than fetched: they are an enum on the server, not a list the
/// business edits, so a round trip would buy nothing and a failed one would leave the form
/// unable to open.
enum _Category {
  printed('printed', 'مطبوعة'),
  general('general', 'سادة');

  const _Category(this.wire, this.label);

  final String wire;
  final String label;
}

enum _Unit {
  piece('piece', 'بالقطعة'),
  kilogram('kilogram', 'بالكيلوغرام');

  const _Unit(this.wire, this.label);

  final String wire;
  final String label;
}
