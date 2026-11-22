import 'dart:async';

import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_dialog.dart';
import 'package:dayaa/core/widgets/appear.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/line_quote_cubit.dart';
import 'package:dayaa/features/orders/presentation/widgets/product_picker_sheet.dart';
import 'package:dayaa/features/tools/presentation/viewmodel/price_calculator_cubit.dart';
import 'package:dayaa/features/tools/presentation/widgets/price_line_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';

/// حاسبة الأسعار: the customer's list on the phone, priced by the catalogue as it is typed, and
/// a message to paste back to them — without an order behind any of it.
///
/// The lines as a table, the total pinned under the thumb with the copy button beside it, and the
/// message itself folded away until the clerk wants to read it over.
class PriceCalculatorPage extends StatelessWidget {
  const PriceCalculatorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PriceCalculatorCubit>(
      create: (_) => sl<PriceCalculatorCubit>(),
      child: const _PriceCalculatorView(),
    );
  }
}

class _PriceCalculatorView extends StatelessWidget {
  const _PriceCalculatorView();

  Future<void> _addLine(BuildContext context) async {
    final cubit = context.read<PriceCalculatorCubit>();
    final picked = await showProductPicker(
      context: context,
      addedVariantIds: cubit.state.variantIds,
    );
    if (picked == null || !context.mounted) return;

    final key = cubit.add(picked.product, picked.variant);
    // Straight on to the quantity: a size with no count is not a line anybody wanted.
    await showPriceLineSheet(context: context, cubit: cubit, lineKey: key, autofocus: true);
  }

  Future<void> _clear(BuildContext context) async {
    final cubit = context.read<PriceCalculatorCubit>();
    final confirmed = await showCustomDialog(
      context: context,
      title: 'مسح كل البنود؟',
      description: 'ستُحذف كل الأصناف من الحاسبة لتبدأ حساباً جديداً.',
      confirmLabel: 'مسح',
      severity: DialogSeverity.danger,
    );
    if (confirmed ?? false) cubit.clear();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PriceCalculatorCubit, PriceCalculatorState>(
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          title: const Text('حاسبة الأسعار'),
          // Clearing everything is rare and costly, so it sits one tap deeper than adding.
          actions: [
            if (!state.isEmpty)
              PopupMenuButton<void>(
                icon: Icon(AppIcons.more),
                tooltip: 'المزيد',
                itemBuilder: (_) => [
                  PopupMenuItem<void>(
                    onTap: () => _clear(context),
                    child: Row(
                      children: [
                        Icon(AppIcons.clear, size: 20.r, color: context.colorScheme.error),
                        SizedBox(width: 10.w),
                        Text('مسح الكل', style: TextStyle(color: context.colorScheme.error)),
                      ],
                    ),
                  ),
                ],
              ),
            SizedBox(width: 4.w),
          ],
        ),
        body: _FadeSwap(
          child: state.isEmpty
              ? _EmptyCalculator(key: const ValueKey('empty'), onAdd: () => _addLine(context))
              : _Estimate(
                  key: const ValueKey('estimate'),
                  state: state,
                  onAdd: () => _addLine(context),
                ),
        ),
        bottomNavigationBar: state.isEmpty ? null : _TotalBar(state: state),
      ),
    );
  }
}

/// A cross-fade and nothing more — no size or scale, and none at all when the system asks for
/// reduced motion.
class _FadeSwap extends StatelessWidget {
  const _FadeSwap({required this.child, this.alignment = Alignment.center});

  final Widget child;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (current, previous) =>
          Stack(alignment: alignment, children: [...previous, ?current]),
      child: child,
    );
  }
}

class _EmptyCalculator extends StatelessWidget {
  const _EmptyCalculator({required this.onAdd, super.key});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72.r,
              height: 72.r,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(22.r),
              ),
              child: Icon(AppIcons.priceCalculator, size: 34.r, color: scheme.onPrimaryContainer),
            ),
            SizedBox(height: 14.h),
            Text(
              'أضف صنفاً ليُحسب سعره',
              textAlign: TextAlign.center,
              style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 18.h),
            AppButton(label: 'إضافة صنف', icon: AppIcons.add, onPressed: onAdd),
          ],
        ),
      ),
    );
  }
}

class _Estimate extends StatelessWidget {
  const _Estimate({required this.state, required this.onAdd, super.key});

