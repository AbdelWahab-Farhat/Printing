import 'dart:async';
import 'dart:math' as math;

import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/theme/app_tones.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/voice/voice_playback.dart';
import 'package:dayaa/core/voice/voice_recorder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// رسالةٌ صوتية داخل فقاعة، كما يرسمها تيليغرام وبريمولا: زرُّ التشغيل المستدير، والموجةُ
/// بجانبه تمتلئ وهي تُسمع، وتحتها المدّة — أو الموضع وهي تُسمع — وسرعةُ التشغيل حين تكون النشطة.
///
/// التشغيلُ مشغّلٌ واحد للتطبيق ([VoicePlayback]): هذه تُعاد بناءً حين تصير النشطةَ أو تكفّ، وما
/// دامت تُسمع فالأعمدةُ والعدّادُ وحدهما يتبعان الموضع — إعادةُ رسمٍ لا بناء.
class VoiceNoteView extends StatelessWidget {
  const VoiceNoteView({
    required this.playbackKey,
    required this.outgoing,
    this.url,
    this.localPath,
    this.durationSeconds,
    this.waveform,
    super.key,
  });

  /// `voice-<رقم المرفق>` — [VoicePlayback.keyForAttachment].
  final String playbackKey;

  /// على فقاعتي: الألوانُ ألوانُ فقاعة المرسِل.
  final bool outgoing;

  final String? url;
  final String? localPath;
  final int? durationSeconds;
  final List<int>? waveform;

