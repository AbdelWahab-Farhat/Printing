import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dayaa/core/files/picked_file.dart';
import 'package:dayaa/features/design_tickets/repositories/design_ticket_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// ما يذهب على السلك حين يُنشأ طلب التصميم — بمرفقاته وبلاها.
///
/// يقرأ البايتات التي أنتجها Dio فعلاً عبر محوّلٍ مستبدَل، فالتأكيدات عن الطلب لا عن النموذج.
///
/// Arrange - Act - Assert في كل اختبار.
class _CapturingAdapter implements HttpClientAdapter {
  String? body;
  String? contentType;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    contentType = options.contentType;

    if (requestStream != null) {
      final chunks = await requestStream.toList();
      body = utf8.decode(chunks.expand((chunk) => chunk).toList(), allowMalformed: true);
    }

    // الجواب لا يهمّ هنا — المهمّ ما أُرسل.
    return ResponseBody.fromString(
      jsonEncode({'status': false, 'message': 'البيانات غير صحيحة'}),
      422,
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
  late DesignTicketRepositoryImpl repository;
  late Directory folder;

  setUp(() {
    adapter = _CapturingAdapter();
    repository = DesignTicketRepositoryImpl(
      Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))..httpClientAdapter = adapter,
    );
    folder = Directory.systemTemp.createTempSync('design-ticket-wire');
  });

  tearDown(() => folder.deleteSync(recursive: true));

  PickedFile file(String name) {
    final path = '${folder.path}/$name';
    File(path).writeAsBytesSync([1, 2, 3]);

    return PickedFile(path: path, name: name, sizeBytes: 3);
  }

  test('a request with files goes as multipart, each file under files[] in the order picked', () async {
    // Arrange
    final files = [file('logo.png'), file('menu.pdf')];

    // Act
    await repository.create(
      customerId: 4,
      title: 'تصميم كيس',
      description: 'الشعار في المنتصف',
      files: files,
    );

    // Assert — `files[]` لكلّ ملف: بلا القوسين يُبقي PHP آخرها وحده.
    expect(adapter.contentType, startsWith('multipart/form-data'));
    final body = adapter.body!;
    expect('name="files[]"'.allMatches(body).length, 2);
    expect(body.indexOf('filename="logo.png"'), lessThan(body.indexOf('filename="menu.pdf"')));
    expect(body, contains('name="customer_id"'));
    expect(body, contains('تصميم كيس'));
  });

  test('a request without files stays JSON, as it always was', () async {
    // Arrange — nothing to pick.

    // Act
    await repository.create(customerId: 4, title: 'تصميم كيس', description: 'الشعار في المنتصف');

    // Assert
    expect(adapter.contentType, isNot(startsWith('multipart/form-data')));
    expect(jsonDecode(adapter.body!), {
      'customer_id': 4,
      'title': 'تصميم كيس',
      'description': 'الشعار في المنتصف',
    });
  });
}
