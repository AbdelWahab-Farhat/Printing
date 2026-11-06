import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/pop_result.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/uuid.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/features/employee_wallet/models/employee_wallet_models.dart';
import 'package:dayaa/features/employee_wallet/presentation/viewmodel/employee_wallet_cubit.dart';
import 'package:dayaa/features/employee_wallet/presentation/viewmodel/employee_wallet_entries_cubit.dart';
import 'package:dayaa/features/employee_wallet/presentation/widgets/employee_deposit_sheet.dart';
import 'package:dayaa/features/employee_wallet/presentation/widgets/employee_wallet_history.dart';
import 'package:dayaa/features/employee_wallet/presentation/widgets/employee_withdraw_sheet.dart';
import 'package:dayaa/features/employee_wallet/presentation/widgets/reverse_entry_sheet.dart';
import 'package:dayaa/features/investors/presentation/widgets/investor_money_tile.dart';
import 'package:dayaa/features/wallet/presentation/widgets/adjust_wallet_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// محفظة موظفٍ واحد لمن يديرها: رصيدها، وكل حركة. Docs/employees/EMPLOYEE-WALLET-DESIGN.md §٥.
///
/// **على شكل محفظة العميل وبمكوّناتها**: الرصيدُ في البطاقة الكبيرة والأزرار داخلها، والسجلُّ بأيامه،
/// ورقائقُ الأنواع تلتفّ. ثلاثة أزرار في صفٍّ واحد، فصار «تعديل الرصيد» كلمة «تعديل» ليتّسع.
///
/// **تسلّم الرصيد لمن فتحها حين يتحرّك مال**، فيرقّع صفّ الموظف بلا طلب.
class EmployeeWalletPage extends StatelessWidget {
  const EmployeeWalletPage({required this.userId, this.employeeName, super.key});

  final int userId;

  /// تحت العنوان — يُمرَّر ولا يُطلب، كما تفعل محفظة العميل.
  final String? employeeName;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<EmployeeWalletCubit>(param1: userId)..load()),
        BlocProvider(
          create: (_) =>
              sl<EmployeeWalletEntriesCubit>(param1: EmployeeWalletLedger.of(userId))..load(),
        ),
      ],
      child: _WalletView(employeeName: employeeName ?? 'الموظف'),
    );
  }
}

class _WalletView extends StatelessWidget {
  const _WalletView({required this.employeeName});

  final String employeeName;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EmployeeWalletCubit, EmployeeWalletState>(
      listener: (context, state) {
        if (state case EmployeeWalletLoaded(:final wallet, :final refreshFailure)) {
          // ما تغيّر يُسلَّم لمن فتح الصفحة، كيفما أُغلقت.
          if (context.read<EmployeeWalletCubit>().moneyMoved) context.handBack(wallet.balance);

          if (refreshFailure != null) context.showFailure(refreshFailure);
        }
      },
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('المحفظة'),
              Text(
                employeeName,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          actions: const [EmployeeWalletRangeButton()],
        ),
        body: switch (state) {
          EmployeeWalletLoading() => const Center(child: CircularProgressIndicator()),
          EmployeeWalletFailed(:final failure) => EmployeeWalletFailedView(
            failure: failure,
            onRetry: context.read<EmployeeWalletCubit>().load,
          ),
          EmployeeWalletLoaded(:final wallet) => Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 4.h),
                child: InvestorMoneyTile.hero(
                  label: 'رصيد المحفظة',
                  amount: wallet.balance,
                  artwork: 'assets/images/wallet.png',
                  footer: _Actions.showFor(wallet) ? _Actions(wallet: wallet) : null,
                ),
              ),
              const EmployeeWalletFilters(),
              Expanded(
                child: EmployeeWalletEntryList(
                  emptyMessage: 'لم تتحرّك هذه المحفظة بعد',
                  onRefresh: () async {
                    await Future.wait([
                      context.read<EmployeeWalletEntriesCubit>().refresh(),
                      context.read<EmployeeWalletCubit>().load(),
                    ]);
                  },
                  onReverse: (context, entry) => unawaited(_reverse(context, entry)),
                ),
              ),
            ],
          ),
        },
      ),
    );
  }

  /// يُلغي الحركة بسببٍ إجباري — يرفضه الخادم إن كان المال قد سُحب، فيُعكس السحب أولاً.
  Future<void> _reverse(BuildContext context, EmployeeWalletEntry entry) async {
    final header = context.read<EmployeeWalletCubit>();
    final entries = context.read<EmployeeWalletEntriesCubit>();

    final reason = await askForReversalReason(context, title: 'إلغاء «${entry.typeLabel}»');

    if (reason == null || !context.mounted) return;

    final result = await entries.reverse(entry, reason: reason);

    if (!context.mounted) return;

    result.fold(context.showFailure, (write) {
      header.applyBalance(write.balance);
      context.showSuccess('أُلغيت الحركة');
    });
  }
}