  /// `00:42` — عدّادُ تيليغرام، الدقائق برقمين دائماً.
  static String formatDuration(Duration value) {
    final total = value.inSeconds;
    final minutes = (total ~/ 60).toString().padLeft(2, '0');
    final seconds = (total % 60).toString().padLeft(2, '0');

    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final playback = sl<VoicePlayback>();
    final scheme = context.colorScheme;
    final accent = outgoing ? scheme.onOutgoingBubble : scheme.primary;
    final idle = (outgoing ? scheme.onOutgoingBubble : scheme.onSurfaceVariant).withValues(
      alpha: 0.32,
    );
    final meta = outgoing ? scheme.outgoingMeta : scheme.incomingMeta;
    final known = durationSeconds == null ? null : Duration(seconds: durationSeconds!);
    final samples = waveform ?? _flatWaveform;
    final direction = Directionality.of(context);

    double progress() {
      final total = playback.duration.value ?? known;
      if (total == null || total.inMilliseconds <= 0) return 0;

      return (playback.position.value.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
    }

    return SizedBox(
      width: 226.w,
      child: ValueListenableBuilder<String?>(
        valueListenable: playback.activeKey,
        builder: (context, active, _) {
          final isActive = active == playbackKey;

          return Row(
            children: [
              _PlayButton(
                playbackKey: playbackKey,
                isActive: isActive,
                outgoing: outgoing,
                onTap: () =>
                    unawaited(playback.toggle(key: playbackKey, localPath: localPath, url: url)),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) => GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        // التقديمُ معنى له في الرسالة التي تُسمع وحدها.
                        onTapUp: isActive
                            ? (details) => _seek(details.localPosition.dx, constraints, direction)
                            : null,
                        onHorizontalDragUpdate: isActive
                            ? (details) => _seek(details.localPosition.dx, constraints, direction)
                            : null,
                        child: SizedBox(
                          height: 26.h,
                          width: constraints.maxWidth,
                          child: CustomPaint(
                            painter: WaveformPainter(
                              samples: samples,
                              played: accent,
                              idle: idle,
                              textDirection: direction,
                              repaint: isActive ? playback.position : null,
                              progress: isActive ? progress : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Row(
                      children: [
                        if (isActive)
                          ValueListenableBuilder<Duration>(
                            valueListenable: playback.position,
                            builder: (context, position, _) =>
                                _Counter(text: formatDuration(position), color: meta),
                          )
                        else if (known != null)
                          _Counter(text: formatDuration(known), color: meta),
                        if (isActive) ...[
                          SizedBox(width: 8.w),
                          _SpeedChip(color: accent, playback: playback),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// الأعمدة تمتلئ من بداية القراءة — اليمين بالعربية — فاللمسةُ تُقاس من هناك.
  void _seek(double dx, BoxConstraints constraints, TextDirection direction) {
    final width = constraints.maxWidth;
    if (width <= 0) return;

    final fraction = (dx / width).clamp(0.0, 1.0);

    unawaited(
      sl<VoicePlayback>().seekFraction(
        playbackKey,
        direction == TextDirection.rtl ? 1 - fraction : fraction,
      ),
    );
  }

  /// رسالةٌ بلا موجة — أُرسلت من مكانٍ لا يقيس — خطٌّ منخفضٌ لا يدّعي صوتاً لم يُقس.
  static final List<int> _flatWaveform = List<int>.filled(VoiceRecorder.waveformBars, 18);
}

class _Counter extends StatelessWidget {
  const _Counter({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textDirection: TextDirection.ltr,
      style: context.textTheme.labelSmall?.copyWith(
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

/// «١٫٥×» — يدور بين السرعات الثلاث، ولا يظهر إلا على الرسالة التي تُسمع.
class _SpeedChip extends StatelessWidget {
  const _SpeedChip({required this.color, required this.playback});

  final Color color;
  final VoicePlayback playback;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: playback.speed,
      builder: (context, speed, _) => Semantics(
        button: true,
        label: 'سرعة التشغيل',
        child: InkWell(
          onTap: () => unawaited(playback.cycleSpeed()),
          borderRadius: BorderRadius.circular(8.r),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: color.withValues(alpha: 0.6)),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
              child: Text(
                '${speed == speed.roundToDouble() ? speed.toInt() : speed}×',
                textDirection: TextDirection.ltr,
                style: context.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.playbackKey,
    required this.isActive,
    required this.outgoing,
    required this.onTap,
  });

  final String playbackKey;
  final bool isActive;
  final bool outgoing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final fill = outgoing ? scheme.onOutgoingBubble : scheme.primary;
    final glyph = outgoing ? scheme.outgoingBubble : scheme.onPrimary;
    final playback = sl<VoicePlayback>();

    return Material(
      color: fill,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox.square(
          dimension: 42.w,
          child: ListenableBuilder(
            listenable: Listenable.merge([
              playback.failedKey,
              playback.loadingKey,
              playback.playing,
            ]),
            builder: (context, _) {
              if (playback.failedKey.value == playbackKey) {
                return Semantics(
                  label: 'أعد تشغيل الرسالة الصوتية',
                  child: Icon(AppIcons.refresh, color: glyph, size: 22.sp),
                );
              }

              if (isActive && playback.loadingKey.value == playbackKey) {
                return _LoadingRing(color: glyph, playback: playback);
              }

              final playing = isActive && playback.playing.value;

              return Semantics(
                label: playing ? 'إيقاف مؤقت' : 'تشغيل الرسالة الصوتية',
                child: Icon(playing ? AppIcons.pause : AppIcons.play, color: glyph, size: 26.sp),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// حلقةُ التنزيل حول ✕، كتيليغرام: تمتلئ بالتنزيل — وتدور ما دام حجمُه مجهولاً — وضغطةٌ عليها تلغي.
class _LoadingRing extends StatelessWidget {
  const _LoadingRing({required this.color, required this.playback});

  final Color color;
  final VoicePlayback playback;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'جارٍ تحميل الرسالة الصوتية',
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.square(
            dimension: 32.w,
            child: ValueListenableBuilder<double?>(
              valueListenable: playback.loadProgress,
              builder: (context, progress, _) => CircularProgressIndicator(
                // شريحةٌ من البداية، فتنزيلٌ بدأ للتوّ يُقرأ تنزيلاً.
                value: progress == null ? null : math.max(0.06, progress),
                strokeWidth: 2.2.w,
                color: color,
              ),
            ),
          ),
          Icon(AppIcons.close, color: color, size: 16.sp),
        ],
      ),
    );
  }
}

/// الأعمدة: خطٌّ مستديرٌ لكل عيّنة، ملوّنٌ حتى [progress].
///
/// [repaint] ساعةُ المشغّل؛ `CustomPaint` يشترك فيها ما دامت الأعمدة على الشاشة.
class WaveformPainter extends CustomPainter {
  WaveformPainter({
    required this.samples,
    required this.played,
    required this.idle,
    required this.textDirection,
    super.repaint,
    this.progress,
  });

  final List<int> samples;
  final Color played;
  final Color idle;
  final TextDirection textDirection;

  /// ٠–١، يُقرأ ساعةَ الرسم؛ `null` يرسم الأعمدة كلّها خاملة.
  final ValueGetter<double>? progress;

  static const double _barWidth = 2.2;
  static const double _minGap = 1.6;

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty || size.width <= 0) return;

    final slots = math.max(1, (size.width / (_barWidth + _minGap)).floor());
    final count = math.min(slots, samples.length);
    final step = size.width / count;
    final filled = (progress?.call() ?? 0) * size.width;
    final rtl = textDirection == TextDirection.rtl;
    final playedPaint = Paint()
      ..color = played
      ..strokeCap = StrokeCap.round
      ..strokeWidth = _barWidth;
    final idlePaint = Paint()
      ..color = idle
      ..strokeCap = StrokeCap.round
      ..strokeWidth = _barWidth;
    final bottom = size.height - _barWidth / 2;

    for (var index = 0; index < count; index++) {
      final sample = samples[(index * samples.length / count).floor()];
      // الأعمدةُ قائمةٌ على خطٍّ كأعمدة تيليغرام، لا منعكسةٌ حول المنتصف.
      final height = math.max(_barWidth, size.height * sample / 100);
      final fromStart = index * step + step / 2;
      final x = rtl ? size.width - fromStart : fromStart;

      canvas.drawLine(
        Offset(x, bottom),
        Offset(x, bottom - height + _barWidth),
        fromStart <= filled ? playedPaint : idlePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) =>
      oldDelegate.samples != samples ||
      oldDelegate.played != played ||
      oldDelegate.idle != idle ||
      (oldDelegate.progress == null) != (progress == null) ||
      oldDelegate.textDirection != textDirection;
}
