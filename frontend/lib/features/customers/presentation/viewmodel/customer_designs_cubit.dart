import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/files/picked_file.dart';
import 'package:printing/features/customers/models/customer_design.dart';
import 'package:printing/features/customers/usecases/delete_customer_design.dart';
import 'package:printing/features/customers/usecases/get_customer_designs.dart';
import 'package:printing/features/customers/usecases/rename_customer_design.dart';
import 'package:printing/features/customers/usecases/upload_customer_design.dart';

part 'customer_designs_state.dart';
part 'customer_designs_cubit.freezed.dart';

/// One customer's library of artwork, and the four things staff do to it.
///
/// ## Two ways a failure is reported, and why
///
/// An **upload** keeps its own failure, in its own row. It has a file attached, retrying is
/// free because the endpoint is idempotent on the checksum, and a person who picked four files
/// needs to see which of them did not make it — a toast that says «تعذّر الرفع» once cannot
/// say that.
///
/// A **rename or a delete** returns its failure to the caller instead, as a `Failure?`. There
/// is nothing left on screen for it to attach to, and a field on the state would either linger
/// into the next rebuild or be cleared by a second emit nobody can see. The screen awaits the
/// call and shows a toast, which is the whole of it.
class CustomerDesignsCubit extends Cubit<CustomerDesignsState> {
  CustomerDesignsCubit({
    required int customerId,
    required GetCustomerDesigns getDesigns,
    required UploadCustomerDesign uploadDesign,
    required RenameCustomerDesign renameDesign,
    required DeleteCustomerDesign deleteDesign,
  }) : _customerId = customerId,
       _getDesigns = getDesigns,
       _uploadDesign = uploadDesign,
       _renameDesign = renameDesign,
       _deleteDesign = deleteDesign,
       super(const CustomerDesignsState.loading());

  final int _customerId;
  final GetCustomerDesigns _getDesigns;
  final UploadCustomerDesign _uploadDesign;
  final RenameCustomerDesign _renameDesign;
  final DeleteCustomerDesign _deleteDesign;

  /// One drain at a time. Not a lock over the network — the queue is in state — but the flag
  /// that keeps a second `add()` mid-upload from starting a parallel loop over the same list.
  bool _isDraining = false;

  Future<void> load() async {
    // Only from nothing. A refresh must not blank a grid the user is looking at, and it must
    // certainly not throw away uploads that are still going.
    if (state is! CustomerDesignsLoaded) emit(const CustomerDesignsState.loading());

    final result = await _getDesigns(_customerId);
    if (isClosed) return;

    emit(
      result.fold(CustomerDesignsState.failure, (designs) {
        final current = state;

        return current is CustomerDesignsLoaded
            ? current.copyWith(designs: designs)
            : CustomerDesignsState.loaded(designs: designs);
      }),
    );
  }

  /// Queues files and starts sending them, one after another.
  ///
  /// A file already queued is ignored rather than added twice — the picker can be opened again
  /// before the first batch has finished, and choosing the same photo would otherwise show two
  /// bars for one upload that the server counts once.
  Future<void> add(List<PickedFile> files) async {
    final current = state;
    if (current is! CustomerDesignsLoaded) return;

    final queued = current.uploads.map((upload) => upload.id).toSet();
    final fresh = [
      for (final file in files)
        if (!queued.contains(file.path)) DesignUpload(file: file),
    ];
    if (fresh.isEmpty) return;

    emit(current.copyWith(uploads: [...current.uploads, ...fresh]));

    await _drain();
  }

  /// Sends a stopped upload again. Free to offer: the server answers a file it already holds
  /// with the design it already made, rather than a second copy.
  Future<void> retry(String uploadId) async {
    final current = state;
    if (current is! CustomerDesignsLoaded) return;

    emit(
      current.copyWith(
        uploads: _replace(
          current.uploads,
          uploadId,
          // `failure: null` through the generated `copyWith` really does clear it — freezed
          // distinguishes "passed null" from "not passed".
          (upload) => upload.copyWith(failure: null, sent: 0),
        ),
      ),
    );

    await _drain();
  }

  /// Gives up on one, and takes its row away.
  void dismiss(String uploadId) {
    final current = state;
    if (current is! CustomerDesignsLoaded) return;

    emit(
      current.copyWith(
        uploads: [
          for (final upload in current.uploads)
            // Never the one in flight: its `onSendProgress` would then emit a row back into
            // existence a moment after the user removed it.
            if (upload.id != uploadId || upload.isUploading) upload,
        ],
      ),
    );
  }

