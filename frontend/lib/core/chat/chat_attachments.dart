import 'package:cached_network_image/cached_network_image.dart';
import 'package:dayaa/core/chat/chat_message.dart';
import 'package:dayaa/core/theme/app_tones.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// عرضُ الصورة في المحادثة، وارتفاعها بنسبتها بين حدّين.
double get _imageWidth => 236.w;

double _imageHeightFor(double? aspectRatio) {
  final ratio = (aspectRatio ?? 4 / 3).clamp(0.62, 1.9);

  return (_imageWidth / ratio).clamp(132.h, 320.h);
}

/// مفتاحُ الصورة في الذاكرة المؤقتة: **رقم الرسالة لا الرابط.** الرابط موقَّعٌ يتغيّر مع كل قراءة،
/// والملف خلفه لا يتغيّر أبداً — مفتاحٌ من الرابط كان سيحمّل الصورة نفسها في كل مرة. وهو المفتاح
/// نفسه الذي يفتح به عارضُ الإيصالات الصورةَ ملء الشاشة، فلا تُنزَّل مرّتين.
String chatImageCacheKey(int messageId) => 'ticket-message-$messageId';

/// صورةٌ في المحادثة: مكانها محجوزٌ بنسبتها قبل أن تصل، فلا تقفز المحادثة، وتقدّمُ تحميلها ظاهرٌ
/// فوقها. منقولةٌ من تطبيق العميل.
class ChatRemoteImage extends StatelessWidget {
  const ChatRemoteImage({
    required this.messageId,
    required this.url,
    this.aspectRatio,
    this.onTap,
    this.cacheKey,
    super.key,
  });

  final int messageId;
  final String? url;
  final double? aspectRatio;
  final VoidCallback? onTap;

  /// مفتاحٌ غيرُ [chatImageCacheKey] — للتذاكر الداخلية، التي ترقيمُ مرفقاتها غيرُ ترقيم رسائل
  /// الدعم: الرقمُ نفسه في الجدولين كان سيُري صورةَ أحدهما في الآخر.
  final String? cacheKey;

  @override
  Widget build(BuildContext context) {
    final height = _imageHeightFor(aspectRatio);
    final link = url;

    return Semantics(
      image: true,
      button: onTap != null,
      label: 'صورة',
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13.r),
          child: SizedBox(
            width: _imageWidth,
            height: height,
            child: link == null
                ? const _ImagePlaceholder(failed: true)
                : CachedNetworkImage(
                    imageUrl: link,
                    cacheKey: cacheKey ?? chatImageCacheKey(messageId),
                    width: _imageWidth,
                    height: height,
                    fit: BoxFit.cover,
                    fadeInDuration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 180),
                    progressIndicatorBuilder: (context, _, progress) =>
                        _ImagePlaceholder(progress: progress.progress),
                    errorWidget: (context, _, _) => const _ImagePlaceholder(failed: true),
                  ),
          ),
        ),
      ),
    );
  }
}

/// ألبومُ صورٍ في رسالةٍ واحدة — **شكلُ بريمولا**: الصورُ حافّةً إلى حافّة بينها نَفَسان، وشكلٌ لكل
/// عدد. صورتان جنباً إلى جنب، وثلاثٌ كبيرةٌ وصغيرتان تحتها بعضُها فوق بعض، وأربعٌ فأكثر شبكةٌ
/// تحمل رابعتُها «+العدد» الباقي. **وعرضُه عرضُ الصورة الواحدة**، فلا تتّسع الفقاعة به.
///
/// [onOpen] برقم الصورة في الألبوم — يفتح العارضَ عليها، والباقي بالسحب.
class ChatImageAlbum extends StatelessWidget {
  const ChatImageAlbum({
    required this.images,
    required this.cacheKeyOf,
    required this.onOpen,
    super.key,
  });

  final List<ChatAttachment> images;
  final String Function(ChatAttachment photo) cacheKeyOf;
  final ValueChanged<int>? onOpen;

  static const double _gap = 2;

  @override
  Widget build(BuildContext context) {
    final width = _imageWidth;

    return ClipRRect(
      borderRadius: BorderRadius.circular(13.r),
      child: SizedBox(width: width, child: _mosaic(width)),
    );
  }

