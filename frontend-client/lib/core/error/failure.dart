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
  ///
  /// **`cause` is the exception's own words**, carried so the second line of the toast can say
  /// which of several steps failed. Without it «تعذّر إنشاء ملف الفاتورة» was reported off a
  /// phone with nothing to work from: a missing asset, a font that would not parse and a
  /// filesystem that refused the write all reached the user as one sentence. Optional, because
  /// most unexpected failures are raised by code that already knows what it is saying.
  const factory Failure.unexpected({required String message, String? cause}) = UnexpectedFailure;
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

  /// The second line: every field message the server sent, one per line.
  ///
  /// Null when there is nothing to add — no `errors` map, or a map that only repeats [message],
  /// which is what an endpoint that sends no envelope message produces once the mapper has
  /// flattened its errors into one. Saying the same sentence twice in one toast reads as a bug.
  ///
  /// A screen with an input to hang these under should render them there instead — that is the
  /// whole reason the API bothers to key them by field. This is for the screens that have
  /// nowhere better, and for fields no form on the phone actually shows.
  ///
  /// **On an [UnexpectedFailure] it is the exception itself**, in English and unedited. Nobody
  /// enjoys reading `MissingPluginException` off a phone, but a fault nobody can name is worse:
  /// this is the line that gets read out over the phone when something the app was never meant
  /// to do happens on somebody else's device.
  String? get details => switch (this) {
    ServerFailure(:final fieldErrors?) => _joined(fieldErrors, except: message),
    UnexpectedFailure(:final cause?) => cause,
    _ => null,
  };
}

String? _joined(Map<String, List<String>> fieldErrors, {required String except}) {
  final lines = <String>[
    for (final messages in fieldErrors.values)
      for (final line in messages)
        if (line.trim() != except.trim()) line.trim(),
  ];

  return lines.isEmpty ? null : lines.join('\n');
}
