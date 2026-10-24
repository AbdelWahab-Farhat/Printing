import 'dart:io';

import 'package:dayaa/core/chat/chat_message.dart';
import 'package:dayaa/core/chat/outgoing_chat_payload.dart';
import 'package:dayaa/core/files/picked_file.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// جسمُ طلب الرسالة، **واحدٌ للمحادثتين**: JSON بلا ملف، وmultipart به — الصوتُ في `file`،
/// والصورُ ألبوماً في `files[]` بالترتيب الذي اختيرت به، كبريمولا.
///
/// Arrange - Act - Assert throughout.
void main() {
  late Directory temp;

  setUp(() => temp = Directory.systemTemp.createTempSync('outgoing_payload_test'));
  tearDown(() => temp.deleteSync(recursive: true));

  PickedFile file(String name) {
    final path = '${temp.path}/$name';
    File(path).writeAsBytesSync(List<int>.filled(16, 1));

    return PickedFile(path: path, name: name, sizeBytes: 16);
  }

  test('words alone are plain JSON', () async {
    // Arrange
    const message = OutgoingChatMessage(clientToken: 't1', body: '  وصلني  ', replyToMessageId: 4);

    // Act
    final payload = await outgoingChatPayload(message);

    // Assert
    expect(payload, {'client_token': 't1', 'body': 'وصلني', 'reply_to_message_id': 4});
  });

  test('an album is one request: every picture under files[], in order, with the caption', () async {
    // Arrange
    final message = OutgoingChatMessage(
      clientToken: 't2',
      body: 'الوجهان',
      images: [file('front.jpg'), file('back.jpg'), file('side.jpg')],
    );

    // Act
    final payload = await outgoingChatPayload(message) as FormData;

    // Assert
    expect(payload.files.map((entry) => entry.key), ['files[]', 'files[]', 'files[]']);
    expect(payload.files.map((entry) => entry.value.filename), ['front.jpg', 'back.jpg', 'side.jpg']);
    expect(
      payload.fields.map((entry) => '${entry.key}=${entry.value}'),
      containsAll(['client_token=t2', 'body=الوجهان']),
    );
  });

  test('a voice note is the one file, with its length and every bar of its wave', () async {
    // Arrange
    final message = OutgoingChatMessage(
      clientToken: 't3',
      voice: file('voice.m4a'),
      durationSeconds: 4,
      waveform: const [10, 20],
    );

    // Act
    final payload = await outgoingChatPayload(message) as FormData;

    // Assert
    expect(payload.files.map((entry) => entry.key), ['file']);
    expect(
      payload.fields.map((entry) => '${entry.key}=${entry.value}'),
      containsAll(['duration_seconds=4', 'waveform[]=10', 'waveform[]=20']),
    );
  });
}
