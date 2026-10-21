import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:dayaa/core/chat/voice_note_view.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/voice/voice_playback.dart';
import 'package:dayaa/core/voice/voice_recorder.dart';
import 'package:dayaa/core/widgets/app_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum _Phase { idle, starting, holding, locked }

/// الحقلُ وزرُّه، ومعهما تسجيلُ الصوت كما في تيليغرام وبريمولا.
///
/// مع [showMic] يصير زرُّ الإرسال ميكروفوناً. **اضغط وأمسك** فيبدأ التسجيل: الحقلُ يصير نقطةً
/// حمراء وعدّاداً، و«اسحب للإلغاء» تدعو إلى سحبةٍ نحو الحقل، وقفلٌ فوق الزرّ يدعو إلى سحبةٍ للأعلى.
/// **أفلت لترسل؛ اسحب جانباً لترميه؛ اسحب للأعلى لتقفله** ثم أرسل بالزرّ متى شئت. وفي آخر ثلاثين
/// ثانيةً يصير العدّادُ عدّاً تنازلياً أحمر، وعند خمس دقائق يقف التسجيلُ ويُرسل.
///
/// **أحداثُ مؤشّرٍ خام لا ساحةُ الإيماءات**: الإمساكُ يتبع الإصبع أينما ذهب، والساحةُ كانت ستعطي
/// السحبةَ الجانبية لأول من يطلبها.
///
/// **والحركةُ إزاحةٌ وشفافيةٌ وحدهما** (RULES §٧) — خلافاً لبريمولا التي يكبر فيها الزرّ تحت الإصبع
/// وتنتفخ هالتُه: الهالةُ هنا ثابتةُ المقاس وتشتدّ بالصوت، والزرُّ يتبع الإصبع ولا يكبر.
class VoiceComposerRow extends StatefulWidget {
  const VoiceComposerRow({
    required this.field,
    required this.sendButton,
    required this.showMic,
    required this.onRecorded,
    super.key,
  });

  /// الحقل — يبقى في مكانه تحت شريط التسجيل، فيعود ما كُتب فيه ومؤشّرُه كما كانا.
  final Widget field;

  /// زرُّ الإرسال العاديّ، كلّما لم يكن الميكروفون.
  final Widget sendButton;

  final bool showMic;
  final Future<void> Function(VoiceRecording recording) onRecorded;

  /// أقصرُ من هذا لمسةٌ تشرح الإيماءة فقط.
  static const Duration holdDelay = Duration(milliseconds: 180);

  /// كم يرتفع الإصبع ليقفل التسجيل.
  static const double lockDistance = 80;

  /// متى يصير العدّادُ عدّاً تنازلياً إلى [VoiceRecorder.maxDuration].
  static const Duration countdownFrom = Duration(seconds: 30);

  @override
  State<VoiceComposerRow> createState() => _VoiceComposerRowState();
}

class _VoiceComposerRowState extends State<VoiceComposerRow> {
  VoiceRecorder? _recorder;
  _Phase _phase = _Phase.idle;
  Timer? _holdTimer;
  Offset _origin = Offset.zero;

  /// كم مضى الإصبع نحو الحقل (x) وللأعلى (y)، كلاهما ≥ ٠.
  final ValueNotifier<Offset> _drag = ValueNotifier(Offset.zero);

  /// رُفع الإصبع والميكروفون ما زال يُفتح.
  bool _pointerUp = false;

  /// حُسمت هذه الضغطة — إلغاءً أو قفلاً — فما بعدها من حركةٍ يُتجاهل.
  bool _settled = false;

  bool get _recording => _phase == _Phase.holding || _phase == _Phase.locked;

  VoiceRecorder get _mic => _recorder ??= VoiceRecorder()..onMaxDuration = _reachedLimit;

  bool get _rtl => Directionality.of(context) == TextDirection.rtl;

  double get _cancelDistance => math.min(140, MediaQuery.sizeOf(context).width * 0.35);

  @override
  void dispose() {
    _holdTimer?.cancel();
    _drag.dispose();
    // الخروجُ في منتصف تسجيلٍ يرميه: لا يُرسل شيءٌ من شاشةٍ غادرها صاحبها.
    unawaited(_recorder?.dispose());
    super.dispose();
  }

