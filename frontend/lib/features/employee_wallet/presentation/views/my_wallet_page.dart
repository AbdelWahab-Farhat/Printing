import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/router/pop_result.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/features/employee_wallet/models/employee_wallet_models.dart';
import 'package:dayaa/features/employee_wallet/presentation/viewmodel/employee_wallet_entries_cubit.dart';
import 'package:dayaa/features/employee_wallet/presentation/viewmodel/my_wallet_cubit.dart';
import 'package:dayaa/features/employee_wallet/presentation/widgets/employee_wallet_history.dart';
import 'package:dayaa/features/investors/presentation/widgets/investor_money_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// «محفظتي» — الموظف يقرأ محفظته هو، بلا صلاحية. EMPLOYEE-WALLET-DESIGN §١٠.
///
/// **قراءةٌ فقط**: لا أزرار ولا إلغاء، ولا اسم حساب ولا اسم من سجّلها، فالخادم لا يرسلهما أصلاً.
///
/// **تسلّم الرصيد لمن فتحها**، فيبقى السطر على الرئيسية وفوق الطابور مطابقاً لما قُرئ هنا.
class MyWalletPage extends StatelessWidget {
  const MyWalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<MyWalletCubit>()..load()),
        BlocProvider(
          create: (_) =>
              sl<EmployeeWalletEntriesCubit>(param1: const EmployeeWalletLedger.mine())..load(),
        ),
      ],
      child: const _MyWalletView(),
    );
  }
}

class _MyWalletView extends StatelessWidget {
  const _MyWalletView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MyWalletCubit, MyWalletState>(
      listener: (context, state) {
        if (state case MyWalletLoaded(:final balance, :final refreshFailure)) {
          context.handBack(balance);

          if (refreshFailure != null) context.showFailure(refreshFailure);
        }
      },
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          title: const Text('محفظتي'),
          actions: const [EmployeeWalletRangeButton()],
        ),
        body: switch (state) {
          MyWalletLoading() => const Center(child: CircularProgressIndicator()),
          MyWalletFailed(:final failure) => EmployeeWalletFailedView(
            failure: failure,
            onRetry: context.read<MyWalletCubit>().load,
          ),
          MyWalletLoaded(:final balance) => Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 4.h),
                child: InvestorMoneyTile.hero(
                  label: 'رصيد المحفظة',
                  amount: balance,
                  artwork: 'assets/images/wallet.png',
                ),
              ),
              const EmployeeWalletFilters(),
              Expanded(
                child: EmployeeWalletEntryList(
                  emptyMessage: 'لم تتحرّك محفظتك بعد',
                  onRefresh: () async {
                    await Future.wait([
                      context.read<EmployeeWalletEntriesCubit>().refresh(),
                      context.read<MyWalletCubit>().load(),
                    ]);
                  },
                ),
              ),
            ],
          ),
        },
      ),
    );
  }
}
