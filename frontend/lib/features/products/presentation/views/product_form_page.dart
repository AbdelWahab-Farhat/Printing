import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/core/di/injector.dart';
import 'package:printing/core/files/attachment_picker.dart';
import 'package:printing/core/files/picked_file.dart';
import 'package:printing/core/router/app_router.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/core/utils/validators.dart';
import 'package:printing/core/widgets/app_button.dart';
import 'package:printing/core/widgets/app_text_field.dart';
import 'package:printing/core/widgets/attachment_sheet.dart';
import 'package:printing/features/products/models/product.dart';
import 'package:printing/features/products/models/product_type.dart';
import 'package:printing/features/products/presentation/viewmodel/product_categories_cubit.dart';
import 'package:printing/features/products/presentation/viewmodel/save_product_cubit.dart';
import 'package:printing/features/products/presentation/widgets/product_category_picker.dart';
import 'package:printing/features/products/usecases/save_product.dart';

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
class ProductFormPage extends StatelessWidget {
  const ProductFormPage({this.product, super.key});

  /// Null adds a product; anything else opens the form on that one.
  final Product? product;

  @override
  Widget build(BuildContext context) {
    // Created here rather than injected app-wide: the Cubit belongs to this screen and is
    // closed with it.
    return MultiBlocProvider(
      providers: [
        BlocProvider<SaveProductCubit>(create: (_) => sl<SaveProductCubit>()),
        // Narrowed to the categories still on offer: a stopped heading is one nobody should be
        // able to file under *today*, while the product's own stays selectable — see
        // [ProductCategoryPicker].
        BlocProvider<ProductCategoriesCubit>(
          create: (_) =>
              sl<ProductCategoriesCubit>(instanceName: Injector.activeProductCategoriesCubit)
                ..load(),
        ),
      ],
      child: _ProductFormView(product: product),
    );
  }
}

class _ProductFormView extends StatefulWidget {
  const _ProductFormView({this.product});

  final Product? product;

  @override
  State<_ProductFormView> createState() => _ProductFormViewState();
}

/// Stateful because it owns every controller on the screen, and controllers must be disposed.
///
/// Nothing here decides anything: the Cubit does that. What lives here is the draft — text the
/// user has typed and not yet sent — which is exactly the kind of thing a widget owns.
class _ProductFormViewState extends State<_ProductFormView> {
  final _formKey = GlobalKey<FormState>();

  late final _name = TextEditingController(text: _editing?.name ?? '');
  late final _minimum = TextEditingController(
    text: _editing?.minOrderQuantityLabel ?? '100',
  );

  /// The quantity thresholds, shared by every size. One column each.
  late final List<TextEditingController> _breaks = _seedBreaks();

  final List<_SizeRow> _sizes = [];

  late ProductType _category = ProductType.fromWire(_editing?.category);

  /// The catalogue heading. Null while nothing has been picked — which is a state a *new*
  /// product opens in, and one an old product recorded before categories existed is still in.
  late int? _productCategoryId = _editing?.productCategoryId;

  /// Shown under the picker after a submit with nothing chosen. Cleared as soon as one is.
  String? _categoryError;
  late PricingUnit _unit = PricingUnit.fromWire(_editing?.pricingUnit);

  /// Priced by the piece with a published list, which is nine bags in ten.
  late bool _isQuoteOnly = _editing?.pricingMode == 'quote_on_request';

  /// The product being corrected, or null while one is being added.
  Product? get _editing => widget.product;

  /// A complaint about the grid as a whole — thresholds out of order, say. It has no single
  /// field to sit under, so it sits above the grid.
  String? _gridError;

  /// The photo, required when adding.
  ///
  /// Null while correcting an existing product and never filled then: the photo is not editable
  /// from this screen. Swapping one is two operations on the images endpoint — upload the
  /// replacement, delete the old — and doing that from a form whose Save button might never be
  /// pressed would change the product before the user committed to anything.
  PickedFile? _image;

  /// Shown under the picker after a submit with nothing chosen. Cleared as soon as one is.
  String? _imageError;

  /// Adding, so a photo has to be collected. Correcting, so it must not be.
  bool get _needsImage => _editing == null;

