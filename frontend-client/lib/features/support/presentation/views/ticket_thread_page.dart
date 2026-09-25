import 'dart:async';

import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/files/attachment_picker.dart';
import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/core/theme/app_tones.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/widgets/app_button.dart';
import 'package:dayaa_client/core/widgets/attachment_sheet.dart';
import 'package:dayaa_client/core/widgets/receipt_viewer.dart';
import 'package:dayaa_client/features/badges/models/customer_badge.dart';
import 'package:dayaa_client/features/badges/presentation/viewmodel/badges_cubit.dart';
import 'package:dayaa_client/features/support/models/support_ticket.dart';
import 'package:dayaa_client/features/support/presentation/viewmodel/attachment_files_cubit.dart';
import 'package:dayaa_client/features/support/presentation/viewmodel/chat_timeline.dart';
import 'package:dayaa_client/features/support/presentation/viewmodel/outgoing_message.dart';
import 'package:dayaa_client/features/support/presentation/viewmodel/ticket_thread_cubit.dart';
import 'package:dayaa_client/features/support/presentation/widgets/chat_attachments.dart';
import 'package:dayaa_client/features/support/presentation/widgets/chat_composer.dart';
import 'package:dayaa_client/features/support/presentation/widgets/chat_pill.dart';
import 'package:dayaa_client/features/support/presentation/widgets/delivery_ticks.dart';
import 'package:dayaa_client/features/support/presentation/widgets/message_bubble.dart';
import 'package:dayaa_client/features/support/presentation/widgets/message_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';

/// One conversation with the shop — **مرسومةٌ كمحادثة تيليغرام.**
///
/// * **فقاعاتٌ بذيل**: رسائلي في نهاية السطر بلون العلامة الباهت، ورسائل الدعم في بدايته بيضاء؛
///   والمتتابعة من طرفٍ واحد سلسلةٌ بذيلٍ تحت آخرها. **يومٌ يُقال مرّةً** فوق رسائله.
/// * **كلّ جملةٍ تجري كما كُتبت**، وحقل الكتابة كذلك وهي تُكتب.
/// * **الوقت وعلامة الوصول في زاوية الفقاعة**: ساعةٌ ما دامت في الطريق، ✓ حين يقبلها الخادم،
///   و✓✓ حين يراها المحل. ورسالةٌ رُفضت تبقى بعلامةٍ حمراء حتى تُعاد أو تُحذف.
/// * **الصور والملفات**: الصورة بنسبتها وتقدّم تحميلها، والملف بزرٍّ يقول حاله — سهمٌ، فحلقةٌ
///   تمتلئ يُلغيها ✕، فملفٌّ يُفتح بعارض الهاتف.
/// * **الضغطة المطوّلة** ترفع الرسالة فوق محادثةٍ مضبّبة، وبجانبها ما يُفعل بها.
///
/// **Opening it is what marks it read**, and the server does that on the same call — so there
/// is no «mark as read» to fire here and no cursor for this app to get wrong.
///
/// **A reply to a closed thread reopens it.** That is the server's decision, not this screen's.
class TicketThreadPage extends StatelessWidget {
  const TicketThreadPage({required this.ticketId, super.key});

  final int ticketId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TicketThreadCubit>(
          create: (_) => sl<TicketThreadCubit>(param1: ticketId)..load(),
        ),
        BlocProvider<AttachmentFilesCubit>(create: (_) => sl<AttachmentFilesCubit>()),
      ],
      child: const _ThreadView(),
    );
  }
}

class _ThreadView extends StatefulWidget {
  const _ThreadView();

  @override
  State<_ThreadView> createState() => _ThreadViewState();
}

class _ThreadViewState extends State<_ThreadView> {
  final _reply = TextEditingController();
  final _scroll = ScrollController();

  /// زرّ «إلى آخر المحادثة» — حالةٌ بصريةٌ بحتة: هل ابتعد القارئ عن آخرها.
  bool _awayFromLatest = false;

