import 'package:freezed_annotation/freezed_annotation.dart';

part 'failure.freezed.dart';

/// Anything that stopped a request from producing data.
///
/// A sealed union rather than a bag of nullable fields, so the UI is forced to decide what to
/// do about each kind. The distinction that matters most is [Failure.network] versus
/// [Failure.server]: the first means **the server never answered**, so for a non-idempotent
/// call (creating an order) retrying may duplicate it, while the second means the server
/// answered and said no.
@freezed
sealed class Failure with _$Failure {
  /// The server answered and refused. `message` is the API's own Arabic text.
  const factory Failure.server({
    required String message,
    int? statusCode,

    /// Laravel's `errors` map, keyed by field — render these under the inputs rather than
    /// as one toast, which is the whole reason the API bothers to send them separately.
    Map<String, List<String>>? fieldErrors,
  }) = ServerFailure;

  /// Timed out or the connection dropped — the request may or may not have been applied.
  const factory Failure.network({required String message}) = NetworkFailure;

  /// 401. The token is gone or expired; the session is over.
  const factory Failure.unauthorized({required String message}) = UnauthorizedFailure;

  /// 403. Authenticated, but this account lacks the permission.
  const factory Failure.forbidden({required String message}) = ForbiddenFailure;

  /// A bug on our side — a parse error, a shape the API never promised.
  const factory Failure.unexpected({required String message}) = UnexpectedFailure;
}

/// The Arabic the user actually reads. Defined as constants so a test can assert on them and
/// so the same wording is never re-typed slightly differently in two places.
abstract final class FailureMessages {
  static const String generic = 'حدث خطأ ما، يرجى المحاولة لاحقاً';
  static const String timeout = 'انتهى وقت الاتصال بالخادم، حاول مجدداً';
  static const String noConnection = 'تعذّر الاتصال بالإنترنت، تحقّق من اتصالك وحاول مجدداً';
  static const String unauthorized = 'انتهت الجلسة، يرجى تسجيل الدخول مجدداً';
  static const String forbidden = 'ليس لديك صلاحية لتنفيذ هذا الإجراء';
  static const String notFound = 'العنصر المطلوب غير موجود';
}

extension FailureMessage on Failure {
  /// The one line to show the user, whatever kind of failure this is.
  String get message => switch (this) {
    ServerFailure(:final message) => message,
    NetworkFailure(:final message) => message,
    UnauthorizedFailure(:final message) => message,
    ForbiddenFailure(:final message) => message,
    UnexpectedFailure(:final message) => message,
  };

  /// True when the request may never have reached the server. Callers creating something
  /// should offer "retry" carefully here — see the note on [Failure.network].
  bool get isNetwork => this is NetworkFailure;
}
