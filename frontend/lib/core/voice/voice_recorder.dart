import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:dayaa/core/files/local_files.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// تسجيلٌ انتهى: الملف، وكم دام، والأعمدة التي تُرسم له.
@immutable
class VoiceRecording {
  const VoiceRecording({required this.path, required this.duration, required this.waveform});

  final String path;
  final Duration duration;

  /// مستوى الصوت مقلَّصاً إلى [VoiceRecorder.waveformBars] رقماً، من ٠ إلى ١٠٠.
  final List<int> waveform;
}

/// كيف انتهت محاولةُ فتح الميكروفون.
enum VoiceStart {
  /// يسجّل.
  started,

  /// رُفض الآن، أمام سؤال النظام — الجوابُ على الشاشة، فلا شيء يُقال فوقه.
  refused,

  /// رُفض من قبل: النظام لا يسأل ثانيةً، والإعداداتُ وحدها تغيّره.
  blocked,

  /// لا ميكروفون في هذا البناء (hot restart فوق بناءٍ قبل الحزمة) أو مسجّلٌ لم يبدأ.
  unavailable,
}

/// الميكروفون، خلف واجهةٍ تستبدلها الاختبارات — الحزمةُ لا جانبَ أصلياً لها تحت `flutter test`.
abstract interface class VoiceRecorderEngine {
  /// يسأل النظامَ أوّل مرة؛ `true` حين يُسمح بفتح الميكروفون.
  Future<bool> hasPermission();

  /// `false` حين لم يبدأ.
  Future<bool> start(String path);

  /// مستوى الصوت أثناء التسجيل، من ٠ إلى ١.
  Stream<double> levels();

  /// مسارُ الملف المكتوب، أو `null` حين لم يُكتب شيء.
  Future<String?> stop();

  Future<void> dispose();
}

/// [VoiceRecorderEngine] فوق حزمة `record`.
///
/// **هنا وحده `catch`**، وهو حدُّ المنصّة كما في `LoadDesignImage`: تحته قناةٌ أصلية قد لا تكون في
/// هذا البناء أصلاً (`MissingPluginException`)، وميكروفونٌ قد يأخذه اتصالٌ هاتفيّ. كلُّ فشلٍ يصير
/// جواباً — `false` أو `null` — فلا يرى ما فوقه استثناءً.
class RecordPackageEngine implements VoiceRecorderEngine {
  static const int _bitRate = 48000;

  final AudioRecorder _recorder = AudioRecorder();

  @override
  Future<bool> hasPermission() async {
    try {
      return await _recorder.hasPermission();
    } on Object catch (error) {
      if (kDebugMode) debugPrint('⚠️ الميكروفون لم يُسأل: $error');

      return false;
    }
  }

  /// AAC في حاوية MP4، أحاديّ، 48 kbps — كبريمولا: كلامٌ واضح بنحو ٦ كيلوبايت في الثانية، وصيغةٌ
  /// يشغّلها كل هاتف بلا مشغّلٍ إضافيّ.
  ///
  /// **وعلى الويب يُمرَّر عشرةُ أضعافه.** الحزمة تضع الرقم في `bitsPerSecond` أيضاً، وChrome يقرأ
  /// ذاك معدّلاً للصوت والصورة معاً ويعطي الصوتَ عُشرَه — فكانت 48 تصير 5 kbps، كلاماً بالكاد
  /// يُفهم. وإن أعطى متصفّحٌ آخر الصوتَ الرقمَ كلَّه، فـ[VoiceRecorder.fitsUpload] يردّ ما زاد قبل
  /// الرفع.
  @override
  Future<bool> start(String path) async {
    try {
      await _recorder.start(
        const RecordConfig(bitRate: kIsWeb ? _bitRate * 10 : _bitRate, numChannels: 1),
        path: path,
      );

      return true;
    } on Object catch (error) {
      if (kDebugMode) debugPrint('⚠️ التسجيل لم يبدأ: $error');

      return false;
    }
  }

  /// dBFS إلى ٠–١: غرفةٌ هادئة قرب -٦٠، والكلامُ بين -٣٥ و-١٠ — فالخمسةُ والخمسون الأخيرة تحمل
  /// شكل الصوت كلّه.
  @override
  Stream<double> levels() => _recorder
      .onAmplitudeChanged(const Duration(milliseconds: 80))
      .map((amplitude) => ((amplitude.current + 55) / 55).clamp(0.0, 1.0));