  // ───────────────────────────── الإصبع ─────────────────────────────

  void _onDown(PointerDownEvent event) {
    if (_phase != _Phase.idle) return;

    _origin = event.position;
    _pointerUp = false;
    _settled = false;
    _drag.value = Offset.zero;
    _holdTimer?.cancel();
    _holdTimer = Timer(VoiceComposerRow.holdDelay, () => unawaited(_begin()));
  }

  void _onMove(PointerMoveEvent event) {
    final delta = event.position - _origin;

    if (_holdTimer?.isActive ?? false) {
      // تحرّك قبل أن يُحسب إمساكاً: تمريرٌ أو انزلاق، لا ضغطة.
      if (delta.distance > 24) _holdTimer?.cancel();

      return;
    }

    if (_phase != _Phase.holding || _settled) return;

    // الحقلُ قبل الزرّ في السطر: يمينه بالعربية.
    final toward = math.max(0.0, _rtl ? delta.dx : -delta.dx);
    final up = math.max(0.0, -delta.dy);
    _drag.value = Offset(toward, up);

    if (toward >= _cancelDistance) {
      _settled = true;
      unawaited(_cancel());
    } else if (up >= VoiceComposerRow.lockDistance) {
      _settled = true;
      unawaited(HapticFeedback.selectionClick());
      _drag.value = Offset.zero;
      setState(() => _phase = _Phase.locked);
    }
  }

  void _onUp(PointerUpEvent _) {
    _pointerUp = true;

    if (_holdTimer?.isActive ?? false) {
      _holdTimer?.cancel();
      context.showInfo('اضغط مطوّلاً للتسجيل، وارفع إصبعك للإرسال');

      return;
    }

    if (_phase == _Phase.holding && !_settled) unawaited(_finish());
  }

  void _onCancel(PointerCancelEvent _) {
    _pointerUp = true;
    _holdTimer?.cancel();
    // أخذ النظامُ اللمسة — اتصالٌ، أو سؤالُ إذن. ميكروفونٌ مفتوحٌ بلا إصبعٍ يسجّل الغرفة.
    if (_phase == _Phase.holding) unawaited(_cancel());
  }

  // ───────────────────────────── التسجيل ─────────────────────────────

  Future<void> _begin() async {
    if (!mounted || _phase != _Phase.idle) return;

    setState(() => _phase = _Phase.starting);
    unawaited(HapticFeedback.mediumImpact());
    // رسالةٌ تُسمع فوق الميكروفون تُسجَّل في الجديدة.
    unawaited(sl<VoicePlayback>().stop());

    final result = await _mic.start();

    if (!mounted) return;

    if (result != VoiceStart.started) {
      setState(() => _phase = _Phase.idle);

      switch (result) {
        case VoiceStart.blocked:
          // أمامه لا في رسالةٍ عابرة: الإعداداتُ وحدها تُرجع «لا» سابقة.
          await showCustomDialog(
            context: context,
            title: 'الميكروفون غير مسموح',
            description:
                'اسمح للتطبيق باستخدام الميكروفون من إعدادات الهاتف، ثم سجّل رسالتك الصوتية.',
            confirmLabel: 'حسناً',
            cancelLabel: null,
          );
        case VoiceStart.unavailable:
          context.showError(
            kDebugMode
                // hot restart يُبقي البناءَ القديم، ولا مسجّلَ فيه.
                ? 'التسجيل غير مضمَّن في هذه النسخة — أوقف التطبيق وشغّله من جديد'
                : 'تعذّر فتح الميكروفون',
          );
        case VoiceStart.refused:
        case VoiceStart.started:
          break;
      }

      return;
    }

    if (_pointerUp) {
      // رُفع الإصبع والميكروفون يُفتح — أقصرُ من أن يُحفظ.
      await _mic.cancel();
      if (mounted) setState(() => _phase = _Phase.idle);

      return;
    }

    setState(() => _phase = _Phase.holding);
  }