  final PriceCalculatorState state;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PriceCalculatorCubit>();

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
      children: [
        _EstimateTable(
          lines: state.lines,
          onOpen: (key) => showPriceLineSheet(context: context, cubit: cubit, lineKey: key),
          onAdd: onAdd,
        ),
        SizedBox(height: 16.h),
        _MessagePreview(state: state),
      ],
    );
  }
}

/// Column shares of the table, start to end. One place, so the header and every row agree.
const _nameFlex = 9;
const _quantityFlex = 5;
const _priceFlex = 4;
const _totalFlex = 5;

/// The lines as an invoice: what, how many, the price of one, and what it comes to. Figures sit
/// flush with the column's far edge in tabular digits, so they read down the column like money.
class _EstimateTable extends StatelessWidget {
  const _EstimateTable({required this.lines, required this.onOpen, required this.onAdd});

  final List<CalculatorLine> lines;
  final ValueChanged<int> onOpen;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final header = context.textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ColoredBox(
              color: scheme.surfaceContainerLow,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                child: Row(
                  children: [
                    Expanded(
                      flex: _nameFlex,
                      child: Text('الصنف', style: header),
                    ),
                    Expanded(
                      flex: _quantityFlex,
                      child: Text('الكمية', textAlign: TextAlign.end, style: header),
                    ),
                    Expanded(
                      flex: _priceFlex,
                      child: Text('السعر', textAlign: TextAlign.end, style: header),
                    ),
                    Expanded(
                      flex: _totalFlex,
                      child: Text('المجموع (د.ل)', textAlign: TextAlign.end, style: header),
                    ),
                  ],
                ),
              ),
            ),
            for (final (index, line) in lines.indexed) ...[
              if (index > 0)
                Divider(
                  height: 1,
                  indent: 14.w,
                  endIndent: 14.w,
                  color: scheme.outlineVariant.withValues(alpha: 0.6),
                ),
              Appear(
                key: ValueKey(line.key),
                child: _TableRow(line: line, onTap: () => onOpen(line.key)),
              ),
            ],
            Divider(height: 1, color: scheme.outlineVariant),
            InkWell(
              onTap: onAdd,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
                child: Row(
                  children: [
                    Icon(AppIcons.add, size: 18.r, color: scheme.primary),
                    SizedBox(width: 8.w),
                    Text(
                      'إضافة صنف',
                      style: context.textTheme.labelLarge?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({required this.line, required this.onTap});

  final CalculatorLine line;
  final VoidCallback onTap;

  static const _tabular = [FontFeature.tabularFigures()];

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;
    final entry = line.entry;
    final hasQuantity = line.westernQuantity.isNotEmpty;
    final needsAttention = line.quote is LineQuoteFailure || line.hasInvalidUnitPrice;
    final muted = text.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final figure = text.bodyMedium?.copyWith(fontFeatures: _tabular);

    final Widget total = switch ((line.quote, entry.total)) {
      (LineQuoteLoading(), _) => SizedBox(
        key: const ValueKey('loading'),
        width: 16.r,
        height: 16.r,
        child: const CircularProgressIndicator(strokeWidth: 2),
      ),
      (_, final total?) => Text(
        groupedDecimal(total),
        key: ValueKey(total),
        style: figure?.copyWith(fontWeight: FontWeight.w800, color: scheme.onSurface),
      ),
      _ => Text('—', key: const ValueKey('none'), style: muted),
    };

    return Material(
      color: needsAttention ? scheme.errorContainer.withValues(alpha: 0.35) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: _nameFlex,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          line.product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        SizedBox(height: 2.h),
                        Text(line.variant.label, style: muted),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: _quantityFlex,
                    child: hasQuantity
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                entry.quantityLabel,
                                style: figure?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              Text(line.unitLabel, style: muted),
                            ],
                          )
                        : Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: Text(
                              'أدخل',
                              style: text.labelMedium?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                                decorationColor: scheme.primary,
                              ),
                            ),
                          ),
                  ),
                  Expanded(
                    flex: _priceFlex,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(switch (entry.unitPrice) {
                          final price? => groupedDecimal(price),
                          null => '—',
                        }, style: entry.unitPrice == null ? muted : figure),
                        if (line.isPricedByHand)
                          Text(
                            line.handUnitPrice == null ? 'حسب الطلب' : 'يدوي',
                            style: text.labelSmall?.copyWith(color: scheme.tertiary),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: _totalFlex,
                    child: _FadeSwap(alignment: AlignmentDirectional.centerEnd, child: total),
                  ),
                ],
              ),
              _LineNote(line: line),
            ],
          ),
        ),
      ),
    );
  }
}