  bool get _hasPrices => !_isQuoteOnly;

  @override
  void initState() {
    super.initState();

    final existing = _editing?.variants ?? const <ProductVariant>[];

    if (existing.isEmpty) {
      _sizes.add(_SizeRow(columns: _breaks.length));

      return;
    }

    // **Prices are matched by threshold, not by position.** The grid is one set of columns over
    // every size, and a product whose sizes do not share thresholds — importable through the
    // API, if never through this screen — would otherwise have its prices land under the wrong
    // headings. Matched by number, a cell with no tier behind it opens empty and the validator
    // asks for it, which is the honest thing to say about a price that is not there.
    final thresholds = [for (final column in _breaks) column.text];

    for (final variant in existing) {
      _sizes.add(
        _SizeRow.from(
          variant: variant,
          prices: [
            for (final threshold in thresholds)
              variant.priceTiers
                      .where((tier) => tier.minQuantityLabel == threshold)
                      .firstOrNull
                      ?.unitPrice ??
                  '',
          ],
        ),
      );
    }
  }

  /// The columns, read off the product being corrected — from whichever size lists the most of
  /// them, so a size priced at fewer breaks than its neighbours does not shrink the grid.
  List<TextEditingController> _seedBreaks() {
    final variants = _editing?.variants ?? const <ProductVariant>[];

    final widest = variants.fold<List<ProductPriceTier>>(
      const [],
      (best, variant) =>
          variant.priceTiers.length > best.length ? variant.priceTiers : best,
    );

    if (widest.isEmpty) {
      return [
        TextEditingController(text: '1'),
        TextEditingController(text: '300'),
        TextEditingController(text: '1000'),
      ];
    }

    return [
      for (final tier in widest)
        TextEditingController(text: tier.minQuantityLabel),
    ];
  }

  @override
  void dispose() {
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

  void _addSize() =>
      setState(() => _sizes.add(_SizeRow(columns: _breaks.length)));

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
      if (value <= previous) {
        return 'حدود الكمية يجب أن تتصاعد: 100 ثم 300 ثم 1000';
      }

      previous = value;
    }

