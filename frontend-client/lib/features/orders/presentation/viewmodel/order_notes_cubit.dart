import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/orders/models/order_note.dart';
import 'package:dayaa_client/features/orders/usecases/read_order_notes.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'order_notes_cubit.freezed.dart';
part 'order_notes_state.dart';

/// شاشة «الملاحظات» لطلبيةٍ واحدة.
///
/// **تحميلها قراءتها**: الخادم يعلّم الملاحظات مقروءةً حين يرسلها، فلا نداء بعده.
class OrderNotesCubit extends Cubit<OrderNotesState> {
  OrderNotesCubit({required this.orderId, required ReadOrderNotes read})
    : _read = read,
      super(const OrderNotesState.loading());

  final int orderId;
  final ReadOrderNotes _read;

  Future<void> load() async {
    emit(const OrderNotesState.loading());

    final result = await _read(orderId);

    if (isClosed) return;

    emit(result.fold(OrderNotesState.failure, OrderNotesState.loaded));
  }
}
