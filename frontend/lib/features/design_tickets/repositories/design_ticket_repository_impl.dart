import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/api_endpoints.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/network/safe_request.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket_counts.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket_file.dart';
import 'package:dayaa/features/design_tickets/repositories/design_ticket_repository.dart';
import 'package:dio/dio.dart';

/// Fulfils [DesignTicketRepository] over HTTP.
///
/// The fact that the API spells the acceptance `POST .../acceptance`, the assignment
/// `PATCH .../designer` and the verdict `POST .../versions/{id}/review` never leaves this file.
class DesignTicketRepositoryImpl implements DesignTicketRepository {
  const DesignTicketRepositoryImpl(this._dio);

  final Dio _dio;

  /// The filters both the list and the chip row are asked with, in one place.
  ///
  /// **Omitted rather than sent as null.** The list endpoint reads its filters without validating
  /// them, so a literal `"null"` reaching an enum is a 500 rather than an empty page — the idiom
  /// `ShortageRepositoryImpl` uses for the same reason.
  Map<String, dynamic> _filters({
    String? designer,
    String? requestedBy,
    int? customerId,
    int? orderId,
    String? search,
  }) => <String, dynamic>{
    'designer': ?designer,
    'requested_by': ?requestedBy,
    'customer_id': ?customerId,
    'order_id': ?orderId,
    'search': ?search,
  };

  @override
  Future<Either<Failure, Paginated<DesignTicket>>> tickets({
    List<String> statuses = const <String>[],
    String? designer,
    String? requestedBy,
    int? customerId,
    int? orderId,
    String? search,
    int page = 1,
    int perPage = 20,
  }) {
    return safePaginatedRequest<DesignTicket>(
      () => _dio.get(
        DesignTicketEndpoints.index,
        queryParameters: <String, dynamic>{
          'page': page,
          'per_page': perPage,
          // A list, sent as `status[]=new&status[]=in_progress` by the client's
          // `multiCompatible` format. One status travels the same way and is read the same way —
          // Dio's default would send `status=a&status=b` and PHP would keep only the last.
          if (statuses.isNotEmpty) 'status': statuses,
          ..._filters(
            designer: designer,
            requestedBy: requestedBy,
            customerId: customerId,
            orderId: orderId,
            search: search,
          ),
        },
      ),
      parseItem: (json) => DesignTicket.fromJson(json),
    );
  }

