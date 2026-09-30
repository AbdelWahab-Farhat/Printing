import 'dart:async';

import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/files/attachment_picker.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/theme/app_tones.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_dialog.dart';
import 'package:dayaa/core/widgets/attachment_sheet.dart';
import 'package:dayaa/core/widgets/receipt_viewer.dart';
import 'package:dayaa/features/support/models/support_ticket.dart';
import 'package:dayaa/features/support/presentation/viewmodel/chat_timeline.dart';
import 'package:dayaa/features/support/presentation/viewmodel/ticket_thread_cubit.dart';
import 'package:dayaa/features/support/presentation/widgets/chat_attachments.dart';
import 'package:dayaa/features/support/presentation/widgets/chat_avatar.dart';
import 'package:dayaa/features/support/presentation/widgets/chat_composer.dart';
import 'package:dayaa/features/support/presentation/widgets/chat_pill.dart';
import 'package:dayaa/features/support/presentation/widgets/delivery_ticks.dart';
import 'package:dayaa/features/support/presentation/widgets/message_bubble.dart';
import 'package:dayaa/features/support/presentation/widgets/message_menu.dart';
import 'package:dayaa/features/support/presentation/widgets/thread_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// محادثةٌ واحدة مع عميلٍ واحد — حيّة، **مرسومةً كمحادثة بريمولا وتيليغرام.**
///
/// * **الشريط كشريط بريمولا**: اسمُ العميل في الوسط وتحته حالُ التذكرة ومكتبُها وكودُه، وما
///   يُفعل بها في «⋮» — الأخذ والإعادة والاتصال وملفّ العميل والإغلاق. والموضوعُ مثبّتٌ تحته.
/// * **الفقاعات كتطبيق العميل**: بذيلٍ في سلاسل، ويومٌ يُقال مرّةً فوق رسائله، والوقتُ و✓/✓✓ في
///   زاوية الفقاعة، واسمُ الزميل فوق أوّل ردوده وصورتُه بجانب آخرها.
/// * **الضغطة المطوّلة** ترفع الرسالة فوق محادثةٍ مضبّبة، وبجانبها ما يُفعل بها.
///
/// **ما يكتبه العميل يظهر هنا ساعةَ يكتبه**، من المقبس لا من طلب ([TicketThreadCubit]). والقائمة
/// مقلوبةٌ تبدأ من آخرها، فالجديدُ يظهر في مكانه.
///
/// **فتحُها يُعلِّم طرفَ المكتب مقروءاً**، على الخادم مع القراءة. فلا تُجلب مسبقاً، والشارةُ
/// تنطفئ لأن أحداً نظر.
///
/// **كلُّ ما يكتب خلف `support.manage`.** قراءة الطابور يحتاجها وردياتٌ كاملة؛ الرد والإسناد
/// والإغلاق وإعادة الفتح عمل. البوابة هنا مجاملة — الحدّ `can:` على المسار — لكن صندوقَ ردٍّ
/// يُرفض ردُّه مجاملةٌ أسوأ من غيابه.
class TicketThreadPage extends StatelessWidget {
  const TicketThreadPage({required this.ticketId, super.key});

  final int ticketId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TicketThreadCubit>(
      create: (_) => sl<TicketThreadCubit>(param1: ticketId)..load(),
      child: const _TicketThreadView(),
    );
  }
}

class _TicketThreadView extends StatefulWidget {
  const _TicketThreadView();

  @override
  State<_TicketThreadView> createState() => _TicketThreadViewState();
}

class _TicketThreadViewState extends State<_TicketThreadView> {
  final _reply = TextEditingController();
  final _scroll = ScrollController();

  /// زرّ «إلى آخر المحادثة» — حالةٌ بصريةٌ بحتة: هل ابتعد القارئ عن آخرها.
  bool _awayFromLatest = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
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

  Future<void> _send() async {
    final sent = await context.read<TicketThreadCubit>().send(_reply.text);

    // **يُمسح عند النجاح وحده.** ردٌّ لم يُرسل يبقى في الصندوق، لأن صاحبه سيُطلب منه إرساله ثانية.
    if (!sent) return;

    _reply.clear();
    _toLatest();
  }

