import 'dart:async';

import 'package:dayaa/core/chat/chat_attachments.dart';
import 'package:dayaa/core/chat/chat_avatar.dart';
import 'package:dayaa/core/chat/chat_message.dart';
import 'package:dayaa/core/chat/chat_pill.dart';
import 'package:dayaa/core/chat/chat_thread_timeline.dart';
import 'package:dayaa/core/chat/delivery_ticks.dart';
import 'package:dayaa/core/chat/message_bubble.dart';
import 'package:dayaa/core/chat/message_menu.dart';
import 'package:dayaa/core/chat/reply_quote.dart';
import 'package:dayaa/core/chat/swipe_to_reply.dart';
import 'package:dayaa/core/chat/voice_note_view.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/voice/voice_playback.dart';
import 'package:dayaa/core/widgets/app_dialog.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/core/widgets/receipt_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// ما تفعله فقاعةٌ برسالتها — يملكه الـCubit صاحبُ المحادثة، والفقاعةُ تناديه.
///
/// **محادثتان على هذه القطع** (DESIGN-TICKET-CHAT): التذاكر الداخلية ومحادثة تذكرة التصميم. ما
/// يُرسم واحد، وما يختلف بينهما هو مَن يُنادى.
@immutable
class ChatThreadActions {
  const ChatThreadActions({
    required this.reply,
    required this.edit,
    required this.retract,
    required this.refresh,
  });

  /// يختار الرسالةَ التي يُردّ عليها — سحبٌ جانبيّ أو «ردّ» من قائمتها.
  final void Function(ChatMessage message) reply;

  /// يغيّر نصَّ رسالتي — والخادمُ يرفض بعد عشرين دقيقة بجملته.
  final Future<bool> Function(int messageId, String body) edit;

  /// يسحب رسالتي: تبقى مكانها «تم حذف هذه الرسالة».
  final Future<bool> Function(int messageId) retract;

  /// السحبُ للأسفل يعيد قراءة المحادثة.
  final Future<void> Function() refresh;
}

/// المحادثة — **مقلوبةٌ تبدأ من آخرها**، كمحادثة الدعم وكلِّ تطبيق محادثة.
///
/// [readUpTo] إلى أين قرأ الطرفُ الآخر عندي — رسائلي حتى رقمه ✓✓. و[showsDelivery] `false` لمن ليس
/// طرفاً: لا علامةَ على كلامٍ لا «آخرَ» يقرؤه عنده. و[attachmentScope] اسمُ المحادثة في مفاتيح
/// الصور والأصوات على الهاتف — انظر [VoicePlayback.keyForAttachment].
class ChatThreadConversation extends StatelessWidget {
  const ChatThreadConversation({
    required this.messages,
    required this.me,
    required this.controller,
    required this.actions,
    required this.canReply,
    this.closedNotice,
    this.readUpTo,
    this.showsDelivery = false,
    this.attachmentScope = '',
    super.key,
  });

  final List<ChatMessage> messages;
  final int? me;
  final ScrollController controller;
  final ChatThreadActions actions;
  final bool canReply;

  /// سطرُ الخدمة في آخرها حين انتهت.
  final String? closedNotice;
  final int? readUpTo;
  final bool showsDelivery;
  final String attachmentScope;

  @override
  Widget build(BuildContext context) {
    final items = chatThreadTimeline(
      messages: messages,
      closedNotice: closedNotice,
    ).reversed.toList(growable: false);

    return RefreshIndicator(
      onRefresh: actions.refresh,
      child: ListView.builder(
        controller: controller,
        reverse: true,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(8.w, 10.h, 8.w, 12.h),
        itemCount: items.length,
        itemBuilder: (context, index) => switch (items[index]) {
          ChatThreadDay(:final day) => ChatPill.day(day),
          ChatThreadNotice(:final label) => ChatPill(label),
          final ChatThreadEntry entry => ChatThreadMessage(
            entry: entry,
            me: me,
            actions: actions,
            canReply: canReply,
            readUpTo: readUpTo,
            showsDelivery: showsDelivery,
            attachmentScope: attachmentScope,
          ),
        },
      ),
    );
  }
}

