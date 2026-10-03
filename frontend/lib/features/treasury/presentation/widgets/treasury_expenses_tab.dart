import 'dart:async';

import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/core/widgets/filter_option_chip.dart';
import 'package:dayaa/core/widgets/paged_list_view.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/presentation/viewmodel/treasury_expenses_cubit.dart';
import 'package:dayaa/features/treasury/presentation/widgets/treasury_dialogs.dart';
import 'package:dayaa/features/treasury/presentation/widgets/treasury_widgets.dart';
import 'package:dayaa/features/warehouses/presentation/widgets/day_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// تبويب «المصاريف» في «المالية» — مصاريف كل الحسابات في قائمة واحدة، ومجموعها فوقها.
/// TREASURY-DESIGN §٢١.
///
/// [accounts] لفلتر «الحساب» — ما قرأته اللوحة أصلاً، فلا يُسأل الخادم عنها مرة ثانية.
/// و[onMoneyMoved] يُنادى بعد عكسٍ ناجح لتُقرأ أرصدة اللوحة.
class TreasuryExpensesTab extends StatelessWidget {
  const TreasuryExpensesTab({required this.accounts, required this.onMoneyMoved, super.key});

  final List<TreasuryAccount> accounts;
  final Future<void> Function() onMoneyMoved;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TreasuryExpensesCubit, TreasuryExpensesState>(
      builder: (context, state) {
        final cubit = context.read<TreasuryExpensesCubit>();

        return Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
              child: TreasuryTotalCard(
                key: const ValueKey('expenses-total'),
                label: _totalLabel(cubit),
                amount: cubit.total,
                inline: true,
              ),
            ),
            _Filters(accounts: accounts),
            Expanded(child: _List(onMoneyMoved: onMoneyMoved)),
          ],
        );
      },
    );
  }

  static String _totalLabel(TreasuryExpensesCubit cubit) => switch (cubit.period) {
    ExpensePeriod.thisMonth => 'مصاريف هذا الشهر',
    ExpensePeriod.lastMonth => 'مصاريف الشهر الماضي',
    ExpensePeriod.all => 'كل المصاريف',
    ExpensePeriod.custom => switch (cubit.range) {
      final r? => 'من ${r.from.shortDayLabel} إلى ${r.to.shortDayLabel}',
      null => 'مصاريف الفترة',
    },
  };
}

/// الفترة في صفّ، والتصنيف والحساب في صفٍّ تحته — كلاهما يُفتح على قائمة.
class _Filters extends StatelessWidget {
  const _Filters({required this.accounts});

  final List<TreasuryAccount> accounts;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TreasuryExpensesCubit>();

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 4.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Wraps rather than scrolls: a chip pushed off the edge — «من – إلى» on a phone — is
          // a filter nobody finds.
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              for (final period in ExpensePeriod.values)
                FilterOptionChip(
                  label: period.label,
                  isSelected: cubit.period == period,
                  onTap: () => unawaited(_choosePeriod(context, period)),
                ),
            ],
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              FilterOptionChip(
                label: 'التصنيف: ${_short(cubit.category?.name ?? 'الكل')}',
                isSelected: cubit.category != null,
                onTap: () => unawaited(_chooseCategory(context)),
              ),
              FilterOptionChip(
                label: 'الحساب: ${_short(cubit.account?.name ?? 'الكل')}',
                isSelected: cubit.account != null,
                onTap: () => unawaited(_chooseAccount(context)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// A name is as long as whoever typed it made it, and a chip cannot wrap its own label.
  static String _short(String name) => name.length <= 22 ? name : '${name.substring(0, 21)}…';

  Future<void> _choosePeriod(BuildContext context, ExpensePeriod period) async {
    final cubit = context.read<TreasuryExpensesCubit>();

    if (period != ExpensePeriod.custom) return cubit.showPeriod(period);

    final now = DateTime.now();
    final current = cubit.customRange;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: now,
      initialDateRange: current == null ? null : DateTimeRange(start: current.from, end: current.to),
    );

    if (picked == null) return;

    await cubit.showPeriod(ExpensePeriod.custom, between: (from: picked.start, to: picked.end));
  }

  Future<void> _chooseCategory(BuildContext context) async {
    final cubit = context.read<TreasuryExpensesCubit>();
    final result = await cubit.categories();

    if (!context.mounted) return;

    final categories = result.fold((failure) {
      context.showFailure(failure);

      return null;
    }, (list) => list);

    if (categories == null) return;

    final picked = await _pick<ExpenseCategory?>(
      context,
      title: 'التصنيف',
      options: [(null, 'الكل'), for (final c in categories) (c, c.name)],
    );

    if (picked case (final category,)) await cubit.showCategory(category);
  }

  Future<void> _chooseAccount(BuildContext context) async {
    final cubit = context.read<TreasuryExpensesCubit>();

    final picked = await _pick<TreasuryAccount?>(
      context,
      title: 'الحساب',
      options: [(null, 'الكل'), for (final a in accounts) (a, a.name)],
    );

    if (picked case (final account,)) await cubit.showAccount(account);
  }
}

