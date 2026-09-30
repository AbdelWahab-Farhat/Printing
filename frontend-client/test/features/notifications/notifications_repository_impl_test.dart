import 'dart:convert';
import 'dart:typed_data';

import 'package:dayaa_client/features/notifications/repositories/notifications_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers every request with the success envelope and remembers what was asked.
class _RecordingAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);

    return ResponseBody.fromString(
      jsonEncode({'status': true, 'message': 'تم', 'data': null}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// العقدُ مع الخادم: أين يُسجَّل الجهاز، وبأيّ حقول.
///
/// Arrange - Act - Assert throughout.
void main() {
  late _RecordingAdapter adapter;
  late NotificationsRepositoryImpl repository;

  setUp(() {
    adapter = _RecordingAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1'))
      ..httpClientAdapter = adapter;
    repository = NotificationsRepositoryImpl(dio);
  });

  test('registering posts the token and the platform to the customer route', () async {
    // Arrange
    const token = 'fcm-token-1';

    // Act
    final result = await repository.registerDevice(token: token, platform: 'ios');

    // Assert
    expect(result.isRight(), isTrue);
    final request = adapter.requests.single;
    expect(request.method, 'POST');
    expect(request.path, '/client/notifications/devices');
    expect(request.data, {'token': token, 'platform': 'ios'});
  });

  test('releasing sends the token in the body of a DELETE, never in the URL', () async {
    // Arrange — a credential-shaped string in a URL lands in every access log on the way.
    const token = 'fcm-token-1';

    // Act
    final result = await repository.releaseDevice(token: token);

    // Assert
    expect(result.isRight(), isTrue);
    final request = adapter.requests.single;
    expect(request.method, 'DELETE');
    expect(request.path, '/client/notifications/devices');
    expect(request.data, {'token': token});
    expect(request.uri.query, isEmpty);
  });
}
