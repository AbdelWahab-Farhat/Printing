import 'dart:async';
import 'dart:io';

import 'package:dayaa/core/voice/voice_recorder.dart';
import 'package:flutter_test/flutter_test.dart';

/// ميكروفونٌ مزيّف: يجيب عن الإذن بعد [answerAfter]، ويكتب ملفاً حين يتوقّف.
class _FakeEngine implements VoiceRecorderEngine {
  _FakeEngine({this.granted = true, this.answerAfter = Duration.zero, this.starts = true});

  final bool granted;
  final Duration answerAfter;
  final bool starts;
  final StreamController<double> levelsOut = StreamController<double>.broadcast();
  String? recordingAt;

  @override
  Future<bool> hasPermission() async {
    if (answerAfter > Duration.zero) await Future<void>.delayed(answerAfter);

    return granted;
  }

  @override
  Future<bool> start(String path) async {
    recordingAt = path;

    return starts;
  }

  @override
  Stream<double> levels() => levelsOut.stream;

  @override
  Future<String?> stop() async {
    final path = recordingAt;
    if (path == null) return null;

    File(path).writeAsBytesSync(List<int>.filled(2048, 7));

    return path;
  }

  @override
  Future<void> dispose() async => levelsOut.close();
}

/// المسجّل: مَن يُسأل ومتى يُرفض، وما يُرجعه تسجيلٌ تمّ — أو لا يُرجعه تسجيلٌ أقصر من رسالة.
///
/// Arrange - Act - Assert throughout.
void main() {
  late Directory folder;
  late DateTime now;

  setUp(() {
    folder = Directory.systemTemp.createTempSync('voice_recorder_test');
    now = DateTime(2026, 10, 21, 9);
  });

  tearDown(() {
    if (folder.existsSync()) folder.deleteSync(recursive: true);
  });

  VoiceRecorder build(_FakeEngine engine) =>
      VoiceRecorder(engine: engine, now: () => now, folder: () async => folder);

  test('a held recording comes back with its length and 48 bars', () async {
    // Arrange
    final engine = _FakeEngine();
    final recorder = build(engine);

    // Act
    final started = await recorder.start();
    engine.levelsOut
      ..add(0.2)
      ..add(0.9)
      ..add(0.4);
    await Future<void>.delayed(Duration.zero);
    now = now.add(const Duration(seconds: 3));
    final recording = await recorder.stop();

    // Assert
    expect(started, VoiceStart.started);
    expect(recording, isNotNull);
    expect(recording!.duration, const Duration(seconds: 3));
    expect(recording.waveform, hasLength(VoiceRecorder.waveformBars));
    expect(recording.waveform.reduce((a, b) => a > b ? a : b), 100);
    expect(recording.path.endsWith('.m4a'), isTrue);
    expect(recording.path.startsWith('${folder.path}/internal_voice/'), isTrue);
    await recorder.dispose();
  });

  test('a press shorter than a message gives nothing and leaves no file', () async {
    // Arrange
    final engine = _FakeEngine();
    final recorder = build(engine);
    await recorder.start();

    // Act
    now = now.add(const Duration(milliseconds: 300));
    final recording = await recorder.stop();

    // Assert
    expect(recording, isNull);
    expect(File(engine.recordingAt!).existsSync(), isFalse);
    await recorder.dispose();
  });

  test('a «no» that comes back at once was given before: only Settings can change it', () async {
    // Arrange
    final recorder = build(_FakeEngine(granted: false));

    // Act
    final started = await recorder.start();

    // Assert
    expect(started, VoiceStart.blocked);
    expect(recorder.isRecording, isFalse);
    await recorder.dispose();
  });

  test('a «no» given at the prompt is just refused', () async {
    // Arrange
    final recorder = build(
      _FakeEngine(granted: false, answerAfter: const Duration(milliseconds: 450)),
    );

    // Act
    final started = await recorder.start();

    // Assert
    expect(started, VoiceStart.refused);
    await recorder.dispose();
  });

  test('a microphone that does not start is unavailable', () async {
    // Arrange
    final recorder = build(_FakeEngine(starts: false));

    // Act
    final started = await recorder.start();

    // Assert
    expect(started, VoiceStart.unavailable);
    expect(recorder.isRecording, isFalse);
    await recorder.dispose();
  });

  test('cancelling throws the recording away', () async {
    // Arrange
    final engine = _FakeEngine();
    final recorder = build(engine);
    await recorder.start();

    // Act
    await recorder.cancel();

    // Assert
    expect(recorder.isRecording, isFalse);
    expect(File(engine.recordingAt!).existsSync(), isFalse);
    await recorder.dispose();
  });

  group('the waveform', () {
    test('each bar is the loudest of its slice, scaled to the recording\'s own peak', () {
      // Act
      final bars = downsampleWaveform([0.1, 0.5, 0.2, 0.25], 2);

      // Assert
      expect(bars, [100, 52]);
    });

    test('silence is a line, not a gap', () {
      // Assert
      expect(downsampleWaveform([0, 0, 0], 3), [4, 4, 4]);
      expect(downsampleWaveform([], 4), [4, 4, 4, 4]);
    });
  });
}