/// قائمةٌ يُختار منها سطر. تعود بـ`(القيمة,)` — فـ«الكل» (`null`) جوابٌ يختلف عن إغلاق القائمة.
Future<(T,)?> _pick<T>(
  BuildContext context, {
  required String title,
  required List<(T, String)> options,
}) {
  return showModalBottomSheet<(T,)>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 8.h),
            child: Text(
              title,
              style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          for (final (value, label) in options)
            ListTile(title: Text(label), onTap: () => Navigator.of(context).pop((value,))),
        ],
      ),
    ),
  );
}

class _List extends StatelessWidget {
  const _List({required this.onMoneyMoved});

  final Future<void> Function() onMoneyMoved;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TreasuryExpensesCubit>();
    final canReverse = sl<Session>().can(AppPermission.reverseTreasuryOperations);

    return BlocBuilder<TreasuryExpensesCubit, TreasuryExpensesState>(
      builder: (context, state) {
        final items = state is PagedLoaded<TreasuryMovement>
            ? state.page.items
            : const <TreasuryMovement>[];

        return PagedListView<TreasuryMovement>(
          state: state,
          emptyMessage: 'لا مصاريف في هذه الفترة',
          onLoadMore: cubit.loadMore,
          onRefresh: cubit.refresh,
          skeletonHeight: 84.h,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, expense, index) {
            final previous = index > 0 && index - 1 < items.length ? items[index - 1] : null;
            final row = TreasuryMovementRow(
              key: ValueKey(expense.id),
              movement: expense,
              // كسجلّ الحساب: اللمسة تفتح الطلبية حين تكون — «ما احتفظ به الناقل».
              onTap: switch (expense.orderId) {
                final orderId? => () => context.push(Routes.order(orderId)),
                null => null,
              },
              onOptions: canReverse && expense.isReversible && expense.operationId != null
                  ? () => _options(context, expense)
                  : null,
            );

            if (expense.occurredAt case final at? when startsNewDay(previous?.occurredAt, at)) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DayHeader(at: at, first: index == 0),
                  row,
                ],
              );
            }

            return row;
          },
        );
      },
    );
  }

  Future<void> _options(BuildContext context, TreasuryMovement expense) {
    return showTreasuryOptions(
      context,
      title: expense.categoryName ?? expense.kindLabel,
      subtitle: [
        treasuryMoney(expense.signedAmount, signed: true),
        ?expense.accountName,
      ].join(' · '),
      options: [
        TreasuryOption(
          icon: AppIcons.undo,
          label: 'عكس العملية',
          isDestructive: true,
          onSelected: () => unawaited(_reverse(context, expense)),
        ),
      ],
    );
  }

  Future<void> _reverse(BuildContext context, TreasuryMovement expense) async {
    final cubit = context.read<TreasuryExpensesCubit>();

    final reason = await askForReason(
      context,
      title: 'عكس «${expense.categoryName ?? expense.kindLabel}»',
      confirmLabel: 'عكس العملية',
    );

    if (reason == null || !context.mounted) return;

    final failure = await cubit.reverse(expense, reason: reason);

    if (!context.mounted) return;

    if (failure != null) {
      context.showFailure(failure);

      return;
    }

    unawaited(onMoneyMoved());
    context.showSuccess('تم عكس العملية');
  }
}
