import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/features/online_payments/models/online_payment_models.dart';
import 'package:dayaa/features/online_payments/presentation/viewmodel/online_payment_methods_cubit.dart';
import 'package:dayaa/features/online_payments/presentation/widgets/method_limits_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// «طرق الدفع الإلكتروني» — طرق EzonePay التي يراها الزبون حين يشحن محفظته، وحدودُ كل طريقةٍ لكل
/// زبون (يومي · شهري · سنوي، بما يصل المحفظة). CUSTOMER-WALLET §٥.
///
/// **يُحفظ كل تغييرٍ ساعةَ يحدث**. التعديلُ لمن يملك `payments.online.manage`؛ غيرُه يقرأ.
class OnlinePaymentMethodsPage extends StatelessWidget {
  const OnlinePaymentMethodsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OnlinePaymentMethodsCubit>()..load(),
      child: Scaffold(
        appBar: AppBar(title: const Text('طرق الدفع الإلكتروني')),
        body: BlocBuilder<OnlinePaymentMethodsCubit, OnlinePaymentMethodsState>(
          builder: (context, state) => switch (state) {
            OnlinePaymentMethodsLoading() => const Center(child: CircularProgressIndicator()),
            OnlinePaymentMethodsFailed(:final failure) => Center(
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(failure.message, textAlign: TextAlign.center),
                    SizedBox(height: 16.h),
                    AppButton.tonal(
                      label: 'إعادة المحاولة',
                      onPressed: context.read<OnlinePaymentMethodsCubit>().load,
                    ),
                  ],
                ),
              ),
            ),
            OnlinePaymentMethodsLoaded(:final methods) => _Loaded(methods: methods),
          },
        ),
      ),
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({required this.methods});

  final OnlinePaymentMethods methods;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnlinePaymentMethodsCubit>();
    final mayManage = sl<Session>().can(AppPermission.manageOnlinePaymentMethods);
    final scheme = context.colorScheme;

    return RefreshIndicator(
      onRefresh: cubit.load,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 48.h),
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: methods.enabled ? scheme.surfaceContainerHighest : scheme.errorContainer,
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Text(
              [
                if (methods.enabled)
                  'الدفع الإلكتروني مفعّل'
                else
                  'الدفع الإلكتروني مطفأ على الخادم — لا يرى الزبائن زرّ الشحن مهما فُعّلت الطرق',
                methods.feePayer == 'shop'
                    ? 'العمولة على المحلّ'
                    : 'العمولة على الزبون — تُغيَّر من «إعدادات المالية»',
              ].join('\n'),
              style: context.textTheme.bodyMedium?.copyWith(
                color: methods.enabled ? scheme.onSurfaceVariant : scheme.onErrorContainer,
              ),
            ),
          ),
          SizedBox(height: 8.h),
          for (final method in methods.methods)
            _MethodTile(
              key: ValueKey(method.id),
              method: method,
              onToggle: mayManage ? (on) => _run(context, () => cubit.setActive(method, on)) : null,
              onEditLimits: mayManage ? () => _editLimits(context, method) : null,
            ),
        ],
      ),
    );
  }

  Future<void> _editLimits(BuildContext context, OnlinePaymentMethodSetting method) async {
    final cubit = context.read<OnlinePaymentMethodsCubit>();

    await showMethodLimitsDialog(
      context: context,
      method: method,
      onSave: ({required daily, required monthly, required yearly}) =>
          cubit.setLimits(method, daily: daily, monthly: monthly, yearly: yearly),
    );
  }
}

/// Shows what a write came back with — a toast on failure, nothing on success (the row redraws).
Future<void> _run(BuildContext context, Future<Failure?> Function() write) async {
  final failure = await write();

  if (failure != null && context.mounted) context.showFailure(failure);
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({required this.method, this.onToggle, this.onEditLimits, super.key});

  final OnlinePaymentMethodSetting method;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onEditLimits;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: method.isActive,
      onChanged: onToggle,
      title: Text(method.label, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: InkWell(
        onTap: onEditLimits,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 4.h),
          child: Text(
            [
              'يومي ${_limit(method.dailyLimit)}',
              'شهري ${_limit(method.monthlyLimit)}',
              'سنوي ${_limit(method.yearlyLimit)}',
            ].join(' · '),
            style: TextStyle(
              color: onEditLimits == null ? null : context.colorScheme.primary,
              decoration: onEditLimits == null ? null : TextDecoration.underline,
            ),
          ),
        ),
      ),
    );
  }

  static String _limit(String? value) => value == null ? 'بلا حد' : value.grouped;
}
