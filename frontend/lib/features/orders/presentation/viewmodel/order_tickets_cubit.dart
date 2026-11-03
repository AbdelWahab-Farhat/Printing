import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/orders/models/order_ticket.dart';
import 'package:dayaa/features/orders/usecases/get_order_tickets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'order_tickets_cubit.freezed.dart';

/// «التذاكر المرتبطة» بطلبيةٍ واحدة.
///
/// **طلبُه وحده، لا حقلٌ في الطلبية**: ثلاثةُ سياقاتٍ أخرى تجيب عنه، وصفحةُ الطلبية تُرسم كاملةً
/// بدونه — كـ`OrderInvestorSharesCubit`.
class OrderTicketsCubit extends Cubit<OrderTicketsState> {
  OrderTicketsCubit({required GetOrderTickets getTickets})
    : _getTickets = getTickets,
      super(const OrderTicketsState.loading());

  final GetOrderTickets _getTickets;

  int? _orderId;

  Future<void> load(int orderId) async {
    _orderId = orderId;

    final result = await _getTickets(orderId);

    if (isClosed) return;

    emit(
      result.fold(
        (failure) => OrderTicketsState.failure(failure),
        (tickets) => OrderTicketsState.loaded(tickets),
      ),
    );
  }

  /// بعد العودة من تذكرةٍ فُتحت أو أُنشئت: حالتُها ربما تغيّرت. **بلا «جارٍ التحميل» بينهما** —
  /// الصفوفُ الحالية تبقى حتى يصل الجواب، فلا يقفز القسم.
  Future<void> reload() async {
    if (_orderId case final orderId?) await load(orderId);
  }
}

@freezed
sealed class OrderTicketsState with _$OrderTicketsState {
  const factory OrderTicketsState.loading() = OrderTicketsLoading;

  /// قائمةٌ فارغة جوابٌ عاديّ — «لا تذاكر» — والقسمُ يقولها بجملة تحت زرّ الإضافة.
  const factory OrderTicketsState.loaded(List<OrderTicket> tickets) = OrderTicketsLoaded;

  const factory OrderTicketsState.failure(Failure failure) = OrderTicketsFailure;
}