  /// ملفٌ من الهاتف — صورةٌ أو PDF — ومعه ما في الصندوق تعليقاً.
  Future<void> _attach() async {
    final source = await showAttachmentSheet(context: context, title: 'إرفاق ملف');
    if (source == null || !mounted) return;

    final picked = await sl<AttachmentPicker>().pick(source);
    if (picked.isEmpty || !mounted) return;

    final sent = await context.read<TicketThreadCubit>().send(
      _reply.text,
      attachment: picked.first,
    );

    if (!sent) return;

    _reply.clear();
    _toLatest();
  }

  /// ما يحقّ لهذا القارئ على هذه التذكرة من «⋮»، بترتيبه هناك.
  ///
  /// **«خذها» و«أعدها للطابور» فقط.** تسليمُها لزميلٍ بالاسم يحتاج قائمةَ موظفين، وحركةُ المكتب
  /// الحقيقية أن يأخذ أحدٌ تذكرة — فالحركتان اللتان لا تحتاجان قائمةً هنا.
  List<ThreadAction> _actionsFor(SupportTicket ticket) {
    final session = sl<Session>();
    final me = session.user?.id;
    final canManage = session.can(AppPermission.manageSupportTickets);
    final isOpen = !ticket.status.isClosed;
    final phone = ticket.customer?.phone?.trim();

    return [
      if (canManage && isOpen && me != null)
        ticket.assignedTo == me ? ThreadAction.giveBack : ThreadAction.take,
      if (phone != null && phone.isNotEmpty) ThreadAction.call,
      if (ticket.customer != null && session.can(AppPermission.viewCustomers))
        ThreadAction.openCustomer,
      if (canManage && isOpen) ThreadAction.close,
    ];
  }

  Future<void> _onAction(ThreadAction action, SupportTicket ticket) async {
    final cubit = context.read<TicketThreadCubit>();
    final me = sl<Session>().user?.id;

    switch (action) {
      case ThreadAction.take:
        await cubit.assignTo(me);
      case ThreadAction.giveBack:
        await cubit.assignTo(null);
      case ThreadAction.call:
        await _call(ticket.customer?.phone);
      case ThreadAction.openCustomer:
        if (ticket.customer case final customer?) {
          unawaited(context.push(Routes.customer(customer.id)));
        }
      case ThreadAction.close:
        await _close();
    }
  }

  Future<void> _call(String? phone) async {
    if (phone == null) return;

    final opened = await launchUrl(Uri(scheme: 'tel', path: phone.trim()));

    if (!opened && mounted) context.showError('تعذّر فتح الاتصال على هذا الجهاز');
  }