  @override
  Future<String?> stop() async {
    try {
      return await _recorder.stop();
    } on Object catch (error) {
      if (kDebugMode) debugPrint('⚠️ التسجيل لم يتوقّف بسلام: $error');

      return null;
    }
  }

  @override
  Future<void> dispose() async {
    try {
      await _recorder.dispose();
    } on MissingPluginException {
      // بناءٌ بلا الحزمة لم يفتح شيئاً ليُغلق.
    }
  }
}

/// تسجيلٌ واحد في وقتٍ واحد — ككاتب بريمولا: يفتح الميكروفون، ويقيسه وهو يعمل، ويُرجع
/// [VoiceRecording] — أو لا شيء لضغطةٍ أقصر من أن تكون رسالة.
class VoiceRecorder {
  VoiceRecorder({
    VoiceRecorderEngine? engine,
    DateTime Function()? now,
    Future<Directory> Function()? folder,
  }) : _engine = engine ?? RecordPackageEngine(),
       _now = now ?? DateTime.now,
       _folder = folder ?? getApplicationSupportDirectory;

  /// خمس دقائق: حدُّ الخادم (`media.internal_ticket_attachments.voice_max_seconds`). التسجيلُ يقف
  /// هنا ويُرسل، لا يمضي إلى رفض.
  static const Duration maxDuration = Duration(minutes: 5);

  /// ٦ ميغابايت: ما يرفض الخادم فوقه. خمسُ دقائق بـ48 kbps دون ٢ ميغابايت، فهذا حارسٌ لمرمِّزٍ
  /// معطوب لا لمتكلّمٍ طويل.
  static const int maxBytes = 6 * 1024 * 1024;

  /// أقصرُ من هذا لمسةٌ على الميكروفون، لا رسالة.
  static const Duration minDuration = Duration(milliseconds: 700);

  /// الأعمدة التي تُرسم تحت الرسالة — ٤٨، كبريمولا والخادم.
  static const int waveformBars = 48;

  /// الإجابةُ أسرع من هذا لم يسبقها سؤال: رُفض من قبل. من يقرأ نافذة النظام يجيب أبطأ.
  static const Duration _promptlessAnswer = Duration(milliseconds: 400);

  final VoiceRecorderEngine _engine;
  final DateTime Function() _now;
  final Future<Directory> Function() _folder;

  /// الوقتُ منذ البدء، لعدّاد النقطة الحمراء.
  final ValueNotifier<Duration> elapsed = ValueNotifier(Duration.zero);

  /// آخرُ مستوى، ٠–١، للهالة حول الزرّ.
  final ValueNotifier<double> level = ValueNotifier(0);

  final List<double> _levels = [];
  DateTime? _startedAt;
  StreamSubscription<double>? _levelSub;
  Timer? _ticker;
  String? _path;
  bool _opening = false;
  bool _disposed = false;

  /// يُنادى مرّةً حين يبلغ التسجيلُ [maxDuration] وهو ما زال يعمل.
  VoidCallback? onMaxDuration;

  bool get isRecording => _path != null;

  /// يفتح الميكروفون، ويسأل النظامَ أوّل مرة — والضغطةُ التي سألت ليست تسجيلاً، فيسأل المستدعي
  /// أما زال الإصبع على الزرّ قبل أن يبقيه.
  Future<VoiceStart> start() async {
    if (isRecording || _opening || _disposed) return VoiceStart.unavailable;

    _opening = true;
    final result = await _open();
    _opening = false;

    return result;
  }

