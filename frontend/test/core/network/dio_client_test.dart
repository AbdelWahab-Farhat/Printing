import 'package:dayaa/core/network/auth_interceptor.dart';
import 'package:dayaa/core/network/dio_client.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/storage/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

/// Who is allowed to read the wire.
///
/// **This is a security rule with a test, not a comment with a hope.** Every request and every
/// response on this client carries a bearer token and, once signed in, real customer records —
/// 574 people's names and telephone numbers. Printed in a shipped build they go to logcat, where
/// on Android they are readable over `adb` by anyone holding the phone.
///
/// The rule was previously written as `AppConfig.isDev && !kReleaseMode`, which tied it to the
/// *flavour*. That had it backwards in both directions: a debug build pointed at production —
/// which is how the app is actually developed against a real server — printed nothing and was
/// undebuggable, while a `dev`-flavour build compiled in profile mode would happily print.
/// The build mode is the fact that matters, so the build mode is what decides.
///
/// Arrange - Act - Assert throughout.
void main() {
  setUp(() => dotenv.testLoad(fileInput: 'BASE_URL=https://api.example.test/api/v1'));

  tearDown(() => dotenv.env.clear());

  Dio build({bool? asDebugBuild}) => DioClient.create(
    tokens: TokenStorage(const FlutterSecureStorage()),
    session: Session(),
    onUnauthorized: () async {},
    refreshSession: () async {},
    isDebugBuild: asDebugBuild ?? kDebugMode,
  );

  group('who prints the wire', () {
    test('a release build never does', () {
      // Arrange — the one case that must never regress: bodies hold the bearer token and the
      // customer book, and a shipped build has no business narrating either.
      // Act
      final prints = DioClient.logsTraffic(isDebugBuild: false);

      // Assert
      expect(prints, isFalse);
    });

    test('a debug build does, whatever server it is pointed at', () {
      // Arrange — the flavour is deliberately not consulted. Developing against the production
      // API is the normal case now that `dev` points at a laptop nobody is running.
      // Act
      final prints = DioClient.logsTraffic(isDebugBuild: true);

      // Assert
      expect(prints, isTrue);
    });
  });

  group('the client it builds', () {
    test('carries the auth interceptor', () {
      // Arrange — without it every authenticated call is a 401, and the failure looks like a
      // server problem rather than a wiring one.
      // Act
      final dio = build();

      // Assert
      expect(dio.interceptors.whereType<AuthInterceptor>(), hasLength(1));
    });

    test('carries exactly one logger under test, because tests are a debug build', () {
      // Arrange — `flutter test` runs in debug, so this asserts the live wiring and not just
      // the predicate above. Exactly one: a logger added twice prints every request twice.
      // Act
      final dio = build();

      // Assert
      expect(dio.interceptors.whereType<PrettyDioLogger>(), hasLength(1));
    });

    test('the shipped client carries no logger at all', () {
      // Arrange — **the assertion the other three could not make.** The two predicate tests
      // above check a function; this checks the object the app actually gets. Without the
      // `isDebugBuild` seam it could not be written, because `flutter test` is always a debug
      // build — and while it could not be written, replacing the guard with `if (true)` left
      // the whole suite green. That mutation now fails here.
      // Act
      final dio = build(asDebugBuild: false);

      // Assert — the auth interceptor survives; nothing that prints does.
      expect(dio.interceptors.whereType<PrettyDioLogger>(), isEmpty);
      expect(dio.interceptors.whereType<AuthInterceptor>(), hasLength(1));
    });

    test('reads its base URL from the loaded env rather than a constant', () {
      // Arrange
      // Act
      final dio = build();

      // Assert
      expect(dio.options.baseUrl, 'https://api.example.test/api/v1');
    });
  });
}