  Future<void> _close() async {
    final confirmed = await showDestructiveDialog(
      context: context,
      title: 'إغلاق التذكرة؟',
      description: 'لن يُكتب فيها بعدها. ردُّ العميل يعيد فتحها، أو تعيد أنت فتحها.',
      confirmLabel: 'إغلاق',
    );

    if (confirmed != true || !mounted) return;

    await context.read<TicketThreadCubit>().closeTicket();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TicketThreadCubit, TicketThreadState>(
      listenWhen: (previous, current) =>
          current is TicketThreadLoaded && current.lastFailure != null,
      listener: (context, state) {
        if (state case TicketThreadLoaded(:final lastFailure?)) {
          context.showFailure(lastFailure);
        }
      },
      builder: (context, state) => switch (state) {
        TicketThreadLoading() => Scaffold(
          appBar: AppBar(),
          body: const Center(child: CircularProgressIndicator()),
        ),

        TicketThreadFailure(:final failure) => Scaffold(
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
                    onPressed: () => unawaited(context.read<TicketThreadCubit>().load()),
                  ),
                ],
              ),
            ),
          ),
        ),

        final TicketThreadLoaded loaded => _loaded(context, loaded),
      },
    );
  }

  Widget _loaded(BuildContext context, TicketThreadLoaded state) {
    final ticket = state.ticket;
    final scheme = context.colorScheme;
    final canManage = sl<Session>().can(AppPermission.manageSupportTickets);

    // **`PopScope` لا رجوعٌ عادي.** الطابور خلف هذه الشاشة يريد التذكرة عائدةً — شارتُها مطفأة
    // على الأقل، وكثيراً بحالةٍ أو مكتبٍ جديد — فلا يعيد قراءة صفحته.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(ticket);
      },
      child: Scaffold(
        backgroundColor: scheme.chatBackdrop,
        appBar: ThreadBar(
          ticket: ticket,
          me: sl<Session>().user?.id,
          actions: _actionsFor(ticket),
          isWorking: state.isWorking,
          onAction: (action) => unawaited(_onAction(action, ticket)),
        ),
        body: Column(
          children: [
            PinnedSubject(
              ticket: ticket,
              onOpenOrder: ticket.order == null
                  ? null
                  : () => unawaited(context.push(Routes.order(ticket.order!.id))),
            ),

            Expanded(
              child: ticket.messages.isEmpty
                  ? Center(
                      child: Text(
                        'لا توجد رسائل',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : Stack(
                      children: [
                        _Conversation(ticket: ticket, controller: _scroll),
                        PositionedDirectional(
                          end: 12.w,
                          bottom: 12.h,
                          child: _JumpToLatest(visible: _awayFromLatest, onTap: _toLatest),
                        ),
                      ],
                    ),
            ),

            if (canManage && ticket.status.acceptsReplies)
              ChatComposer(
                controller: _reply,
                isSending: state.isWorking,
                onSend: () => unawaited(_send()),
                onAttach: () => unawaited(_attach()),
              )
            // **لا صندوقَ فارغاً في مكان صندوق الرد**: الخادم يرفض ردَّ الموظف على المغلقة، و«أُغلقت
            // التذكرة» في آخر المحادثة تقول ذلك — وهنا الطريقُ الوحيد إليها.
            else if (canManage && ticket.status.isClosed)
              _ReopenBar(
                isWorking: state.isWorking,
                onReopen: () => context.read<TicketThreadCubit>().reopenTicket(),
              ),
          ],
        ),
      ),
    );
  }
}

/// المحادثة نفسها: **مقلوبةٌ تبدأ من آخرها**، كما يُفتح كل تطبيق محادثة — لا من أول رسالةٍ
/// قيلت قبل أسبوع.
///
/// **السحبُ باقٍ وإن صار الخيطُ حيّاً**: هو ما يبقى حين لا يصل المقبس — خادمٌ بلا Reverb بعد، أو
/// شبكةٌ تحجب المقابس. والقراءةُ تُعلِّم المكتبَ قارئاً، وهذا صحيح: أحدٌ ينظر.
class _Conversation extends StatelessWidget {
  const _Conversation({required this.ticket, required this.controller});

  final SupportTicket ticket;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final items = chatTimeline(
      messages: ticket.messages,
      isClosed: ticket.status.isClosed,
    ).reversed.toList(growable: false);

    return RefreshIndicator(
      onRefresh: context.read<TicketThreadCubit>().load,
      child: ListView.builder(
        controller: controller,
        reverse: true,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(8.w, 10.h, 8.w, 12.h),
        itemCount: items.length,
        itemBuilder: (context, index) => switch (items[index]) {
          ChatDay(:final day) => ChatPill.day(day),
          ChatNotice(:final label) => ChatPill(label),
          final ChatEntry entry => _Message(ticket: ticket, entry: entry),
        },
      ),
    );
  }
}

/// رسالةٌ واحدة في سلسلتها.
class _Message extends StatelessWidget {
  const _Message({required this.ticket, required this.entry});

  final SupportTicket ticket;
  final ChatEntry entry;

