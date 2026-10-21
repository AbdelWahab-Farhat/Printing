import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:dayaa/core/voice/voice_note_cache.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// الرسالةُ الصوتية التي تُسمع في التطبيق — واحدةٌ فقط، كقاعدة تيليغرام وبريمولا: تشغيلُ الثانية
/// يوقف الأولى.
///
/// الفقاعاتُ تسمع [activeKey] — ولا يتغيّر إلا حين ينتقل التشغيل إلى رسالةٍ أخرى — والنشطةُ وحدها
/// تتبع [position]، فالرسالةُ التي تُسمع تعيد رسم أعمدتها وحدها.
///
/// **المشغّلُ يُبنى عند أوّل ضغطة لا عند الإقلاع**: أكثرُ الجلسات لا تشغّل شيئاً، والحزمةُ لا جانبَ
/// أصلياً لها تحت الاختبارات — وفيها [debugOpen] يقوم مقامه.
class VoicePlayback {
  VoicePlayback({required VoiceNoteCache cache}) : _cache = cache;

  final VoiceNoteCache _cache;

  AudioPlayer? _player;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _stateSub;

  /// الرسالةُ المحمّلة في المشغّل، أو `null`.
  final ValueNotifier<String?> activeKey = ValueNotifier(null);

  final ValueNotifier<bool> playing = ValueNotifier(false);
  final ValueNotifier<Duration> position = ValueNotifier(Duration.zero);

  /// طولُها الحقيقيّ، حين يقرؤه المشغّل.
  final ValueNotifier<Duration?> duration = ValueNotifier(null);

  /// ١× ← ١٫٥× ← ٢×، كبريمولا.
  final ValueNotifier<double> speed = ValueNotifier(1);

  /// الرسالةُ التي تنزل قبل أن تُسمع — زرُّها حلقةٌ تمتلئ، وضغطةٌ عليها تلغي.
  final ValueNotifier<String?> loadingKey = ValueNotifier(null);

  /// كم نزل منها: ٠–١، أو `null` ما دام حجمُها مجهولاً.
  final ValueNotifier<double?> loadProgress = ValueNotifier(null);

  /// آخرُ رسالةٍ لم تُفتح — زرُّها «أعد المحاولة».
  final ValueNotifier<String?> failedKey = ValueNotifier(null);

  static const List<double> speeds = [1, 1.5, 2];

  /// يرتفع مع كل ضغطةٍ جديدة ومع [stop]: تحميلٌ ينتهي بعدهما لتشغيلٍ لم يعد أحدٌ يريده.
  int _generation = 0;

  /// يقوم مقام المشغّل في الاختبارات: يسمع من أين كانت الرسالة ستُشغَّل.
  @visibleForTesting
  void Function(String path)? debugOpen;

  /// يشغّل [key] — من [localPath] (تسجيلٌ على هذا الهاتف)، أو من الذاكرة، أو بعد تنزيل [url].
  /// ضغطةٌ ثانية على التي تُسمع توقفها، وعلى الموقوفة تكملها، وعلى التي تنزل تلغيها.
  Future<void> toggle({required String key, String? localPath, String? url}) async {
    if (activeKey.value == key) {
      if (loadingKey.value == key) return stop();

      final player = _player;
      if (player != null) {
        if (playing.value) {
          await player.pause();
        } else {
          // المنتهيةُ تبدأ من أوّلها، كضغطةٍ ثانية في تيليغرام.
          if (duration.value case final total? when position.value >= total) {
            await player.seek(Duration.zero);
          }
          unawaited(player.play());
        }

        return;
      }
    }

    final generation = ++_generation;
    bool current() => generation == _generation;

    failedKey.value = null;
    loadProgress.value = null;
    activeKey.value = key;
    playing.value = false;
    position.value = Duration.zero;
    duration.value = null;

    // التي كانت تُسمع تقف عند الضغطة، لا بعد التنزيل.
    await _player?.stop();

    final path = await _pathOf(key: key, localPath: localPath, url: url, current: current);

    if (!current()) return;

    if (path == null) {
      _fail(key);

      return;
    }

    if (debugOpen case final open?) {
      loadingKey.value = null;

      return open(path);
    }

    final opened = await _open(path);

    if (!current()) return;

    loadingKey.value = null;
    if (!opened) _fail(key);
  }

