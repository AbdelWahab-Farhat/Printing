import 'package:dayaa_client/core/theme/app_tones.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/utils/dates.dart';
import 'package:dayaa_client/core/utils/text_direction.dart';
import 'package:dayaa_client/features/support/presentation/widgets/chat_bubble_border.dart';
import 'package:dayaa_client/features/support/presentation/widgets/delivery_ticks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// عرضُ ذيل الفقاعة، ويُحجز من جهتها لكل فقاعات السلسلة كي تصطفّ حوافّها.
double get chatTailWidth => 7.w;

/// أقصى عرضٍ للفقاعة: ما يكفي لسطرٍ مريح، ويبقى فراغٌ في الجهة الأخرى يقول مَن المتكلّم.
double get chatBubbleMaxWidth => 0.76.sw;

/// فقاعةٌ واحدة: نصٌّ، أو ملفٌّ، أو كلاهما — ووقتها وعلامة وصولها في زاويتها.
///
/// **رسائلي في نهاية السطر ورسائل الدعم في بدايته**، كما في شاشة الملاحظات التي قبلها صاحب
/// المحل: `end` في هذا التطبيق العربي هو اليسار. **وكلّ جملةٍ تجري كما كُتبت** — «ok» أو اسم
/// ملفٍّ لاتيني يُرسم من اليسار داخل الفقاعة نفسها، انظر [ReadingDirection].
///
/// **الوقت على آخر سطرٍ من الكلام حين يتّسع له**، وإلا نزل إلى سطرٍ وحده — حيلةُ تيليغرام: نسخةٌ
/// شفّافة من الوقت في آخر النص تحجز مكانه، والوقت الظاهر فوقها في الزاوية. تصحّ حين تجري الجملة
/// في اتجاه الفقاعة؛ جملةٌ تجري عكسه ينزل وقتها إلى سطره.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    required this.isMine,
    required this.startsRun,
    required this.endsRun,
    this.sentAt,
    this.delivery,
    this.text = '',
    this.attachment,
    this.imageOnly = false,
    this.failed = false,
    this.onFailedTap,
    this.onLongPress,
    this.detached = false,
    super.key,
  });

  final bool isMine;
  final bool startsRun;
  final bool endsRun;
  final DateTime? sentAt;

  /// علامة الوصول — على رسائلي وحدها.
  final Delivery? delivery;

  final String text;

  /// الصورة أو الملف، فوق النص إن كان.
  final Widget? attachment;

  /// صورةٌ بلا تعليق: الوقت يطفو فوق الصورة نفسها في زاويتها.
  final bool imageOnly;

  /// لم تُرسل: علامةٌ حمراء بجانب الفقاعة، تفتح «أعد الإرسال» و«احذف».
  final bool failed;
  final VoidCallback? onFailedTap;

  /// الضغطة المطوّلة — تُمرَّر سياقُ الفقاعة نفسها، كي تُرفع القائمة فوقها في مكانها.
  final void Function(BuildContext bubbleContext)? onLongPress;

  /// الفقاعة وحدها، بلا صفّها ولا هوامشها ولا لمسها — لتُرسم فوق ضباب قائمة الرسالة في المستطيل
  /// نفسه الذي كانت فيه. انظر `showMessageMenu`.
  final bool detached;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final fill = isMine ? scheme.outgoingBubble : scheme.incomingBubble;
    final ink = isMine ? scheme.onOutgoingBubble : scheme.onIncomingBubble;
    final metaInk = isMine ? scheme.outgoingMeta : scheme.incomingMeta;
    final edge = isMine ? scheme.outgoingBubbleEdge : scheme.incomingBubbleEdge;
    final hasText = text.trim().isNotEmpty;

    final meta = _Meta(sentAt: sentAt, delivery: delivery, color: metaInk);

    final content = switch ((attachment, hasText)) {
      // صورةٌ بلا تعليق: إطارٌ رفيع حولها، والوقت فوقها في شريطٍ داكن.
      (final Widget file?, false) when imageOnly => Stack(
        children: [
          file,
          PositionedDirectional(
            end: 6.w,
            bottom: 6.w,
            child: _MetaOnImage(sentAt: sentAt, delivery: delivery),
          ),
        ],
      ),
      (final Widget file?, false) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [file, SizedBox(height: 4.h), meta],
      ),
      (final Widget file?, true) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          file,
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(imageOnly ? 8.w : 0, 6.h, imageOnly ? 8.w : 0, 0),
            child: _TextWithMeta(text: text, ink: ink, meta: meta),
          ),
        ],
      ),
      (null, _) => _TextWithMeta(text: text, ink: ink, meta: meta),
    };

    final padding = imageOnly
        ? EdgeInsets.all(3.w)
        : attachment != null
        ? EdgeInsetsDirectional.fromSTEB(9.w, 9.w, 9.w, 6.h)
        : EdgeInsetsDirectional.fromSTEB(11.w, 6.h, 11.w, 5.h);

    final shape = DecoratedBox(
      decoration: ShapeDecoration(
        color: fill,
        shape: ChatBubbleBorder(
          atEnd: isMine,
          hasTail: endsRun,
          startsRun: startsRun,
          radius: 16.r,
          tightRadius: 6.r,
          tailWidth: chatTailWidth,
          side: edge.a == 0 ? BorderSide.none : BorderSide(color: edge, width: 1),
        ),
      ),
      child: Padding(padding: padding, child: content),
    );

    if (detached) return shape;

    final bubble = Builder(
      builder: (bubbleContext) => GestureDetector(
        onLongPress: onLongPress == null ? null : () => onLongPress!(bubbleContext),
        child: shape,
      ),
    );

    return Padding(
      padding: EdgeInsets.only(top: startsRun ? 8.h : 2.h),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (failed && isMine) ...[
            _FailedBadge(onTap: onFailedTap),
            SizedBox(width: 6.w),
          ],
          Flexible(
            child: Padding(
              // الذيل خارج الفقاعة: يُحجز عرضه من جهتها لكل رسائل السلسلة، فتصطفّ حوافّها.
              padding: EdgeInsetsDirectional.only(
                start: isMine ? 0 : chatTailWidth,
                end: isMine ? chatTailWidth : 0,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: chatBubbleMaxWidth),
                child: bubble,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// النصّ، والوقتُ في زاوية سطره الأخير حين يتّسع.
class _TextWithMeta extends StatelessWidget {
  const _TextWithMeta({required this.text, required this.ink, required this.meta});

  final String text;
  final Color ink;
  final Widget meta;

  @override
  Widget build(BuildContext context) {
    final style = context.textTheme.bodyLarge?.copyWith(color: ink, height: 1.45);
    final own = text.readingDirection;
    final bubbleDirection = Directionality.of(context);

    // جملةٌ تجري عكس الفقاعة: آخرُ سطرها في الطرف الآخر، فينزل الوقت إلى سطرٍ وحده.
    if (own != null && own != bubbleDirection) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(text, textDirection: own, style: style),
          SizedBox(height: 2.h),
          meta,
        ],
      );
    }

    return Stack(
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: text),
              // نسخةٌ شفّافة تحجز مكان الوقت في آخر السطر الأخير.
              WidgetSpan(
                child: ExcludeSemantics(
                  child: Opacity(
                    opacity: 0,
                    child: Padding(padding: EdgeInsetsDirectional.only(start: 10.w), child: meta),
                  ),
                ),
              ),
            ],
          ),
          textDirection: own,
          style: style,
        ),
        PositionedDirectional(end: 0, bottom: 0, child: meta),
      ],
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.sentAt, required this.delivery, required this.color});

  final DateTime? sentAt;
  final Delivery? delivery;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (sentAt case final at?)
          Text(
            at.timeLabel,
            textDirection: TextDirection.rtl,
            style: context.textTheme.labelSmall?.copyWith(color: color, height: 1.2),
          ),
        if (delivery case final state?) ...[
          SizedBox(width: 4.w),
          DeliveryTicks(delivery: state, color: color),
        ],
      ],
    );
  }
}

/// الوقت فوق صورةٍ بلا تعليق: شريطٌ داكن نصف شفّاف، أبيضُ عليه — يُقرأ على أيّ صورة.
class _MetaOnImage extends StatelessWidget {
  const _MetaOnImage({required this.sentAt, required this.delivery});

  final DateTime? sentAt;
  final Delivery? delivery;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10.r)),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
        child: _Meta(sentAt: sentAt, delivery: delivery, color: Colors.white),
      ),
    );
  }
}

class _FailedBadge extends StatelessWidget {
  const _FailedBadge({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'لم تُرسل',
      child: InkResponse(
        onTap: onTap,
        radius: 20.r,
        child: Icon(AppIcons.error, size: 24.sp, color: context.colorScheme.error),
      ),
    );
  }
}