  Future<VoiceStart> _open() async {
    final asked = Stopwatch()..start();

    if (!await _engine.hasPermission()) {
      return asked.elapsed < _promptlessAnswer ? VoiceStart.blocked : VoiceStart.refused;
    }

    final path = await _newPath();

    if (!await _engine.start(path)) return VoiceStart.unavailable;

    if (_disposed) {
      await _engine.stop();
      _delete(path);

      return VoiceStart.unavailable;
    }

    _path = path;
    _levels.clear();
    _startedAt = _now();
    elapsed.value = Duration.zero;
    _levelSub = _engine.levels().listen((value) {
      level.value = value;
      _levels.add(value);
    });
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final now = _elapsed;
      elapsed.value = now;
      if (now >= maxDuration) onMaxDuration?.call();
    });

    return VoiceStart.started;
  }

  /// يُنهي التسجيل. `null` لتسجيلٍ أقصر من [minDuration] — ويُمحى ملفُّه في الطريق.
  Future<VoiceRecording?> stop() async {
    final path = _path;
    if (path == null) return null;

    final duration = _elapsed;
    final written = await _engine.stop();
    final levels = List<double>.of(_levels);
    _reset();

    final file = written ?? path;

    if (duration < minDuration || !LocalFiles.exists(file)) {
      _delete(file);

      return null;
    }

    return VoiceRecording(
      path: file,
      duration: duration > maxDuration ? maxDuration : duration,
      waveform: downsampleWaveform(levels, waveformBars),
    );
  }

  /// يُنهي التسجيل ويرميه.
  Future<void> cancel() async {
    final path = _path;
    if (path == null) return;

    await _engine.stop();
    _reset();
    _delete(path);
  }

  Future<void> dispose() async {
    _disposed = true;
    await cancel();
    await _engine.dispose();
    elapsed.dispose();
    level.dispose();
  }

  /// أيرسله الخادم؟ يُسأل هنا قبل الرفع، لا يُكتشف رفضاً على خطٍّ بطيء.
  static Future<bool> fitsUpload(String path) async =>
      LocalFiles.exists(path) && await LocalFiles.length(path) <= maxBytes;

  Duration get _elapsed {
    final started = _startedAt;

    return started == null ? Duration.zero : _now().difference(started);
  }

  void _reset() {
    _ticker?.cancel();
    _ticker = null;
    unawaited(_levelSub?.cancel());
    _levelSub = null;
    _startedAt = null;
    _path = null;
    if (!_disposed) level.value = 0;
  }

  /// مجلّدُ الدعم لا المستندات: المستنداتُ تُرى من تطبيق «الملفات»، وصوتُ زميلٍ لا مكان له هناك.
  Future<String> _newPath() async {
    // المتصفّح يسجّل في الذاكرة ويُرجع رابط blob من [stop]؛ المسار المعطى يُهمَل هناك.
    if (kIsWeb) return 'voice.m4a';

    final directory = Directory('${(await _folder()).path}/internal_voice');
    if (!directory.existsSync()) directory.createSync(recursive: true);

    final random = math.Random.secure();
    final name = List<String>.generate(16, (_) => random.nextInt(16).toRadixString(16)).join();

    return '${directory.path}/$name.m4a';
  }

  static void _delete(String path) => LocalFiles.delete(path);
}

/// يقلّص مستويات المسجّل إلى [bars] رقماً من ٠ إلى ١٠٠ — كدالة بريمولا نفسها.
///
/// **كلُّ عمودٍ أعلى ما في شريحته** لا متوسّطها: المتوسّط يسطّح المقاطع التي تعطي الصوتَ شكله.
/// والنتيجة على قمّة التسجيل نفسه، فالمتكلّم الهادئ يرسم أعمدةً حيّة كالعالي، وحدٌّ أدنى يُبقي
/// الصمتَ خطّاً لا فراغاً.
List<int> downsampleWaveform(List<double> levels, int bars) {
  if (bars <= 0) return const [];
  if (levels.isEmpty) return List<int>.filled(bars, 4);

  final peaks = <double>[];

  for (var index = 0; index < bars; index++) {
    final from = (index * levels.length / bars).floor();
    final to = ((index + 1) * levels.length / bars).ceil().clamp(from + 1, levels.length);
    var peak = 0.0;

    for (var at = from; at < to; at++) {
      if (levels[at] > peak) peak = levels[at];
    }

    peaks.add(peak);
  }

  final loudest = peaks.fold<double>(0, (highest, value) => value > highest ? value : highest);

  return [
    for (final value in peaks)
      loudest <= 0 ? 4 : (4 + (value / loudest) * 96).round().clamp(4, 100),
  ];
}
