import 'dart:async';

import 'package:dayaa/core/chat/chat_composer.dart';
import 'package:dayaa/core/chat/chat_thread_view.dart';
import 'package:dayaa/core/chat/media_attach_sheet.dart';
import 'package:dayaa/core/chat/reply_quote.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/theme/app_tones.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/voice/voice_playback.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket_thread.dart';
import 'package:dayaa/features/design_tickets/presentation/viewmodel/design_ticket_thread_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// «الرد داخل التذكرة» — **محادثةُ التذكرة الداخلية نفسها**، على قطع `core/chat` نفسها
/// (DESIGN-TICKET-CHAT §٦):
///
/// * **الشريط**: الطرفُ الآخر في الوسط — المصمّمُ عند الطالب، والطالبُ عند المصمّم — وتحته الكودُ
///   والحالة. والعنوانُ واسمُ العميل مثبّتان تحته.
/// * **الرسائل**: فقاعاتٌ بذيلٍ في سلاسل، والوقتُ و✓/✓✓ في زاويتها، و«معدّلة»، والمسحوبةُ مكانها.
///   الصوتُ زرٌّ وموجةٌ تمتلئ، والصورةُ تُفتح ملء الشاشة.
/// * **الردّ على رسالة**: اسحبها جانباً، أو «ردّ» من قائمة الضغطة المطوّلة.
/// * **الصندوق**: اكتب وأرسل، أو أرفق صورة، أو اضغط على الميكروفون وأمسك لتسجّل.
///
/// **فتحُها يعلّمها مقروءة** على الخادم ويطفئ جرسها. **والتذكرةُ المنتهية** — اعتُمدت أو أُلغيت —
/// تبقى تُقرأ، ومكانَ الصندوق سببُ انتهائها.
class DesignTicketThreadPage extends StatelessWidget {
  const DesignTicketThreadPage({required this.ticketId, super.key});

  final int ticketId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DesignTicketThreadCubit>(
      create: (_) => sl<DesignTicketThreadCubit>(param1: ticketId)..load(),
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
    final sent = await context.read<DesignTicketThreadCubit>().sendText(_reply.text);

    // يُمسح عند النجاح وحده: ردٌّ لم يُرسل يبقى في الصندوق.
    if (!sent) return;

    _reply.clear();
    _toLatest();
  }

  /// ورقةُ الصور، **كبريمولا**: صورُ الهاتف شبكةً، حتى عشرٍ مرقّمةً بترتيب اختيارها، وتعليقُها —
  /// **رسالةً واحدة**. صورٌ فقط؛ الملفاتُ مكانها «المرفقات». وما في الصندوق يبقى فيه.
  Future<void> _attach() {
    // يُقرأ هنا لا داخل الورقة: الورقةُ تُبنى فوق المتصفّح، خارج مزوّدات المحادثة.
    final cubit = context.read<DesignTicketThreadCubit>();

    return showMediaAttachSheet(
      context,
      onSend: (images, caption) async {
        final sent = await cubit.sendImages(images, caption: caption);

        if (sent && mounted) _toLatest();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DesignTicketThreadCubit, DesignTicketThreadState>(
      listenWhen: (previous, current) =>
          current is DesignTicketThreadLoaded && current.lastFailure != null,
      listener: (context, state) {
        if (state case DesignTicketThreadLoaded(:final lastFailure?)) {
          context.showFailure(lastFailure);
        }
      },
      builder: (context, state) => switch (state) {
        DesignTicketThreadLoading() => Scaffold(
          appBar: AppBar(),
          body: const Center(child: CircularProgressIndicator()),
        ),
        DesignTicketThreadFailure(:final failure) => Scaffold(
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
                    onPressed: () => unawaited(context.read<DesignTicketThreadCubit>().load()),
                  ),
                ],
              ),
            ),
          ),
        ),
        final DesignTicketThreadLoaded loaded => _loaded(context, loaded),
      },
    );
  }

  Widget _loaded(BuildContext context, DesignTicketThreadLoaded state) {
    final thread = state.thread;
    final ticket = thread.ticket;
    final scheme = context.colorScheme;
    final cubit = context.read<DesignTicketThreadCubit>();
    final me = cubit.me;
    final other = thread.otherSideOf(me);

    return Scaffold(
      backgroundColor: scheme.chatBackdrop,
      appBar: AppBar(
        centerTitle: true,
        title: Column(
          children: [
            Text(
              other?.name ??
                  [ticket.requester?.name, ticket.designer?.name]
                      .whereType<String>()
                      .join(' ← ')
                      .ifEmpty(ticket.code),
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
      ),
      body: Column(
        children: [
          _PinnedTitle(ticket: ticket),
          Expanded(
            child: Stack(
              children: [
                ChatThreadConversation(
                  messages: thread.messages,
                  me: me,
                  controller: _scroll,
                  canReply: thread.canReply,
                  closedNotice: ticket.isOpen ? null : _endingOf(ticket.status),
                  readUpTo: thread.readByOtherSideUpTo(me),
                  showsDelivery: thread.isParty,
                  attachmentScope: DesignTicketThreadCubit.attachmentScope,
                  actions: ChatThreadActions(
                    reply: cubit.replyTo,
                    edit: cubit.editMessage,
                    retract: cubit.retractMessage,
                    refresh: cubit.load,
                  ),
                ),
                PositionedDirectional(
                  end: 12.w,
                  bottom: 12.h,
                  child: JumpToLatestButton(visible: _awayFromLatest, onTap: _toLatest),
                ),
              ],
            ),
          ),
          if (thread.canReply)
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
                DesignTicketThreadLoaded(:final unsentVoice?) => UnsentVoiceBar(
                  voice: unsentVoice,
                  isWorking: state.isWorking,
                  onRetry: () => unawaited(cubit.retryVoice()),
                  onDiscard: cubit.discardVoice,
                ),
                DesignTicketThreadLoaded(:final replyingTo?) => ReplyQuote(
                  authorName: replyingTo.isFrom(me) ? 'أنت' : replyingTo.author?.name,
                  preview: replyingTo.preview,
                  onClose: cubit.cancelReply,
                ),
                _ => null,
              },
            )
          else
            ChatThreadFootnote(text: thread.closedNote ?? 'أُغلقت المحادثة'),
        ],
      ),
    );
  }

  /// سطرُ الخدمة في آخر المحادثة المنتهية — أيَّ نهايتيها بلغت.
  static String? _endingOf(DesignTicketStatus status) => switch (status) {
    DesignTicketStatus.completed => 'اعتُمد التصميم',
    DesignTicketStatus.cancelled => 'أُلغيت التذكرة',
    _ => null,
  };
}

/// العنوانُ مثبّتٌ تحت الشريط، كموضوع التذكرة الداخلية — ومعه اسمُ العميل.
class _PinnedTitle extends StatelessWidget {
  const _PinnedTitle({required this.ticket});

  final DesignThreadTicket ticket;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final customer = ticket.customerName;

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
            if (customer != null && customer.isNotEmpty)
              Text(
                customer,
                style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
          ],
        ),
      ),
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
