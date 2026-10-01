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
import 'package:dayaa/core/widgets/app_tab_bar.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/presentation/viewmodel/account_change.dart';
import 'package:dayaa/features/treasury/presentation/viewmodel/treasury_cubit.dart';
import 'package:dayaa/features/treasury/presentation/widgets/treasury_account_sheet.dart';
import 'package:dayaa/features/treasury/presentation/widgets/treasury_operation_sheet.dart';
import 'package:dayaa/features/treasury/presentation/widgets/treasury_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// الحسابات والكاش — every account and what it holds, whose the money is, and what the
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
            title: const Text('الحسابات والكاش'),
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
          body: switch (state) {
            TreasuryLoading() => const Center(child: CircularProgressIndicator()),
            TreasuryFailed(:final failure) => _Failed(failure: failure, onRetry: cubit.load),
            TreasuryLoaded() => _Loaded(state: state),
          },
        );
      },
    );
  }
}

/// المجموع وتحته زرّا ما لا يقدّمه أي حساب، ثم الإجابات الثلاث في تبويبات: الحسابات، ولمن
/// المال، والمخزون — واحدة على الشاشة في كل مرة بدل ثلاث بطاقات تحت بعضها.
///
/// من لا يرى إلا حساباته لا يصله إلا تبويب واحد، فتُرسم القائمة وحدها بلا شريط تبويبات.
class _Loaded extends StatelessWidget {
  const _Loaded({required this.state});

  final TreasuryLoaded state;

  @override
  Widget build(BuildContext context) {
    final accounts = state.accounts;
    final cubit = context.read<TreasuryCubit>();

    // صفحة الحساب تعيد ما تغيّر: تعديلٌ يُرقَّع صفُّه، ومالٌ تحرّك يُقرأ له المجموع.
    Future<void> open(TreasuryAccount account) async {
      final change = await context.pushForResult<AccountChange>(
        Routes.treasuryAccount(account.id),
      );

      if (change != null) await cubit.applyAccountChange(change);
    }

    final money = [for (final a in accounts.accounts) if (!a.isPayable) a];
    final payables = [for (final a in accounts.accounts) if (a.isPayable) a];

    final tabs = <(String, Widget)>[
      (
        'الحسابات',
        _Tab(
          onRefresh: cubit.load,
          children: [
            if (accounts.accounts.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 32.h),
                child: Text(
                  'لا يوجد حساب باسمك',
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodyLarge,
                ),
              ),
            for (final account in money)
              TreasuryAccountTile(
                key: ValueKey(account.id),
                account: account,
                onTap: () => open(account),
              ),
            if (payables.isNotEmpty)
              _Payables(payables: payables, total: accounts.payablesTotal, onOpen: open),
          ],
        ),
      ),
      if (state.ownership case final ownership?)
        (
          'لمن المال',
          _Tab(
            onRefresh: cubit.load,
            children: [
              TreasuryFigures(
                lines: [
                  ('كل ما في الحسابات', ownership.totalHeld),
                  for (final investor in ownership.investors)
                    (investor.name, addDecimals(investor.capital, investor.profit)),
                  ('نقد الصندوق الاستثماري', ownership.fundCash),
                  // يُطرح من مال الشركة نفسها — فيُرسم بالإشارة التي يُطرح بها.
                  if (ownership.payablesTotal != '0.00')
                    ('علينا', negateAmount(ownership.payablesTotal)),
                ],
                emphasis: ('مال الشركة نفسها', ownership.companyOwn),
              ),
            ],
          ),
        ),
      if (state.inventory case final inventory?)
        (
          'المخزون',
          _Tab(
            onRefresh: cubit.load,
            children: [
              TreasuryFigures(
                lines: [
                  ('بضاعة الشركة', inventory.company),
                  ('بضاعة الصندوق', inventory.fund),
                  for (final warehouse in inventory.byWarehouse)
                    ('في ${warehouse.name}', warehouse.value),
                ],
                emphasis: ('الإجمالي', inventory.total),
              ),
            ],
          ),
        ),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
            child: Column(
              children: [
                TreasuryTotalCard(
                  label: accounts.canViewAll ? 'كل ما في الحسابات' : 'ما في حساباتك',
                  amount: accounts.total,
                  inline: true,
                ),
                if (accounts.canViewAll) _Actions(accounts: accounts.accounts),
              ],
            ),
          ),
          if (tabs.length > 1) AppTabBar(labels: [for (final (label, _) in tabs) label]),
          Expanded(
            child: tabs.length > 1
                ? TabBarView(children: [for (final (_, body) in tabs) body])
                : tabs.single.$2,
          ),
        ],
      ),
    );
  }
}

