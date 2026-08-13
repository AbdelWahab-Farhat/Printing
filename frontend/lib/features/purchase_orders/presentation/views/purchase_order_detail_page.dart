import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/core/di/injector.dart';
import 'package:printing/core/permissions/app_permission.dart';
import 'package:printing/core/router/app_router.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/core/utils/digits.dart';
import 'package:printing/core/widgets/app_dialog.dart';
import 'package:printing/core/widgets/app_speed_dial.dart';
import 'package:printing/features/audit/models/audit_subject.dart';
import 'package:printing/features/purchase_orders/models/purchase_order.dart';
import 'package:printing/features/purchase_orders/presentation/viewmodel/purchase_order_detail_cubit.dart';
import 'package:printing/features/purchase_orders/presentation/widgets/receive_arrival_sheet.dart';

/// One purchase order: what was asked for, what has turned up, and what is left.
///
/// Pops with `true` when anything was written, so the list behind re-reads.
class PurchaseOrderDetailPage extends StatelessWidget {
  const PurchaseOrderDetailPage({required this.purchaseOrderId, super.key});

  final int purchaseOrderId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PurchaseOrderDetailCubit>(
      create: (_) => sl<PurchaseOrderDetailCubit>(param1: purchaseOrderId)..load(),
      child: const _PurchaseOrderDetailView(),
    );
  }
}

class _PurchaseOrderDetailView extends StatefulWidget {
  const _PurchaseOrderDetailView();

  @override
  State<_PurchaseOrderDetailView> createState() => _PurchaseOrderDetailViewState();
}

class _PurchaseOrderDetailViewState extends State<_PurchaseOrderDetailView> {
  bool _changed = false;

  Future<void> _edit(BuildContext context) async {
    final cubit = context.read<PurchaseOrderDetailCubit>();
    final order = cubit.state.order;
    if (order == null) return;

    final saved = await context.push<bool>(Routes.purchaseOrderForm, extra: order);
    if (saved != true || !context.mounted) return;

    setState(() => _changed = true);
    await cubit.load();
  }

  /// The one status a person moves a purchase order to by hand. See `offeredNext`.
  Future<void> _cancel(BuildContext context) async {
    final cubit = context.read<PurchaseOrderDetailCubit>();

    final confirmed = await showCustomDialog(
      context: context,
      title: 'إلغاء أمر الشراء؟',
      description:
          'لن يمكن استلام شحنات عليه بعد الإلغاء، ولا التراجع عنه. '
          'ما وصل منه قبل الآن يبقى في المخزن كما هو.',
      confirmLabel: 'إلغاء الأمر',
      cancelLabel: 'تراجع',
    );

    if (confirmed != true || !context.mounted) return;

    final failure = await cubit.changeStatus(PurchaseOrderStatus.cancelled);
    if (!context.mounted) return;

    if (failure != null) {
      context.showFailure(failure);

      return;
    }

    setState(() => _changed = true);
    context.showSuccess('تم إلغاء أمر الشراء');
  }

  Future<void> _receive(BuildContext context) async {
    final cubit = context.read<PurchaseOrderDetailCubit>();
    final order = cubit.state.order;
    if (order == null) return;

    if (order.warehouseId == null) {
      // The server refuses this too. Said here first, because «تعذّر استلام الشحنة» after a
      // sheet has been filled in is a wasted minute.
      context.showInfo('هذا الأمر بلا مخزن وجهة — عدّله واختر مخزناً أولاً');

      return;
    }

    if (order.outstanding.isEmpty) {
      context.showInfo('كل البنود وصلت بالكامل');

      return;
    }

    final shipment = await showReceiveArrivalSheet(context: context, order: order);
    if (shipment == null || !context.mounted) return;

    final failure = await cubit.receive(
      quantities: shipment.quantities,
      invoiceNumber: shipment.invoiceNumber,
      notes: shipment.notes,
    );

    if (!context.mounted) return;

    if (failure != null) {
      context.showFailure(failure);

      return;
    }

    setState(() => _changed = true);
    context.showSuccess('تم تسجيل الشحنة ودخلت المخزن');
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PurchaseOrderDetailCubit>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.pop(_changed);
      },
      child: Scaffold(
        floatingActionButtonLocation: AppSpeedDial.location,
        appBar: AppBar(
          title: BlocBuilder<PurchaseOrderDetailCubit, PurchaseOrderDetailState>(
            builder: (context, state) =>
                Text(state.order == null ? 'أمر شراء' : 'أمر شراء #${state.order!.id}'),
          ),
        ),
        floatingActionButton: BlocBuilder<PurchaseOrderDetailCubit, PurchaseOrderDetailState>(
          builder: (context, state) {
            final order = state.order;
            if (order == null) return const SizedBox.shrink();

            return _Actions(
              order: order,
              onEdit: _edit,
              onCancel: _cancel,
              onReceive: _receive,
            );
          },
        ),
        body: BlocBuilder<PurchaseOrderDetailCubit, PurchaseOrderDetailState>(
          builder: (context, state) {
            final order = state.order;

            if (order == null) {
              return switch (state) {
                PurchaseOrderDetailFailure(:final failure) => Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.w),
                    child: Text(failure.message, textAlign: TextAlign.center),
                  ),
                ),
                _ => const Center(child: CircularProgressIndicator()),
              };
            }

