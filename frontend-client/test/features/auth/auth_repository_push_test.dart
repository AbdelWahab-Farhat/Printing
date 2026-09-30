import 'dart:convert';
import 'dart:typed_data';

import 'package:dayaa_client/core/push/push_service.dart';
import 'package:dayaa_client/core/storage/token_storage.dart';
import 'package:dayaa_client/features/auth/repositories/auth_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPush extends Mock implements PushService {}

class _MockTokens extends Mock implements TokenStorage {}

/// Answers by path, and remembers every request in the order it was made.
class _ScriptedAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];

  /// Paths answered with a 401 instead of the success envelope.
  final Set<String> refused = {};

  static const Map<String, dynamic> _customer = {'id': 7, 'name': 'سالم', 'phone': '0911234567'};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);

    if (refused.contains(options.path)) {
      return _json({'status': false, 'message': 'بيانات الدخول غير صحيحة'}, 401);
    }

    final data = switch (options.path) {
      '/client/auth/login' || '/client/auth/register' => {'customer': _customer, 'token': 't-1'},
      '/client/auth/me' => _customer,
      _ => null,
    };

    return _json({'status': true, 'message': 'تم', 'data': data}, 200);
  }

  ResponseBody _json(Map<String, dynamic> body, int status) => ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}

/// متى يُسجَّل هاتفُ العميل ومتى يُحرَّر — في المستودع، لا في شاشة قد تنسى.
///
/// Arrange - Act - Assert throughout.
void main() {
  late _MockPush push;
  late _MockTokens tokens;
  late _ScriptedAdapter adapter;
  late AuthRepositoryImpl repository;

  setUp(() {
    push = _MockPush();
    tokens = _MockTokens();
    adapter = _ScriptedAdapter();

    when(() => push.register(askPermission: any(named: 'askPermission')))
        .thenAnswer((_) async => true);
    when(() => push.release()).thenAnswer((_) async {});
    when(() => tokens.write(any())).thenAnswer((_) async {});
    when(() => tokens.clear()).thenAnswer((_) async {});

    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1'))
      ..httpClientAdapter = adapter;
    repository = AuthRepositoryImpl(dio, tokens, push);
  });

  group('signing in', () {
    test('registers the phone and asks the OS — the one moment a prompt is earned', () async {
      // Arrange
      // Act
      final result = await repository.login(phone: '0911234567', password: 'secret');

      // Assert
      expect(result.isRight(), isTrue);
      verify(() => push.register()).called(1);
    });

    test('a refused sign-in registers nothing', () async {
      // Arrange
      adapter.refused.add('/client/auth/login');

      // Act
      final result = await repository.login(phone: '0911234567', password: 'wrong');

      // Assert
      expect(result.isLeft(), isTrue);
      verifyNever(() => push.register(askPermission: any(named: 'askPermission')));
    });

    test('a new account is registered the same way', () async {
      // Arrange
      // Act
      final result = await repository.register(
        name: 'سالم',
        phone: '0911234567',
        password: 'secret',
      );

      // Assert
      expect(result.isRight(), isTrue);
      verify(() => push.register()).called(1);
    });
  });

  group('opening the app on a stored session', () {
    test('re-registers without prompting', () async {
      // Arrange — the token may have rotated while the app was closed, or the customer may
      // have allowed notifications from the phone's settings since.
      // Act
      final result = await repository.currentCustomer();

      // Assert
      expect(result.isRight(), isTrue);
      verify(() => push.register(askPermission: false)).called(1);
      verifyNever(() => push.register());
    });

    test('a dead session registers nothing', () async {
      // Arrange
      adapter.refused.add('/client/auth/me');

      // Act
      await repository.currentCustomer();

      // Assert
      verifyNever(() => push.register(askPermission: any(named: 'askPermission')));
    });
  });

  group('signing out', () {
    test('releases the phone before the logout request and before the token is cleared', () async {
      // Arrange — releasing is itself an authenticated call: after either of those it would
      // 401, and a shared phone would go on receiving the previous customer's orders.
      var requestsBeforeRelease = -1;
      var tokenClearedBeforeRelease = false;
      var cleared = false;
      when(() => tokens.clear()).thenAnswer((_) async => cleared = true);
      when(() => push.release()).thenAnswer((_) async {
        requestsBeforeRelease = adapter.requests.length;
        tokenClearedBeforeRelease = cleared;
      });

      // Act
      await repository.logout();

      // Assert
      verify(() => push.release()).called(1);
      expect(requestsBeforeRelease, 0);
      expect(tokenClearedBeforeRelease, isFalse);
      expect(adapter.requests.single.path, '/client/auth/logout');
    });
  });
}