  @override
  void initState() {
    super.initState();

    _scroll.addListener(_onScroll);

    // **Opening the thread is what marks it read, server-side.** So by the time this screen has
    // drawn, the count the home tile is holding is already stale — clearing it here saves a
    // round trip to learn something this screen just caused.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<BadgesCubit>().clear(CustomerBadge.support);
    });
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    _reply.dispose();
    super.dispose();
  }

  void _onScroll() {
    // القائمة مقلوبة: الصفر آخرُ المحادثة.
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

  void _send() {
    final text = _reply.text;
    if (text.trim().isEmpty) return;

    // **يُمسح الحقل في الحال**: ما كُتب صار فقاعةً بساعة في المحادثة، ولا يضيع إن رُفض — يبقى
    // بعلامةٍ حمراء حتى يُعاد.
    _reply.clear();
    unawaited(context.read<TicketThreadCubit>().send(text));
    _toLatest();
  }

  Future<void> _attach() async {
    final source = await showAttachmentSheet(context: context, title: 'إرسال صورة أو ملف');
    if (source == null || !mounted) return;

    final files = await sl<AttachmentPicker>().pick(source);
    if (files.isEmpty || !mounted) return;

    final cubit = context.read<TicketThreadCubit>();

    // كل ملفٍّ رسالةٌ وحده، كما في المرجع — وتُرسل بترتيب اختيارها.
    for (final file in files) {
      unawaited(cubit.sendFile(file));
    }

    _toLatest();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<TicketThreadCubit, TicketThreadState>(
          listenWhen: (previous, current) =>
              current is TicketThreadLoaded &&
              current.lastFailure != null &&
              (previous is! TicketThreadLoaded || previous.lastFailure != current.lastFailure),
          listener: (context, state) {
            if (state case TicketThreadLoaded(:final lastFailure?)) {
              context.showFailure(lastFailure);
            }
          },
        ),
        // أيُّ الملفات على الهاتف من قبل — مرّةً لكل رسالة، كلما وصلت رسائل.
        BlocListener<TicketThreadCubit, TicketThreadState>(
          listenWhen: (previous, current) => previous.ticket?.messages != current.ticket?.messages,
          listener: (context, state) {
            final messages = state.ticket?.messages;
            if (messages != null) {
              unawaited(context.read<AttachmentFilesCubit>().discover(messages));
            }
          },
        ),
      ],
      child: BlocBuilder<TicketThreadCubit, TicketThreadState>(
        builder: (context, state) {
          final ticket = state.ticket;
          final scheme = context.colorScheme;

          // **`canPop: false` so that leaving *always* carries the thread back**, whether the
          // customer used the back button or the system gesture. The list patches itself from
          // it rather than re-reading page one — see `SupportCubit.absorb`.
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) return;

              Navigator.of(context).pop(ticket);
            },
            child: Scaffold(
              backgroundColor: scheme.chatBackdrop,
              appBar: _ThreadBar(ticket: ticket),
              body: switch (state) {
                TicketThreadLoading() => const Center(child: CircularProgressIndicator()),

                TicketThreadFailure(:final failure) => Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.w),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(failure.message, textAlign: TextAlign.center),
                        SizedBox(height: 16.h),
                        AppButton.outlined(
                          label: 'أعد المحاولة',
                          onPressed: context.read<TicketThreadCubit>().load,
                        ),
                      ],
                    ),
                  ),
                ),

                TicketThreadLoaded(:final ticket, :final outbox) => Column(
                  children: [
                    if (ticket.order case final order?) _PinnedOrder(order: order),
                    Expanded(
                      child: Stack(
                        children: [
                          _Conversation(
                            ticket: ticket,
                            outbox: outbox,
                            controller: _scroll,
                          ),
                          PositionedDirectional(
                            end: 12.w,
                            bottom: 12.h,
                            child: _JumpToLatest(visible: _awayFromLatest, onTap: _toLatest),
                          ),
                        ],
                      ),
                    ),
                    ChatComposer(
                      controller: _reply,
                      onSend: _send,
                      onAttach: () => unawaited(_attach()),
                      // مغلقة: الردّ يعيد فتحها — والحقل نفسه يقولها، لا سطرٌ تحته.
                      hint: ticket.isOpen ? 'اكتب رسالتك…' : 'اكتب لإعادة فتح التذكرة…',
                    ),
                  ],
                ),
              },
            ),
          );
        },
      ),
    );
  }
}

/// شريط العنوان كرأس محادثة: دائرةٌ بلون حال التذكرة، والموضوع، وتحته حالُها.
class _ThreadBar extends StatelessWidget implements PreferredSizeWidget {
  const _ThreadBar({required this.ticket});