  @override
  Future<Either<Failure, DesignTicketCounts>> statusCounts({
    String? designer,
    String? requestedBy,
    int? customerId,
    int? orderId,
    String? search,
  }) {
    return safeRequest<DesignTicketCounts>(
      () => _dio.get(
        DesignTicketEndpoints.summary,
        queryParameters: _filters(
          designer: designer,
          requestedBy: requestedBy,
          customerId: customerId,
          orderId: orderId,
          search: search,
        ),
      ),
      parse: (data) => DesignTicketCounts.fromJson(data! as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, DesignTicket>> ticket(int ticketId) {
    return safeRequest<DesignTicket>(
      () => _dio.get(DesignTicketEndpoints.show(ticketId)),
      parse: (data) => DesignTicket.fromJson(data! as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, DesignTicket>> create({
    required int customerId,
    required String title,
    required String description,
    String? instructions,
    int? orderId,
    int? assignedDesignerId,
  }) {
    return safeRequest<DesignTicket>(
      () => _dio.post(
        DesignTicketEndpoints.index,
        data: <String, dynamic>{
          'customer_id': customerId,
          'title': title.trim(),
          'description': description.trim(),
          // Omitted rather than sent empty: `nullable|string` reads `''` as a present-but-blank
          // value, which would store an empty paragraph where «لا توجد تعليمات» was meant.
          if (instructions != null && instructions.trim().isNotEmpty)
            'instructions': instructions.trim(),
          'order_id': ?orderId,
          'assigned_designer_id': ?assignedDesignerId,
        },
      ),
      parse: (data) => DesignTicket.fromJson(data! as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, DesignTicket>> update(
    int ticketId, {
    required String title,
    required String description,
    String? instructions,
  }) {
    return safeRequest<DesignTicket>(
      () => _dio.put(
        DesignTicketEndpoints.show(ticketId),
        data: <String, dynamic>{
          'title': title.trim(),
          'description': description.trim(),
          if (instructions != null && instructions.trim().isNotEmpty)
            'instructions': instructions.trim(),
        },
      ),
      parse: (data) => DesignTicket.fromJson(data! as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, DesignTicket>> assign(int ticketId, {required int? designerId}) {
    return safeRequest<DesignTicket>(
      () => _dio.patch(
        DesignTicketEndpoints.designer(ticketId),
        // **Sent even when null, unlike every filter above.** The server asks for the field to be
        // `present`, so that null reads as «أرجِعها إلى الطابور» and an omission reads as a
        // half-built request — which is what stops a mistake quietly clearing somebody's queue.
        data: <String, dynamic>{'assigned_designer_id': designerId},
      ),
      parse: (data) => DesignTicket.fromJson(data! as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, DesignTicket>> accept(int ticketId) {
    return safeRequest<DesignTicket>(
      () => _dio.post(DesignTicketEndpoints.acceptance(ticketId)),
      parse: (data) => DesignTicket.fromJson(data! as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, DesignTicket>> cancel(int ticketId, {required String reason}) {
    return safeRequest<DesignTicket>(
      () => _dio.post(
        DesignTicketEndpoints.cancellation(ticketId),
        data: <String, dynamic>{'reason': reason.trim()},
      ),
      parse: (data) => DesignTicket.fromJson(data! as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, DesignTicketFile>> attach(
    int ticketId, {
    required String path,
    required String filename,
    String? note,
    ProgressCallback? onProgress,
  }) {
    return _upload(
      DesignTicketEndpoints.attachments(ticketId),
      path: path,
      filename: filename,
      note: note,
      onProgress: onProgress,
    );
  }

  @override
  Future<Either<Failure, Unit>> removeAttachment(int ticketId, int attachmentId) async {
    final result = await safeCommand(
      () => _dio.delete(DesignTicketEndpoints.attachment(ticketId, attachmentId)),
    );

    return result.map((_) => unit);
  }

  @override
  Future<Either<Failure, DesignTicketFile>> submitVersion(
    int ticketId, {
    required String path,
    required String filename,
    String? note,
    ProgressCallback? onProgress,
  }) {
    return _upload(
      DesignTicketEndpoints.versions(ticketId),
      path: path,
      filename: filename,
      note: note,
      onProgress: onProgress,
    );
  }

  @override
  Future<Either<Failure, DesignTicketFile>> reviewVersion(
    int ticketId,
    int versionId, {
    required String verdict,
    String? note,
  }) {
    return safeRequest<DesignTicketFile>(
      () => _dio.post(
        DesignTicketEndpoints.review(ticketId, versionId),
        data: <String, dynamic>{
          'verdict': verdict,
          if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        },
      ),
      parse: (data) => DesignTicketFile.fromJson(data! as Map<String, dynamic>),
    );
  }

  /// The two uploads, which differ only in where they post.
  ///
  /// `fromFile` streams from disk. `fromBytes` would hold a 25 MB design in memory for the length
  /// of the upload, and a mid-range phone kills the app for less — the reason
  /// `CustomerDesignRepositoryImpl` does the same.
  Future<Either<Failure, DesignTicketFile>> _upload(
    String url, {
    required String path,
    required String filename,
    String? note,
    ProgressCallback? onProgress,
  }) {
    return safeRequest<DesignTicketFile>(
      () async => _dio.post(
        url,
        data: FormData.fromMap(<String, dynamic>{
          'file': await MultipartFile.fromFile(path, filename: filename),
          if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        }),
        onSendProgress: onProgress,
      ),
      parse: (data) => DesignTicketFile.fromJson(data! as Map<String, dynamic>),
    );
  }
}
