import 'dart:async';

import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/router/pop_result.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_speed_dial.dart';
import 'package:dayaa/core/widgets/filter_option_chip.dart';
import 'package:dayaa/core/widgets/paged_list_view.dart';
import 'package:dayaa/core/widgets/search_field.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/presentation/viewmodel/treasury_account_cubit.dart';
import 'package:dayaa/features/treasury/presentation/widgets/treasury_account_sheet.dart';
import 'package:dayaa/features/treasury/presentation/widgets/treasury_dialogs.dart';
import 'package:dayaa/features/treasury/presentation/widgets/treasury_operation_sheet.dart';
import 'package:dayaa/features/treasury/presentation/widgets/treasury_widgets.dart';
import 'package:dayaa/features/warehouses/presentation/widgets/day_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// حسابٌ واحد: رصيده، وكل حركة — التاريخ، والمبلغ، والنوع، ومن فعلها، والطلبية التي تخصّها،
/// والملاحظة. يُقصر على مال الطلبيات أو المصاريف، ويُبحث فيه برقم الطلبية. TREASURY-DESIGN §٩.
///
/// **يُعيد لمن فتحه ما تغيّر** ([TreasuryAccountCubit.change]) — فلا تعيد اللوحة قراءة نفسها
/// بعد كل زيارة.
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
            getAccounts: sl(),
            recordOperation: sl(),
            saveAccount: sl(),
          )..load(),
        ),
        BlocProvider(
          create: (_) => AccountMovementsCubit(
            accountId: accountId,
            getMovements: sl(),
            reverseOperation: sl(),
          )..load(),
        ),
      ],
      child: const _AccountView(),
    );
  }
}

class _AccountView extends StatelessWidget {
  const _AccountView();

  @override
  Widget build(BuildContext context) {
    final movements = context.read<AccountMovementsCubit>();

    return BlocConsumer<TreasuryAccountCubit, TreasuryAccountState>(
      listener: (context, state) {
        // كل قراءةٍ تمرّ هنا: ما تغيّر يُسلَّم لمن فتح الصفحة، كيفما أُغلقت.
        context.handBack(context.read<TreasuryAccountCubit>().change);

        if (state case TreasuryAccountLoaded(:final refreshFailure?)) {
          context.showFailure(refreshFailure);
        }
      },
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
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
                  child: SearchField(
                    hint: 'ابحث برقم الطلبية',
                    keyboardType: TextInputType.number,
                    onChanged: movements.search,
                  ),
                ),
                const _Filters(),
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

    await showTreasuryAccountSheet(
      context: context,
      account: account,
      onSubmit: ({required name, kind, isDefault, isActive, holderUserId, notes}) => cubit.save(
        name: name,
        isDefault: isDefault,
        isActive: isActive,
        holderUserId: holderUserId,
        notes: notes,
      ),
    );
  }
}

/// «الكل · الطلبيات · المصاريف» — صفٌّ ثابت لا يمرَّر. حلّ محلَّ صفّ المجاميع بطلب المستخدم
/// (2026-10-01): «داخل خارج هذي كلها ماليهاش فائدة».
class _Filters extends StatelessWidget {
  const _Filters();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AccountMovementsCubit>();

    return BlocBuilder<AccountMovementsCubit, AccountMovementsState>(
      builder: (context, _) => Padding(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 4.h),
        child: Row(
          children: [
            for (final filter in MovementFilter.values) ...[
              if (filter != MovementFilter.values.first) SizedBox(width: 8.w),
              FilterOptionChip(
                label: filter.label,
                isSelected: cubit.filter == filter,
                onTap: () => unawaited(cubit.narrowTo(filter)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _History extends StatelessWidget {
  const _History();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AccountMovementsCubit>();
    final canReverse = sl<Session>().can(AppPermission.reverseTreasuryOperations);

    return BlocBuilder<AccountMovementsCubit, AccountMovementsState>(
      builder: (context, state) {
        final items = state is PagedLoaded<TreasuryMovement>
            ? state.page.items
            : const <TreasuryMovement>[];
        return PagedListView<TreasuryMovement>(
          state: state,
          emptyMessage: switch (cubit.filter) {
            MovementFilter.all => 'لم يتحرّك هذا الحساب بعد',
            MovementFilter.orders => 'لا مال طلبيات في هذا الحساب',
            MovementFilter.expenses => 'لا مصاريف من هذا الحساب',
          },
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
              // اللمسة تفتح مصدر المال حين يكون له باب — الطلبية — ولا شيء غير ذلك.
              onTap: switch (movement.orderId) {
                final orderId? => () => context.push(Routes.order(orderId)),
                null => null,
              },
              // العكس في «...» وحده، وحين يقول الخادم إن السطر يُعكس.
              onOptions: canReverse && movement.isReversible && movement.operationId != null
                  ? () => _options(context, movement)
                  : null,
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

  Future<void> _options(BuildContext context, TreasuryMovement movement) {
    return showTreasuryOptions(
      context,
      title: movement.kindLabel,
      subtitle: [
        treasuryMoney(movement.signedAmount, signed: true),
        if (movement.occurredAt case final at?) at.timeLabel,
      ].join(' · '),
      options: [
        TreasuryOption(
          icon: AppIcons.undo,
          label: 'عكس العملية',
          isDestructive: true,
          onSelected: () => unawaited(_reverse(context, movement)),
        ),
      ],
    );
  }

  /// يعكس العملية بسببٍ إجباري. السجلُّ يُرقَّع (الأصل مشطوب وسطرُ العكس فوقه)، والرأسُ يُقرأ.
  Future<void> _reverse(BuildContext context, TreasuryMovement movement) async {
    final header = context.read<TreasuryAccountCubit>();
    final movements = context.read<AccountMovementsCubit>();

    final reason = await askForReason(
      context,
      title: 'عكس «${movement.kindLabel}»',
      confirmLabel: 'عكس العملية',
    );

    if (reason == null || !context.mounted) return;

    final failure = await movements.reverse(movement, reason: reason);

    if (!context.mounted) return;

    if (failure != null) {
      context.showFailure(failure);

      return;
    }

    unawaited(header.moneyMoved());
    context.showSuccess('تم عكس العملية');
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.account});

  final TreasuryAccount account;

  @override
  Widget build(BuildContext context) {
    final header = context.read<TreasuryAccountCubit>();
    final movements = context.read<AccountMovementsCubit>();

    Future<void> open(
      BuildContext context,
      OperationKind kind, {
      bool into = false,
      String? title,
    }) async {
      var accounts = [account];

      // الطرف الآخر في التحويل يحتاج كل الحسابات — وفشلُ قراءتها يُقال، فلا يُفتح التحويل على
      // هذا الحساب وحده.
      if (kind == OperationKind.transfer) {
        final targets = await header.transferTargets();

        if (!context.mounted) return;

        final list = targets.fold<List<TreasuryAccount>?>((failure) {
          context.showFailure(failure);

          return null;
        }, (list) => list);

        if (list == null) return;

        accounts = list;
      }

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
              clientToken,
            }) async {
              final result = await header.record(
                kind: kind,
                amount: amount,
                fromAccountId: fromAccountId,
                toAccountId: toAccountId,
                categoryId: categoryId,
                employeeId: employeeId,
                countedBalance: countedBalance,
                notes: notes,
                clientToken: clientToken,
              );

              return result.fold((failure) => failure, (operation) {
                // السطر الذي كتبته العملية يُضاف أعلى السجل — لا يُعاد السجل كله.
                unawaited(movements.addWrittenBy(operation));

                return null;
              });
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