/// The one sentence a line has to add, when it has one: why it has no price, or the saving
/// still on the table — which is the one thing a clerk can act on with the customer listening.
class _LineNote extends StatelessWidget {
  const _LineNote({required this.line});

  final CalculatorLine line;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    final (text, color) = switch (line.quote) {
      LineQuoteFailure(:final failure) => (failure.message, scheme.error),
      LineQuoteByHand() when line.hasInvalidUnitPrice => ('السعر المكتوب غير صحيح', scheme.error),
      LineQuoteByHand() when line.handUnitPrice != null => (null, null),
      LineQuoteByHand() => ('لا يدخل في الإجمالي · اضغط لإضافة سعر', scheme.onSurfaceVariant),
      LineQuotePriced(:final quote) => switch (quote.nextTier) {
        final next? => (
          'أضف ${next.quantityToReachLabel} ليصبح السعر ${next.unitPriceLabel} د.ل',
          scheme.tertiary,
        ),
        null => (null, null),
      },
      LineQuoteIdle() || LineQuoteLoading() => (null, null),
    };

    if (text == null) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: 8.h),
      child: Text(text, style: context.textTheme.bodySmall?.copyWith(color: color)),
    );
  }
}

/// The message exactly as it will be pasted, folded away by default — the cards already say
/// everything it says, and it is there to read over, not to scroll past every time.
class _MessagePreview extends StatefulWidget {
  const _MessagePreview({required this.state});

  final PriceCalculatorState state;

  @override
  State<_MessagePreview> createState() => _MessagePreviewState();
}

class _MessagePreviewState extends State<_MessagePreview> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final state = widget.state;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'معاينة الرسالة',
                      style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Icon(_open ? AppIcons.collapse : AppIcons.expand, color: scheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
          if (_open)
            Appear(
              child: Padding(
                padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
                child: state.isComplete
                    ? Container(
                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerLowest,
                          borderRadius: BorderRadiusDirectional.only(
                            topStart: Radius.circular(16.r),
                            topEnd: Radius.circular(16.r),
                            bottomStart: Radius.circular(16.r),
                            bottomEnd: Radius.circular(4.r),
                          ),
                        ),
                        child: SelectableText(
                          state.message,
                          style: context.textTheme.bodyMedium?.copyWith(height: 1.7),
                        ),
                      )
                    : Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        child: Text(
                          'أكمل كميات كل البنود لتظهر الرسالة',
                          textAlign: TextAlign.center,
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The total under the thumb, with sending it one tap away. Shut, not busy, until every line
/// has what the message needs.
class _TotalBar extends StatelessWidget {
  const _TotalBar({required this.state});

  final PriceCalculatorState state;

  void _copy(BuildContext context) {
    unawaited(HapticFeedback.selectionClick());
    unawaited(Clipboard.setData(ClipboardData(text: state.message)));
    context.showSuccess('تم نسخ الرسالة — الصقها للعميل');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final ready = state.isComplete;
    final total = state.total;
    final leavesSomeOut = state.lines.any(
      (line) => line.isPricedByHand && line.handUnitPrice == null,
    );

    final caption = switch ((ready, total)) {
      (false, _) => 'أكمل كميات كل البنود',
      (true, null) => 'كل البنود حسب الطلب',
      (true, _) when leavesSomeOut => 'بدون الأصناف حسب الطلب',
      _ => '${state.lines.length} ${state.lines.length == 1 ? 'صنف' : 'أصناف'}',
    };

    return Material(
      color: scheme.surface,
      elevation: 8,
      shadowColor: scheme.shadow.withValues(alpha: 0.25),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 10.h),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الإجمالي · $caption',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    _FadeSwap(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        switch ((ready, total)) {
                          (true, final total?) => '${groupedDecimal(total)} د.ل',
                          _ => '—',
                        },
                        key: ValueKey((ready, total)),
                        style: context.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: ready ? scheme.primary : scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.outlined(
                onPressed: ready
                    ? () => unawaited(SharePlus.instance.share(ShareParams(text: state.message)))
                    : null,
                icon: Icon(AppIcons.share),
                tooltip: 'مشاركة',
                constraints: BoxConstraints.tight(Size(48.r, 48.r)),
              ),
              SizedBox(width: 8.w),
              AppButton(
                label: 'نسخ الرسالة',
                icon: AppIcons.copy,
                expands: false,
                onPressed: ready ? () => _copy(context) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
