import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/pagination/changes.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/widgets/app_dialog.dart';
import 'package:dayaa/core/widgets/app_speed_dial.dart';
import 'package:dayaa/features/audit/models/audit_subject.dart';
import 'package:dayaa/features/purchase_orders/models/purchase_order.dart';
import 'package:dayaa/features/purchase_orders/presentation/viewmodel/purchase_order_detail_cubit.dart';
import 'package:dayaa/features/purchase_orders/presentation/widgets/receive_arrival_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// One purchase order: what was asked for, what has turned up, and what is left.
///
/// Pops with `true` when anything was written, so the list behind re-reads.
class PurchaseOrderDetailPage extends StatelessWidget {
  const PurchaseOrderDetailPage({required this.purchaseOrderId, super.key});

  final int purchaseOrderId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PurchaseOrderDetailCubit>(
      create: (_) =>
          sl<PurchaseOrderDetailCubit>(param1: purchaseOrderId)..load(),
      child: const _PurchaseOrderDetailView(),
    );
  }
}

class _PurchaseOrderDetailView extends StatefulWidget {
  const _PurchaseOrderDetailView();

  @override
  State<_PurchaseOrderDetailView> createState() =>
      _PurchaseOrderDetailViewState();
}

/// Stateful for one reason: it remembers the order as it changed — sent, cancelled, a shipment
/// booked in — so `pop` can hand the list behind the new row instead of making it re-read the
/// page. That is screen lifecycle, not business state.
class _PurchaseOrderDetailViewState extends State<_PurchaseOrderDetailView> {
  final _changes = Changes<PurchaseOrder>();

  Future<void> _edit(BuildContext context) async {
    final cubit = context.read<PurchaseOrderDetailCubit>();
    final order = cubit.state.order;
    if (order == null) return;

    final saved = await context.push<PurchaseOrder>(
      Routes.purchaseOrderForm,
      extra: order,
    );
    if (saved == null || !context.mounted) return;

    // Re-read rather than taking the form's copy: a purchase order's outstanding quantities are
    // the server's arithmetic over every shipment booked against it, and this screen is the one
    // that has to be right about them. The *list* behind is handed the result, which is the
    // request this used to cost twice.
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

    context.showSuccess('تم إلغاء أمر الشراء');
  }

  /// Naming the partners who paid for this shipment — and the deal that settles it.
  ///
  /// **Before the lorry arrives, and once.** The cost layer is stamped with its deal at the gate
  /// and can never be stamped afterwards, so the server refuses this the moment a line has been
  /// received. Said here first, because a filled-in form answered with a refusal is a wasted
  /// minute.
  Future<void> _fund(BuildContext context) async {
    final cubit = context.read<PurchaseOrderDetailCubit>();
    final order = cubit.state.order;
    if (order == null) return;

    if (order.items.isEmpty) {
      context.showInfo('أضف بنود الأمر أولاً — التمويل يقف على ما تشتريه');

      return;
    }

    final deal = await context.push<Object?>(
      Routes.purchaseOrderFunding,
      extra: order,
    );

    if (deal == null || !context.mounted) return;

    // Re-read: the order itself did not change, but the screen now has a deal to name, and the
    // server is the one that knows its code.
    await cubit.load();
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

    final shipment = await showReceiveArrivalSheet(
      context: context,
      order: order,
    );
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

    context.showSuccess('تم تسجيل الشحنة ودخلت المخزن');
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PurchaseOrderDetailCubit>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.pop(_changes.result);
      },
      child: Scaffold(
        floatingActionButtonLocation: AppSpeedDial.location,
        appBar: AppBar(
          title:
              BlocBuilder<PurchaseOrderDetailCubit, PurchaseOrderDetailState>(
                builder: (context, state) => Text(
                  state.order == null
                      ? 'أمر شراء'
                      : 'أمر شراء #${state.order!.id}',
                ),
              ),
        ),
        floatingActionButton:
            BlocBuilder<PurchaseOrderDetailCubit, PurchaseOrderDetailState>(
              builder: (context, state) {
                final order = state.order;
                if (order == null) return const SizedBox.shrink();

                return _Actions(
                  order: order,
                  onEdit: _edit,
                  onCancel: _cancel,
                  onReceive: _receive,
                  onFund: _fund,
                );
              },
            ),
        body: BlocConsumer<PurchaseOrderDetailCubit, PurchaseOrderDetailState>(
          // Every reading goes past here, whatever produced it — the form, a cancellation, a
          // shipment booked in. What differs from the first one is what the list behind is
          // handed on the way out.
          listener: (context, state) => _changes.saw(state.order),
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
    required this.onFund,
  });

