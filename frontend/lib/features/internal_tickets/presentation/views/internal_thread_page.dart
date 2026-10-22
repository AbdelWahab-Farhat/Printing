import 'dart:async';

import 'package:dayaa/core/chat/chat_attachments.dart';
import 'package:dayaa/core/chat/chat_avatar.dart';
import 'package:dayaa/core/chat/chat_composer.dart';
import 'package:dayaa/core/chat/chat_pill.dart';
import 'package:dayaa/core/chat/delivery_ticks.dart';
import 'package:dayaa/core/chat/message_bubble.dart';
import 'package:dayaa/core/chat/message_menu.dart';
import 'package:dayaa/core/chat/reply_quote.dart';
import 'package:dayaa/core/chat/swipe_to_reply.dart';
import 'package:dayaa/core/chat/voice_note_view.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/files/attachment_picker.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/theme/app_tones.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/voice/voice_playback.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_dialog.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/core/widgets/attachment_sheet.dart';
import 'package:dayaa/core/widgets/receipt_viewer.dart';
import 'package:dayaa/features/internal_tickets/models/internal_ticket.dart';
import 'package:dayaa/features/internal_tickets/presentation/viewmodel/internal_chat_timeline.dart';
import 'package:dayaa/features/internal_tickets/presentation/viewmodel/internal_thread_cubit.dart';
import 'package:dayaa/features/internal_tickets/presentation/widgets/colleague_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// محادثةُ تذكرةٍ داخلية — **مرسومةً كمحادثة بريمولا وتيليغرام**، وعلى أجزاء محادثة الدعم نفسها.
///
/// * **الشريط**: الزميلُ في الوسط وتحته الكودُ والحالة، وما يُفعل بها في «⋮» — الإغلاقُ والتحويل
///   والطلبيةُ والعميل. والعنوانُ مثبّتٌ تحته.
/// * **الرسائل**: فقاعاتٌ بذيلٍ في سلاسل، والوقتُ و✓/✓✓ في زاويتها، و«معدّلة»، والمسحوبةُ مكانها.
///   الصوتُ زرٌّ وموجةٌ تمتلئ، والصورةُ تُفتح ملء الشاشة.
/// * **الردّ على رسالة**: اسحبها جانباً، أو «ردّ» من قائمة الضغطة المطوّلة — فيُقتبس فوق الصندوق.
/// * **الصندوق**: اكتب وأرسل، أو اضغط على الميكروفون وأمسك لتسجّل (انظر `VoiceComposerRow`).
///
/// **فتحُها يعلّمها مقروءة** على الخادم — لطرفيها. والمديرُ الذي ليس طرفاً يقرأ ولا يكتب.
class InternalThreadPage extends StatelessWidget {
  const InternalThreadPage({required this.ticketId, super.key});

  final int ticketId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<InternalThreadCubit>(
      create: (_) => sl<InternalThreadCubit>(param1: ticketId)..load(),
      child: const _ThreadView(),
    );
  }
}

enum _ThreadAction { close, transfer, openOrder, openCustomer }

class _ThreadView extends StatefulWidget {
  const _ThreadView();

  @override
  State<_ThreadView> createState() => _ThreadViewState();
}

class _ThreadViewState extends State<_ThreadView> {
  final _reply = TextEditingController();
  final _scroll = ScrollController();

  /// زرّ «إلى آخر المحادثة» — حالةٌ بصريةٌ بحتة.
  bool _awayFromLatest = false;