/// «علينا» — ما على الشركة. TREASURY-DESIGN §٢٠.
///
/// ما فُتح باليد — قرضٌ أو إيجار — قليلٌ ومسمّى، فلكلٍّ صفّ. أما الموردون فلكلٍّ منهم حساب وقد
/// يكونون عشرات، فيُطوَون في «ذمم الموردين» بمجموعهم وتُفتح على من له شيءٌ منهم؛ ومن سُدّد له
/// كلُّه لا يُذكر.
class _Payables extends StatelessWidget {
  const _Payables({required this.payables, required this.total, required this.onOpen});

  final List<TreasuryAccount> payables;
  final String total;
  final void Function(TreasuryAccount account) onOpen;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final own = [for (final a in payables) if (!a.isVendorPayable) a];
    final vendors = [
      for (final a in payables)
        if (a.isVendorPayable && a.owed != '0.00') a,
    ];

    return Column(
      key: const ValueKey('payables'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 16.h),
        Row(
          children: [
            Icon(AppIcons.payable, size: 20.sp, color: scheme.error),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                'علينا',
                style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            Text(
              owedLabel(total),
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: total.startsWith('-') ? null : scheme.error,
              ),
            ),
          ],
        ),
        for (final account in own)
          TreasuryAccountTile(
            key: ValueKey(account.id),
            account: account,
            onTap: () => onOpen(account),
          ),
        if (vendors.isNotEmpty)
          ExpansionTile(
            key: const ValueKey('vendor-payables'),
            tilePadding: EdgeInsets.symmetric(horizontal: 4.w),
            childrenPadding: EdgeInsetsDirectional.only(start: 12.w),
            leading: Icon(AppIcons.vendors),
            title: Text(
              'ذمم الموردين',
              style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            subtitle: Text('${vendors.length} مورد'),
            trailing: Text(
              owedLabel(_owedBy(vendors)),
              style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            children: [
              for (final account in vendors)
                TreasuryAccountTile(
                  key: ValueKey(account.id),
                  account: account,
                  onTap: () => onOpen(account),
                ),
            ],
          ),
      ],
    );
  }

  /// ما للموردين المعروضين معاً — بأعدادٍ صحيحة، لا بكسورٍ عائمة.
  static String _owedBy(List<TreasuryAccount> accounts) {
    var total = 0;

    for (final account in accounts) {
      final owed = account.owed;
      final negative = owed.startsWith('-');
      final parts = (negative ? owed.substring(1) : owed).split('.');
      final whole = int.tryParse(parts.first) ?? 0;
      final fraction =
          int.tryParse((parts.length > 1 ? parts[1] : '0').padRight(2, '0').substring(0, 2)) ?? 0;
      final value = whole * 100 + fraction;

      total += negative ? -value : value;
    }

    final sign = total < 0 ? '-' : '';
    final absolute = total.abs();

    return '$sign${absolute ~/ 100}.${(absolute % 100).toString().padLeft(2, '0')}';
  }
}

/// ما لا يجده القارئ داخل أي حساب: فتح حساب جديد، والمصروف الذي يُسجَّل من هنا دون البحث
/// أولاً عن الحساب الذي خرج منه. الإيداع والسحب والتحويل والجرد في صفحة الحساب نفسه.
///
/// كل زر يظهر لمن يملك صلاحيته فقط، والزر الباقي وحده يأخذ العرض كله.
class _Actions extends StatelessWidget {
  const _Actions({required this.accounts});

  final List<TreasuryAccount> accounts;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TreasuryCubit>();
    final session = sl<Session>();

    final buttons = [
      if (session.can(AppPermission.manageTreasury))
        AppButton.tonal(
          label: 'حساب جديد',
          icon: AppIcons.add,
          onPressed: () => unawaited(
            showTreasuryAccountSheet(
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
        ),
      if (session.can(AppPermission.recordTreasuryOperations))
        AppButton.tonal(
          label: 'مصروف جديد',
          icon: AppIcons.expense,
          onPressed: () => unawaited(
            showTreasuryOperationSheet(
              context: context,
              kind: OperationKind.expense,
              accounts: accounts,
              onSubmit: cubit.record,
            ),
          ),
        ),
    ];

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: 12.h),
      child: Row(
        children: [
          for (final (index, button) in buttons.indexed) ...[
            if (index > 0) SizedBox(width: 12.w),
            Expanded(child: button),
          ],
        ],
      ),
    );
  }
}

/// تبويب واحد: قائمة تُسحب للتحديث، حتى حين تكون أقصر من الشاشة.
class _Tab extends StatelessWidget {
  const _Tab({required this.onRefresh, required this.children});

  final Future<void> Function() onRefresh;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
        children: children,
      ),
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
