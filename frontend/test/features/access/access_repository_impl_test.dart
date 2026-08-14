import 'dart:convert';
import 'dart:typed_data';

import 'package:dayaa/features/access/repositories/access_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// What actually goes down the wire when an employee is changed.
///
/// **Why this test exists.** An employee is changed through four endpoints, one per guard —
/// details, password, salary, activation — and getting the *path* wrong is the failure mode
/// that looks like a permissions bug: a salary sent to `PUT /users/{id}` is silently ignored by
/// a server that never validated it. Asserting on the repository's return value would prove
/// none of that; this reads the request Dio actually produced.
///
/// Arrange - Act - Assert throughout.
class _CapturingAdapter implements HttpClientAdapter {
  String? body;
  String? path;
  String? method;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    path = options.path;
    method = options.method;

    if (requestStream != null) {
      final chunks = await requestStream.toList();
      body = utf8.decode(chunks.expand((chunk) => chunk).toList());
    }

    return ResponseBody.fromString(
      jsonEncode({
        'status': true,
        'message': 'تم',
        'data': {
          'id': 4,
          'name': 'محمد عز الدين',
          'phone': '0944909851',
          'email': 'mohamed@printing.ly',
          'employee_code': 'E4',
          'is_active': true,
          'salary': '2500.00',
        },
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _CapturingAdapter adapter;
  late AccessRepositoryImpl repository;

  Map<String, dynamic> sent() => jsonDecode(adapter.body!) as Map<String, dynamic>;

  setUp(() {
    adapter = _CapturingAdapter();
    repository = AccessRepositoryImpl(
      Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))..httpClientAdapter = adapter,
    );
  });

  test('correcting the details sends three keys and never a password', () async {
    // Arrange

    // Act
    await repository.updateUser(
      userId: 4,
      name: 'محمد عز الدين',
      email: 'mohamed@printing.ly',
      phone: '0944909851',
    );

    // Assert — a password here would be ignored by the server anyway, and sending one would put
    // a live credential in a log for nothing.
    expect(adapter.method, 'PUT');
    expect(adapter.path, '/users/4');
    expect(sent().keys.toSet(), {'name', 'email', 'phone'});
  });

  test('the password goes to its own path, with the confirmation Laravel looks for', () async {
    // Arrange

    // Act
    await repository.setUserPassword(4, 'كلمة-جديدة');

    // Assert
    expect(adapter.path, '/users/4/password');
    expect(sent()['password'], 'كلمة-جديدة');
    expect(sent()['password_confirmation'], 'كلمة-جديدة');
  });

  test('the salary goes to its own path, guarded by its own permission', () async {
    // Arrange

    // Act
    await repository.setUserSalary(4, '3000');

    // Assert
    expect(adapter.path, '/users/4/salary');
    expect(sent()['salary'], '3000');
  });

  test('clearing the salary sends the key with a null rather than omitting it', () async {
    // Arrange — the endpoint requires the key to be `present`: an explicit null is how «لم
    // يُحدَّد» is recorded, and an absent one is indistinguishable from a half-built request.
    // Act
    await repository.setUserSalary(4, null);

    // Assert
    final body = sent();

    expect(body.containsKey('salary'), isTrue);
    expect(body['salary'], isNull);
  });

  test('stopping an account is its own request, not a field on the details', () async {
    // Arrange

    // Act
    await repository.setUserActivation(4, isActive: false);

    // Assert — which is the safety property: because saving an edit never carries `is_active`,
    // correcting a stopped employee's number can never let them back in.
    expect(adapter.path, '/users/4/activation');
    expect(sent()['is_active'], isFalse);
  });

  test('reading one employee asks for that employee', () async {
    // Arrange

    // Act
    final result = await repository.user(4);

    // Assert
    expect(adapter.method, 'GET');
    expect(adapter.path, '/users/4');
    expect(result.isRight(), isTrue);
  });
}
