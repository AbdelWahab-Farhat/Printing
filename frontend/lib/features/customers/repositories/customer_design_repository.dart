import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/customers/models/customer_design.dart';

/// What the app can do about a customer's artwork.
///
/// Its own contract rather than four more methods on `CustomerRepository`, because the two
/// have different shapes: everything here is scoped to one customer, one call is multipart
/// with a progress stream, and nothing here paginates. A repository that does both ends up
/// with an upload sitting next to a search filter.
abstract interface class CustomerDesignRepository {
  /// Every design this customer has, newest first.
  ///
  /// A plain list, not a page. The server caps a customer at fifty — see
  /// `media.customer_designs.max_per_customer` — so there is nothing to page through, and
  /// pretending otherwise would put a load-more spinner under a list that is already complete.
  Future<Either<Failure, List<CustomerDesign>>> designs(int customerId);

  /// Uploads one file and answers with the design the server stored.
  ///
  /// **Idempotent, and the app leans on it.** The server hashes the bytes: sending a file this
  /// customer already has answers `200` with the existing design instead of a second copy. So a
  /// retry after a dropped connection is free, which is what lets the upload row offer «إعادة
  /// المحاولة» without asking anybody whether it landed the first time.
  ///
  /// [onProgress] is called as the bytes go out. Given rather than a `Stream` because there is
  /// exactly one listener — the row showing the bar — and a stream would need closing.
  Future<Either<Failure, CustomerDesign>> upload(
    int customerId, {
    required String path,
    required String filename,
    String? label,
    String? notes,
    void Function(int sent, int total)? onProgress,
  });

  /// Changes what a design is called, and the note under it.
  ///
  /// **The file itself cannot be replaced.** There is no endpoint for it: an order points at a
  /// design, so swapping the bytes under a stable id would change what an order placed last
  /// year says was printed. A new version is a new upload.
  Future<Either<Failure, CustomerDesign>> rename(
    int customerId,
    int designId, {
    required String label,
    String? notes,
  });

  /// The file's own bytes, for saving it onto the phone.
  ///
  /// [fileUrl] rather than an id, because the address is what the server signed for *this*
  /// request — see the note on [CustomerDesign]. A link held for an hour is a 403, which is why
  /// this takes the URL the screen is holding right now instead of one it stored earlier.
  ///
  /// Ours or not: on production the file sits on a private bucket and the signed link points at
  /// the storage host, not at the API. So this is a plain GET with no envelope to unwrap.
  Future<Either<Failure, Uint8List>> fileBytes(String fileUrl);

  /// Takes a design out of the customer's library.
  ///
  /// **The file is kept.** The row is soft-deleted and the stored object is left exactly where
  /// it is, because an order printed last year must still be able to show what was printed —
  /// and the colleague tidying the list has no way of knowing which designs old orders point
  /// at. Answers with the server's own message.
  Future<Either<Failure, String>> remove(int customerId, int designId);
}
