import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/utils/text_direction.dart';
import 'package:dayaa_client/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// صندوق الكتابة أسفل المحادثة: الحقل ومشبكُ الورق فيه، وزرُّ الإرسال المستدير بجانبه.
///
/// **زرٌّ مستدير لا زرٌّ بعرض الشاشة** — الاستثناء نفسه الذي أُذن به لشاشة الملاحظات: زرٌّ بعرض
/// الشاشة تحت صندوق رسالة يأكل سطراً من المحادثة في كل شاشة. ومكانه ثابت: يخفت حين لا شيء يُرسل
/// ويشتعل حين يُكتب شيء، ولا يظهر ولا يختفي فيقفز الحقل تحته.
///
/// **الحقل يجري في اتجاه ما يُكتب فيه**: جملةٌ لاتينية تبدأ من اليسار وهي تُكتب، لا بعد إرسالها.
///
/// **النصّ يعيش هنا وحده**، في [controller] يملكه صاحب الشاشة: الـCubit يسمع الجملة مرّةً حين
/// تُرسل، لا مع كل حرف.
class ChatComposer extends StatefulWidget {
  const ChatComposer({
    required this.controller,
    required this.onSend,
    required this.onAttach,
    this.hint = 'اكتب رسالتك…',
    super.key,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final String hint;

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTyped);
  }

  @override
  void didUpdateWidget(covariant ChatComposer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTyped);
      widget.controller.addListener(_onTyped);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTyped);
    super.dispose();
  }

  /// بصريٌّ بحت: لون الزرّ واتجاه الحقل.
  void _onTyped() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = widget.controller.text;
    final canSend = text.trim().isNotEmpty;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 8.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: AppTextField(
                  controller: widget.controller,
                  hint: widget.hint,
                  minLines: 1,
                  maxLines: 5,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  textDirection: text.readingDirection,
                  suffix: IconButton(
                    onPressed: widget.onAttach,
                    tooltip: 'إرفاق صورة أو ملف',
                    icon: Icon(AppIcons.attach, size: 24.sp, color: scheme.onSurfaceVariant),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              _SendKey(active: canSend, onTap: canSend ? widget.onSend : null),
            ],
          ),
        ),
      ),
    );
  }
}

class _SendKey extends StatelessWidget {
  const _SendKey({required this.active, this.onTap});

  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final instant = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      button: true,
      enabled: active,
      label: 'أرسل',
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox.square(
          dimension: 52.w,
          child: Stack(
            alignment: Alignment.center,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(color: scheme.surfaceContainerHigh, shape: BoxShape.circle),
                child: const SizedBox.expand(),
              ),
              // اللون يتبدّل بالشفافية وحدها — الحركة المسموحة (RULES §7).
              AnimatedOpacity(
                opacity: active ? 1 : 0,
                duration: instant ? Duration.zero : const Duration(milliseconds: 160),
                child: DecoratedBox(
                  decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
                  child: const SizedBox.expand(),
                ),
              ),
              Icon(
                AppIcons.send,
                size: 22.sp,
                color: active ? scheme.onPrimary : scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
