import 'dart:async';

import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_speed_dial.dart';
import 'package:dayaa/core/widgets/paged_list_view.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/presentation/viewmodel/treasury_account_cubit.dart';
import 'package:dayaa/features/treasury/presentation/widgets/treasury_account_sheet.dart';
import 'package:dayaa/features/treasury/presentation/widgets/treasury_operation_sheet.dart';
import 'package:dayaa/features/treasury/presentation/widgets/treasury_widgets.dart';
import 'package:dayaa/features/treasury/usecases/treasury_usecases.dart';
import 'package:dayaa/features/warehouses/presentation/widgets/day_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// One account: its balance, what came in and went out by kind, and every movement — the date,
/// the amount, the kind, who did it, the order it belongs to, the note. TREASURY-DESIGN §٩.
class TreasuryAccountPage extends StatelessWidget {
  const TreasuryAccountPage({required this.accountId, super.key});

  final int accountId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => TreasuryAccountCubit(
            accountId: accountId,
            getAccount: sl(),
            recordOperation: sl(),
            reverseOperation: sl(),
            saveAccount: sl(),
          )..load(),
        ),
        BlocProvider(
          create: (_) => AccountMovementsCubit(accountId: accountId, getMovements: sl())..load(),
        ),
      ],
      child: const _AccountView(),
    );
  }
}

class _AccountView extends StatelessWidget {
  const _AccountView();

  /// After anything that moved money here: the header and the history both change.
  static void _refreshAll(BuildContext context) {
    unawaited(context.read<TreasuryAccountCubit>().load());
    unawaited(context.read<AccountMovementsCubit>().refresh());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TreasuryAccountCubit, TreasuryAccountState>(
      builder: (context, state) {
        final detail = state is TreasuryAccountLoaded ? state.detail : null;

        return Scaffold(
          appBar: AppBar(
            title: Text(detail?.account.name ?? 'الحساب'),
            actions: [
              if (detail != null && sl<Session>().can(AppPermission.manageTreasury))
                IconButton(
                  tooltip: 'تعديل الحساب',
                  icon: Icon(AppIcons.edit),
                  onPressed: () => _edit(context, detail.account),
                ),
            ],
          ),
          // A vendor's «علينا» moves by its purchase orders and payments alone (§٢٠).
          floatingActionButton: detail == null || detail.account.isVendorPayable
              ? null
              : _Actions(account: detail.account),
          body: switch (state) {
            TreasuryAccountLoading() => const Center(child: CircularProgressIndicator()),
            TreasuryAccountFailed(:final failure) => _Failed(
              failure: failure,
              onRetry: context.read<TreasuryAccountCubit>().load,
            ),
            TreasuryAccountLoaded(:final detail) => Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 4.h),
                  // A debt is said as what is owed — «علينا 1,000» — not as −1,000.
                  child: TreasuryTotalCard(
                    label: !detail.account.isPayable
                        ? 'الرصيد الحالي'
                        : detail.account.owed.startsWith('-')
                        ? 'لنا عنده'
                        : 'المستحق علينا',
                    amount: !detail.account.isPayable
                        ? detail.account.balance ?? '0'
                        : detail.account.owed.replaceFirst('-', ''),
                    footnote: [
                      detail.account.kindLabel,
                      if (detail.account.holder case final holder?) 'باسم ${holder.name}',
                      if (detail.account.isVendorPayable) 'يتحرك من أوامر الشراء ودفعات المورد',
                    ].join(' · '),
                  ),
                ),
                _Totals(detail: detail),
                const Expanded(child: _History()),
              ],
            ),
          },
        );
      },
    );
  }

  Future<void> _edit(BuildContext context, TreasuryAccount account) async {
    final cubit = context.read<TreasuryAccountCubit>();

    await showTreasuryAccountSheet(context: context, account: account, onSubmit: cubit.save);
  }
}

/// «الإيداعات · المسحوبات · التحويلات الداخلة والخارجة · التسويات» — each kind this account has
/// seen, net of reversals, in the enum's order the server keeps.
class _Totals extends StatelessWidget {
  const _Totals({required this.detail});

  final TreasuryAccountDetail detail;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    final chips = <String>[
      'داخل ${treasuryMoney(detail.totalIn)}',
      'خارج ${treasuryMoney(detail.totalOut)}',
      for (final kind in detail.byKind)
        if (kind.kind == 'transfer') ...[
          'تحويلات داخلة ${treasuryMoney(kind.moneyIn)}',
          'تحويلات خارجة ${treasuryMoney(kind.moneyOut)}',
        ] else
          '${kind.label} ${treasuryMoney(kind.net, signed: true)}',
    ];