  late final VoicePlayback _playback = sl<VoicePlayback>();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    // رسالةٌ صوتية لا تبقى تُسمع من محادثةٍ أُغلقت.
    unawaited(_playback.stop());
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    _reply.dispose();
    super.dispose();
  }

  void _onScroll() {
    final away = _scroll.hasClients && _scroll.offset > 280.h;

    if (away != _awayFromLatest) setState(() => _awayFromLatest = away);
  }

  void _toLatest() {
    if (!_scroll.hasClients) return;

    if (MediaQuery.disableAnimationsOf(context)) {
      _scroll.jumpTo(0);
    } else {
      unawaited(
        _scroll.animateTo(0, duration: const Duration(milliseconds: 280), curve: Curves.easeOut),
      );
    }
  }

  Future<void> _send() async {
    final sent = await context.read<InternalThreadCubit>().sendText(_reply.text);

    // يُمسح عند النجاح وحده: ردٌّ لم يُرسل يبقى في الصندوق.
    if (!sent) return;

    _reply.clear();
    _toLatest();
  }

  /// صورةٌ من الهاتف — صورٌ فقط، كبريمولا — وما في الصندوق تعليقاً.
  Future<void> _attach() async {
    final source = await showAttachmentSheet(
      context: context,
      title: 'إرفاق صورة',
      sources: const [AttachmentSource.photos, AttachmentSource.camera],
    );
    if (source == null || !mounted) return;

    final picked = await sl<AttachmentPicker>().pick(
      source,
      extensions: const ['jpg', 'jpeg', 'png', 'webp'],
    );
    if (picked.isEmpty || !mounted) return;

    final sent = await context.read<InternalThreadCubit>().sendImage(
      picked.first,
      caption: _reply.text,
    );

    if (!sent) return;

    _reply.clear();
    _toLatest();
  }

  List<_ThreadAction> _actionsFor(InternalTicket ticket) => [
    if (ticket.order != null) _ThreadAction.openOrder,
    if (ticket.customer != null && sl<Session>().can(AppPermission.viewCustomers))
      _ThreadAction.openCustomer,
    if (ticket.canTransfer) _ThreadAction.transfer,
    if (ticket.canClose) _ThreadAction.close,
  ];

  Future<void> _onAction(_ThreadAction action, InternalTicket ticket) async {
    switch (action) {
      case _ThreadAction.openOrder:
        if (ticket.order case final order?) unawaited(context.push(Routes.order(order.id)));
      case _ThreadAction.openCustomer:
        if (ticket.customer case final customer?) {
          unawaited(context.push(Routes.customer(customer.id)));
        }
      case _ThreadAction.transfer:
        await _transfer(ticket);
      case _ThreadAction.close:
        await _close();
    }
  }

  Future<void> _close() async {
    final confirmed = await showDestructiveDialog(
      context: context,
      title: 'إغلاق التذكرة؟',
      description: 'الإغلاق نهائي: لا يُكتب فيها بعده. من عنده ما يضيفه يفتح تذكرةً جديدة.',
      confirmLabel: 'إغلاق',
    );

    if (confirmed != true || !mounted) return;

    await context.read<InternalThreadCubit>().closeTicket();
  }

  /// «تحويل»: موظفٌ يحلّ محلّ صاحبها — لا الزميلُ الذي وُجّهت إليه، ولا صاحبُها نفسه.
  Future<void> _transfer(InternalTicket ticket) async {
    final cubit = context.read<InternalThreadCubit>();
    final colleagues = await cubit.colleaguesForTransfer();

    if (!mounted || colleagues.isEmpty) return;

    final chosen = await showColleaguePicker(
      context: context,
      colleagues: colleagues,
      title: 'تحويل التذكرة إلى',
      excluding: {?ticket.opener?.id, ?ticket.assignee?.id},
    );

    if (chosen == null || !mounted) return;

    final confirmed = await showCustomDialog(
      context: context,
      title: 'تحويل التذكرة إلى ${chosen.name}؟',
      description:
          'يصير صاحبَها بدلك، ويبقى ${ticket.assignee?.name ?? 'الزميل'} كما هو. '
          'ولن تراها بعدها إلا إن كنت طرفاً فيها.',
      confirmLabel: 'تحويل',
    );

    if (confirmed != true || !mounted) return;

    final moved = await cubit.transferTo(chosen.id);

    if (!moved || !mounted) return;

    context.showSuccess('حُوّلت التذكرة إلى ${chosen.name}');

    // خرجتُ منها — إلا إن كنتُ المدير — فلا محادثةَ أبقى عليها.
    final state = cubit.state;
    if (state is InternalThreadLoaded && !state.ticket.isParty && !sl<Session>().isAdmin) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InternalThreadCubit, InternalThreadState>(
      listenWhen: (previous, current) =>
          current is InternalThreadLoaded && current.lastFailure != null,
      listener: (context, state) {
        if (state case InternalThreadLoaded(:final lastFailure?)) context.showFailure(lastFailure);
      },
      builder: (context, state) => switch (state) {
        InternalThreadLoading() => Scaffold(
          appBar: AppBar(),
          body: const Center(child: CircularProgressIndicator()),
        ),
        InternalThreadFailure(:final failure) => Scaffold(
          appBar: AppBar(),
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(failure.message, textAlign: TextAlign.center),
                  SizedBox(height: 16.h),
                  AppButton.outlined(
                    label: 'أعد المحاولة',
                    icon: AppIcons.refresh,
                    onPressed: () => unawaited(context.read<InternalThreadCubit>().load()),
                  ),
                ],
              ),
            ),
          ),
        ),
        final InternalThreadLoaded loaded => _loaded(context, loaded),
      },
    );
  }

  Widget _loaded(BuildContext context, InternalThreadLoaded state) {
    final ticket = state.ticket;
    final scheme = context.colorScheme;
    final cubit = context.read<InternalThreadCubit>();
    final me = cubit.me;
    final actions = _actionsFor(ticket);
    final other = ticket.otherSideOf(me);

    return PopScope(
      canPop: false,
      // القائمةُ خلفها تريد التذكرة عائدة — شارتُها مطفأة — فلا تعيد قراءة صفحتها.
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(ticket);
      },
      child: Scaffold(
        backgroundColor: scheme.chatBackdrop,
        appBar: AppBar(
          centerTitle: true,
          title: Column(
            children: [
              Text(
                other?.name ??
                    [ticket.opener?.name, ticket.assignee?.name].whereType<String>().join(' ← '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                [ticket.code, ticket.statusLabel].where((part) => part.isNotEmpty).join(' · '),
                style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          actions: [
            if (actions.isNotEmpty)
              PopupMenuButton<_ThreadAction>(
                enabled: !state.isWorking,
                icon: Icon(AppIcons.more),
                onSelected: (action) => unawaited(_onAction(action, ticket)),
                itemBuilder: (context) => [
                  for (final action in actions)
                    PopupMenuItem(
                      value: action,
                      child: Text(switch (action) {
                        _ThreadAction.openOrder => 'فتح الطلبية',
                        _ThreadAction.openCustomer => 'ملف العميل',
                        _ThreadAction.transfer => 'تحويل التذكرة',
                        _ThreadAction.close => 'إغلاق التذكرة',
                      }),
                    ),
                ],
              ),
          ],
        ),
        body: Column(
          children: [
            _PinnedTitle(ticket: ticket),
            Expanded(
              child: Stack(
                children: [
                  _Conversation(ticket: ticket, me: me, controller: _scroll),
                  PositionedDirectional(
                    end: 12.w,
                    bottom: 12.h,
                    child: _JumpToLatest(visible: _awayFromLatest, onTap: _toLatest),
                  ),
                ],
              ),
            ),
            if (ticket.canReply)
              ChatComposer(
                controller: _reply,
                isSending: state.isWorking,
                hint: 'اكتب رسالتك…',
                onSend: () => unawaited(_send()),
                onAttach: () => unawaited(_attach()),
                onRecorded: (recording) async {
                  final sent = await cubit.sendVoice(recording);
                  if (sent) _toLatest();
                },
                banner: switch (state) {
                  InternalThreadLoaded(:final unsentVoice?) => _UnsentVoiceBar(
                    voice: unsentVoice,
                    isWorking: state.isWorking,
                  ),
                  InternalThreadLoaded(:final replyingTo?) => ReplyQuote(
                    authorName: replyingTo.isFrom(me) ? 'أنت' : replyingTo.author?.name,
                    preview: replyingTo.preview,
                    onClose: cubit.cancelReply,
                  ),
                  _ => null,
                },
              )
            else
              _Footnote(
                text: ticket.status.isOpen
                    ? 'تقرأ هذه التذكرة ولا تكتب فيها — لست طرفاً فيها'
                    : 'أُغلقت التذكرة. من عنده ما يضيفه يفتح تذكرةً جديدة',
              ),
          ],
        ),
      ),
    );
  }
}

/// العنوانُ مثبّتٌ تحت الشريط، كموضوع تذكرة الدعم — ومعه نوعُ المشكلة والأولوية والطلبيةُ والعميل.
class _PinnedTitle extends StatelessWidget {
  const _PinnedTitle({required this.ticket});

  final InternalTicket ticket;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final details = [
      ?ticket.category?.name,
      if (ticket.priority == InternalTicketPriority.high) 'أولوية ${ticket.priorityLabel}',
      if (ticket.order case final order?) 'الطلبية ${order.code}',
      ?ticket.customer?.name,
    ];

    return Material(
      color: scheme.surface,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
        ),
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ticket.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (details.isNotEmpty)
              Text(
                details.join(' · '),
                style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
          ],
        ),
      ),
    );
  }
}

