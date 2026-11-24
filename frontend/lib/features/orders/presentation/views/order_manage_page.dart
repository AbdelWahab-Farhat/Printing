import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/router/pop_result.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/manage_order_cubit.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/order_detail_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// «إدارة الطلبية» — each line's quantity and price, from the quantities being set until
/// «تم الاستلام» (owner's decision, 2026-11-24). Where is the server's answer:
/// [Order.linesAreManageable].
///
/// **Its own screen, not a mode of «تعديل الطلبية».** That one keeps every lock it always had,
/// whoever opens it; this one offers exactly what the owner has opened to `orders.edit_fully`
/// and nothing more. Further fields are added here one at a time.
///
/// The price typed is the one the line is billed at, for a product with listed prices too.
/// Pops with `true` when anything was saved, so the screen behind re-reads.
class OrderManagePage extends StatelessWidget {
  const OrderManagePage({required this.orderId, super.key});

  final int orderId;

  @override
  Widget build(BuildContext context) {
    // Read fresh rather than handed over: the order may have been delivered or cancelled since
    // the screen behind drew its button.
    return BlocProvider<OrderDetailCubit>(
      create: (_) => sl<OrderDetailCubit>(param1: orderId)..load(),
      child: Scaffold(
        appBar: AppBar(title: const Text('إدارة الطلبية')),
        body: BlocBuilder<OrderDetailCubit, OrderDetailState>(
          builder: (context, state) {
            final order = state.order;

            if (order == null) {
              return switch (state) {
                OrderDetailFailure(:final failure) => _Message(
                  text: failure.message,
                  onRetry: context.read<OrderDetailCubit>().load,
                ),
                _ => const Center(child: CircularProgressIndicator()),
              };
            }

            if (!order.linesAreManageable) {
              return _Message(
                text: 'لا يمكن تعديل كميات وأسعار الطلبية وهي «${order.statusLabel}»',
              );
            }

            return BlocProvider<ManageOrderCubit>(
              create: (_) => sl<ManageOrderCubit>(param1: order),
              child: const _Form(),
            );
          },
        ),
      ),
    );
  }
}

class _Form extends StatelessWidget {
  const _Form();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ManageOrderCubit>();