  final PurchaseOrder order;
  final Future<void> Function(BuildContext context) onEdit;
  final Future<void> Function(BuildContext context) onCancel;
  final Future<void> Function(BuildContext context) onReceive;
  final Future<void> Function(BuildContext context) onFund;

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
        // Only while nothing has arrived: who paid for goods is declared before they land.
        if (order.status.isEditable)
          AppAction(
            label: 'تمويل مستثمرين',
            icon: AppIcons.investors,
            tone: AppActionTone.primary,
            permission: AppPermission.manageInvestors,
            onTap: onFund,
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
          onTap: (context) => context.push(
            Routes.activityLog(AuditSubject.purchaseOrder, order.id),
          ),
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
                _Row(
                  label: 'إجمالي التكلفة',
                  value: '${groupedDecimal(total)} د.ل',
                ),
              ],
              // **Part of the total above, not on top of it.** Every line's cost already carries
              // its share, so the two must never be added together — this row says how much of
              // the total was not goods.
              if (order.hasAdditionalCosts)
                if (order.totalAdditionalCost case final additional?) ...[
                  Divider(height: 18.h),
                  _Row(
                    label: 'منها تكاليف إضافية',
                    value: '${groupedDecimal(additional)} د.ل',
                  ),
                ],
            ],
          ),
        ),
        // Itemised, and only when there is something to itemise. This is what answers «why is
        // this line dearer than the invoice said» — without it the allocated shares on the lines
        // below are a number with no source.
        if (order.hasAdditionalCosts) ...[
          SizedBox(height: 14.h),
          _Section(
            title: 'التكاليف الإضافية',
            child: Column(
              children: [
                for (final (index, cost) in order.additionalCosts.indexed) ...[
                  if (index > 0) Divider(height: 18.h),
                  _Row(label: cost.name, value: '${cost.amountLabel} د.ل'),
                ],
              ],
            ),
          ),
        ],
        if (order.notes case final notes?) ...[
          SizedBox(height: 14.h),
          _Section(title: 'ملاحظات', child: Text(notes)),
        ],
        // Whose money is on this lorry. Placed above the lines because it is the thing a person
        // opening a funded order wants first — and absent entirely on the ordinary order the
        // company bought for itself, rather than drawn as an empty box.
        for (final funding in order.investorFunding) ...[
          SizedBox(height: 14.h),
          _FundingSection(funding: funding, order: order),
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

/// One deal on this order: its partners, what each put in, and the share it bought him.
///
/// **The two numbers stand together.** «30,000 · 60%» is one fact stated twice — the percentage
/// was computed from the money when the deal was struck — and showing only the percentage would
/// hide what a partner can check against his own receipt.
class _FundingSection extends StatelessWidget {
  const _FundingSection({required this.funding, required this.order});

  final PurchaseOrderFunding funding;
  final PurchaseOrder order;

  /// The lines this deal paid for, named as the order names them.
  String get _lines => order.items
      .where((item) => funding.stockItemIds.contains(item.stockItemId))
      .map((item) => item.stockItem?.displayName ?? 'مادة #${item.stockItemId}')
      .join(' · ');

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return _Section(
      title: 'تمويل ${funding.code}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => context.push(Routes.investorDeal(funding.dealId)),
            borderRadius: BorderRadius.circular(8.r),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 4.h),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _lines.isEmpty ? funding.code : _lines,
                      style: context.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    funding.statusLabel,
                    style: context.textTheme.bodyLarge?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Icon(AppIcons.forward, size: 18.r, color: scheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
          Divider(height: 18.h),
          for (final (index, funder) in funding.investors.indexed) ...[
            if (index > 0) SizedBox(height: 10.h),
            Row(
              children: [
                Expanded(child: Text(funder.name, style: context.textTheme.bodyLarge)),
                Text(
                  '${groupedDecimal(funder.committedAmount)} د.ل',
                  style: context.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(width: 10.w),
                Text(
                  '${trimDecimals(funder.sharePercent)}%',
                  style: context.textTheme.bodyLarge?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
          Divider(height: 18.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  'حصة المستثمرين من الربح',
                  style: context.textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                '${trimDecimals(funding.investorProfitSharePercent)}%',
                style: context.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    // «كيس شحن 25*35» — the shelf's own name, composed by the server. **No
                    // product name here, deliberately**: two products draw on this line's pile,
                    // so naming either of them would be picking one arbitrarily.
                    item.title,
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  // `S7`, quieter and underneath. It is what a buyer quotes to the supplier, and
                  // what stands where the product's name and photograph used to.
                  if (item.itemCode case final code?) ...[
                    SizedBox(height: 2.h),
                    Text(
                      code,
                      textDirection: TextDirection.ltr,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isDone)
              Icon(AppIcons.activate, size: 18.sp, color: scheme.primary)
            else
              Text(
                // The number that decides whether the next shipment is accepted, printed once
                // and computed by the server.
                'متبقٍ ${item.remainingWithUnit}',
                style: context.textTheme.bodySmall?.copyWith(
                  color: scheme.error,
                ),
              ),
          ],
        ),
        SizedBox(height: 4.h),
        Text(
          // The unit on the *ordered* figure and not repeated on the received one: they are the
          // same unit by construction, and saying it twice in one line is read as two facts.
          'مطلوب ${item.orderedWithUnit} · وصل ${item.receivedLabel}',
          style: context.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        // The money on its own line, and only when there is any. A line raised before cost
        // tracking says nothing rather than «0 د.ل», which would read as a free delivery.
        if (item.hasCost) ...[
          SizedBox(height: 4.h),
          Text(
            // **The landed cost, not the invoiced one.** «١٫٥ د.ل للكيلوغرام» is a price a buyer
            // can check against the quote they were given — and once delivery has been spread
            // over the lines, the landed figure is the one a job's margin is worked out against.
            // «للوحدة» named nothing, and named it identically for both units.
            '${item.unitCostLabel} د.ل ${item.perUnitSuffix} · '
            'الإجمالي ${item.totalCostLabel} د.ل',
            style: context.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          // The split, and only when something was actually spread onto this line. Faint,
          // because it explains the figure above rather than competing with it — and absent on
          // the ordinary order that carried no delivery at all.
          if (item.hasAllocatedCost) ...[
            SizedBox(height: 2.h),
            Text(
              'الأساسي ${item.baseTotalCostLabel} د.ل '
              '+ حصة من التكاليف الإضافية ${item.allocatedCostLabel} د.ل',
              style: context.textTheme.bodySmall?.copyWith(
                color: scheme.outline,
              ),
            ),
          ],
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
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.6),
            ),
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
          style: context.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
