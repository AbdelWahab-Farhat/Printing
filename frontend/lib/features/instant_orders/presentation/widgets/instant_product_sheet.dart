import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/instant_orders/models/instant_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// What the sheet hands back: a size and how much of it.
typedef PickedInstantLine = ({InstantProduct product, InstantVariant variant, double quantity});

/// «إضافة منتج» for an instant sale — INSTANT-ORDERS-PLAN.md §12, «إضافة منتج».
///
/// Lists only what may be sold at this branch, each size with what its warehouse holds. The add
/// button stays disabled while the quantity is more than is free, and says so — the server checks
/// again when the order is taken.
///
/// [alreadyAsked] is what the order's other lines ask of each size, so a second line of the same
/// size is judged against what is left.
Future<PickedInstantLine?> showInstantProductSheet({
  required BuildContext context,
  required InstantCatalogue catalogue,
  required double Function(int variantId) availableFor,
  Map<int, double> alreadyAsked = const {},
}) {
  return showModalBottomSheet<PickedInstantLine>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _InstantProductSheet(
      catalogue: catalogue,
      availableFor: availableFor,
      alreadyAsked: alreadyAsked,
    ),
  );
}

class _InstantProductSheet extends StatefulWidget {
  const _InstantProductSheet({
    required this.catalogue,
    required this.availableFor,
    required this.alreadyAsked,
  });

  final InstantCatalogue catalogue;
  final double Function(int variantId) availableFor;
  final Map<int, double> alreadyAsked;

  @override
  State<_InstantProductSheet> createState() => _InstantProductSheetState();
}

class _InstantProductSheetState extends State<_InstantProductSheet> {
  final _quantity = TextEditingController();
  InstantProduct? _product;
  InstantVariant? _variant;

  @override
  void dispose() {
    _quantity.dispose();
    super.dispose();
  }

  double? get _typed =>
      double.tryParse(Validators.toWesternDigits(_quantity.text.trim()).replaceAll(',', '.'));

  double get _free {
    final variant = _variant;
    if (variant == null) return 0;

    return widget.availableFor(variant.id) - (widget.alreadyAsked[variant.id] ?? 0);
  }

  String? get _problem {
    final typed = _typed;
    if (_variant == null || typed == null) return null;
    if (typed <= 0) return 'الكمية يجب أن تكون أكبر من صفر';
    if (typed > _free) return 'الكمية غير متوفرة — المتاح ${_figure(_free)} ${_product!.unitLabel}';

    return null;
  }

  bool get _canAdd => _variant != null && (_typed ?? 0) > 0 && _problem == null;

  @override
  Widget build(BuildContext context) {
    final products = widget.catalogue.products;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'إضافة منتج',
              style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (widget.catalogue.warehouseName case final warehouse?) ...[
              SizedBox(height: 4.h),
              Text(
                'المخزن: $warehouse',
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            SizedBox(height: 12.h),
            if (products.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 24.h),
                child: Text(
                  'لا توجد منتجات متاحة للبيع الفوري في هذا الفرع',
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodyMedium,
                ),
              )
            else ...[
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  for (final product in products)
                    ChoiceChip(
                      label: Text(product.name),
                      selected: product.id == _product?.id,
                      onSelected: (_) => setState(() {
                        _product = product;
                        // A product with one size skips the second question.
                        _variant = product.variants.length == 1 ? product.variants.single : null;
                      }),
                    ),
                ],
              ),
              if (_product case final product?) ...[
                SizedBox(height: 14.h),
                Text('المقاس', style: context.textTheme.labelLarge),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: [
                    for (final variant in product.variants)
                      ChoiceChip(
                        label: Text(variant.label),
                        selected: variant.id == _variant?.id,
                        onSelected: (_) => setState(() => _variant = variant),
                      ),
                  ],
                ),
              ],
              if (_variant != null) ...[
                SizedBox(height: 14.h),
                Text(
                  'المتاح: ${_figure(_free)} ${_product!.unitLabel}',
                  style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 10.h),
                AppTextField(
                  controller: _quantity,
                  label: 'الكمية المطلوبة (${_product!.unitLabel})',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩.,]'))],
                  errorText: _problem,
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ],
            SizedBox(height: 16.h),
            AppButton(
              label: 'إضافة المنتج',
              onPressed: _canAdd
                  ? () => Navigator.of(context).pop((product: _product!, variant: _variant!, quantity: _typed!))
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  static String _figure(double value) =>
      value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(3).replaceFirst(RegExp(r'0+$'), '');
}