  Widget _mosaic(double width) => switch (images.length) {
    0 => const SizedBox.shrink(),
    1 => AspectRatio(aspectRatio: 4 / 3, child: _tile(0)),
    2 => SizedBox(
      height: (width - _gap) / 2,
      child: Row(
        children: [
          Expanded(child: _tile(0)),
          const SizedBox(width: _gap),
          Expanded(child: _tile(1)),
        ],
      ),
    ),
    3 => SizedBox(
      height: width * .62,
      child: Row(
        children: [
          Expanded(flex: 3, child: _tile(0)),
          const SizedBox(width: _gap),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Expanded(child: _tile(1)),
                const SizedBox(height: _gap),
                Expanded(child: _tile(2)),
              ],
            ),
          ),
        ],
      ),
    ),
    _ => SizedBox(
      height: width,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _tile(0)),
                const SizedBox(width: _gap),
                Expanded(child: _tile(1)),
              ],
            ),
          ),
          const SizedBox(height: _gap),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _tile(2)),
                const SizedBox(width: _gap),
                // الرابعةُ تحمل باقي الألبوم.
                Expanded(child: _tile(3, hiddenCount: images.length - 4)),
              ],
            ),
          ),
        ],
      ),
    ),
  };

  Widget _tile(int index, {int hiddenCount = 0}) {
    final photo = images[index];
    final link = photo.url;
    final open = onOpen;

    return Semantics(
      container: true,
      image: true,
      button: open != null,
      excludeSemantics: true,
      label: 'صورة ${index + 1} من ${images.length}',
      child: GestureDetector(
        onTap: open == null ? null : () => open(index),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (link == null)
              const _ImagePlaceholder(failed: true)
            else
              CachedNetworkImage(
                imageUrl: link,
                cacheKey: cacheKeyOf(photo),
                fit: BoxFit.cover,
                progressIndicatorBuilder: (context, _, progress) =>
                    _ImagePlaceholder(progress: progress.progress),
                errorWidget: (context, _, _) => const _ImagePlaceholder(failed: true),
              ),
            if (hiddenCount > 0)
              ColoredBox(
                // ألوانٌ ثابتة عمداً: الخلفيةُ صورةٌ لا سطحٌ من الثيم.
                color: Colors.black.withValues(alpha: .45),
                child: Center(
                  child: Text(
                    '+$hiddenCount',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({this.progress, this.failed = false});

  final double? progress;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return ColoredBox(
      color: scheme.surfaceContainerHigh,
      child: Center(
        child: failed
            ? Icon(AppIcons.offline, size: 30.sp, color: scheme.onSurfaceVariant)
            : SizedBox.square(
                dimension: 36.w,
                child: CircularProgressIndicator(
                  value: progress == null || progress! <= 0 ? null : progress,
                  strokeWidth: 2.4.w,
                ),
              ),
      ),
    );
  }
}

/// ملفٌّ في المحادثة — PDF أو ما لا يُرسم صورة: دائرةٌ بأيقونته، واسمُه، وسطرُه.
///
/// **شكلُ تطبيق العميل، وفتحٌ واحد**: يُفتح بعارض الإيصالات نفسه الذي تُفتح به الملفات في هذا
/// التطبيق، فلا حلقةَ تنزيلٍ هنا.
class ChatFileRow extends StatelessWidget {
  const ChatFileRow({
    required this.name,
    required this.caption,
    required this.fromDesk,
    this.isPdf = true,
    this.onTap,
    super.key,
  });

  final String name;

  /// «1.2 م.ب · PDF».
  final String caption;
  final bool fromDesk;
  final bool isPdf;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final ink = fromDesk ? scheme.onOutgoingBubble : scheme.onIncomingBubble;
    final metaInk = fromDesk ? scheme.outgoingMeta : scheme.incomingMeta;

    // على فقاعة المحل: دائرةٌ بحبر الفقاعة، وإلا ذاب لونُ العلامة في لونها الباهت.
    final (fill, glyph) = fromDesk
        ? (scheme.onOutgoingBubble, scheme.outgoingBubble)
        : (scheme.primary, scheme.onPrimary);

    return Semantics(
      button: onTap != null,
      label: 'فتح: $name',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: SizedBox(
          width: 232.w,
          child: Row(
            children: [
              Container(
                width: 46.w,
                height: 46.w,
                decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
                child: Icon(isPdf ? AppIcons.pdf : AppIcons.document, size: 20.sp, color: glyph),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      caption,
                      style: context.textTheme.bodySmall?.copyWith(color: metaInk),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// «3.2 م.ب» أو «840 ك.ب» — ما يكفي ليعرف الموظف أنه سيفتح ملفاً ثقيلاً قبل أن يلمسه.
String fileSizeLabel(int bytes) {
  if (bytes >= 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} م.ب';

  return '${(bytes / 1024).ceil()} ك.ب';
}
