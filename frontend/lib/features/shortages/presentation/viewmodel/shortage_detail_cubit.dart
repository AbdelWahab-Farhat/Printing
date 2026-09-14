import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/files/picked_file.dart';
import 'package:dayaa/features/shortages/models/shortage.dart';
import 'package:dayaa/features/shortages/usecases/shortage_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'shortage_detail_cubit.freezed.dart';
part 'shortage_detail_state.dart';

/// One shortage, and everything that can be done to it.
///
/// **Every write ends in a re-read, and two of them have no choice.** Recording a supply and
/// undoing one answer with the *supply row*, not with the shortage — so the new
/// `supplied_quantity`, the new remainder and possibly the new «مكتمل» exist only on the server
/// until this asks for them again. Doing the same after a status change or an assignment keeps
/// one rule instead of three, and costs a request on actions nobody repeats.
///
/// **The failures are handed back rather than swallowed.** Every refusal this screen can meet is
/// a 422 with its own sentence — a move the machine does not allow, a quantity above the
/// remainder, a warehouse missing on goods that need a shelf, an arrival from the order that may
/// not be undone here — and each tells the person something different to do.
class ShortageDetailCubit extends Cubit<ShortageDetailState> {
  ShortageDetailCubit({
    required int shortageId,
    required GetShortage getShortage,
    required ChangeShortageStatus changeStatus,
    required AssignShortage assignShortage,
    required RecordShortageSupply recordSupply,
    required ReverseShortageSupply reverseSupply,
  }) : _id = shortageId,
       _getShortage = getShortage,
       _changeStatus = changeStatus,
       _assign = assignShortage,
       _recordSupply = recordSupply,
       _reverseSupply = reverseSupply,
       super(const ShortageDetailState.loading());

  final int _id;
  final GetShortage _getShortage;
  final ChangeShortageStatus _changeStatus;
  final AssignShortage _assign;
  final RecordShortageSupply _recordSupply;
  final ReverseShortageSupply _reverseSupply;

  Future<void> load() async {
    // What it already has is kept while the next read is in flight, so a pull-to-refresh does not
    // blank the screen the user is reading.
    emit(ShortageDetailState.loading(shortage: state.shortage));

    final result = await _getShortage(_id);

    if (isClosed) return;

    emit(
      result.fold(
        (failure) => ShortageDetailState.failure(failure, shortage: state.shortage),
        ShortageDetailState.ready,
      ),
    );
  }

  /// Moves it along. **Only ever a value out of `available_transitions`** — the screen draws
  /// exactly those buttons, so «مكتمل» is never offered and never sent.
  Future<Failure?> changeStatus(String status) =>
      _write(() => _changeStatus(_id, status: status));

  /// Hands it to somebody, or takes it back — a null [userId] is «غير مُسنَد», which is a queue
  /// and not an absence.
  Future<Failure?> assign(int? userId) => _write(() => _assign(_id, userId: userId));

  /// Records what was bought — **and puts it on a shelf**.
  ///
  /// The ceiling on [quantity] is re-checked on the server under a lock, so «الكمية أكبر من
  /// المتبقي» can still arrive from a screen that capped the box: two clerks can record the last
  /// ten kilos at once.
  Future<Failure?> recordSupply({
    required String quantity,
    String? amount,
    String? method,
    int? warehouseId,
    String? occurredOn,
    String? notes,
    PickedFile? receipt,
  }) {
    return _write(
      () => _recordSupply(
        _id,
        quantity: quantity,
        amount: amount,
        method: method,
        warehouseId: warehouseId,
        occurredOn: occurredOn,
        notes: notes,
        receipt: receipt,
      ),
    );
  }

  /// Undoes one, taking the goods back off the shelf — which Inventory may refuse in its own
  /// words if the layer has been drawn on or repriced since.
  Future<Failure?> reverseSupply(int supplyId, {String? notes}) =>
      _write(() => _reverseSupply(_id, supplyId, notes: notes));

  /// Runs a write, then re-reads.
  ///
  /// The shortage on screen is left exactly as it was while the write is in flight — `isWorking`
  /// is what the buttons read — so a refusal returns the user to the screen they were looking at
  /// rather than to a spinner.
  Future<Failure?> _write(Future<Either<Failure, Object?>> Function() write) async {
    final shortage = state.shortage;
    if (shortage == null || state.isWorking) return null;

    emit(ShortageDetailState.working(shortage));

    final result = await write();

    if (isClosed) return null;

    final failure = result.fold<Failure?>((f) => f, (_) => null);

    if (failure != null) {
      emit(ShortageDetailState.ready(shortage));

      return failure;
    }

    await load();

    return null;
  }
}