  final SupportTicket? ticket;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 4);

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final ticket = this.ticket;

    if (ticket == null) return AppBar(title: const Text('المحادثة'));

    final (fill, ink) = switch (ticket.status) {
      TicketStatus.open => (scheme.attentionContainer, scheme.onAttentionContainer),
      TicketStatus.inProgress => (scheme.infoContainer, scheme.onInfoContainer),
      TicketStatus.closed || TicketStatus.unknown => (
        scheme.surfaceContainerHigh,
        scheme.onSurfaceVariant,
      ),
    };

    return AppBar(
      titleSpacing: 0,
      toolbarHeight: kToolbarHeight + 4,
      shape: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      title: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
            child: Icon(AppIcons.comments, size: 20.sp, color: ink),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ticket.subject,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  'الدعم · ${ticket.statusLabel}',
                  maxLines: 1,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// «بخصوص الطلبية» فوق رقمها «1220»، مثبّتةً تحت العنوان — كرسالةٍ مثبّتة في تيليغرام — تفتح
/// الطلبية.
class _PinnedOrder extends StatelessWidget {
  const _PinnedOrder({required this.order});

  final TicketOrderRef order;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Material(
      color: scheme.surface,
      child: InkWell(
        onTap: () => unawaited(context.push(Routes.order(order.id))),
        child: Container(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
          ),
          child: Row(
            children: [
              Container(
                width: 3.w,
                height: 34.h,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'بخصوص الطلبية',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      // الرقم وحده بلا «#»: «بخصوص الطلبية» فوقه تقول ما هو.
                      order.code,
                      style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              Icon(AppIcons.forward, size: 20.sp, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// المحادثة نفسها: **مقلوبةٌ تبدأ من آخرها**، كما يُفتح كل تطبيق محادثة — لا من أول رسالةٍ
/// قيلت قبل أسبوع.
///
/// **سحبُ آخرها إلى أعلى يعيد قراءتها** بلا دائرة تحميل: حين لا يصل البثّ الحيّ، هذا ما يقول
/// «هل ردّ أحد؟».
class _Conversation extends StatelessWidget {
  const _Conversation({required this.ticket, required this.outbox, required this.controller});

  final SupportTicket ticket;
  final List<OutgoingMessage> outbox;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TicketThreadCubit>();
    final items = chatTimeline(
      messages: ticket.messages,
      pending: outbox,
      isClosed: !ticket.isOpen,
    ).reversed.toList(growable: false);

    return RefreshIndicator(
      onRefresh: () async {
        await cubit.refresh();

        if (context.mounted) context.read<BadgesCubit>().clear(CustomerBadge.support);
      },
      child: ListView.builder(
        controller: controller,
        reverse: true,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(6.w, 10.h, 6.w, 12.h),
        itemCount: items.length,
        itemBuilder: (context, index) => switch (items[index]) {
          ChatDay(:final day) => ChatPill.day(day),
          ChatNotice(:final label) => ChatPill(label),
          final ChatEntry entry => _Sent(ticket: ticket, entry: entry),
          final ChatOutgoing pending => _Pending(item: pending),
        },
      ),
    );
  }
}

/// رسالةٌ قبلها الخادم.
class _Sent extends StatelessWidget {
  const _Sent({required this.ticket, required this.entry});

  final SupportTicket ticket;
  final ChatEntry entry;

  @override
  Widget build(BuildContext context) {
    final message = entry.message;
    final attachment = message.attachment;

    MessageBubble bubble({bool detached = false}) => MessageBubble(
      isMine: message.isMine,
      startsRun: entry.startsRun,
      endsRun: entry.endsRun,
      sentAt: message.sentAt,
      delivery: message.isMine
          ? (ticket.isReadBySupport(message) ? Delivery.read : Delivery.sent)
          : null,
      text: message.body,
      imageOnly: attachment?.isImage == true,
      attachment: switch (attachment) {
        null => null,
        final TicketAttachment file when file.isImage => ChatRemoteImage(
          messageId: message.id,
          url: file.url,
          aspectRatio: file.aspectRatio,
          onTap: detached ? null : () => _viewImage(context, message),
        ),
        final TicketAttachment file => _RemoteFile(message: message, file: file),
      },
      detached: detached,
      onLongPress: (bubbleContext) => unawaited(
        showMessageMenu(
          bubbleContext,
          alignsToEnd: message.isMine,
          preview: bubble(detached: true),
          actions: _actionsFor(context, message),
        ),
      ),
    );

    return bubble();
  }

  List<MessageMenuAction> _actionsFor(BuildContext context, TicketMessage message) {
    final attachment = message.attachment;

    return [
      if (attachment != null)
        MessageMenuAction(
          label: 'فتح',
          icon: attachment.isImage ? AppIcons.photos : AppIcons.openExternal,
          onSelected: () => attachment.isImage
              ? _viewImage(context, message)
              : unawaited(_openFile(context, message)),
        ),
      if (attachment != null)
        MessageMenuAction(
          label: 'مشاركة أو حفظ',
          icon: AppIcons.share,
          onSelected: () => unawaited(_shareFile(context, message)),
        ),
      if (message.hasText)
        MessageMenuAction(
          label: 'نسخ',
          icon: AppIcons.copy,
          onSelected: () => unawaited(_copy(context, message.body)),
        ),
    ];
  }
}

/// ملفٌّ وصل من الخادم، وزرُّه يقول حاله على هذا الهاتف.
class _RemoteFile extends StatelessWidget {
  const _RemoteFile({required this.message, required this.file});

  final TicketMessage message;
  final TicketAttachment file;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AttachmentFilesCubit, AttachmentFilesState, AttachmentFile>(
      selector: (state) => state.of(message.id),
      builder: (context, state) {
        final files = context.read<AttachmentFilesCubit>();

        final (action, progress, caption) = switch (state) {
          AttachmentRemote() => (ChatFileAction.fetch, 0.0, file.metaLine),
          AttachmentDownloading(:final progress) => (
            ChatFileAction.transferring,
            progress,
            _transferred(progress, file.sizeBytes),
          ),
          AttachmentLocal() => (ChatFileAction.open, 1.0, file.metaLine),
          AttachmentDownloadFailed() => (ChatFileAction.retry, 0.0, 'لم يُنزَّل — المس لإعادة المحاولة'),
        };

        return ChatFileRow(
          name: file.name ?? 'ملف',
          caption: caption,
          action: action,
          progress: progress,
          isMine: message.isMine,
          isPdf: file.kind == AttachmentKind.pdf,
          onTap: switch (state) {
            AttachmentDownloading() => () => files.cancel(message.id),
            _ => () => unawaited(_openFile(context, message)),
          },
        );
      },
    );
  }
}

/// رسالةٌ لم يقبلها الخادم بعد.
class _Pending extends StatelessWidget {
  const _Pending({required this.item});

  final ChatOutgoing item;

  @override
  Widget build(BuildContext context) {
    final pending = item.message;
    final cubit = context.read<TicketThreadCubit>();
    final file = pending.file;

    MessageBubble bubble({bool detached = false}) => MessageBubble(
      isMine: true,
      startsRun: item.startsRun,
      endsRun: item.endsRun,
      sentAt: pending.createdAt,
      delivery: pending.isFailed ? null : Delivery.sending,
      text: pending.body,
      imageOnly: file != null && pending.isImage,
      failed: pending.isFailed,
      onFailedTap: () => unawaited(_failedMenu(context, pending)),
      attachment: switch (file) {
        null => null,
        _ when pending.isImage => ChatLocalImage(
          path: file.path,
          progress: pending.progress,
          failed: pending.isFailed,
          onCancel: () => cubit.cancelUpload(pending.clientToken),
        ),
        _ => ChatFileRow(
          name: file.name,
          caption: pending.isFailed
              ? 'لم يُرفع'
              : _transferred(pending.progress, file.sizeBytes),
          action: pending.isFailed ? ChatFileAction.retry : ChatFileAction.transferring,
          progress: pending.progress,
          isMine: true,
          isPdf: file.name.toLowerCase().endsWith('.pdf'),
          onTap: pending.isFailed
              ? () => unawaited(cubit.retry(pending.clientToken))
              : () => cubit.cancelUpload(pending.clientToken),
        ),
      },
      detached: detached,
      onLongPress: (bubbleContext) => unawaited(
        showMessageMenu(
          bubbleContext,
          alignsToEnd: true,
          preview: bubble(detached: true),
          actions: [
            if (pending.isFailed) ..._failedActions(context, pending),
            if (!pending.isFailed && file != null)
              MessageMenuAction(
                label: 'إلغاء الرفع',
                icon: AppIcons.close,
                isDestructive: true,
                onSelected: () => cubit.cancelUpload(pending.clientToken),
              ),
            if (pending.body.trim().isNotEmpty)
              MessageMenuAction(
                label: 'نسخ',
                icon: AppIcons.copy,
                onSelected: () => unawaited(_copy(context, pending.body)),
              ),
          ],
        ),
      ),
    );

    return bubble();
  }

  Future<void> _failedMenu(BuildContext context, OutgoingMessage pending) async {
    final failure = pending.failure;
    if (failure != null) context.showFailure(failure);

    final chosen = await showModalBottomSheet<MessageMenuAction>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final action in _failedActions(context, pending))
                ListTile(
                  leading: Icon(
                    action.icon,
                    color: action.isDestructive ? sheetContext.colorScheme.error : null,
                  ),
                  title: Text(
                    action.label,
                    style: TextStyle(
                      color: action.isDestructive ? sheetContext.colorScheme.error : null,
                    ),
                  ),
                  onTap: () => Navigator.of(sheetContext).pop(action),
                ),
            ],
          ),
        ),
      ),
    );

    chosen?.onSelected();
  }

  List<MessageMenuAction> _failedActions(BuildContext context, OutgoingMessage pending) {
    final cubit = context.read<TicketThreadCubit>();

    return [
      MessageMenuAction(
        label: 'أعد الإرسال',
        icon: AppIcons.refresh,
        onSelected: () => unawaited(cubit.retry(pending.clientToken)),
      ),
      MessageMenuAction(
        label: 'احذفها',
        icon: AppIcons.delete,
        isDestructive: true,
        onSelected: () => cubit.discard(pending.clientToken),
      ),
    ];
  }
}

