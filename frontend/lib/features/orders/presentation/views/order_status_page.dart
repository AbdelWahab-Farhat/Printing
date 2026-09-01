import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/order_status_cubit.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_status_bar.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_status_chip.dart';
import 'package:dayaa/features/orders/presentation/widgets/transition_field_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// Moving one order: where it goes, and what that path asks for on the way.
///
/// **A screen, not a sheet.** «قيد التصميم» wants artwork — a file picker, an upload with a bar
/// on it, a library to choose from — and a sheet that grows to hold all that is a sheet that
/// fights the keyboard. It also means the move has a place of its own to grow into: a path that
/// starts asking for three things gets room without anything being redesigned.
///
/// **The screen holds no state machine and no form.** The destinations are the order's own
/// `available_transitions`, already narrowed to what the signed-in user may do, and the fields
/// under each are that transition's `fields`, written by the server for *this* order. Add a
/// field to a path on the backend and it appears here — see [TransitionFieldInput].
///
/// Pops with the updated [Order] when the move succeeded, so the screen behind replaces what it
/// is showing instead of fetching it again.
class OrderStatusPage extends StatelessWidget {
  const OrderStatusPage({required this.orderId, super.key});

  final int orderId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrderStatusCubit>(
      create: (_) => sl<OrderStatusCubit>(param1: orderId)..load(),
      child: const _OrderStatusView(),
    );
  }
}

class _OrderStatusView extends StatelessWidget {
  const _OrderStatusView();

  Future<void> _submit(BuildContext context) async {
    final cubit = context.read<OrderStatusCubit>();

    final updated = await cubit.submit();
    if (updated == null || !context.mounted) return;

    context.showSuccess('تم نقل الطلبية إلى «${updated.statusLabel}»');
    context.pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OrderStatusCubit>();

    return Scaffold(
      appBar: AppBar(title: const Text('تغيير الحالة')),
      body: BlocConsumer<OrderStatusCubit, OrderStatusState>(
        listener: (context, state) {
          // Only when there is a form underneath to keep. With nothing on screen the body
          // already shows the failure, and a snackbar over it would say it twice.
          if (state case OrderStatusFailure(:final failure)) {
            if (state.order != null) context.showFailure(failure);
          }
        },
        builder: (context, state) => switch (state) {
          OrderStatusLoading() => const Center(child: CircularProgressIndicator()),
          OrderStatusFailure(:final failure) when state.order == null => _FailureView(
            message: failure.message,
            onRetry: cubit.load,
          ),
          _ => _Body(
            order: state.order!,
            selected: state.selected,
            values: state.values,
            isSubmitting: state.isSubmitting,
            canSubmit: state.canSubmit,
            onSelect: cubit.select,
            onValueChanged: cubit.setValue,
            onSubmit: () => _submit(context),
          ),
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.order,
    required this.selected,
    required this.values,
    required this.isSubmitting,
    required this.canSubmit,
    required this.onSelect,
    required this.onValueChanged,
    required this.onSubmit,
  });

  final Order order;
  final OrderTransition? selected;
  final Map<String, Object?> values;
  final bool isSubmitting;
  final bool canSubmit;
  final ValueChanged<OrderTransition> onSelect;
  final void Function(String key, Object? value) onValueChanged;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    final transition = selected;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
            children: [
              OrderStatusBar(status: order.status, label: order.statusLabel),
              SizedBox(height: 20.h),
              Text(
                'انقل الطلبية إلى',
                style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 10.h),
              for (final option in order.availableTransitions)
                Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: _Destination(
                    transition: option,
                    isSelected: option.status == transition?.status,
                    onTap: () => onSelect(option),
                  ),
                ),

              // The fields of the chosen path, and only of it. Rebuilt from scratch on every
              // change of destination — keyed by the status, so a controller from one path is
              // never handed the answer typed for another.
              if (transition != null && transition.fields.isNotEmpty) ...[
                SizedBox(height: 12.h),
                for (final field in transition.fields)
                  Padding(
                    key: ValueKey('${transition.status.wire}:${field.key}'),
                    padding: EdgeInsets.only(bottom: 16.h),
                    child: TransitionFieldInput(
                      field: field,
                      value: values[field.key],
                      customerId: order.customerId,
                      onChanged: (value) => onValueChanged(field.key, value),
                    ),
                  ),
              ],
            ],
          ),
        ),

        // Pinned rather than at the end of the list: on «قيد التصميم» the artwork field can be
        // taller than the screen, and a confirm button somebody has to scroll to find is a
        // button they think is missing.
        SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
            child: AppButton(
              label: transition == null
                  ? 'اختر الحالة'
                  : 'نقل إلى «${transition.label}»',
              icon: AppIcons.statusChange,
              isLoading: isSubmitting,
              // Null, not merely dimmed: there is genuinely nothing to send until a destination
              // is picked and whatever it asks for is filled in.
              onPressed: canSubmit ? onSubmit : null,
            ),
          ),
        ),
      ],
    );
  }
}

/// One destination, with what it will ask for said on it.
class _Destination extends StatelessWidget {
  const _Destination({
    required this.transition,
    required this.isSelected,
    required this.onTap,
  });

  final OrderTransition transition;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final (background, foreground) =
        OrderStatusChip.toneColour(scheme, transition.status.tone);
    final radius = BorderRadius.circular(16.r);

    // **كل وجهة بلون حالتها، لا الرمادي.** الموظف يعرف «نواقص» بالأحمر و«جاهزة» بالأخضر من
    // البطاقة ومن الشريط أعلى الطلبية، وكان هذا هو المكان الوحيد الذي يسقط فيه اللون — وهو
    // المكان الذي يُتَّخذ فيه القرار. غير المختارة تلبس غَسلاً من نغمتها، والمختارة تلبسها
    // كاملة بحافة أعرض، فيبقى الفرق بينهما مقروءاً بلا رماد.
    return Material(
      color: isSelected
          ? background
          : OrderStatusChip.tintFor(scheme, transition.status.tone),
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: foreground.withValues(alpha: isSelected ? 0.5 : 0.2),
              width: isSelected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                OrderStatusChip.iconFor(transition.status),
                size: 22.sp,
                color: foreground,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  transition.label,
                  style: context.textTheme.bodyLarge?.copyWith(
                    // The chosen row is the one being sent, so it says its own name loudest.
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                    color: foreground,
                  ),
                ),
              ),
              // Said before it is chosen, so somebody with nothing to attach knows which of the
              // two paths they can actually finish right now.
              if (transition.fields.any((field) => field.isRequired))
                Text(
                  'يتطلب بيانات',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: foreground.withValues(alpha: 0.75),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FailureView extends StatelessWidget {
  const _FailureView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.error, size: 48.sp, color: scheme.error),
            SizedBox(height: 16.h),
            Text(
              // The server's own Arabic: it usually says what to do about it.
              message,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
            ),
            SizedBox(height: 20.h),
            AppButton.tonal(label: 'إعادة المحاولة', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
