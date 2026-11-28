import 'package:dartz/dartz.dart' show Either;
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/features/warehouses/models/awaiting_handover_order.dart';
import 'package:dayaa/features/warehouses/models/warehouse_stock.dart';
import 'package:dayaa/features/warehouses/repositories/warehouse_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// The orders behind one shelf's «بانتظار التسليم» — INSTANT-ORDERS-PLAN.md §4.
///
/// Each is an instant order still «جديدة»: its stock left the books when it was taken and is
/// still on the shelf until the customer collects it. Tapping one opens the order.
Future<void> showAwaitingHandoverSheet({
  required BuildContext context,
  required WarehouseStock stock,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _AwaitingHandoverSheet(stock: stock),
  );
}

class _AwaitingHandoverSheet extends StatefulWidget {
  const _AwaitingHandoverSheet({required this.stock});

  final WarehouseStock stock;

  @override
  State<_AwaitingHandoverSheet> createState() => _AwaitingHandoverSheetState();
}

class _AwaitingHandoverSheetState extends State<_AwaitingHandoverSheet> {
  late final Future<Either<Failure, List<AwaitingHandoverOrder>>> _orders =
      sl<WarehouseRepository>().awaitingHandover(widget.stock.warehouseId, widget.stock.id);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'بانتظار التسليم — ${widget.stock.title}',
            style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 4.h),
          Text(
            'طلبات فورية لم تُسلَّم بعد: خُصمت من الرصيد وما زالت على الرف',
            style: context.textTheme.bodySmall?.copyWith(color: context.colorScheme.onSurfaceVariant),
          ),
          SizedBox(height: 12.h),
          FutureBuilder<Either<Failure, List<AwaitingHandoverOrder>>>(
            future: _orders,
            builder: (context, snapshot) {
              final result = snapshot.data;
              if (result == null) return const Center(child: CircularProgressIndicator());

              final orders = result.fold((_) => null, (orders) => orders);
              if (orders == null) {
                return Text(result.fold((failure) => failure.message, (_) => ''));
              }
              if (orders.isEmpty) return const Text('لا توجد طلبات بانتظار التسليم');

              return Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final order in orders)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('#${order.code} — ${order.customerName ?? ''}'),
                        trailing: Text(
                          '${order.quantity} ${widget.stock.unitLabel}',
                          textDirection: TextDirection.ltr,
                        ),
                        onTap: () {
                          // Read before the pop: the sheet's context is gone after it.
                          final router = GoRouter.of(context);
                          Navigator.of(context).pop();
                          router.push(Routes.order(order.orderId)).ignore();
                        },
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