  /// Renames one design. Returns null when it worked, and the failure when it did not.
  Future<Failure?> rename(int designId, {required String label, String? notes}) async {
    final current = state;
    if (current is! CustomerDesignsLoaded || current.busy.contains(designId)) return null;

    emit(current.copyWith(busy: {...current.busy, designId}));

    final result = await _renameDesign(_customerId, designId, label: label, notes: notes);
    if (isClosed) return null;

    return result.fold(
      (failure) {
        _clearBusy(designId);

        return failure;
      },
      (design) {
        final after = state;
        if (after is! CustomerDesignsLoaded) return null;

        emit(
          after.copyWith(
            designs: [
              for (final existing in after.designs)
                if (existing.id == design.id) design else existing,
            ],
            busy: {...after.busy}..remove(designId),
          ),
        );

        return null;
      },
    );
  }

  /// Takes a design out of the library. The stored file is kept — see [DeleteCustomerDesign].
  Future<Failure?> remove(int designId) async {
    final current = state;
    if (current is! CustomerDesignsLoaded || current.busy.contains(designId)) return null;

    emit(current.copyWith(busy: {...current.busy, designId}));

    final result = await _deleteDesign(_customerId, designId);
    if (isClosed) return null;

    return result.fold(
      (failure) {
        _clearBusy(designId);

        return failure;
      },
      (_) {
        final after = state;
        if (after is! CustomerDesignsLoaded) return null;

        emit(
          after.copyWith(
            designs: [
              for (final design in after.designs)
                if (design.id != designId) design,
            ],
            busy: {...after.busy}..remove(designId),
          ),
        );

        return null;
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────

  /// Sends whatever is waiting, one at a time, until nothing is.
  ///
  /// Sequential rather than concurrent: three uploads sharing one slow uplink means three bars
  /// that all crawl and none of them finishes, and the first file is the one the user is
  /// waiting on.
  Future<void> _drain() async {
    if (_isDraining) return;
    _isDraining = true;

    try {
      while (!isClosed) {
        final current = state;
        if (current is! CustomerDesignsLoaded) break;

        final next = current.uploads.where((upload) => upload.isWaiting).firstOrNull;
        if (next == null) break;

        await _send(next);
      }
    } finally {
      _isDraining = false;
    }
  }

  Future<void> _send(DesignUpload upload) async {
    _patch(upload.id, (it) => it.copyWith(isUploading: true, sent: 0));

    final result = await _uploadDesign(
      _customerId,
      file: upload.file,
      onProgress: (sent, total) => _onProgress(upload.id, sent, total),
    );
    if (isClosed) return;

    final current = state;
    if (current is! CustomerDesignsLoaded) return;

    emit(
      result.fold(
        (failure) => current.copyWith(
          uploads: _replace(
            current.uploads,
            upload.id,
            (it) => it.copyWith(isUploading: false, failure: failure),
          ),
        ),
        (design) => current.copyWith(
          // Newest first, matching the order the server lists them in. Filtered by id as well
          // as prepended, because an upload of a file the customer already had answers with
          // the design that already exists — and it must move to the top, not appear twice.
          designs: [design, ...current.designs.where((it) => it.id != design.id)],
          uploads: [
            for (final it in current.uploads)
              if (it.id != upload.id) it,
          ],
        ),
      ),
    );
  }

  /// Dio reports progress per chunk, which on a fast connection is far more often than a
  /// progress bar can show. Emitting only on a whole percent turns hundreds of rebuilds of the
  /// whole grid into a hundred.
  void _onProgress(String uploadId, int sent, int total) {
    final current = state;
    if (current is! CustomerDesignsLoaded) return;

    final upload = current.uploads.where((it) => it.id == uploadId).firstOrNull;
    if (upload == null || total <= 0) return;

    if ((upload.sent * 100) ~/ total == (sent * 100) ~/ total) return;

    emit(
      current.copyWith(
        uploads: _replace(current.uploads, uploadId, (it) => it.copyWith(sent: sent)),
      ),
    );
  }

  void _patch(String uploadId, DesignUpload Function(DesignUpload upload) change) {
    final current = state;
    if (current is! CustomerDesignsLoaded) return;

    emit(current.copyWith(uploads: _replace(current.uploads, uploadId, change)));
  }

  void _clearBusy(int designId) {
    final current = state;
    if (current is! CustomerDesignsLoaded) return;

    emit(current.copyWith(busy: {...current.busy}..remove(designId)));
  }

  static List<DesignUpload> _replace(
    List<DesignUpload> uploads,
    String uploadId,
    DesignUpload Function(DesignUpload upload) change,
  ) => [
    for (final upload in uploads)
      if (upload.id == uploadId) change(upload) else upload,
  ];
}