    return SizedBox(
      height: 44.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        itemCount: chips.length,
        separatorBuilder: (_, _) => SizedBox(width: 8.w),
        itemBuilder: (context, index) => Chip(
          label: Text(chips[index], textDirection: TextDirection.rtl),
          backgroundColor: scheme.surfaceContainerHighest,
          side: BorderSide.none,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}

class _History extends StatelessWidget {
  const _History();

  static const _reversible = {'deposit', 'withdrawal', 'expense', 'transfer', 'adjustment'};

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AccountMovementsCubit>();

    return BlocBuilder<AccountMovementsCubit, AccountMovementsState>(
      builder: (context, state) {
        final items = state is PagedLoaded<TreasuryMovement>
            ? state.page.items
            : const <TreasuryMovement>[];

        return PagedListView<TreasuryMovement>(
          state: state,
          emptyMessage: 'لم يتحرّك هذا الحساب بعد',
          onLoadMore: cubit.loadMore,
          onRefresh: cubit.refresh,
          skeletonHeight: 84.h,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, movement, index) {
            final previous = index > 0 && index - 1 < items.length ? items[index - 1] : null;
            final row = TreasuryMovementRow(
              key: ValueKey(movement.id),
              movement: movement,
              onTap: _tapOf(context, movement),
            );

            if (movement.occurredAt case final at? when startsNewDay(previous?.occurredAt, at)) {
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

  /// A hand operation is undone from its line; money that belongs to an order opens the order.
  VoidCallback? _tapOf(BuildContext context, TreasuryMovement movement) {
    final operationId = movement.operationId;
    final canReverse = sl<Session>().can(AppPermission.reverseTreasuryOperations);

    if (operationId != null &&
        !movement.isReversal &&
        canReverse &&
        _reversible.contains(movement.kind)) {
      return () => _reverse(context, operationId, movement);
    }

    if (movement.orderId case final orderId?) {
      return () => context.push(Routes.order(orderId));
    }

    return null;
  }

  Future<void> _reverse(BuildContext context, int operationId, TreasuryMovement movement) async {
    final cubit = context.read<TreasuryAccountCubit>();
    final movements = context.read<AccountMovementsCubit>();

    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _ReasonDialog(title: 'عكس «${movement.kindLabel}»'),
    );

    if (reason == null || !context.mounted) return;

    final failure = await cubit.reverse(operationId, reason: reason);

    if (!context.mounted) return;

    if (failure != null) {
      context.showError(failure.message, details: failure.details);

      return;
    }

    unawaited(movements.refresh());
    context.showSuccess('تم عكس العملية');
  }
}

/// Why an operation is undone — the reason is mandatory, and it travels onto the reversal.
///
/// The controller lives and dies with the dialog, not with whoever opened it: the exit animation
/// is still reading it after `showDialog` returns.
class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog({required this.title});

  final String title;

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _reason,
        autofocus: true,
        maxLines: 2,
        decoration: const InputDecoration(labelText: 'السبب'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
        FilledButton(
          onPressed: () {
            final text = _reason.text.trim();

            if (text.isNotEmpty) Navigator.of(context).pop(text);
          },
          child: const Text('عكس'),
        ),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.account});

  final TreasuryAccount account;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TreasuryAccountCubit>();

    Future<void> open(
      BuildContext context,
      OperationKind kind, {
      bool into = false,
      String? title,
    }) async {
      // The other side of a transfer needs every account, not just this one.
      final all = await sl<GetTreasuryAccounts>()(activeOnly: true);

      if (!context.mounted) return;

      final accounts = all.fold((_) => [account], (list) => list.accounts);

      await showTreasuryOperationSheet(
        context: context,
        kind: kind,
        accounts: accounts,
        // This account is fixed in the sheet — only the other side is chosen.
        account: account,
        into: into,
        title: title,
        onSubmit:
            ({
              required kind,
              amount,
              fromAccountId,
              toAccountId,
              categoryId,
              employeeId,
              countedBalance,
              notes,
            }) async {
              final failure = await cubit.record(
                kind: kind,
                amount: amount,
                fromAccountId: fromAccountId,
                toAccountId: toAccountId,
                categoryId: categoryId,
                employeeId: employeeId,
                countedBalance: countedBalance,
                notes: notes,
              );

              if (failure == null && context.mounted) _AccountView._refreshAll(context);

              return failure;
            },
      );
    }

    AppAction operation(OperationKind kind, IconData icon, AppPermission permission) => AppAction(
      label: kind.label,
      icon: icon,
      permission: permission,
      onTap: (context) => open(context, kind),
    );

    return AppSpeedDial(
      actions: [
        // A payable takes an expense bought on credit and a transfer — borrowing from it,
        // repaying into it — but no deposit or withdrawal: no money arrives or leaves (§٢٠).
        if (account.isPayable) ...[
          operation(
            OperationKind.expense,
            AppIcons.expense,
            AppPermission.recordTreasuryOperations,
          ),
          // The two directions a transfer takes on a debt, each with the loan fixed on its side.
          AppAction(
            label: 'اقتراض',
            icon: AppIcons.fundDeposit,
            permission: AppPermission.recordTreasuryOperations,
            onTap: (context) => open(context, OperationKind.transfer, title: 'اقتراض — من الالتزام إلى حساب'),
          ),
          AppAction(
            label: 'سداد',
            icon: AppIcons.fundWithdraw,
            permission: AppPermission.recordTreasuryOperations,
            onTap: (context) => open(
              context,
              OperationKind.transfer,
              into: true,
              title: 'سداد — من حساب إلى الالتزام',
            ),
          ),
        ],
        if (account.isSpendable) ...[
          operation(
            OperationKind.deposit,
            AppIcons.fundDeposit,
            AppPermission.recordTreasuryOperations,
          ),
          operation(
            OperationKind.withdrawal,
            AppIcons.fundWithdraw,
            AppPermission.recordTreasuryOperations,
          ),
          operation(
            OperationKind.expense,
            AppIcons.expense,
            AppPermission.recordTreasuryOperations,
          ),
          operation(
            OperationKind.transfer,
            AppIcons.transfer,
            AppPermission.recordTreasuryOperations,
          ),
        ],
        operation(
          OperationKind.adjustment,
          AppIcons.countBalance,
          AppPermission.adjustTreasuryBalances,
        ),
        operation(OperationKind.opening, AppIcons.treasury, AppPermission.manageTreasury),
      ],
    );
  }
}

class _Failed extends StatelessWidget {
  const _Failed({required this.failure, required this.onRetry});

  final Failure failure;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(failure.message, textAlign: TextAlign.center),
            SizedBox(height: 16.h),
            AppButton.tonal(label: 'إعادة المحاولة', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
