import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/orders/models/order_note.dart';
import 'package:dayaa_client/features/orders/repositories/order_notes_repository.dart';

/// ملاحظات طلبيةٍ واحدة — وقراءتها تعلّمها مقروءة.
class ReadOrderNotes {
  const ReadOrderNotes(this._repository);

  final OrderNotesRepository _repository;

  Future<Either<Failure, List<OrderNote>>> call(int orderId) => _repository.notes(orderId);
}