  /// يقف ويرسل — إفلاتُ الإمساك، أو زرُّ الإرسال لتسجيلٍ مقفول، أو انتهاءُ الوقت.
  Future<void> _finish() async {
    if (!_recording) return;

    setState(() => _phase = _Phase.idle);
    final recording = await _mic.stop();

    if (!mounted) return;

    if (recording == null) {
      context.showInfo('التسجيل قصير جداً');

      return;
    }

    if (!VoiceRecorder.fitsUpload(recording.path)) {
      File(recording.path).deleteSync();
      context.showError('الرسالة الصوتية أكبر من 6 ميغابايت');

      return;
    }

    unawaited(HapticFeedback.lightImpact());
    await widget.onRecorded(recording);
  }

  /// خمسُ دقائق: يُرسل كما سُجّل، ويُقال ذلك — قد يكون الإصبعُ ما زال عليه، أو الهاتفُ في جيب.
  void _reachedLimit() {
    if (!_recording) return;

    context.showInfo('بلغ التسجيل خمس دقائق، فأُرسل');
    unawaited(_finish());
  }

  Future<void> _cancel() async {
    if (!_recording && _phase != _Phase.starting) return;

    unawaited(HapticFeedback.lightImpact());
    setState(() => _phase = _Phase.idle);
    await _mic.cancel();
  }