/// «إيداع» و«سحب» و«تعديل» داخل بطاقة الرصيد — كلٌّ بصلاحيته، **وغائبٌ لا معطّل**: من يقرأ المحفظة
/// ولا يحرّكها يرى البطاقة رقماً وحده.
///
/// **ولا يحرّك أحدٌ محفظته بنفسه ولو ملك الصلاحية** (س٥): الخادم يقولها في `can_move`.
///
/// `tonal` لا `primary`: الملءُ الأساسي هو لونُ البطاقة نفسها، فزرٌّ به يذوب فيها.
class _Actions extends StatelessWidget {
  const _Actions({required this.wallet});

  final EmployeeWallet wallet;

  static bool _can(AppPermission permission) => sl<Session>().can(permission);

  static bool get _mayReceiveMoney => _can(AppPermission.depositToEmployeeWallets);

  static bool get _mayCredit => _can(AppPermission.creditEmployeeWallets);

  static bool get _mayWithdraw => _can(AppPermission.withdrawFromEmployeeWallets);

  static bool get _mayAdjust => _can(AppPermission.adjustEmployeeWallets);

  /// هل في البطاقة زرٌّ أصلاً — فلا تُترك فيها فسحةٌ لصفٍّ فارغ.
  static bool showFor(EmployeeWallet wallet) =>
      wallet.canMove && (_mayReceiveMoney || _mayCredit || _mayWithdraw || _mayAdjust);

  /// السطرُ الذي كتبه الخادم أعلى السجل. يعود بالفشل لتبقى الورقة مفتوحة، أو بـnull لتُغلق.
  static Future<Failure?> _written(
    EmployeeWalletEntriesCubit entries,
    Future<Either<Failure, EmployeeWalletWrite>> write,
  ) async {
    final result = await write;

    return result.fold((failure) => failure, (written) {
      entries.addWritten(written.entry);

      return null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final buttons = [
      if (_mayReceiveMoney || _mayCredit) ('إيداع', _deposit),
      if (_mayWithdraw) ('سحب', _withdraw),
      if (_mayAdjust) ('تعديل', _adjust),
    ];

    return Row(
      children: [
        for (final (index, (label, onTap)) in buttons.indexed) ...[
          if (index > 0) SizedBox(width: 10.w),
          Expanded(
            child: AppButton.tonal(
              label: label,
              height: 48.h,
              onPressed: () => onTap(context),
            ),
          ),
        ],
      ],
    );
  }

  /// رمزٌ لكل نوع: إعادةُ «مال» بعد انقطاعٍ لا يجوز أن تُقرأ إعادةً لـ«مستحق».
  Future<void> _deposit(BuildContext context) async {
    final header = context.read<EmployeeWalletCubit>();
    final entries = context.read<EmployeeWalletEntriesCubit>();
    final moneyToken = uuidV4();
    final creditToken = uuidV4();

    final saved = await showEmployeeDepositSheet(
      context: context,
      mayReceiveMoney: _mayReceiveMoney,
      mayCredit: _mayCredit,
      salary: wallet.salary,
      onMoney: (draft) => _written(entries, header.deposit(draft, clientToken: moneyToken)),
      onCredit: (draft) => _written(entries, header.credit(draft, clientToken: creditToken)),
    );

    if (saved == null || !context.mounted) return;

    context.showSuccess(saved == EmployeeDepositKind.money ? 'تم الإيداع' : 'تم تسجيل المستحق');
  }

  Future<void> _withdraw(BuildContext context) async {
    final header = context.read<EmployeeWalletCubit>();
    final entries = context.read<EmployeeWalletEntriesCubit>();
    final token = uuidV4();

    final saved = await showEmployeeWithdrawSheet(
      context: context,
      balance: wallet.balance,
      onSubmit: (draft) => _written(entries, header.withdraw(draft, clientToken: token)),
    );

    if (saved == true && context.mounted) context.showSuccess('تم السحب');
  }

  Future<void> _adjust(BuildContext context) async {
    final header = context.read<EmployeeWalletCubit>();
    final entries = context.read<EmployeeWalletEntriesCubit>();
    final token = uuidV4();

    final saved = await showAdjustWalletSheet(
      context: context,
      balance: wallet.balance,
      onSubmit: ({required amount, required credit, required reason}) => _written(
        entries,
        header.adjust(amount: amount, credit: credit, reason: reason, clientToken: token),
      ),
    );

    if (saved == true && context.mounted) context.showSuccess('تم تعديل الرصيد');
  }
}