            return RefreshIndicator(
              onRefresh: cubit.load,
              child: _Body(order: order),
            );
          },
        ),
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.order,
    required this.onEdit,
    required this.onCancel,
    required this.onReceive,
  });

  final PurchaseOrder order;
  final Future<void> Function(BuildContext context) onEdit;
  final Future<void> Function(BuildContext context) onCancel;
  final Future<void> Function(BuildContext context) onReceive;

  @override
  Widget build(BuildContext context) {
    return AppSpeedDial(
      actions: [
        // **First, because it is the one that happens most.** Receiving is guarded by
        // `inventory.manage` rather than by `purchase_orders.manage` — it writes to the stock
        // ledger, and that is the storekeeper's grant, not the buyer's.
        if (order.status.isReceivable)
          AppAction(
            label: 'تسجيل شحنة',
            icon: AppIcons.receiveShipment,
            tone: AppActionTone.primary,
            permission: AppPermission.manageInventory,
            onTap: onReceive,
          ),
        if (order.status.isEditable)
          AppAction(
            label: 'تعديل الأمر',
            icon: AppIcons.edit,
            tone: AppActionTone.primary,
            permission: AppPermission.managePurchaseOrders,
            onTap: onEdit,
          ),
        // The only status a person moves an order to by hand — the machine's other two moves are
        // on no button, each for its own reason. See `offeredNext`.
        if (order.status.offeredNext.contains(PurchaseOrderStatus.cancelled))
          AppAction(
            label: 'إلغاء الأمر',
            icon: AppIcons.deactivate,
            tone: AppActionTone.warning,
            permission: AppPermission.managePurchaseOrders,
            onTap: onCancel,
          ),
        AppAction(
          label: 'سجل التعديلات',
          icon: AppIcons.history,
          permission: AppPermission.viewActivityLogs,
          onTap: (context) =>
              context.push(Routes.activityLog(AuditSubject.purchaseOrder, order.id)),
        ),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.order});

  final PurchaseOrder order;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 96.h),
      children: [
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.vendorName,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      order.warehouseName,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                order.statusLabel,
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 14.h),
        _Section(
          title: 'التواريخ',
          child: Column(
            children: [
              _Row(label: 'تاريخ الطلب', value: order.orderDate),
              if (order.expectedDate case final expected?) ...[
                Divider(height: 18.h),
                _Row(label: 'الوصول المتوقع', value: expected),
              ],
              // Summed by the server from the lines, never added up here. Absent on paperwork
              // raised before cost tracking, and left off entirely rather than shown as zero.
              if (order.totalAmount case final total?) ...[
                Divider(height: 18.h),
                _Row(label: 'إجمالي التكلفة', value: '${groupedDecimal(total)} د.ل'),
              ],
            ],
          ),
        ),
        if (order.notes case final notes?) ...[
          SizedBox(height: 14.h),
          _Section(title: 'ملاحظات', child: Text(notes)),
        ],
        SizedBox(height: 14.h),
        _Section(
          title: 'البنود',
          child: Column(
            children: [
              for (final (index, item) in order.items.indexed) ...[
                if (index > 0) Divider(height: 18.h),
                _LineRow(item: item),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// One line: what was ordered, what has arrived, and what is still owing.
class _LineRow extends StatelessWidget {
  const _LineRow({required this.item});

  final PurchaseOrderItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isDone = !item.isOutstanding;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.title,
                style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            if (isDone)
              Icon(AppIcons.activate, size: 18.sp, color: scheme.primary)
            else
              Text(
                // The number that decides whether the next shipment is accepted, printed once
                // and computed by the server.
                'متبقٍ ${item.remainingWithUnit}',
                style: context.textTheme.bodySmall?.copyWith(color: scheme.error),
              ),
          ],
        ),
        SizedBox(height: 4.h),
        Text(
          // The unit on the *ordered* figure and not repeated on the received one: they are the
          // same unit by construction, and saying it twice in one line is read as two facts.
          'مطلوب ${item.orderedWithUnit} · وصل ${item.receivedLabel}',
          style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        // The money on its own line, and only when there is any. A line raised before cost
        // tracking says nothing rather than «0 د.ل», which would read as a free delivery.
        if (item.hasCost) ...[
          SizedBox(height: 4.h),
          Text(
            // «١٫٥ د.ل للكيلوغرام» — a price a buyer can check against the quote they were
            // given. «للوحدة» named nothing, and named it identically for both units.
            '${groupedDecimal(item.unitCost!)} د.ل ${item.perUnitSuffix} · '
            'الإجمالي ${groupedDecimal(item.totalCost ?? '0')} د.ل',
            style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: context.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: scheme.primary,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          value,
          textDirection: TextDirection.ltr,
          style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