/// المحادثة — **مقلوبةٌ تبدأ من آخرها**، كمحادثة الدعم وكلِّ تطبيق محادثة.
class _Conversation extends StatelessWidget {
  const _Conversation({required this.ticket, required this.me, required this.controller});

  final InternalTicket ticket;
  final int? me;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final items = internalChatTimeline(
      messages: ticket.messages,
      isClosed: !ticket.status.isOpen,
    ).reversed.toList(growable: false);

    return RefreshIndicator(
      onRefresh: context.read<InternalThreadCubit>().load,
      child: ListView.builder(
        controller: controller,
        reverse: true,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(8.w, 10.h, 8.w, 12.h),
        itemCount: items.length,
        itemBuilder: (context, index) => switch (items[index]) {
          InternalChatDay(:final day) => ChatPill.day(day),
          InternalChatNotice(:final label) => ChatPill(label),
          final InternalChatEntry entry => _Message(ticket: ticket, entry: entry, me: me),
        },
      ),
    );
  }
}

/// رسالةٌ واحدة في سلسلتها.
class _Message extends StatelessWidget {
  const _Message({required this.ticket, required this.entry, required this.me});

  final InternalTicket ticket;
  final InternalChatEntry entry;
  final int? me;

  @override
  Widget build(BuildContext context) {
    final message = entry.message;
    final mine = message.isFrom(me);
    final deleted = message.isDeleted;
    final voice = deleted ? null : message.voice;
    final image = deleted ? null : message.image;
    final body = message.body ?? '';
    final readUpTo = ticket.readByOtherSideUpTo(me);
    final cubit = context.read<InternalThreadCubit>();

    MessageBubble bubble({bool detached = false}) => MessageBubble(
      fromDesk: mine,
      startsRun: entry.startsRun,
      endsRun: entry.endsRun,
      sentAt: message.sentAt,
      // ✓✓ حين يكون رقمُها ضمن ما رآه زميلي. ولا علامةَ لمن ليس طرفاً.
      delivery: mine && ticket.isParty
          ? (readUpTo != null && message.id <= readUpTo ? Delivery.read : Delivery.sent)
          : null,
      readLabel: 'قرأها زميلك',
      text: body,
      // الاسمُ على كلام الآخرين وحده — والمديرُ الذي ليس طرفاً يرى الاسمين.
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
        (final InternalAttachment note?, _) => VoiceNoteView(
          playbackKey: VoicePlayback.keyForAttachment(note.id),
          outgoing: mine,
          url: note.url,
          durationSeconds: note.durationSeconds,
          waveform: note.waveform,
        ),
        (_, final InternalAttachment photo?) => ChatRemoteImage(
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
                  if (ticket.canReply)
                    MessageMenuAction(
                      label: 'ردّ',
                      icon: AppIcons.reply,
                      onSelected: () => cubit.replyTo(message),
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
      enabled: ticket.canReply && !deleted,
      onReply: () => cubit.replyTo(message),
      child: bubble(),
    );
  }

  static String _imageKey(InternalAttachment photo) => 'internal-attachment-${photo.id}';

  static double? _aspectRatioOf(InternalAttachment file) {
    final (width, height) = (file.widthPx, file.heightPx);

    return width == null || height == null || height == 0 ? null : width / height;
  }

  static Future<void> _openImage(BuildContext context, InternalAttachment photo) =>
      showReceipt(context, Receipt(cacheKey: _imageKey(photo), url: photo.url, isImage: true));

  static Future<void> _copy(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));

    if (context.mounted) context.showSuccess('نُسخ النص');
  }

