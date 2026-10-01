import 'dart:async';

import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/router/pop_result.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/fixed_point.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_speed_dial.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/presentation/viewmodel/account_change.dart';
import 'package:dayaa/features/treasury/presentation/viewmodel/treasury_cubit.dart';
import 'package:dayaa/features/treasury/presentation/widgets/treasury_account_sheet.dart';
import 'package:dayaa/features/treasury/presentation/widgets/treasury_operation_sheet.dart';
import 'package:dayaa/features/treasury/presentation/widgets/treasury_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
    return BlocConsumer<TreasuryCubit, TreasuryState>(
      // إعادة تحميلٍ فشلت والشاشة باقية على ما قبلها: يُقال الفشل ولا يُمحى ما عليها.
      listener: (context, state) {
        if (state case TreasuryLoaded(:final refreshFailure?)) context.showFailure(refreshFailure);
      },
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
                    // الإعدادات تقول إن حُفظ فيها شيء — فتُقرأ الحسابات مرةً، لا بعد كل زيارة.
                    final changed = await context.pushForResult<bool>(Routes.treasurySettings);

                    if ((changed ?? false) && context.mounted) unawaited(cubit.load());
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
            // صفحة الحساب تعيد ما تغيّر: تعديلٌ يُرقَّع صفُّه، ومالٌ تحرّك يُقرأ له المجموع.
            onTap: () async {
              final change = await context.pushForResult<AccountChange>(
                Routes.treasuryAccount(account.id),
              );

              if (change != null) await cubit.applyAccountChange(change);
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
                (investor.name, addDecimals(investor.capital, investor.profit)),
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