    return BlocConsumer<ManageOrderCubit, ManageOrderState>(
      listenWhen: (before, now) =>
          before.saved != now.saved || before.failure != now.failure,
      listener: (context, state) {
        if (state.saved != null) {
          context.handBack(true);
          return;
        }

        // A refusal about a field is drawn under that field; anything else is a toast.
        if (state.failure case final failure? when failure.fieldError('items') == null &&
            !_isAboutALine(failure)) {
          context.showFailure(failure);
        }
      },
      builder: (context, state) {
        final scheme = context.colorScheme;

        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.w),
                    margin: EdgeInsets.only(bottom: 12.h),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      state.movesStock
                          ? 'السعر هنا هو سعر البند مهما كان سعر الكتالوج. وتغيير الكمية يحرّك'
                                ' المخزن، لأن البضاعة خرجت منه'
                          : 'السعر هنا هو سعر البند مهما كان سعر الكتالوج',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (state.isAtCarrier)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12.w),
                      margin: EdgeInsets.only(bottom: 12.h),
                      decoration: BoxDecoration(
                        color: scheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        'الطلبية عند النورس، والتعديل هنا لا يصلهم: سيحصّل المندوب المبلغ القديم',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: scheme.onTertiaryContainer,
                        ),
                      ),
                    ),
                  if (state.failure?.fieldError('items') case final error?)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12.w),
                      margin: EdgeInsets.only(bottom: 12.h),
                      decoration: BoxDecoration(
                        color: scheme.errorContainer,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        error,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: scheme.onErrorContainer,
                        ),
                      ),
                    ),
                  for (final (index, line) in state.lines.indexed)
                    _LineCard(
                      key: ValueKey(line.item.id),
                      line: line,
                      movesStock: state.movesStock,
                      quantityError: state.errorAt(index, 'quantity'),
                      priceError: state.errorAt(index, 'unit_price'),
                      weightError: state.errorAt(index, 'warehouse_quantity'),
                      onQuantity: (value) => cubit.setQuantity(line.item.id, value),
                      onUnitPrice: (value) => cubit.setUnitPrice(line.item.id, value),
                      onWeight: (value) => cubit.setWeight(line.item.id, value),
                    ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
                child: AppButton(
                  label: 'حفظ',
                  isLoading: state.isSaving,
                  onPressed: state.isDirty && state.isValid ? cubit.save : null,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static bool _isAboutALine(Failure failure) => switch (failure) {
    ServerFailure(:final fieldErrors?) => fieldErrors.keys.any((key) => key.startsWith('items.')),
    _ => false,
  };
}

class _LineCard extends StatefulWidget {
  const _LineCard({
    required this.line,
    required this.movesStock,
    required this.onQuantity,
    required this.onUnitPrice,
    required this.onWeight,
    this.quantityError,
    this.priceError,
    this.weightError,
    super.key,
  });

  final ManageLineDraft line;
  final bool movesStock;
  final ValueChanged<String> onQuantity;
  final ValueChanged<String> onUnitPrice;
  final ValueChanged<String> onWeight;
  final String? quantityError;
  final String? priceError;
  final String? weightError;

  @override
  State<_LineCard> createState() => _LineCardState();
}

class _LineCardState extends State<_LineCard> {
  late final TextEditingController _quantity = TextEditingController(text: widget.line.quantity);
  late final TextEditingController _price = TextEditingController(text: widget.line.unitPrice);
  late final TextEditingController _weight = TextEditingController(
    text: widget.line.warehouseQuantity,
  );

  /// Arabic-Indic digits are what the keyboard produces; normalised on the way out.
  static final List<TextInputFormatter> _number = [
    FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹.,٫]')),
  ];

  @override
  void dispose() {
    _quantity.dispose();
    _price.dispose();
    _weight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final line = widget.line;
    final item = line.item;
    const keyboard = TextInputType.numberWithOptions(decimal: true);

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: line.isChanged ? scheme.primary : scheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${item.productName} — ${item.variantLabel}',
            style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 2.h),
          Text(
            'الحالي: ${item.quantity.grouped} ${item.pricingUnitLabel}'
            ' × ${item.unitPriceOrZero.grouped}',
            style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          SizedBox(height: 10.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppTextField(
                  controller: _quantity,
                  label: 'الكمية',
                  errorText: widget.quantityError,
                  keyboardType: keyboard,
                  inputFormatters: _number,
                  onChanged: widget.onQuantity,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: AppTextField(
                  controller: _price,
                  label: 'سعر ال${item.pricingUnitLabel}',
                  errorText: widget.priceError,
                  keyboardType: keyboard,
                  inputFormatters: _number,
                  onChanged: widget.onUnitPrice,
                ),
              ),
            ],
          ),
          if (line.needsWeight(movesStock: widget.movesStock) || widget.weightError != null) ...[
            SizedBox(height: 8.h),
            AppTextField(
              controller: _weight,
              label: 'الكمية من المخزن (${item.stockUnitLabel ?? 'وحدة المخزن'})',
              helperText: 'يُباع بال${item.pricingUnitLabel} ويُخزَّن بوحدة أخرى، كم يخرج من الرف؟',
              errorText: widget.weightError,
              keyboardType: keyboard,
              inputFormatters: _number,
              onChanged: widget.onWeight,
            ),
          ],
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.onRetry});

  final String text;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.locked, size: 48.sp, color: scheme.onSurfaceVariant),
            SizedBox(height: 16.h),
            Text(
              text,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
            ),
            if (onRetry case final retry?) ...[
              SizedBox(height: 20.h),
              AppButton.tonal(label: 'إعادة المحاولة', onPressed: retry),
            ],
          ],
        ),
      ),
    );
  }
}