  static Future<void> _edit(BuildContext context, InternalMessage message) async {
    final cubit = context.read<InternalThreadCubit>();
    final body = await showDialog<String>(
      context: context,
      builder: (context) => _EditMessageDialog(initial: message.body ?? ''),
    );

    if (body == null) return;

    await cubit.editMessage(message.id, body);
  }

  static Future<void> _retract(BuildContext context, InternalMessage message) async {
    final cubit = context.read<InternalThreadCubit>();
    final confirmed = await showDestructiveDialog(
      context: context,
      title: 'حذف الرسالة؟',
      description: 'تبقى مكانها في المحادثة وتقول «تم حذف هذه الرسالة».',
    );

    if (confirmed != true) return;

    await cubit.retractMessage(message.id);
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
class _UnsentVoiceBar extends StatelessWidget {
  const _UnsentVoiceBar({required this.voice, required this.isWorking});

  final PendingVoice voice;
  final bool isWorking;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final cubit = context.read<InternalThreadCubit>();

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
              onPressed: isWorking ? null : () => unawaited(cubit.retryVoice()),
              tooltip: 'لم تُرسل — أعد الإرسال',
              icon: Icon(AppIcons.resend, color: scheme.error),
            ),
            IconButton(
              onPressed: isWorking ? null : cubit.discardVoice,
              tooltip: 'احذف التسجيل',
              icon: Icon(AppIcons.delete, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// مكانَ الصندوق حين لا يُكتب: مغلقة، أو قارئٌ ليس طرفاً.
class _Footnote extends StatelessWidget {
  const _Footnote({required this.text});

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
class _JumpToLatest extends StatelessWidget {
  const _JumpToLatest({required this.visible, required this.onTap});

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
