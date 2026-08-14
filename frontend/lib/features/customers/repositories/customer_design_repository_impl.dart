import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/api_endpoints.dart';
import 'package:dayaa/core/network/safe_request.dart';
import 'package:dayaa/features/customers/models/customer_design.dart';
import 'package:dayaa/features/customers/repositories/customer_design_repository.dart';
import 'package:dio/dio.dart';

/// Fulfils [CustomerDesignRepository] over HTTP.
class CustomerDesignRepositoryImpl implements CustomerDesignRepository {
  const CustomerDesignRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Either<Failure, List<CustomerDesign>>> designs(int customerId) {
    return safeRequest<List<CustomerDesign>>(
      () => _dio.get(CustomerEndpoints.designs(customerId)),
      // `safeRequest`, not `safePaginatedRequest`: `data` is the bare list, with no `meta`
      // beside it. Putting this through the paginated parser would report a malformed response
      // for a reply that is exactly what the API promised.
      parse: (data) => (data! as List)
          .whereType<Map<String, dynamic>>()
          .map(CustomerDesign.fromJson)
          .toList(growable: false),
    );
  }

  @override
  Future<Either<Failure, CustomerDesign>> upload(
    int customerId, {
    required String path,
    required String filename,
    String? label,
    String? notes,
    void Function(int sent, int total)? onProgress,
  }) {
    return safeRequest<CustomerDesign>(
      () async => _dio.post(
        CustomerEndpoints.designs(customerId),
        // `fromFile` streams from disk. `fromBytes` would hold a 25 MB design in memory for the
        // length of the upload, and a mid-range phone kills the app for less.
        data: FormData.fromMap(<String, dynamic>{
          'file': await MultipartFile.fromFile(path, filename: filename),
          // Omitted rather than sent empty: `nullable|string` on the server treats `''` as a
          // present-but-blank name, which would overwrite the filename fallback with nothing.
          if (label != null && label.trim().isNotEmpty) 'label': label.trim(),
          if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        }),
        onSendProgress: onProgress,
      ),
      // 201 for a new file, 200 for one the server already had — the same body either way, and
      // the caller does not need to know which. Its answer is *the design that now exists*.
      parse: (data) => CustomerDesign.fromJson(data! as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, Uint8List>> fileBytes(String fileUrl) {
    return safeDownload(
      // The URL is absolute and may point at the storage host rather than at our API, so it is
      // passed whole — Dio leaves an absolute address alone and the `baseUrl` is not prefixed.
      // `responseType: bytes` is what stops Dio trying to decode a PNG as JSON.
      () => _dio.get<List<int>>(
        fileUrl,
        options: Options(
          responseType: ResponseType.bytes,
          // A print-ready file is megabytes over a phone connection; the client's default
          // receive timeout is tuned for a JSON page and would abandon it halfway.
          receiveTimeout: const Duration(minutes: 2),
        ),
      ),
    );
  }

  @override
  Future<Either<Failure, CustomerDesign>> rename(
    int customerId,
    int designId, {
    required String label,
    String? notes,
  }) {
    return safeRequest<CustomerDesign>(
      () => _dio.put(
        CustomerEndpoints.design(customerId, designId),
        // Both keys always, and that is the point of `sometimes` on the server: a note the user
        // cleared must arrive as null to be cleared, which an "omit when empty" would prevent
        // forever.
        data: <String, dynamic>{
          'label': label.trim(),
          'notes': (notes?.trim().isEmpty ?? true) ? null : notes!.trim(),
        },
      ),
      parse: (data) => CustomerDesign.fromJson(data! as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, String>> remove(int customerId, int designId) {
    // A command: the answer is the server's message, because there is no body to parse and
    // nothing left to show.
    return safeCommand(() => _dio.delete(CustomerEndpoints.design(customerId, designId)));
  }
}
