import 'dart:async';

import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/router/pop_result.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/employee_wallet/presentation/viewmodel/employee_wallet_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// صفُّ المحفظة في صفحة الموظف، تحت الراتب — رصيدها، ويفتحها.
///
/// **يقرأ [EmployeeWalletCubit] من فوقه**: تملكه الصفحة، فسحبُ التحديث يعيده معها. وفشلُ قراءة الرصيد
/// لا يُسقط الصفحة: يبقى الصفّ بلا رقم، وشاشةُ المحفظة تقول السبب. وإيقافُ الموظف لا يمسّه، فمالُه
/// باقٍ ويمكن صرفه.
class EmployeeWalletTile extends StatelessWidget {
  const EmployeeWalletTile({required this.userId, required this.employeeName, super.key});

  final int userId;
  final String employeeName;

  /// **يرقّع ولا يعيد**: ما تسلّمه شاشة المحفظة هو رصيد الخادم بعد آخر كتابة.
  Future<void> _open(BuildContext context) async {
    final cubit = context.read<EmployeeWalletCubit>();
    final balance = await context.pushForResult<String>(
      Routes.employeeWallet(userId),
      extra: employeeName,
    );

    if (balance != null) cubit.applyBalance(balance);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final corner = BorderRadius.circular(20.r);

    return Material(
      color: scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: corner,
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: InkWell(
        borderRadius: corner,
        onTap: () => unawaited(_open(context)),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          child: Row(
            children: [
              Container(
                height: 44.w,
                width: 44.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.secondaryContainer,
                ),
                child: Icon(AppIcons.wallet, size: 20.sp, color: scheme.onSecondaryContainer),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'رصيد المحفظة',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    BlocBuilder<EmployeeWalletCubit, EmployeeWalletState>(
                      builder: (context, state) => switch (state) {
                        EmployeeWalletLoaded(:final wallet) => Padding(
                          padding: EdgeInsets.only(top: 2.h),
                          child: Text(
                            '${wallet.balance.grouped} د.ل',
                            textDirection: TextDirection.ltr,
                            style: context.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        _ => const SizedBox.shrink(),
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              Icon(AppIcons.forward, size: 20.sp, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
