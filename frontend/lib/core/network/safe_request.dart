/// The single place a `DioException` is allowed to be caught.
///
/// Everything below this line throws; everything above it receives an `Either`. That is the
/// same split the backend makes — one boundary turns a failure into a value, and no data
/// source, repository or Cubit is allowed to have its own `try`/`catch` and quietly decide
/// something different. A screen stuck on a spinner with no message is almost always a
/// `catch` somebody added because it "shouldn't happen".
///
/// Every API response has the same envelope, so it is unwrapped exactly once — here:
///
/// ```json
/// { "status": true, "message": "تم بنجاح", "data": { }, "meta": { } }
/// ```
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dio/dio.dart';

/// Runs [send] and hands the envelope's `data` to [parse].
///
/// ```dart
/// safeRequest(
///   () => _dio.get(CityEndpoints.index),
///   parse: (data) => (data as List).map((e) => CityModel.fromJson(e)).toList(),
/// );
/// ```
Future<Either<Failure, T>> safeRequest<T>(
  Future<Response<dynamic>> Function() send, {
  required T Function(dynamic data) parse,
}) async {
  return _guard(() async {
    final response = await send();
    final envelope = _envelopeOf(response);

    return parse(envelope['data']);
  });
}

/// The same guarantees, for a server that is not ours.
///
/// [safeRequest] unwraps `{status, message, data}`, which is our API's contract and nobody
/// else's. A geocoder answers a bare JSON array; putting it through the envelope parser would
/// report "الرد من الخادم غير مفهوم" for a response that is perfectly correct.
///
/// So the body is handed to [parse] untouched. Everything else is shared: the same timeout and
/// connection failures become the same [Failure] cases, and `try`/`catch` still lives only in
/// this file.
Future<Either<Failure, T>> safeForeignRequest<T>(
  Future<Response<dynamic>> Function() send, {
  required T Function(dynamic body) parse,
}) async {
  return _guard(() async {
    final response = await send();

    return parse(response.data);
  });
}

/// The paginated twin: `data` is the list, `meta` sits beside it.
Future<Either<Failure, Paginated<T>>> safePaginatedRequest<T>(
  Future<Response<dynamic>> Function() send, {
  required T Function(Map<String, dynamic> json) parseItem,
}) async {
  return _guard(() async {
    final response = await send();
    final envelope = _envelopeOf(response);

    final data = envelope['data'];
    if (data is! List) {
      throw const _MalformedResponse('توقعنا قائمة من الخادم');
    }

    final meta = envelope['meta'];
    if (meta is! Map<String, dynamic>) {
      throw const _MalformedResponse('الرد لا يحتوي على بيانات الصفحات');
    }

    return Paginated<T>(
      items: data.whereType<Map<String, dynamic>>().map(parseItem).toList(growable: false),
      meta: PageMeta.fromJson(meta),
      // Handed on untouched. Some endpoints put facts about the whole filtered set beside the
      // page numbers — see `Paginated.extraMeta` — and this layer is the wrong place to decide
      // which of them matter.
      extraMeta: meta,
    );
  });
}

/// A call whose answer is a **file**, not JSON.
///
/// A design's bytes come back raw — no envelope to unwrap and nothing to parse — so neither
/// [safeRequest] nor [safeForeignRequest] fits: the first would look for `data` in a PNG, and
/// the second would hand back a `List<int>` typed as `dynamic` at every call site.
///
/// It goes through the same guard as everything else, which is the whole point: a signed link
/// that expired is a 403 and a dropped connection is a network failure, and both have to reach
/// the screen as the same [Failure] the rest of the app already knows how to show.
Future<Either<Failure, Uint8List>> safeDownload(
  Future<Response<List<int>>> Function() send,
) async {
  return _guard(() async {
    final response = await send();
    final bytes = response.data;

    if (bytes == null || bytes.isEmpty) {
      throw const _MalformedResponse('الملف الذي وصل فارغ');
    }

    return Uint8List.fromList(bytes);
  });
}

/// A call whose answer is the *message*, not a body — logout, delete.
Future<Either<Failure, String>> safeCommand(Future<Response<dynamic>> Function() send) async {
  return _guard(() async {
    final response = await send();
    final envelope = _envelopeOf(response);

    return _asText(envelope['message']) ?? 'تم بنجاح';
  });
}

// ─────────────────────────────────────────────────────────────────────────────

