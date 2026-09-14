import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/files/picked_file.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/shortages/models/shortage.dart';
import 'package:dayaa/features/shortages/models/shortage_counts.dart';
import 'package:dayaa/features/shortages/models/shortage_supply.dart';
import 'package:dayaa/features/shortages/repositories/shortage_repository.dart';

/// One page of the نواقص list.
class GetShortages {
  const GetShortages(this._repository);

  final ShortageRepository _repository;

  Future<Either<Failure, Paginated<Shortage>>> call({
    List<ShortageStatus> statuses = const <ShortageStatus>[],
    String? assignedTo,
    int? productId,
    int? orderId,
    int? customerId,
    String? source,
    String? search,
    int page = 1,
  }) {
    return _repository.shortages(
      // Wire values, and never [ShortageStatus.unknown]: its wire is the empty string, which the
      // server would read as a status it cannot parse.
      statuses: [
        for (final wanted in statuses)
          if (wanted != ShortageStatus.unknown) wanted.wire,
      ],
      assignedTo: assignedTo,
      productId: productId,
      orderId: orderId,
      customerId: customerId,
      source: source,
      search: search,
      page: page,
    );
  }
}

/// The numbers behind the chip row.
///
/// **It takes no status**, and that is the board's whole shape: it answers «what else is there?»,
/// so narrowing it by the status already on screen would make every chip but one read zero.
class GetShortageCounts {
  const GetShortageCounts(this._repository);

  final ShortageRepository _repository;

  Future<Either<Failure, ShortageCounts>> call({
    String? assignedTo,
    int? productId,
    int? orderId,
    int? customerId,
    String? source,
    String? search,
  }) {
    return _repository.statusCounts(
      assignedTo: assignedTo,
      productId: productId,
      orderId: orderId,
      customerId: customerId,
      source: source,
      search: search,
    );
  }
}

/// One shortage, with the ledger no list payload carries.
class GetShortage {
  const GetShortage(this._repository);

  final ShortageRepository _repository;

  Future<Either<Failure, Shortage>> call(int shortageId) => _repository.shortage(shortageId);
}

/// Writing one down by hand.
class CreateShortage {
  const CreateShortage(this._repository);

  final ShortageRepository _repository;

  Future<Either<Failure, Shortage>> call({
    required String name,
    required String quantity,
    int? productId,
    int? productVariantId,
    String? unit,
    int? assignedToUserId,
    String? description,
  }) {
    return _repository.create(
      name: name,
      quantity: quantity,
      productId: productId,
      productVariantId: productVariantId,
      unit: unit,
      assignedToUserId: assignedToUserId,
      description: description,
    );
  }
}

/// Correcting one — refused on a shortage born of an order, which `Shortage.isEditable` says in
/// advance.
class UpdateShortage {
  const UpdateShortage(this._repository);

  final ShortageRepository _repository;

  Future<Either<Failure, Shortage>> call(
    int shortageId, {
    required String name,
    required String quantity,
    int? assignedToUserId,
    String? description,
  }) {
    return _repository.update(
      shortageId,
      name: name,
      quantity: quantity,
      assignedToUserId: assignedToUserId,
      description: description,
    );
  }
}

/// Moving it along the chase — only ever a value out of `available_transitions`.
class ChangeShortageStatus {
  const ChangeShortageStatus(this._repository);

  final ShortageRepository _repository;

  Future<Either<Failure, Shortage>> call(int shortageId, {required String status}) =>
      _repository.changeStatus(shortageId, status: status);
}

/// Handing it to somebody, or taking it back.
///
/// **A null [userId] is the instruction, not its absence** — «غير مُسنَد» is a queue a supervisor
/// works from, so putting a shortage back into it is a write like any other.
class AssignShortage {
  const AssignShortage(this._repository);

  final ShortageRepository _repository;

  Future<Either<Failure, Shortage>> call(int shortageId, {required int? userId}) =>
      _repository.assign(shortageId, userId: userId);
}

/// Recording what was bought — **and putting it on a shelf.** See the repository's own note.
class RecordShortageSupply {
  const RecordShortageSupply(this._repository);

  final ShortageRepository _repository;

  Future<Either<Failure, ShortageSupply>> call(
    int shortageId, {
    required String quantity,
    String? amount,
    String? method,
    int? warehouseId,
    String? occurredOn,
    String? notes,
    PickedFile? receipt,
  }) {
    return _repository.recordSupply(
      shortageId,
      quantity: quantity,
      amount: amount,
      method: method,
      warehouseId: warehouseId,
      occurredOn: occurredOn,
      notes: notes,
      receipt: receipt,
    );
  }
}

/// Undoing one, which takes the goods back off the shelf.
class ReverseShortageSupply {
  const ReverseShortageSupply(this._repository);

  final ShortageRepository _repository;

  Future<Either<Failure, ShortageSupply>> call(
    int shortageId,
    int supplyId, {
    String? notes,
  }) => _repository.reverseSupply(shortageId, supplyId, notes: notes);
}