  // ───────────────────────────── الرسم ─────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = 52.w;
    final micMode = widget.showMic || _phase != _Phase.idle;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Stack(
            children: [
              // مخفيٌّ لا مُزال: المسوّدةُ والمؤشّرُ ولوحةُ المفاتيح تعود كما هي بعد التسجيل.
              Opacity(
                opacity: _recording ? 0 : 1,
                child: IgnorePointer(ignoring: _recording, child: widget.field),
              ),
              if (_recording)
                Positioned.fill(
                  child: _RecordingBar(
                    elapsed: _mic.elapsed,
                    drag: _drag,
                    locked: _phase == _Phase.locked,
                    cancelDistance: _cancelDistance,
                    rtl: _rtl,
                    onCancel: () => unawaited(_cancel()),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(width: 8.w),
        SizedBox.square(
          dimension: size,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (_phase == _Phase.holding)
                Positioned(
                  bottom: size + 10.h,
                  child: _LockPill(drag: _drag),
                ),
              if (_recording) _LevelHalo(level: _mic.level, size: size),
              if (!micMode)
                widget.sendButton
              else if (_phase == _Phase.locked)
                _RoundButton(
                  size: size,
                  label: 'إرسال الرسالة الصوتية',
                  icon: AppIcons.send,
                  onTap: () => unawaited(_finish()),
                )
              else
                Listener(
                  onPointerDown: _onDown,
                  onPointerMove: _onMove,
                  onPointerUp: _onUp,
                  onPointerCancel: _onCancel,
                  child: _FollowingMic(
                    drag: _drag,
                    holding: _phase == _Phase.holding,
                    rtl: _rtl,
                    size: size,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.size, required this.label, required this.icon, this.onTap});

  final double size;
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Semantics(
      button: true,
      label: label,
      child: SizedBox.square(
        dimension: size,
        child: Material(
          color: scheme.primary,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            canRequestFocus: false,
            child: Icon(icon, size: 24.sp, color: scheme.onPrimary),
          ),
        ),
      ),
    );
  }
}

/// الميكروفون: يتبع الإصبعَ نحو الحقل وللأعلى وهو مُمسَك — إزاحةٌ في الرسم، لا إعادةُ تخطيط.
class _FollowingMic extends StatelessWidget {
  const _FollowingMic({
    required this.drag,
    required this.holding,
    required this.rtl,
    required this.size,
  });

  final ValueNotifier<Offset> drag;
  final bool holding;
  final bool rtl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final button = _RoundButton(
      size: size,
      label: 'اضغط مطوّلاً لتسجيل رسالة صوتية',
      icon: AppIcons.mic,
    );

    if (!holding) return button;

    return ValueListenableBuilder<Offset>(
      valueListenable: drag,
      child: button,
      builder: (context, offset, child) => Transform.translate(
        offset: Offset((rtl ? offset.dx : -offset.dx) * 0.6, -math.min(offset.dy, 60) * 0.6),
        child: child,
      ),
    );
  }
}

/// دائرةٌ ناعمة خلف الميكروفون الممسَك تشتدّ بالصوت — **ثابتةُ المقاس**، والصوتُ في شفافيتها.
class _LevelHalo extends StatelessWidget {
  const _LevelHalo({required this.level, required this.size});

  final ValueNotifier<double> level;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = context.colorScheme.primary;
    final halo = size * 1.9;

    return IgnorePointer(
      child: OverflowBox(
        maxWidth: halo,
        maxHeight: halo,
        child: ValueListenableBuilder<double>(
          valueListenable: level,
          builder: (context, value, _) => Container(
            width: halo,
            height: halo,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10 + value * 0.22),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

/// القفلُ فوق الميكروفون الممسَك؛ يرتفع مع الإصبع ويبهت.
class _LockPill extends StatelessWidget {
  const _LockPill({required this.drag});

  final ValueNotifier<Offset> drag;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return IgnorePointer(
      child: ValueListenableBuilder<Offset>(
        valueListenable: drag,
        builder: (context, offset, child) {
          final t = (offset.dy / VoiceComposerRow.lockDistance).clamp(0.0, 1.0);

          return Transform.translate(
            offset: Offset(0, -t * 24),
            child: Opacity(opacity: 1 - t * 0.4, child: child),
          );
        },
        child: Container(
          width: 38.w,
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(19.r),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(AppIcons.locked, size: 18.sp, color: scheme.onSurfaceVariant),
              SizedBox(height: 4.h),
              Icon(AppIcons.collapse, size: 18.sp, color: scheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}

/// ما يظهر مكان الحقل وهو يسجّل: الإرشادُ (أو «إلغاء» بعد القفل)، والنقطةُ الحمراء والعدّاد.
class _RecordingBar extends StatelessWidget {
  const _RecordingBar({
    required this.elapsed,
    required this.drag,
    required this.locked,
    required this.cancelDistance,
    required this.rtl,
    required this.onCancel,
  });

  final ValueNotifier<Duration> elapsed;
  final ValueNotifier<Offset> drag;
  final bool locked;
  final double cancelDistance;
  final bool rtl;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          const _BlinkingDot(),
          SizedBox(width: 8.w),
          ValueListenableBuilder<Duration>(
            valueListenable: elapsed,
            builder: (context, value, _) {
              // نصفُ الدقيقة الأخير عدٌّ تنازليٌّ أحمر: التسجيلُ على وشك أن يقف ويُرسل.
              final left = VoiceRecorder.maxDuration - value;
              final closing = left <= VoiceComposerRow.countdownFrom;
              final seconds = math.max(0, (left.inMilliseconds / 1000).ceil());

              return Text(
                closing
                    ? 'متبقٍّ ${VoiceNoteView.formatDuration(Duration(seconds: seconds))}'
                    : VoiceNoteView.formatDuration(value),
                style: context.textTheme.labelLarge?.copyWith(
                  color: closing ? scheme.error : scheme.onSurface,
                  fontWeight: closing ? FontWeight.w700 : null,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              );
            },
          ),
          Expanded(
            child: locked
                ? Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton(
                      onPressed: onCancel,
                      child: Text(
                        'إلغاء',
                        style: context.textTheme.labelLarge?.copyWith(
                          color: scheme.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                : ValueListenableBuilder<Offset>(
                    valueListenable: drag,
                    builder: (context, offset, child) {
                      final t = (offset.dx / cancelDistance).clamp(0.0, 1.0);

                      return Transform.translate(
                        offset: Offset((rtl ? offset.dx : -offset.dx) * 0.5, 0),
                        child: Opacity(opacity: 1 - t * 0.8, child: child),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // يشير نحو الحقل، جهةِ السحب.
                        Icon(AppIcons.forward, size: 18.sp, color: scheme.outline),
                        Text(
                          'اسحب للإلغاء',
                          style: context.textTheme.labelLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// النقطةُ الحمراء تنبض بالشفافية — وتثبت بلا نبضٍ مع «تقليل الحركة».
class _BlinkingDot extends StatefulWidget {
  const _BlinkingDot();

  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
    value: 0,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      unawaited(_controller.repeat(reverse: true));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.25).animate(_controller),
      child: Container(
        width: 10.w,
        height: 10.w,
        decoration: BoxDecoration(color: context.colorScheme.error, shape: BoxShape.circle),
      ),
    );
  }
}
