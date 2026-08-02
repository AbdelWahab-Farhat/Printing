import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/core/di/injector.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/core/widgets/app_button.dart';
import 'package:printing/features/orders/models/order.dart';
import 'package:printing/features/orders/presentation/viewmodel/order_detail_cubit.dart';
import 'package:printing/features/orders/presentation/widgets/order_designs_section.dart';
import 'package:printing/features/orders/presentation/widgets/order_move_sheet.dart';
import 'package:printing/features/orders/presentation/widgets/order_status_chip.dart';
import 'package:printing/features/orders/presentation/widgets/order_timeline.dart';
import 'package:printing/features/orders/presentation/widgets/order_totals.dart';

/// One order, everything about it, and the moves staff make on it.
///
/// **The action buttons are drawn from `available_transitions` and from nothing else.** The
/// server sends that list already narrowed to what the signed-in user may do, so this screen
/// holds no copy of the state machine — no "if ready show dispatch", no permission checks of its
/// own. Add a status on the backend and the button appears here without an app release; take a
/// permission away and it disappears. A second copy of those rules in Dart is the one that
/// drifts, and it drifts on the side that guards the button.
///
/// Pops with the updated [Order] when a move succeeded, so the list behind replaces its row
/// instead of re-fetching a page.
class OrderDetailPage extends StatelessWidget {
  const OrderDetailPage({required this.orderId, super.key});

  final int orderId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrderDetailCubit>(
      create: (_) => sl<OrderDetailCubit>(param1: orderId)..load(),
      child: const _OrderDetailView(),
    );
  }
}

class _OrderDetailView extends StatefulWidget {
  const _OrderDetailView();

  @override
  State<_OrderDetailView> createState() => _OrderDetailViewState();
}