/// رسالةٌ واحدة في سلسلتها.
class ChatThreadMessage extends StatelessWidget {
  const ChatThreadMessage({
    required this.entry,
    required this.me,
    required this.actions,
    required this.canReply,
    this.readUpTo,
    this.showsDelivery = false,
    this.attachmentScope = '',
    super.key,
  });

  final ChatThreadEntry entry;
  final int? me;
  final ChatThreadActions actions;
  final bool canReply;
  final int? readUpTo;
  final bool showsDelivery;
  final String attachmentScope;

  @override
  Widget build(BuildContext context) {
    final message = entry.message;
    final mine = message.isFrom(me);
    final deleted = message.isDeleted;
    final voice = deleted ? null : message.voice;
    final image = deleted ? null : message.image;
    final body = message.body ?? '';
    final readUpTo = this.readUpTo;

    MessageBubble bubble({bool detached = false}) => MessageBubble(
      fromDesk: mine,
      startsRun: entry.startsRun,
      endsRun: entry.endsRun,
      sentAt: message.sentAt,
      // ✓✓ حين يكون رقمُها ضمن ما رآه زميلي. ولا علامةَ لمن ليس طرفاً.
      delivery: mine && showsDelivery
          ? (readUpTo != null && message.id <= readUpTo ? Delivery.read : Delivery.sent)
          : null,
      readLabel: 'قرأها زميلك',
      text: body,
      // الاسمُ على كلام الآخرين وحده — ومَن ليس طرفاً يرى الاسمين.
      author: mine ? null : message.author?.name,
      avatar: ChatAvatar.desk(name: message.author?.name),
      imageOnly: image != null && body.trim().isEmpty,
      isEdited: message.isEdited,
      isDeleted: deleted,
      quote: switch (message.replyTo) {
        null => null,
        final quoted => ReplyQuote(
          authorName: quoted.authorName,
          preview: quoted.preview,
          isDeleted: quoted.isDeleted,
          outgoing: mine,
        ),
      },
      attachment: switch ((voice, image)) {
        (final ChatAttachment note?, _) => VoiceNoteView(
          playbackKey: VoicePlayback.keyForAttachment(note.id, scope: attachmentScope),
          outgoing: mine,
          url: note.url,
          durationSeconds: note.durationSeconds,
          waveform: note.waveform,
        ),
        (_, final ChatAttachment photo?) => ChatRemoteImage(
          messageId: message.id,
          cacheKey: _imageKey(photo),
          url: photo.url,
          aspectRatio: _aspectRatioOf(photo),
          onTap: detached ? null : () => unawaited(_openImage(context, photo)),
        ),
        _ => null,
      },
      detached: detached,
      onLongPress: deleted
          ? null
          : (bubbleContext) => unawaited(
              showMessageMenu(
                bubbleContext,
                alignsToEnd: mine,
                preview: bubble(detached: true),
                actions: [
                  if (canReply)
                    MessageMenuAction(
                      label: 'ردّ',
                      icon: AppIcons.reply,
                      onSelected: () => actions.reply(message),
                    ),
                  if (body.trim().isNotEmpty)
                    MessageMenuAction(
                      label: 'نسخ',
                      icon: AppIcons.copy,
                      onSelected: () => unawaited(_copy(context, body)),
                    ),
                  if (image != null)
                    MessageMenuAction(
                      label: 'فتح الصورة',
                      icon: AppIcons.photos,
                      onSelected: () => unawaited(_openImage(context, image)),
                    ),
                  if (message.canEdit && voice == null)
                    MessageMenuAction(
                      label: 'تعديل',
                      icon: AppIcons.edit,
                      onSelected: () => unawaited(_edit(context, message)),
                    ),
                  if (message.canDelete)
                    MessageMenuAction(
                      label: 'حذف',
                      icon: AppIcons.delete,
                      isDestructive: true,
                      onSelected: () => unawaited(_retract(context, message)),
                    ),
                ],
              ),
            ),
    );

    return SwipeToReply(
      enabled: canReply && !deleted,
      onReply: () => actions.reply(message),
      child: bubble(),
    );
  }

  /// مفتاحُ الصورة على الهاتف. **التذاكر الداخلية بمفتاحها الذي كان**، فلا يُنزَّل ما حُفظ ثانيةً.
  String _imageKey(ChatAttachment photo) => attachmentScope.isEmpty
      ? 'internal-attachment-${photo.id}'
      : '$attachmentScope-attachment-${photo.id}';

