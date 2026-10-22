import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/investors/models/profit_sources.dart';
import 'package:dayaa/features/investors/presentation/viewmodel/profit_sources_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// «من أين جاء هذا الرقم؟» — one gate of his profit card, opened.
///
/// [onOrder] opens an order from the page beneath, after the sheet has closed: the sheet's own
/// context is gone by then, and the page's router is the one that should own the new screen.
Future<void> showProfitSourcesSheet({
  required BuildContext context,
  required int investorId,
  required ProfitGate gate,
  required void Function(int orderId) onOrder,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => BlocProvider<ProfitSourcesCubit>(
      create: (_) => sl<ProfitSourcesCubit>()..load(investorId, gate),
      child: _ProfitSourcesSheet(investorId: investorId, gate: gate, onOrder: onOrder),
    ),
  );
}

class _ProfitSourcesSheet extends StatelessWidget {
  const _ProfitSourcesSheet({required this.investorId, required this.gate, required this.onOrder});

  final int investorId;
  final ProfitGate gate;
  final void Function(int orderId) onOrder;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, controller) => Column(
        children: [
          SizedBox(height: 8.h),
          Container(
            height: 4.h,
            width: 40.w,
            decoration: BoxDecoration(
              color: scheme.outlineVariant,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 4.h),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    gate.title,
                    style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                BlocBuilder<ProfitSourcesCubit, ProfitSourcesState>(
                  builder: (context, state) => state is ProfitSourcesLoaded
                      ? _Amount(state.sources.total, strong: true)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          if (gate != ProfitGate.awaitingDelivery)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Text(
                // المطابقةُ تحتاج جملتَها: المحفظةُ لا تحفظ أيَّ طلبيةٍ بقي مالُها فيها.
                gate == ProfitGate.available
                    ? 'ما أُفرج عنه من كل فترة، ثم ما سُحب منه. المجموع هو الرقم على البطاقة.'
                    : 'ربح كل طلبية بحالها، فترةً فترة، وما أُفرج عنه مطروحاً. المجموع هو الرقم على البطاقة.',
                style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          SizedBox(height: 8.h),
          const Divider(height: 1),
          Expanded(
            child: BlocBuilder<ProfitSourcesCubit, ProfitSourcesState>(
              builder: (context, state) => switch (state) {
                ProfitSourcesLoading() => const Center(child: CircularProgressIndicator()),
                ProfitSourcesFailure(:final failure) => _Retry(
                  message: failure.message,
                  onRetry: () => context.read<ProfitSourcesCubit>().load(investorId, gate),
                ),
                ProfitSourcesLoaded(:final sources) when sources.groups.isEmpty => Center(
                  child: Text(
                    'لا شيء خلف هذا الرقم',
                    style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
                ProfitSourcesLoaded(:final sources) => ListView(
                  controller: controller,
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
                  children: [
                    for (final group in sources.groups) ...[
                      if (group.title != null) _GroupHeader(group: group),
                      for (final line in group.lines)
                        _Line(line: line, onOrder: (id) => _openOrder(context, id)),
                      SizedBox(height: 12.h),
                    ],
                  ],
                ),
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openOrder(BuildContext context, int orderId) {
    Navigator.of(context).pop();
    onOrder(orderId);
  }
}

/// A period: its code, its state in the register's words, its days, and what it adds.
class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.group});

  final ProfitSourceGroup group;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final starts = DateTime.tryParse(group.startsOn ?? '');
    final ends = DateTime.tryParse(group.endsOn ?? '');

    return Padding(
      padding: EdgeInsets.only(top: 8.h, bottom: 4.h),
      child: Row(
        children: [
          Text(
            group.title!,
            textDirection: TextDirection.ltr,
            style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (group.statusLabel != null) ...[
            SizedBox(width: 8.w),
            _Chip(label: group.statusLabel!, tone: _toneOfPeriod(group.status)),
          ],
          if (starts != null && ends != null) ...[
            SizedBox(width: 8.w),
            Flexible(
              child: Text(
                AppDates.span(starts, ends),
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ],
          const Spacer(),
          _Amount(group.total, strong: true),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.line, required this.onOrder});

  final ProfitSourceLine line;
  final void Function(int orderId) onOrder;

  @override
  Widget build(BuildContext context) {
    return switch (line.kind) {
      'order' => _OrderLine(line: line, onOrder: onOrder),
      'release' => _ReleaseLine(line: line, onOrder: onOrder),
      _ => _EntryLine(line: line),
    };
  }
}

/// An order and his share of it. Opens the order.
class _OrderLine extends StatelessWidget {
  const _OrderLine({required this.line, required this.onOrder});

  final ProfitSourceLine line;
  final void Function(int orderId) onOrder;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final subtitle = [line.customerName, line.orderStatusLabel].whereType<String>().join(' · ');

    return InkWell(
      onTap: line.orderId == null ? null : () => onOrder(line.orderId!),
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // يلتفّ ولا يفيض: رمزُ طلبيةٍ طويلٌ وشارةُ «بانتظار انتهاء الفترة» لا يسعهما سطرٌ
                  // على هاتفٍ ضيّق.
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 4.h,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        line.code ?? '#${line.orderId}',
                        textDirection: TextDirection.ltr,
                        style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (line.stateLabel != null)
                        _Chip(label: line.stateLabel!, tone: _toneOfState(line.state)),
                    ],
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            _Amount(line.amount),
          ],
        ),
      ),
    );
  }
}

/// What a period's close put in his wallet — opens onto the orders it was made of.
class _ReleaseLine extends StatelessWidget {
  const _ReleaseLine({required this.line, required this.onOrder});

  final ProfitSourceLine line;
  final void Function(int orderId) onOrder;

  @override
  Widget build(BuildContext context) {
    final at = DateTime.tryParse(line.occurredAt ?? '');

    return Theme(
      // بلا خطَّي الحدود اللذين يرسمهما ExpansionTile مفتوحاً — القائمةُ مسطّرةٌ بفراغها.
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 4.w),
        childrenPadding: EdgeInsetsDirectional.only(start: 12.w),
        title: Text(
          line.label ?? '',
          style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: at == null ? null : Text(AppDates.day(at)),
        trailing: _Amount(line.amount),
        children: [
          if (line.children.isEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Text(
                'لا تفصيل لهذا الإفراج',
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          for (final child in line.children) _Line(line: child, onOrder: onOrder),
        ],
      ),
    );
  }
}

/// What is not an order: an expense share, a withdrawal, what a close took out.
class _EntryLine extends StatelessWidget {
  const _EntryLine({required this.line});

  final ProfitSourceLine line;

  @override
  Widget build(BuildContext context) {
    final at = DateTime.tryParse(line.occurredAt ?? '');

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line.label ?? '', style: context.textTheme.bodyLarge),
                if (at != null)
                  Text(
                    AppDates.day(at),
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          _Amount(line.amount),
        ],
      ),
    );
  }
}

/// A signed figure: what is taken out is red and carries its minus.
class _Amount extends StatelessWidget {
  const _Amount(this.amount, {this.strong = false});

  final String amount;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final negative = amount.startsWith('-');

    return Text(
      '${negative ? '-' : ''}${unsigned(amount).grouped} د.ل',
      textDirection: TextDirection.ltr,
      style: (strong ? context.textTheme.titleSmall : context.textTheme.bodyLarge)?.copyWith(
        fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
        color: negative ? context.colorScheme.error : null,
      ),
    );
  }
}

enum _Tone { primary, secondary, warning, muted }

_Tone _toneOfPeriod(String? status) => switch (status) {
  'open' => _Tone.primary,
  'closing' => _Tone.secondary,
  _ => _Tone.muted,
};

_Tone _toneOfState(String? state) => switch (state) {
  'awaiting_payment' => _Tone.warning,
  'released' => _Tone.muted,
  'awaiting_delivery' => _Tone.secondary,
  _ => _Tone.primary,
};

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.tone});

  final String label;
  final _Tone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    final (fill, ink) = switch (tone) {
      _Tone.primary => (scheme.primaryContainer, scheme.onPrimaryContainer),
      _Tone.secondary => (scheme.secondaryContainer, scheme.onSecondaryContainer),
      _Tone.warning => (scheme.errorContainer, scheme.onErrorContainer),
      _Tone.muted => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(8.r)),
      child: Text(label, style: context.textTheme.labelSmall?.copyWith(color: ink)),
    );
  }
}

class _Retry extends StatelessWidget {
  const _Retry({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          SizedBox(height: 8.h),
          TextButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
        ],
      ),
    );
  }
}