  @override
  Widget build(BuildContext context) {
    final message = entry.message;
    final attachment = message.attachment;
    final body = message.body ?? '';

    // **`unknown` يُرسم ردَّ المحل**، وهي القراءة الآمنة: نسبةُ كلامٍ إلى العميل لم يقله أسوأ
    // الخطأين.
    final fromDesk = message.from != MessageAuthor.customer;
    final isImage = attachment?.kind == AttachmentKind.image;

    MessageBubble bubble({bool detached = false}) => MessageBubble(
      fromDesk: fromDesk,
      startsRun: entry.startsRun,
      endsRun: entry.endsRun,
      sentAt: message.sentAt,
      // ✓✓ حين يكون رقمُ الردّ ضمن ما رآه العميل. رسالةُ العميل لا علامة عليها هنا.
      delivery: fromDesk
          ? (_isReadByCustomer(ticket, message) ? Delivery.read : Delivery.sent)
          : null,
      text: body,
      author: fromDesk ? message.authorName : null,
      avatar: fromDesk ? ChatAvatar.desk(name: message.authorName) : const ChatAvatar.customer(),
      imageOnly: isImage && body.trim().isEmpty,
      attachment: switch (attachment) {
        null => null,
        final TicketAttachment file when isImage => ChatRemoteImage(
          messageId: message.id,
          url: file.url,
          aspectRatio: _aspectRatioOf(file),
          onTap: detached ? null : () => unawaited(_open(context, message)),
        ),
        final TicketAttachment file => ChatFileRow(
          name: file.name ?? file.kindLabel ?? 'ملف',
          // الحجمُ أوّلاً: سطرٌ عربيّ يبدأ بـ«PDF» يقلبه الاتجاه، فيُقرأ «3.2 · PDF م.ب».
          caption: [if (file.sizeBytes case final size?) fileSizeLabel(size), ?file.kindLabel]
              .join(' · '),
          fromDesk: fromDesk,
          isPdf: file.kind == AttachmentKind.pdf,
          onTap: detached ? null : () => unawaited(_open(context, message)),
        ),
      },
      detached: detached,
      onLongPress: (bubbleContext) => unawaited(
        showMessageMenu(
          bubbleContext,
          alignsToEnd: fromDesk,
          preview: bubble(detached: true),
          actions: [
            if (attachment != null)
              MessageMenuAction(
                label: 'فتح',
                icon: isImage ? AppIcons.photos : AppIcons.openExternal,
                onSelected: () => unawaited(_open(context, message)),
              ),
            if (body.trim().isNotEmpty)
              MessageMenuAction(
                label: 'نسخ',
                icon: AppIcons.copy,
                onSelected: () => unawaited(_copy(context, body)),
              ),
          ],
        ),
      ),
    );

    return bubble();
  }

  static bool _isReadByCustomer(SupportTicket ticket, TicketMessage message) {
    final upTo = ticket.customerReadUpTo;

    return upTo != null && message.id <= upTo;
  }

  static double? _aspectRatioOf(TicketAttachment file) {
    final (width, height) = (file.widthPx, file.heightPx);

    return width == null || height == null || height == 0 ? null : width / height;
  }
}

/// الملفُّ ملء الشاشة — العارض نفسه الذي تُفتح فيه الإيصالات، والصورةُ بمفتاحها في الذاكرة
/// المؤقتة فلا تُنزَّل مرّتين.
Future<void> _open(BuildContext context, TicketMessage message) {
  final attachment = message.attachment;
  if (attachment == null) return Future<void>.value();

  final isImage = attachment.kind == AttachmentKind.image;

  return showReceipt(
    context,
    Receipt(
      cacheKey: chatImageCacheKey(message.id),
      url: attachment.url,
      isImage: isImage,
      // اسمُ صورةٍ من الكاميرا اسمُها المؤقت على هاتف مرسلها، لا يقول شيئاً لأحد.
      filename: isImage ? null : attachment.name,
    ),
  );
}

Future<void> _copy(BuildContext context, String text) async {
  await Clipboard.setData(ClipboardData(text: text));

  if (context.mounted) context.showSuccess('نُسخ النص');
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

/// تحت خيطٍ مغلق، لمن يملك الرد: زرٌّ بعرض الشاشة يعيد فتحه.
class _ReopenBar extends StatelessWidget {
  const _ReopenBar({required this.isWorking, required this.onReopen});

  final bool isWorking;
  final Future<bool> Function() onReopen;

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
          padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 10.h),
          child: AppButton.tonal(
            label: 'إعادة فتح التذكرة',
            icon: AppIcons.reopen,
            isLoading: isWorking,
            onPressed: () => unawaited(onReopen()),
          ),
        ),
      ),
    );
  }
}
