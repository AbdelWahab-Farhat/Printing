import 'dart:convert';
import 'dart:typed_data';

import 'package:dayaa_client/features/social_links/models/social_link.dart';
import 'package:dayaa_client/features/social_links/repositories/social_link_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// يجيب كل طلبٍ بالمغلّف الناجح وبالقائمة المعطاة، ويتذكّر ما طُلب.
class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this.data);

  final Object? data;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);

    return ResponseBody.fromString(
      jsonEncode({'status': true, 'message': 'تم حفظ الروابط', 'data': data}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// العقد مع الخادم: أين تُقرأ الروابط وتُحفظ، وبأيّ جسم.
///
/// Arrange - Act - Assert throughout.
void main() {
  const saved = [
    {'id': 12, 'url': 'https://facebook.com/alnoor.print'},
    {'id': 13, 'url': 'https://instagram.com/alnoor.print'},
  ];

  SocialLinkRepositoryImpl repositoryOver(_RecordingAdapter adapter) {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1'))
      ..httpClientAdapter = adapter;

    return SocialLinkRepositoryImpl(dio);
  }

  test('the list is read from the customer’s own route, in the server’s order', () async {
    // Arrange
    final adapter = _RecordingAdapter(saved);
    final repository = repositoryOver(adapter);

    // Act
    final result = await repository.list();

    // Assert
    final request = adapter.requests.single;
    expect(request.method, 'GET');
    expect(request.path, '/client/social-links');
    expect(result.getOrElse(() => []), const [
      SocialLink(id: 12, url: 'https://facebook.com/alnoor.print'),
      SocialLink(id: 13, url: 'https://instagram.com/alnoor.print'),
    ]);
  });

  test('saving puts the whole set: a kept link with its id, a new one without', () async {
    // Arrange
    final adapter = _RecordingAdapter(saved);
    final repository = repositoryOver(adapter);

    // Act
    final result = await repository.save(const [
      (id: 12, url: 'https://facebook.com/alnoor.print'),
      (id: null, url: 'https://instagram.com/alnoor.print'),
    ]);

    // Assert — مُعرِّفٌ `null` يُحذف من الجسم ولا يُرسل: الخادم يقرأ غيابه «رابطٌ جديد».
    final request = adapter.requests.single;
    expect(request.method, 'PUT');
    expect(request.path, '/client/social-links');
    expect(request.data, {
      'social_links': [
        {'id': 12, 'url': 'https://facebook.com/alnoor.print'},
        {'url': 'https://instagram.com/alnoor.print'},
      ],
    });
    expect(result.getOrElse(() => []).length, 2);
  });

  test('saving nothing still sends the key, as an empty list — that is «remove them all»', () async {
    // Arrange
    final adapter = _RecordingAdapter(const <Object>[]);
    final repository = repositoryOver(adapter);

    // Act
    final result = await repository.save(const []);

    // Assert
    expect(adapter.requests.single.data, {'social_links': <Object>[]});
    expect(result.getOrElse(() => [const SocialLink(id: 0, url: '')]), isEmpty);
  });
}