    return null;
  }

  /// Chooses the product's photo.
  ///
  /// The document browser is not offered. Every other picker in this app accepts a PDF because
  /// a customer's design usually is one; a product photo is a photograph, and the two places it
  /// comes from are the library and the camera.
  Future<void> _pickImage() async {
    FocusScope.of(context).unfocus();

    final source = await showAttachmentSheet(
      context: context,
      title: 'صورة المنتج',
      sources: const [AttachmentSource.photos, AttachmentSource.camera],
    );
    if (source == null || !mounted) return;

    final files = await sl<AttachmentPicker>().pick(source);
    // Cancelling a picker is not a failure and nothing is said about it.
    if (files.isEmpty || !mounted) return;

    setState(() {
      _image = files.first;
      _imageError = null;
    });
  }

  void _submit() {
    // Dismissed first so the button the user just pressed is not hidden behind the keyboard
    // while the request runs.
    FocusScope.of(context).unfocus();

    final gridError = _validateThresholds();
    // Checked here rather than by a FormField validator: the picker is not a text input, and
    // wrapping it in one to borrow `validate()` would be more machinery than the single rule
    // needs.
    final imageError = _needsImage && _image == null
        ? 'صورة المنتج مطلوبة'
        : null;

    setState(() {
      _gridError = gridError;
      _imageError = imageError;
    });

    // The picker is a dropdown rather than a form field, so `validate()` cannot see it: the
    // check is written here for the same reason the photo's is.
    final categoryError = _productCategoryId == null ? 'اختر تصنيف المنتج' : null;
    setState(() => _categoryError = categoryError);

    if (!_formKey.currentState!.validate() ||
        gridError != null ||
        imageError != null ||
        categoryError != null) {
      return;
    }

    context.read<SaveProductCubit>().submit(
      id: _editing?.id,
      image: _image,
      name: _name.text,
      category: _category.wire,
      // Non-null by the guard above: nothing reaches here without a heading picked.
      productCategoryId: _productCategoryId!,
      pricingUnit: _unit.wire,
      pricingMode: _isQuoteOnly ? 'quote_on_request' : 'tiered',
      minOrderQuantity: _minimum.text,
      variants: [
        for (final size in _sizes)
          DraftVariant(
            // The existing row's id, so the server corrects this size rather than replacing it.
            id: size.id,
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

  /// Back to wherever this was opened from, saying whether anything was written.
  ///
  /// `canPop` because the screen has its own route: a deep link straight to it has nothing
  /// beneath to return to.
  void _leave(BuildContext context) =>
      context.canPop() ? context.pop(true) : context.go(Routes.products);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editing == null ? 'منتج جديد' : 'تعديل المنتج'),
      ),
      body: SafeArea(
        child: BlocConsumer<SaveProductCubit, SaveProductState>(
          listener: (context, state) {
            switch (state) {
              case SaveProductSuccess(:final product):
                // The code is the server's answer and what staff will call this bag from now
                // on, so it is read back on creation rather than left to be discovered. On an
                // edit it is old news, and repeating it would bury what actually changed.
                if (_editing == null) {
                  context.showSuccess(
                    'تم إضافة ${product.name}',
                    details: 'رمز المنتج: ${product.code}',
                  );
                } else {
                  context.showSuccess('تم حفظ ${product.name}');
                }

                _leave(context);

              case SaveProductFailure(:final failure):
                // Only what the form has nowhere to paint. Everything else is already under
                // its own field, and saying it twice is worse than saying it once.
                if (state.hasUnrenderedErrors) context.showFailure(failure);

              default:
                break;
            }
          },
          builder: (context, state) {
            final cubit = context.read<SaveProductCubit>();

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

                      // Only while adding. A product being corrected already has its photo, and
                      // this screen is not where one is swapped — see [_image].
                      if (_needsImage) ...[
                        _ImageField(
                          image: _image,
                          // The server's complaint about the file wins over the form's about
                          // there being none: if it came back, one was sent.
                          errorText: state.imageError ?? _imageError,
                          onTap: _pickImage,
                        ),
                        SizedBox(height: 16.h),
                      ],

                      ProductCategoryPicker(
                        value: _productCategoryId,
                        // The product's own heading, so a stopped one stays selectable rather
                        // than being silently blanked by opening the form.
                        current: _editing?.productCategory,
                        errorText: state.productCategoryError ?? _categoryError,
                        onChanged: (id) => setState(() {
                          _productCategoryId = id;
                          _categoryError = null;
                        }),
                      ),
                      SizedBox(height: 12.h),

                      _ChoiceRow<ProductType>(
                        label: 'النوع',
                        values: ProductType.choices,
                        selected: _category,
                        labelOf: (value) => value.label,
                        onSelected: (value) =>
                            setState(() => _category = value),
                      ),
                      SizedBox(height: 12.h),

                      _ChoiceRow<PricingUnit>(
                        label: 'وحدة التسعير',
                        values: PricingUnit.choices,
                        selected: _unit,
                        labelOf: (value) => value.label,
                        onSelected: (value) => setState(() => _unit = value),
                      ),
                      SizedBox(height: 16.h),

                      AppTextField(
                        controller: _minimum,
                        label: 'أقل كمية للطلب',
                        prefixIcon: AppIcons.orders,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textDirection: TextDirection.ltr,
                        // Whole pieces, but a weight can be fractional — the API draws the same
                        // line and this asks earlier so the user is not told by a round trip.
                        validator: _unit == PricingUnit.piece
                            ? Validators.integer(allowZero: false)
                            : Validators.decimal(allowZero: false),
                        errorText: state.minimumError,
                        onChanged: (_) => cubit.clearFailure(),
                      ),
                      SizedBox(height: 20.h),

                      SwitchListTile.adaptive(
                        value: _isQuoteOnly,
                        onChanged: (value) =>
                            setState(() => _isQuoteOnly = value),
                        title: const Text('السعر حسب الطلب'),
                        subtitle: const Text(
                          'بدون قائمة أسعار — يُتفق على السعر مع الزبون',
                        ),
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
                          priceErrorOf: (column) =>
                              state.priceError(index, column),
                          onRemove: _sizes.length <= 1
                              ? null
                              : () => _removeSize(index),
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
                        label: _editing == null
                            ? 'إضافة المنتج'
                            : 'حفظ التعديلات',
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
                style: context.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
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
                      suffixIconConstraints: BoxConstraints(
                        minWidth: 28.w,
                        minHeight: 28.w,
                      ),
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
                style: context.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
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
              Expanded(
                child: _Dimension(controller: row.width, label: 'العرض (سم)'),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _Dimension(
                  controller: row.height,
                  label: 'الارتفاع (سم)',
                ),
              ),
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
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
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
    : id = null,
      label = TextEditingController(),
      width = TextEditingController(),
      height = TextEditingController(),
      prices = List.generate(
        columns,
        (_) => TextEditingController(),
        growable: true,
      );

  /// A size that already exists, opened for correction.
  ///
  /// It carries its **id**, and that is the load-bearing part: the server matches sizes by id
  /// and removes any it is not sent, so a row that lost its id on the way through this screen
  /// would be deleted and recreated — taking the order lines that point at it with it.
  _SizeRow.from({required ProductVariant variant, required List<String> prices})
    : id = variant.id,
      prices = [for (final price in prices) TextEditingController(text: price)],
      label = TextEditingController(text: variant.label),
      width = TextEditingController(text: variant.widthCm?.toString() ?? ''),
      height = TextEditingController(text: variant.heightCm?.toString() ?? '');

  final int? id;

  final TextEditingController label;
  final TextEditingController width;
  final TextEditingController height;
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

/// The product's photo: a prompt to choose one, then the one that was chosen.
///
/// Full width like every other field on this form rather than a centred square — the row it
/// sits in is a form row, and a picker that centres itself in a column of stretched inputs
/// reads as belonging to a different screen.
class _ImageField extends StatelessWidget {
  const _ImageField({required this.image, required this.onTap, this.errorText});

  final PickedFile? image;
  final VoidCallback onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final invalid = errorText != null;
    final corner = BorderRadius.circular(12.r);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: corner,
          child: Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              borderRadius: corner,
              border: Border.all(
                color: invalid ? scheme.error : scheme.outlineVariant,
                width: invalid ? 1.4 : 1,
              ),
            ),
            child: Row(
              children: [
                _preview(scheme, corner),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        image == null ? 'صورة المنتج' : image!.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        image == null
                            ? 'مطلوبة — اضغط للاختيار'
                            : 'اضغط لاختيار صورة أخرى',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(AppIcons.photos, color: scheme.primary, size: 22.sp),
              ],
            ),
          ),
        ),
        if (invalid) ...[
          SizedBox(height: 6.h),
          Padding(
            // Lines up with the text inside the box above rather than with its border, so the
            // complaint sits under the thing it is about.
            padding: EdgeInsetsDirectional.only(start: 12.w),
            child: Text(
              errorText!,
              style: context.textTheme.bodySmall?.copyWith(color: scheme.error),
            ),
          ),
        ],
      ],
    );
  }

  /// The chosen photo, or a placeholder tile before there is one.
  ///
  /// `Image.file` and not a network image: this file has not been uploaded yet and exists only
  /// on the device.
  Widget _preview(ColorScheme scheme, BorderRadius corner) {
    final side = 52.w;

    return ClipRRect(
      borderRadius: corner,
      child: SizedBox(
        width: side,
        height: side,
        child: image == null
            ? ColoredBox(
                color: scheme.surfaceContainerHigh,
                child: Icon(
                  AppIcons.products,
                  color: scheme.onSurfaceVariant,
                  size: 22.sp,
                ),
              )
            : Image.file(
                File(image!.path),
                fit: BoxFit.cover,
                // The path can go stale — iOS copies a library pick into a cache the system may
                // sweep — and a broken image with no fallback is a red crash box in a form.
                errorBuilder: (_, _, _) => ColoredBox(
                  color: scheme.surfaceContainerHigh,
                  child: Icon(
                    AppIcons.photos,
                    color: scheme.onSurfaceVariant,
                    size: 22.sp,
                  ),
                ),
              ),
      ),
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