  static double? _aspectRatioOf(ChatAttachment file) {
    final (width, height) = (file.widthPx, file.heightPx);

    return width == null || height == null || height == 0 ? null : width / height;
  }

  Future<void> _openImage(BuildContext context, ChatAttachment photo) =>
      showReceipt(context, Receipt(cacheKey: _imageKey(photo), url: photo.url, isImage: true));

  static Future<void> _copy(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));

    if (context.mounted) context.showSuccess('نُسخ النص');
  }

  Future<void> _edit(BuildContext context, ChatMessage message) async {
    final body = await showDialog<String>(
      context: context,
      builder: (context) => _EditMessageDialog(initial: message.body ?? ''),
    );

    if (body == null) return;

    await actions.edit(message.id, body);
  }

  Future<void> _retract(BuildContext context, ChatMessage message) async {
    final confirmed = await showDestructiveDialog(
      context: context,
      title: 'حذف الرسالة؟',
      description: 'تبقى مكانها في المحادثة وتقول «تم حذف هذه الرسالة».',
    );

    if (confirmed != true) return;

    await actions.retract(message.id);
  }
}

/// تعديلُ نصّ رسالة. **الحوارُ يملك حقلَه ويتخلّص منه بنفسه** — لا من استدعاه بعد أن يعود
/// `showDialog`: حركةُ الخروج ما زالت ترسم الحقل.
class _EditMessageDialog extends StatefulWidget {
  const _EditMessageDialog({required this.initial});

  final String initial;

  @override
  State<_EditMessageDialog> createState() => _EditMessageDialogState();
}

class _EditMessageDialogState extends State<_EditMessageDialog> {
  late final TextEditingController _text = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تعديل الرسالة'),
      content: AppTextField(
        controller: _text,
        hint: 'نص الرسالة',
        minLines: 1,
        maxLines: 6,
        keyboardType: TextInputType.multiline,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_text.text),
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}

/// صوتٌ لم يصل، فوق الصندوق: يُسمع من الهاتف، ويُعاد أو يُرمى.
class UnsentVoiceBar extends StatelessWidget {
  const UnsentVoiceBar({
    required this.voice,
    required this.isWorking,
    required this.onRetry,
    required this.onDiscard,
    super.key,
  });

  final PendingVoice voice;
  final bool isWorking;
  final VoidCallback onRetry;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(8.w, 6.h, 4.w, 6.h),
        child: Row(
          children: [
            Expanded(
              child: VoiceNoteView(
                playbackKey: 'unsent-${voice.clientToken}',
                outgoing: false,
                localPath: voice.path,
                durationSeconds: voice.durationSeconds,
                waveform: voice.waveform,
              ),
            ),
            IconButton(
              onPressed: isWorking ? null : onRetry,
              tooltip: 'لم تُرسل — أعد الإرسال',
              icon: Icon(AppIcons.resend, color: scheme.error),
            ),
            IconButton(
              onPressed: isWorking ? null : onDiscard,
              tooltip: 'احذف التسجيل',
              icon: Icon(AppIcons.delete, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// مكانَ الصندوق حين لا يُكتب: مغلقة، أو قارئٌ لا يكتب.
class ChatThreadFootnote extends StatelessWidget {
  const ChatThreadFootnote({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
          child: Row(
            children: [
              Icon(AppIcons.threadClosed, size: 20.sp, color: scheme.onSurfaceVariant),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  text,
                  style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// «إلى آخر المحادثة» — بالتلاشي وحده، كمحادثة الدعم.
class JumpToLatestButton extends StatelessWidget {
  const JumpToLatestButton({required this.visible, required this.onTap, super.key});

  final bool visible;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 160),
        child: Semantics(
          button: true,
          label: 'إلى آخر المحادثة',
          child: Material(
            color: scheme.surface,
            shape: CircleBorder(side: BorderSide(color: scheme.outlineVariant)),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: SizedBox.square(
                dimension: 44.w,
                child: Icon(AppIcons.expand, size: 26.sp, color: scheme.onSurfaceVariant),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
