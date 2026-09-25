import 'dart:async';

import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/pop_result.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/core/widgets/filter_option_chip.dart';
import 'package:dayaa/core/widgets/paged_list_view.dart';
import 'package:dayaa/features/investment_fund/presentation/widgets/fund_detail_body.dart';
import 'package:dayaa/features/investors/models/wallet_entry.dart';
import 'package:dayaa/features/investors/presentation/viewmodel/investor_statement_cubit.dart';
import 'package:dayaa/features/investors/presentation/widgets/wallet_entry_row.dart';
import 'package:dayaa/features/warehouses/presentation/widgets/day_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// سجلُّ حركات المستثمر — كلُّ ما جرى لماله: إيداعٌ وسحب، اشتراكٌ في الصندوق واستردادٌ منه،
/// ربحٌ وخسارة، وما أُلغي منها.
///
/// الأحدثُ أوّلاً، مجموعاً باليوم كسجلّ الخزينة. فوق القائمة عائلاتُ الحركة، وفي الشريط مدى
/// الأيام — والفلترُ كلُّه على الخادم، لا على الصفحة المحمّلة.
///
/// **يُرجع `true` إن أُلغيت حركة**، فتعيد صفحةُ المستثمر قراءةَ أرصدته: الإلغاءُ يغيّرها، ولا
/// أحدَ غيرُ هذه الشاشة يعرف أنه وقع.
class InvestorStatementPage extends StatelessWidget {
  const InvestorStatementPage({required this.investorId, this.investorName, super.key});

  final int investorId;

  /// في الشريط تحت العنوان إن عُرف — يُمرَّر من صفحته، فلا طلبَ ثانٍ لأجله.
  final String? investorName;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<InvestorStatementCubit>()..open(investorId),
      child: _StatementView(investorName: investorName),
    );
  }
}

class _StatementView extends StatelessWidget {
  const _StatementView({this.investorName});

  final String? investorName;

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<InvestorStatementCubit>();
    final state = cubit.state;
    final items = state is InvestorStatementLoaded ? state.page.items : const <WalletEntry>[];
    final canReverse = sl<Session>().can(AppPermission.recordInvestorMoney);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('سجل الحركات'),
            if (investorName case final name?)
              Text(
                name,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'حسب التاريخ',
            icon: const Icon(Icons.date_range_rounded),
            onPressed: () => _pickRange(context, cubit),
          ),
        ],
      ),
      body: Column(
        children: [
          _CategoryBar(selected: cubit.category, onSelect: cubit.filterBy),
          if (cubit.from case final from?)
            if (cubit.to case final to?)
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 4.h),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: InputChip(
                    label: Text(AppDates.span(from, to)),
                    onDeleted: () => unawaited(cubit.between(null, null)),
                  ),
                ),
              ),
          Expanded(
            child: PagedListView<WalletEntry>(
              state: state,
              emptyMessage: cubit.category == null && cubit.from == null
                  ? 'لا حركات على ماله بعد'
                  : 'لا حركات تطابق هذا الفلتر',
              onLoadMore: cubit.loadMore,
              onRefresh: cubit.refresh,
              skeletonHeight: 96.h,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              separatorBuilder: (context, index) => const FundHairline(),
              itemBuilder: (context, entry, index) => _groupedByDay(
                items: items,
                index: index,
                entry: entry,
                row: WalletEntryRow(
                  key: ValueKey(entry.id),
                  entry: entry,
                  onReverse: canReverse && entry.canBeReversed
                      ? () => _reverse(context, cubit, entry)
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickRange(BuildContext context, InvestorStatementCubit cubit) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: now,
      initialDateRange: cubit.from != null && cubit.to != null
          ? DateTimeRange(start: cubit.from!, end: cubit.to!)
          : null,
    );

    if (picked == null) return;

    await cubit.between(picked.start, picked.end);
  }

  /// يُلغي حركةً بعد تأكيد — والإلغاءُ يُبطل معها وحداتِ الصندوق وصفَّ الخزينة الذي كتبته.
  Future<void> _reverse(
    BuildContext context,
    InvestorStatementCubit cubit,
    WalletEntry entry,
  ) async {
    final notes = await showDialog<String>(
      context: context,
      builder: (_) => _ReverseDialog(entry: entry),
    );

    if (notes == null || !context.mounted) return;

    final failure = await cubit.reverse(entry, notes: notes);

    if (!context.mounted) return;

    if (failure != null) {
      context.showFailure(failure);

      return;
    }

    context.handBack(true);
    context.showSuccess('أُلغيت الحركة');
  }
}

/// الكلُّ، ثم العائلاتُ الأربع — **تلتفّ ولا تُمرَّر.** خمسُ رقائق لا تتّسع لسطرٍ على هاتفٍ ضيّق،
/// وصفٌّ يُمرَّر أفقياً كان يُخفي «الأرباح» و«الخسائر» خلف حافّة الشاشة: فلترٌ لا يُرى لا يُسأل.
class _CategoryBar extends StatelessWidget {
  const _CategoryBar({required this.selected, required this.onSelect});

  final WalletEntryCategory? selected;
  final Future<void> Function(WalletEntryCategory?) onSelect;

  @override
  Widget build(BuildContext context) {
    final options = <WalletEntryCategory?>[null, ...WalletEntryCategory.values];

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 6.h),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            for (final option in options)
              FilterOptionChip(
                label: option?.label ?? 'الكل',
                isSelected: option == selected,
                onTap: () => unawaited(onSelect(option)),
              ),
          ],
        ),
      ),
    );
  }
}

/// تأكيدُ الإلغاء، وملاحظةٌ اختيارية تبقى على صفّ الإلغاء.
///
/// **ويدٌ تملك المتحكّم** — لا متحكّمٌ يُنشأ بجانب `showDialog` ويُتلف بعد عودته، والحوارُ ما زال
/// يتلاشى ويستعمله. انظر حوارَ إلغاء الدفعة في الطلبيات.
class _ReverseDialog extends StatefulWidget {
  const _ReverseDialog({required this.entry});

  final WalletEntry entry;

  @override
  State<_ReverseDialog> createState() => _ReverseDialogState();
}

class _ReverseDialogState extends State<_ReverseDialog> {
  final _notes = TextEditingController();

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;

    return AlertDialog(
      title: const Text('إلغاء الحركة'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '«${entry.typeLabel}» بمبلغ ${entry.amount.grouped} د.ل تبقى في السجل مشطوبة، '
            'ويُكتب بجانبها قيدُ إلغائها. وإن كانت اشتراكاً في الصندوق أو استرداداً منه أُلغيت '
            'وحداتُه معها.',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 16.h),
          AppTextField(
            controller: _notes,
            label: 'ملاحظة (اختياري)',
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('تراجع')),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_notes.text.trim()),
          child: Text(
            'إلغاء الحركة',
            style: TextStyle(color: context.colorScheme.error),
          ),
        ),
      ],
    );
  }
}

/// [row]، وفوقه ترويسةُ اليوم إن كان أوّلَ يومه — القاعدةُ نفسُها في سجلّ الخزينة والمخزن.
Widget _groupedByDay({
  required List<WalletEntry> items,
  required int index,
  required WalletEntry entry,
  required Widget row,
}) {
  final previous = index > 0 && index - 1 < items.length ? items[index - 1] : null;

  if (entry.occurredAt case final at? when startsNewDay(previous?.occurredAt, at)) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [DayHeader(at: at, first: index == 0), row],
    );
  }

  return row;
}
