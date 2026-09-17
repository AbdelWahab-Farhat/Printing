import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/files/picked_file.dart';
import 'package:dayaa_client/features/designs/models/customer_design.dart';
import 'package:dayaa_client/features/designs/usecases/list_designs.dart';
import 'package:dayaa_client/features/designs/usecases/remove_design.dart';
import 'package:dayaa_client/features/designs/usecases/rename_design.dart';
import 'package:dayaa_client/features/designs/usecases/upload_design.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'designs_cubit.freezed.dart';
part 'designs_state.dart';

/// The ViewModel for «تصاميمي».
///
/// **The list is held in the loaded state and mutated locally after a write**, rather than
/// re-fetching the whole library each time. The server answers every write with the row it
/// wrote, so a refetch would be a second round trip for data already in hand — and on a phone
/// that is the difference between a rename that lands instantly and one that blinks.
class DesignsCubit extends Cubit<DesignsState> {
  DesignsCubit({
    required ListDesigns list,
    required UploadDesign upload,
    required RenameDesign rename,
    required RemoveDesign remove,
  }) : _list = list,
       _upload = upload,
       _rename = rename,
       _remove = remove,
       super(const DesignsState.loading());

  final ListDesigns _list;
  final UploadDesign _upload;
  final RenameDesign _rename;
  final RemoveDesign _remove;

  Future<void> load() async {
    emit(const DesignsState.loading());

    final result = await _list();

    if (isClosed) return;

    emit(result.fold(DesignsState.failure, DesignsState.loaded));
  }

  /// Adds a file. On success the new design goes to the front — the library is newest first, and
  /// a design somebody just uploaded is the one they are looking for.
  ///
  /// **A file already in the library is answered with the row that exists**, not a duplicate, so
  /// the guard below replaces rather than prepends: sending the same file twice must leave one
  /// entry, which is what makes a retry free.
  Future<void> add({required PickedFile file, String? label}) async {
    final current = _current;
    if (current == null) return;

    emit(DesignsState.loaded(current, isBusy: true));

    final result = await _upload(file: file, label: label);

    if (isClosed) return;

    emit(
      result.fold(
        (failure) => DesignsState.loaded(current, lastFailure: failure),
        (design) => DesignsState.loaded([
          design,
          ...current.where((existing) => existing.id != design.id),
        ]),
      ),
    );
  }

  Future<void> renameTo({required int id, required String label}) async {
    final current = _current;
    if (current == null) return;

    emit(DesignsState.loaded(current, isBusy: true));

    final result = await _rename(id: id, label: label);

    if (isClosed) return;

    emit(
      result.fold(
        (failure) => DesignsState.loaded(current, lastFailure: failure),
        (design) => DesignsState.loaded([
          for (final existing in current)
            if (existing.id == design.id) design else existing,
        ]),
      ),
    );
  }

  Future<void> removeAt(int id) async {
    final current = _current;
    if (current == null) return;

    emit(DesignsState.loaded(current, isBusy: true));

    final result = await _remove(id);

    if (isClosed) return;

    emit(
      result.fold(
        (failure) => DesignsState.loaded(current, lastFailure: failure),
        (_) => DesignsState.loaded(
          current.where((existing) => existing.id != id).toList(),
        ),
      ),
    );
  }

  /// The list as it stands, or null when nothing has loaded yet — a write before the first load
  /// has nothing to mutate and is ignored rather than guessed at.
  List<CustomerDesign>? get _current => switch (state) {
    DesignsLoaded(:final designs) => designs,
    _ => null,
  };
}
