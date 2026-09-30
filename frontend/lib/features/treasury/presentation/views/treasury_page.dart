import 'dart:async';

import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_speed_dial.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/presentation/viewmodel/treasury_cubit.dart';
import 'package:dayaa/features/treasury/presentation/widgets/treasury_account_sheet.dart';
import 'package:dayaa/features/treasury/presentation/widgets/treasury_operation_sheet.dart';
import 'package:dayaa/features/treasury/presentation/widgets/treasury_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// الحسابات والخزائن — every account and what it holds, whose the money is, and what the
/// shelves are worth. TREASURY-DESIGN §٩.
///
/// **Somebody without `treasury.view` sees the accounts in their own name** — a driver his
/// custody, Ali «مصرف علي» — and nothing about the shop's. The server decides which; this screen
/// draws what it was sent and hides the cards it was not.
class TreasuryPage extends StatelessWidget {
  const TreasuryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TreasuryCubit(
        getAccounts: sl(),
        getOwnership: sl(),
        getInventoryValue: sl(),
        recordOperation: sl(),
        saveAccount: sl(),
      )..load(),
      child: const _TreasuryView(),
    );
  }
}

class _TreasuryView extends StatelessWidget {
  const _TreasuryView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TreasuryCubit, TreasuryState>(
      builder: (context, state) {
        final cubit = context.read<TreasuryCubit>();

        return Scaffold(
          appBar: AppBar(
            title: const Text('الحسابات والخزائن'),
            actions: [
              if (sl<Session>().can(AppPermission.manageTreasury))
                IconButton(
                  tooltip: 'إعدادات المالية',
                  icon: Icon(AppIcons.settings),
                  onPressed: () async {
                    await context.push(Routes.treasurySettings);

                    if (context.mounted) unawaited(cubit.load());
                  },
                ),
            ],
          ),
          floatingActionButton: state is TreasuryLoaded && state.accounts.canViewAll
              ? _Actions(accounts: state.accounts.accounts)
              : null,
          body: switch (state) {
            TreasuryLoading() => const Center(child: CircularProgressIndicator()),
            TreasuryFailed(:final failure) => _Failed(failure: failure, onRetry: cubit.load),
            TreasuryLoaded() => RefreshIndicator(
              onRefresh: cubit.load,
              child: _Loaded(state: state),
            ),
          },
        );
      },
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({required this.state});

  final TreasuryLoaded state;

  @override
  Widget build(BuildContext context) {
    final accounts = state.accounts;
    final cubit = context.read<TreasuryCubit>();

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 96.h),
      children: [
        TreasuryTotalCard(
          label: accounts.canViewAll ? 'كل ما في الحسابات' : 'ما في حساباتك',
          amount: accounts.total,
        ),
        SizedBox(height: 16.h),

        if (accounts.accounts.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 32.h),
            child: Text(
              'لا يوجد حساب باسمك',
              textAlign: TextAlign.center,
              style: context.textTheme.bodyLarge,
            ),
          ),

        for (final account in accounts.accounts)
          TreasuryAccountTile(
            key: ValueKey(account.id),
            account: account,
            onTap: () async {
              await context.push(Routes.treasuryAccount(account.id));

              unawaited(cubit.load());
            },
          ),

        if (state.ownership case final ownership?) ...[
          SizedBox(height: 16.h),
          TreasuryFiguresCard(
            title: 'لمن المال',
            icon: AppIcons.investors,
            lines: [
              ('كل ما في الحسابات', ownership.totalHeld),
              for (final investor in ownership.investors)
                (investor.name, _sum(investor.capital, investor.profit)),
              ('نقد الصندوق الاستثماري', ownership.fundCash),
            ],
            emphasis: ('مال الشركة نفسها', ownership.companyOwn),
          ),
        ],

        if (state.inventory case final inventory?) ...[
          SizedBox(height: 16.h),
          TreasuryFiguresCard(
            title: 'قيمة المخزون بالتكلفة',
            icon: AppIcons.warehouse,
            lines: [
              ('بضاعة الشركة', inventory.company),
              ('بضاعة الصندوق', inventory.fund),
              for (final warehouse in inventory.byWarehouse)
                ('في ${warehouse.name}', warehouse.value),
            ],
            emphasis: ('الإجمالي', inventory.total),
          ),
        ],
      ],
    );
  }

  /// Capital and profit are both kept for the investor, so the card shows them as one figure.
  /// Decimal strings added as integers of millimes — never through a float.
  static String _sum(String a, String b) {
    int millimes(String value) {
      final negative = value.startsWith('-');
      final parts = (negative ? value.substring(1) : value).split('.');
      final whole = int.tryParse(parts.first) ?? 0;
      final fraction =
          int.tryParse((parts.length > 1 ? parts[1] : '0').padRight(2, '0').substring(0, 2)) ?? 0;
      final total = whole * 100 + fraction;

      return negative ? -total : total;
    }

    final total = millimes(a) + millimes(b);
    final sign = total < 0 ? '-' : '';
    final absolute = total.abs();

    return '$sign${absolute ~/ 100}.${(absolute % 100).toString().padLeft(2, '0')}';
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.accounts});

  final List<TreasuryAccount> accounts;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TreasuryCubit>();

    AppAction operation(OperationKind kind, IconData icon, AppPermission permission) => AppAction(
      label: kind.label,
      icon: icon,
      permission: permission,
      onTap: (context) => showTreasuryOperationSheet(
        context: context,
        kind: kind,
        accounts: accounts,
        onSubmit: cubit.record,
      ),
    );

    return AppSpeedDial(
      actions: [
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
        operation(OperationKind.expense, AppIcons.expense, AppPermission.recordTreasuryOperations),
        operation(
          OperationKind.transfer,
          AppIcons.transfer,
          AppPermission.recordTreasuryOperations,
        ),
        operation(
          OperationKind.adjustment,
          AppIcons.countBalance,
          AppPermission.adjustTreasuryBalances,
        ),
        operation(OperationKind.opening, AppIcons.treasury, AppPermission.manageTreasury),
        AppAction(
          label: 'حساب جديد',
          icon: AppIcons.add,
          tone: AppActionTone.primary,
          permission: AppPermission.manageTreasury,
          onTap: (context) => showTreasuryAccountSheet(
            context: context,
            onSubmit: ({required name, kind, isDefault, isActive, holderUserId, notes}) =>
                cubit.saveAccount(
                  name: name,
                  kind: kind,
                  isDefault: isDefault,
                  holderUserId: holderUserId,
                  notes: notes,
                ),
          ),
        ),
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