/// Stateful for one reason: it remembers whether anything was moved, so `pop` can hand the
/// result back. That is screen lifecycle, not business state — the Cubit owns the order itself.
class _OrderDetailViewState extends State<_OrderDetailView> {
  Order? _moved;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OrderDetailCubit>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // Always through here, so the back button and the app bar's arrow return the same thing.
        context.pop(_moved);
      },
      child: Scaffold(
        appBar: AppBar(
          title: BlocBuilder<OrderDetailCubit, OrderDetailState>(
            builder: (context, state) {
              final order = state.order;

              return Text(order == null ? 'تفاصيل الطلبية' : 'طلبية #${order.code}');
            },
          ),
        ),
        body: BlocConsumer<OrderDetailCubit, OrderDetailState>(
          listener: (context, state) {
            // Only when there is still a page underneath: with nothing to fall back to, the
            // body already shows the failure and a snackbar would say it twice.
            if (state case OrderDetailFailure(:final failure)) {
              if (state.order != null) context.showFailure(failure);
            }
          },
          builder: (context, state) => switch (state) {
            OrderDetailLoading() => const Center(child: CircularProgressIndicator()),
            OrderDetailFailure(:final failure) when state.order == null => _FailureView(
              message: failure.message,
              onRetry: cubit.load,
            ),
            _ => RefreshIndicator(
              onRefresh: cubit.load,
              child: _Body(
                order: state.order!,
                isMoving: state.isMoving,
                onMove: _move,
              ),
            ),
          },
        ),
      ),
    );
  }

  Future<void> _move(OrderTransition transition) async {
    final cubit = context.read<OrderDetailCubit>();

    // Asked for *before* sending, so the server's 422 for a missing reason is a case the user
    // never reaches. `requires_reason` comes from the server too, so a future status that starts
    // demanding one gets the field with no app change.
    final reason = await showOrderMoveSheet(context: context, transition: transition);
    if (reason == null) return;

    final updated = await cubit.move(transition.status, reason: reason.value);
    if (updated == null || !mounted) return;

    setState(() => _moved = updated);
    context.showSuccess('تم نقل الطلبية إلى «${updated.statusLabel}»');
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.order, required this.isMoving, required this.onMove});

  final Order order;
  final bool isMoving;
  final Future<void> Function(OrderTransition transition) onMove;

  @override
  Widget build(BuildContext context) {
    return ListView(
      // Scrollable even when short, so pull-to-refresh works on every state.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 32.h),
      children: [
        _Header(order: order),
        SizedBox(height: 16.h),
        _MoveActions(order: order, isMoving: isMoving, onMove: onMove),
        SizedBox(height: 16.h),
        _Destination(order: order),
        SizedBox(height: 16.h),
        if (order.items != null && order.items!.isNotEmpty) ...[
          _Section(title: 'البنود', child: _Items(items: order.items!)),
          SizedBox(height: 16.h),
        ],
        _Section(title: 'الحساب', child: OrderTotals(order: order)),
        if (order.designs != null && order.designs!.isNotEmpty) ...[
          SizedBox(height: 16.h),
          _Section(
            title: 'التصاميم',
            child: OrderDesignsSection(designs: order.designs!),
          ),
        ],
        if (order.transitions != null && order.transitions!.isNotEmpty) ...[
          SizedBox(height: 16.h),
          _Section(
            title: 'سجل الحالات',
            child: OrderTimeline(records: order.transitions!),
          ),
        ],
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              OrderStatusChip(status: order.status, label: order.statusLabel),
              const Spacer(),
              Text(
                order.grandTotal,
                style: context.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            order.customer?.name ?? 'عميل #${order.customerId}',
            style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (order.customer?.phone case final phone?) ...[
            SizedBox(height: 4.h),
            Text(
              phone,
              style: context.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          if (order.cancellationReason case final reason?) ...[
            SizedBox(height: 12.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                'سبب الإلغاء: $reason',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: scheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The buttons, and only the ones the server offered.
class _MoveActions extends StatelessWidget {
  const _MoveActions({required this.order, required this.isMoving, required this.onMove});

  final Order order;
  final bool isMoving;
  final Future<void> Function(OrderTransition transition) onMove;

  @override
  Widget build(BuildContext context) {
    if (!order.hasActions) {
      // Two different silences, said differently. A finished order has nothing left to do; an
      // open one with no buttons means this user holds none of its permissions, and "لا توجد
      // إجراءات" would read as a bug to them.
      return _Note(
        text: order.isFinal
            ? 'الطلبية ${order.statusLabel} — لا مزيد من الإجراءات'
            : 'لا تملك صلاحية تغيير حالة هذه الطلبية',
      );
    }

    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: [
        for (final transition in order.availableTransitions)
          AppButton.tonal(
            label: transition.label,
            // Busy, not unavailable: `onPressed: null` greys the button out, which reads as
            // "you may not" rather than "in progress". AppButton refuses the tap itself.
            isLoading: isMoving,
            onPressed: () => onMove(transition),
          ),
      ],
    );
  }
}

class _Destination extends StatelessWidget {
  const _Destination({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: order.isOfficePickup ? 'الاستلام' : 'التوصيل',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Row(
            icon: order.isOfficePickup ? AppIcons.warehouse : AppIcons.mapPin,
            label: order.fulfilmentTypeLabel,
            value: order.destination,
          ),
          if (order.customerShopName case final shop?)
            _Row(icon: AppIcons.warehouse, label: 'المحل', value: shop),
          if (order.addressDetails case final address?)
            _Row(icon: AppIcons.mapPin, label: 'العنوان', value: address),
          if (order.recipientName case final name?)
            _Row(icon: AppIcons.person, label: 'المستلم', value: name),
          if (order.recipientPhone case final phone?)
            _Row(icon: AppIcons.phone, label: 'هاتف المستلم', value: phone),
          if (order.trackingNumber case final tracking?)
            _Row(icon: AppIcons.tag, label: 'رقم التتبع', value: tracking),
          if (order.shippingCompany case final company?)
            _Row(icon: AppIcons.warehouse, label: 'شركة الشحن', value: company),
          if (order.notes case final notes?)
            _Row(icon: AppIcons.edit, label: 'ملاحظات', value: notes),
        ],
      ),
    );
  }
}

class _Items extends StatelessWidget {
  const _Items({required this.items});

  final List<OrderItem> items;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.productName} — ${item.variantLabel}',
                        style: context.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        // The quantity, its unit and the rate it was priced at — the three
                        // numbers somebody checking an invoice reads together.
                        '${item.quantity} ${item.pricingUnitLabel} × ${item.unitPrice}',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  item.lineTotal,
                  style: context.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 12.h),
          child,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17.sp, color: scheme.onSurfaceVariant),
          SizedBox(width: 10.w),
          Text(
            '$label: ',
            style: context.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: Text(value, style: context.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
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
              style: context.textTheme.bodyLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 20.h),
            AppButton.tonal(label: 'إعادة المحاولة', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