/// Turns every throw into a typed [Failure]. Nothing escapes: an exception that got past here
/// would leave the calling Cubit in `loading` forever.
Future<Either<Failure, T>> _guard<T>(Future<T> Function() run) async {
  try {
    return Right(await run());
  } on DioException catch (e) {
    return Left(_failureFrom(e));
  } on _MalformedResponse catch (e) {
    return Left(Failure.unexpected(message: e.message));
  } catch (_) {
    // A parse error in `parse`: our bug, not the server's. Deliberately not rethrown —
    // the user gets a message instead of a frozen screen, and the crash reporter is where
    // this belongs once one is wired up.
    return const Left(Failure.unexpected(message: FailureMessages.generic));
  }
}

Failure _failureFrom(DioException e) {
  switch (e.type) {
    // The server never answered. Kept apart from a refusal because for a non-idempotent
    // call, "retry" here can create the thing twice.
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return const Failure.network(message: FailureMessages.timeout);

    case DioExceptionType.connectionError:
      return const Failure.network(message: FailureMessages.noConnection);

    default:
      if (e.error is SocketException) {
        return const Failure.network(message: FailureMessages.noConnection);
      }
  }

  final status = e.response?.statusCode;
  final body = e.response?.data;
  final message = serverMessage(body);

  return switch (status) {
    401 => Failure.unauthorized(message: message ?? FailureMessages.unauthorized),
    403 => Failure.forbidden(message: message ?? FailureMessages.forbidden),
    404 => Failure.server(message: message ?? FailureMessages.notFound, statusCode: status),
    _ => Failure.server(
      message: message ?? FailureMessages.generic,
      statusCode: status,
      fieldErrors: fieldErrorsOf(body),
    ),
  };
}

/// Reads the envelope off a 2xx response, or throws if the body is not one.
Map<String, dynamic> _envelopeOf(Response<dynamic> response) {
  final body = response.data;

  if (body is! Map<String, dynamic>) {
    throw const _MalformedResponse(FailureMessages.generic);
  }

  // `status: false` with a 2xx should not happen, but the envelope allows it to be said,
  // so it is honoured rather than parsed as success.
  if (body['status'] == false) {
    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      type: DioExceptionType.badResponse,
    );
  }

  return body;
}

/// The message to show, dug out of whatever the server actually sent.
///
/// The body is usually the envelope, but a 502 from nginx or Cloudflare is an HTML page, and a
/// dropped upstream can be an empty string. Indexing straight into `body['message']` throws on
/// both — and `String` really does define `operator []`, so it fails with a confusing TypeError
/// rather than a NoSuchMethodError.
String? serverMessage(dynamic body) {
  if (body == null) return null;

  if (body is String) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return null;

    // A gateway's error page is not something a customer should be shown.
    final looksLikeHtml = trimmed.startsWith('<') || trimmed.toLowerCase().contains('<html');
    if (looksLikeHtml || trimmed.length > 300) return null;

    return trimmed;
  }

  if (body is! Map) return null;

  return _asText(body['message']) ?? _flattenErrors(body['errors']);
}

/// Laravel's `errors` map, ready to hang under the matching inputs.
Map<String, List<String>>? fieldErrorsOf(dynamic body) {
  if (body is! Map) return null;

  final errors = body['errors'];
  if (errors is! Map) return null;

  final result = <String, List<String>>{};

  errors.forEach((key, value) {
    final messages = switch (value) {
      final List list => list.map((e) => e.toString().trim()).where((e) => e.isNotEmpty),
      null => const <String>[],
      _ => [value.toString().trim()].where((e) => e.isNotEmpty),
    };

    if (messages.isNotEmpty) result['$key'] = messages.toList(growable: false);
  });

  return result.isEmpty ? null : result;
}

/// Every field error joined into one readable block, for when there is nowhere to show them
/// inline.
String? _flattenErrors(dynamic errors) {
  final byField = fieldErrorsOf({'errors': errors});
  if (byField == null) return null;

  return byField.values.expand((messages) => messages).join('\n');
}

/// A value that can be shown as text, or null. Guards against a number, bool or Map landing in
/// a `String?` and throwing at the assignment rather than at the mistake.
String? _asText(dynamic value) {
  if (value == null) return null;
  if (value is String) {
    final trimmed = value.trim();

    return trimmed.isEmpty ? null : trimmed;
  }
  if (value is num || value is bool) return value.toString();

  return null;
}

/// The server answered, but not with the shape it promised.
class _MalformedResponse implements Exception {
  const _MalformedResponse(this.message);

  final String message;
}