/// «إلى آخر المحادثة» — يظهر حين يبتعد القارئ عن آخرها، بالتلاشي وحده.
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

// ───────────────────────── ما يُفعل بالرسالة ─────────────────────────

/// «0.4 من 1.2 م.ب» — كم انتقل من الملف.
String _transferred(double progress, int? totalBytes) {
  if (totalBytes == null || totalBytes <= 0) return '${(progress * 100).round()}٪';

  String size(double bytes) => bytes < 1024 * 1024
      ? '${(bytes / 1024).round()} ك.ب'
      : '${(bytes / (1024 * 1024)).toStringAsFixed(1)} م.ب';

  return '${size(totalBytes * progress)} من ${size(totalBytes.toDouble())}';
}

/// الصورة ملء الشاشة، تُكبَّر بالإصبعين — العارض نفسه الذي تُعرض فيه إيصالات الدفع.
///
/// **بلا اسمها تحتها** (طلب المستخدم، 2026-09-25): اسمُ صورةٍ من الكاميرا أو المعرض هو اسمها
/// المؤقت على هاتف مرسلها — «image_picker_A3CC…» — لا يقول شيئاً لأحد. الإيصالات تُبقي اسمها.
void _viewImage(BuildContext context, TicketMessage message) {
  unawaited(
    showReceipt(
      context,
      Receipt(
        cacheKey: chatImageCacheKey(message.id),
        url: message.attachment?.url,
        isImage: true,
      ),
    ),
  );
}

