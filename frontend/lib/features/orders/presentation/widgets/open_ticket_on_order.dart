import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket_for_order.dart';
import 'package:dayaa/features/internal_tickets/models/internal_ticket_query.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_flow.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/order_tickets_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// A new ticket on [order]: a design ticket or an internal one, picked from one sheet.
///
/// The one way to open a ticket on an order. The dial's «فتح تذكرة» and the «إضافة تذكرة»
/// button over «التذاكر المرتبطة» both call it. The dial used to go straight to an internal
/// ticket, so a design ticket could only be found far down the page (owner's request,
/// 2026-11-13).
///
/// The design ticket is always on the sheet. Where it cannot be opened it is disabled and says
/// why, see [designTicketBlocker].
///
/// On the way back the order's tickets are read again, when the page provides them.
Future<void> openTicketOnOrder(BuildContext context, Order order) async {
  final kind = await _chooseKind(context, designTicketBlocker(order));
  if (kind == null || !context.mounted) return;

  // Null where the page shows no «التذاكر المرتبطة».
  final tickets = context.read<OrderTicketsCubit?>();

  await switch (kind) {
    _TicketKind.internal => context.push<Object?>(
      Routes.newInternalTicket,
      extra: InternalTicketSubject(
        orderId: order.id,
        orderCode: order.code,
        customerId: order.customer?.id,
        customerName: order.customer?.name,
      ),
    ),
    _TicketKind.design => context.push<Object?>(
      Routes.designTicketForm,
      extra: DesignTicketForOrder(
        // Never null here: a missing customer disables the design ticket.
        customer: order.customer!,
        orderId: order.id,
        orderCode: order.code,
        brief: _brief(order),
        colorsRequired: order.productionFlow == OrderFlow.standard,
      ),
    ),
  };

  if (tickets != null && !tickets.isClosed) await tickets.reload();
}

/// Why a design ticket cannot be opened on [order], or null when it can.
///
/// The server's own refusals (`CreateDesignTicket`, and the 404 on an archived order), read off
/// what the order already says, so the sheet names the reason instead of sending a request it
/// knows will fail. The order's own facts come first: when nobody could open one, that is the
/// answer, whoever is asking.
String? designTicketBlocker(Order order) {
  if (order.isArchived) return 'الطلبية في الأرشيف';
  if (order.customer == null) return 'الطلبية بلا عميل';
  if (!order.designsAreEditable) {
    return 'الطلبية في «${order.statusLabel}» ولم تعد تقبل تصميماً';
  }
  if (!sl<Session>().can(AppPermission.manageDesignTickets)) {
    return 'لا تملك صلاحية فتح تذاكر التصميم';
  }

  return null;
}

enum _TicketKind { internal, design }

/// The two kinds. The design ticket is disabled, with [designBlocked] under it, when it cannot
/// be opened.
Future<_TicketKind?> _chooseKind(BuildContext context, String? designBlocked) {
  return showModalBottomSheet<_TicketKind>(
    context: context,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            enabled: designBlocked == null,
            leading: Icon(AppIcons.designs),
            title: const Text('تذكرة تصميم'),
            subtitle: switch (designBlocked) {
              null => const Text('لهذه الطلبية — يُضاف التصميم المعتمد إليها تلقائياً'),
              // Kept readable: a disabled tile fades its subtitle along with its title.
              final reason => Text(
                reason,
                style: TextStyle(color: sheet.colorScheme.onSurfaceVariant),
              ),
            },
            onTap: () => Navigator.of(sheet).pop(_TicketKind.design),
          ),
          ListTile(
            leading: Icon(AppIcons.add),
            title: const Text('تذكرة داخلية'),
            subtitle: const Text('سؤالٌ أو مهمة لموظف'),
            onTap: () => Navigator.of(sheet).pop(_TicketKind.internal),
          ),
        ],
      ),
    ),
  );
}

/// What the order is, to start the brief: one line per printed size, so the designer knows the
/// bag and the size without opening the order.
String _brief(Order order) {
  final lines = [
    for (final item in order.items ?? const <OrderItem>[])
      '• ${item.productName} — ${item.variantLabel} — ${item.quantity.grouped}',
  ];

  return lines.isEmpty ? '' : 'الطلبية ${order.code}:\n${lines.join('\n')}\n\n';
}
