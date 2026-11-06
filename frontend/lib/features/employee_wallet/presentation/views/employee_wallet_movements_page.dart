import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/router/pop_result.dart';
import 'package:dayaa/core/widgets/search_field.dart';
import 'package:dayaa/features/employee_wallet/models/employee_wallet_models.dart';
import 'package:dayaa/features/employee_wallet/presentation/viewmodel/employee_wallet_entries_cubit.dart';
import 'package:dayaa/features/employee_wallet/presentation/widgets/employee_wallet_history.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// «حركات محافظ الموظفين» — كل المحافظ في صفحة، الأحدث أولاً، يُبحث فيها باسم الموظف أو هاتفه أو
/// رمزه، وتُقصر على نوع. نظير «المعاملات المالية» للعملاء.
///
/// **للقراءة**: اللمسةُ تفتح محفظة الموظف، وهناك يُسحب ويُعدَّل ويُلغى — في سياق رصيده.
class EmployeeWalletMovementsPage extends StatelessWidget {
  const EmployeeWalletMovementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<EmployeeWalletEntriesCubit>(param1: const EmployeeWalletLedger.all())..load(),
      child: const _MovementsView(),
    );
  }
}

class _MovementsView extends StatelessWidget {
  const _MovementsView();

  /// محفظة الموظف — وحين يتحرّك فيها مال يُعاد هذا السجل، فالسطر الجديد مكانه أعلاه.
  Future<void> _openWallet(BuildContext context, EmployeeWalletEntry entry) async {
    final userId = entry.userId;

    if (userId == null) return;

    final cubit = context.read<EmployeeWalletEntriesCubit>();
    final balance = await context.pushForResult<String>(
      Routes.employeeWallet(userId),
      extra: entry.employeeName,
    );

    if (balance != null) await cubit.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EmployeeWalletEntriesCubit>();

    return Scaffold(
      appBar: AppBar(title: const Text('حركات محافظ الموظفين')),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
            child: SearchField(hint: 'ابحث باسم الموظف أو هاتفه أو رمزه', onChanged: cubit.search),
          ),
          const EmployeeWalletFilters(),
          Expanded(
            child: EmployeeWalletEntryList(
              emptyMessage: 'لا حركات',
              showEmployee: true,
              onRefresh: cubit.refresh,
              onOpen: _openWallet,
            ),
          ),
        ],
      ),
    );
  }
}