  /// من أين تُسمع: التسجيلُ نفسه ما دام على الهاتف، ثم الذاكرة، ثم التنزيل — والحلقةُ لا تظهر إلا
  /// حين تدخل الشبكة، فرسالةٌ على الهاتف تُفتح أسرع من أن تومض لها حلقة.
  ///
  /// **`catch` هنا حدُّ الشبكة**: تنزيلٌ فشل أو رابطٌ انتهى يصير `null`، والزرُّ يقول «أعد».
  Future<String?> _pathOf({
    required String key,
    required String? localPath,
    required String? url,
    required bool Function() current,
  }) async {
    if (localPath != null && File(localPath).existsSync()) return localPath;

    final cacheKey = _cacheKeyOf(key);

    if (cacheKey != null) {
      final hit = await _cache.cached(cacheKey);
      if (hit != null) return hit.path;
    }

    if (url == null || cacheKey == null) return null;

    if (current()) loadingKey.value = key;

    try {
      final file = await _cache.fetch(
        cacheKey,
        url,
        onProgress: (progress) {
          if (current()) loadProgress.value = progress;
        },
      );

      return file.path;
    } on Object catch (error) {
      if (kDebugMode) debugPrint('⚠️ الرسالة الصوتية لم تنزل: $error');

      return null;
    }
  }

  /// **`catch` هنا حدُّ المنصّة**: ملفٌّ لا يقرؤه المشغّل، أو مشغّلٌ ليس في هذا البناء.
  Future<bool> _open(String path) async {
    try {
      final player = _ensurePlayer();
      await _prepareSession();
      duration.value = await player.setFilePath(path);
      await player.setSpeed(speed.value);
      unawaited(player.play());

      return true;
    } on Object catch (error) {
      if (kDebugMode) debugPrint('⚠️ الرسالة الصوتية لم تُشغَّل: $error');

      return false;
    }
  }

  void _fail(String key) {
    activeKey.value = null;
    playing.value = false;
    loadingKey.value = null;
    loadProgress.value = null;
    failedKey.value = key;
  }

  /// يقفز بالرسالة النشطة إلى [fraction] من طولها.
  Future<void> seekFraction(String key, double fraction) async {
    final player = _player;
    final total = duration.value;
    if (player == null || total == null || activeKey.value != key) return;

    final target = total * fraction.clamp(0.0, 1.0);
    position.value = target;
    await player.seek(target);
  }

  /// ١× ← ١٫٥× ← ٢× ← ١×.
  Future<void> cycleSpeed() async {
    final next = speeds[(speeds.indexOf(speed.value) + 1) % speeds.length];
    speed.value = next;
    await _player?.setSpeed(next);
  }

  /// يوقف ما يُسمع — محادثةٌ تُغلق، أو ميكروفونٌ يُفتح: رسالةٌ تُسمع فوق الميكروفون تُسجَّل فيه.
  Future<void> stop() async {
    _generation++;
    loadingKey.value = null;
    loadProgress.value = null;
    activeKey.value = null;
    playing.value = false;
    position.value = Duration.zero;
    await _player?.stop();
  }

  /// قبل كل رسالة لا مرّةً واحدة: المسجّلُ يترك iOS في وضع التشغيل والتسجيل، حيث يخرج الصوت أخفت
  /// بوضوح. `speech()` فئةُ التشغيل بنمط الكلام: مكبّرُ الصوت، والموسيقى تُخفَض.
  Future<void> _prepareSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
    await session.setActive(true);
  }

  AudioPlayer _ensurePlayer() {
    final existing = _player;
    if (existing != null) return existing;

    final player = AudioPlayer();

    _positionSub = player
        .createPositionStream(
          steps: 400,
          minPeriod: const Duration(milliseconds: 33),
          maxPeriod: const Duration(milliseconds: 120),
        )
        .listen((value) => position.value = value);

    _stateSub = player.playerStateStream.listen((state) {
      final done = state.processingState == ProcessingState.completed;
      playing.value = state.playing && !done;

      if (done) {
        // إلى أوّلها موقوفةً — تُقرأ الفقاعة جديدةً من جديد.
        position.value = Duration.zero;
        unawaited(player.pause());
        unawaited(player.seek(Duration.zero));
      }
    });

    return _player = player;
  }

  /// مفتاحُ الذاكرة من مفتاح التشغيل: `voice-<رقم المرفق>`، وما سواه تسجيلٌ لم يصل الخادم بعد.
  static String? _cacheKeyOf(String key) {
    final id = int.tryParse(key.replaceFirst(playbackKeyPrefix, ''));

    return key.startsWith(playbackKeyPrefix) && id != null ? VoiceNoteCache.keyFor(id) : null;
  }

  static const String playbackKeyPrefix = 'voice-';

  /// مفتاحُ تشغيل رسالةٍ وصلت الخادم.
  static String keyForAttachment(int attachmentId) => '$playbackKeyPrefix$attachmentId';

  Future<void> dispose() async {
    await _positionSub?.cancel();
    await _stateSub?.cancel();
    await _player?.dispose();
  }
}
