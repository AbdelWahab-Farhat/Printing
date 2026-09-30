import 'package:dayaa/core/theme/app_tones.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/core/utils/text_direction.dart';
import 'package:dayaa/features/support/presentation/widgets/chat_bubble_border.dart';
import 'package:dayaa/features/support/presentation/widgets/delivery_ticks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// عرضُ ذيل الفقاعة، ويُحجز من جهتها لكل فقاعات السلسلة كي تصطفّ حوافّها.
double get chatTailWidth => 7.w;

/// قطرُ صورة المتكلّم بجانب آخر فقاعةٍ من سلسلته.
double get chatAvatarSize => 30.w;

/// فقاعةٌ واحدة: نصٌّ، أو ملفٌّ، أو كلاهما — ووقتها وعلامة وصولها في زاويتها.
///
/// **منقولةٌ من تطبيق العميل**، وعليها ما تحتاجه شاشةُ الموظف فوق ذلك، كما في بريمولا:
///
/// * **اسمُ الزميل** فوق أوّل فقاعةٍ من سلسلته ([author]) — «من ردّ عليه؟» سؤالٌ يحقّ للمحل أن
///   يسأله نفسه. وكلامُ العميل بلا اسم: الشريطُ فوق المحادثة يسمّيه.
/// * **صورةُ المتكلّم** ([avatar]) بجانب آخر فقاعةٍ من السلسلة، حيث يشير الذيل — كمحادثات
///   المجموعات في تيليغرام؛ ومكانُها محجوزٌ لبقية السلسلة كي تصطفّ الحوافّ.
///
/// **ردود المحل في نهاية السطر وكلام العميل في بدايته**، كشاشة الملاحظات وتطبيق العميل: `end`
/// في هذا التطبيق العربي هو اليسار. **وكلّ جملةٍ تجري كما كُتبت** — انظر [ReadingDirection].
///
/// **الوقت على آخر سطرٍ من الكلام حين يتّسع له**، وإلا نزل إلى سطرٍ وحده — حيلةُ تيليغرام: نسخةٌ
/// شفّافة من الوقت في آخر النص تحجز مكانه، والوقت الظاهر فوقها في الزاوية.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    required this.fromDesk,
    required this.startsRun,
    required this.endsRun,
    this.sentAt,
    this.delivery,
    this.text = '',
    this.author,
    this.avatar,
    this.attachment,
    this.imageOnly = false,
    this.onLongPress,
    this.detached = false,
    super.key,
  });

  /// ردُّ المحل — في نهاية السطر وبلون العلامة.
  final bool fromDesk;
  final bool startsRun;
  final bool endsRun;
  final DateTime? sentAt;

  /// علامة الوصول — على ردود المحل وحدها.
  final Delivery? delivery;

  final String text;

  /// اسمُ الزميل فوق أوّل فقاعةٍ من سلسلته. فارغٌ على كلام العميل.
  final String? author;

  /// صورةُ المتكلّم، تُرسم بجانب آخر فقاعةٍ من السلسلة.
  final Widget? avatar;

  /// الصورة أو الملف، فوق النص إن كان.
  final Widget? attachment;

  /// صورةٌ بلا تعليق: الوقت يطفو فوق الصورة نفسها في زاويتها.
  final bool imageOnly;

  /// الضغطة المطوّلة — تُمرَّر سياقُ الفقاعة نفسها، كي تُرفع القائمة فوقها في مكانها.
  final void Function(BuildContext bubbleContext)? onLongPress;

  /// الفقاعة وحدها، بلا صفّها ولا صورتها ولا لمسها — لتُرسم فوق ضباب قائمة الرسالة في المستطيل
  /// نفسه الذي كانت فيه. انظر `showMessageMenu`.
  final bool detached;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final fill = fromDesk ? scheme.outgoingBubble : scheme.incomingBubble;
    final ink = fromDesk ? scheme.onOutgoingBubble : scheme.onIncomingBubble;
    final metaInk = fromDesk ? scheme.outgoingMeta : scheme.incomingMeta;
    final edge = fromDesk ? scheme.outgoingBubbleEdge : scheme.incomingBubbleEdge;
    final hasText = text.trim().isNotEmpty;
    final name = startsRun ? author?.trim() : null;
    final hasName = name != null && name.isNotEmpty;

    final meta = _Meta(sentAt: sentAt, delivery: delivery, color: metaInk);

    final body = switch ((attachment, hasText)) {
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

    final content = hasName
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: imageOnly
                    ? EdgeInsetsDirectional.fromSTEB(8.w, 4.h, 8.w, 4.h)
                    : EdgeInsets.only(bottom: 2.h),
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.labelLarge?.copyWith(
                    color: metaInk,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              body,
            ],
          )
        : body;

    final padding = imageOnly
        ? EdgeInsets.all(3.w)
        : attachment != null
        ? EdgeInsetsDirectional.fromSTEB(9.w, 9.w, 9.w, 6.h)
        : EdgeInsetsDirectional.fromSTEB(11.w, 6.h, 11.w, 5.h);

    final shape = DecoratedBox(
      decoration: ShapeDecoration(
        color: fill,
        shape: ChatBubbleBorder(
          atEnd: fromDesk,
          hasTail: endsRun,
          startsRun: startsRun,
          radius: 16.r,
          tightRadius: 6.r,
          tailWidth: chatTailWidth,
          side: edge.a == 0 ? BorderSide.none : BorderSide(color: edge),
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

    // الصورةُ بجانب آخر السلسلة، ومكانُها فارغٌ محجوزٌ لبقيتها.
    final lane = SizedBox(
      width: chatAvatarSize,
      child: endsRun ? avatar : null,
    );

    return Padding(
      padding: EdgeInsets.only(top: startsRun ? 8.h : 2.h),
      child: Row(
        mainAxisAlignment: fromDesk ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!fromDesk) lane,
          Flexible(
            child: Padding(
              // الذيل خارج الفقاعة: يُحجز عرضه من جهتها لكل رسائل السلسلة، فتصطفّ حوافّها.
              padding: EdgeInsetsDirectional.only(
                start: fromDesk ? 0 : chatTailWidth,
                end: fromDesk ? chatTailWidth : 0,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 0.72.sw),
                child: bubble,
              ),
            ),
          ),
          if (fromDesk) lane,
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