/// ينزّل الملف إن لم يكن على الهاتف — بالحلقة نفسها على فقاعته — ثم يفتحه بعارض الهاتف: معاينة
/// iOS نفسها داخل التطبيق، وعارض PDF على أندرويد.
Future<void> _openFile(BuildContext context, TicketMessage message) async {
  final path = await context.read<AttachmentFilesCubit>().fetch(message);
  if (path == null || !context.mounted) return;

  final result = await OpenFile.open(path);
  if (result.type == ResultType.done || !context.mounted) return;

  context.showError('لا يوجد تطبيق على هذا الجهاز يفتح هذا الملف');
}

/// ورقة المشاركة في النظام: «حفظ في الملفات»، و«حفظ الصورة»، وواتساب — صفوفٌ يعطيها النظام.
Future<void> _shareFile(BuildContext context, TicketMessage message) async {
  final path = await context.read<AttachmentFilesCubit>().fetch(message);
  if (path == null || !context.mounted) return;

  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(path, mimeType: message.attachment?.mimeType)],
      fileNameOverrides: [?message.attachment?.name],
    ),
  );
}

Future<void> _copy(BuildContext context, String text) async {
  await Clipboard.setData(ClipboardData(text: text));

  if (context.mounted) context.showSuccess('نُسخ النص');
}
