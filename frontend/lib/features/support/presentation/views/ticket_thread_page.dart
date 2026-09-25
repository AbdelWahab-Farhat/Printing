import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/files/attachment_picker.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_dialog.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/core/widgets/attachment_sheet.dart';
import 'package:dayaa/core/widgets/dismiss_keyboard.dart';
import 'package:dayaa/core/widgets/receipt_viewer.dart';
import 'package:dayaa/features/support/models/support_ticket.dart';
import 'package:dayaa/features/support/presentation/viewmodel/ticket_thread_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// محادثةٌ واحدة مع عميلٍ واحد — حيّة.
///
/// **ما يكتبه العميل يظهر هنا ساعةَ يكتبه**، من المقبس لا من طلب ([TicketThreadCubit]). والشاشة
/// تتبع آخرَ الخيط: تفتح عليه، وتنزل إلى كل رسالةٍ تصل ما دام القارئ قريباً من الأسفل — قارئٌ
/// صعد يقرأ ما قيل قبل ساعة لا يُجرّ من سطره.
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

  /// كم رسالةً رُسمت آخرَ مرة — به تعرف الشاشة أن رسالةً وصلت. ‎-1: لم يُرسم الخيط بعد.
  int _drawn = -1;

  @override
  void dispose() {
    _reply.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final sent = await context.read<TicketThreadCubit>().send(_reply.text);

    // **يُمسح عند النجاح وحده.** ردٌّ لم يُرسل يبقى في الصندوق، لأن صاحبه سيُطلب منه إرساله ثانية.
    if (sent) _reply.clear();
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

    if (sent) _reply.clear();
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

  /// تأخذ التذكرة، أو تعيدها إلى الطابور.
  ///
  /// **«خذها» و«أعدها للطابور» فقط.** تسليمُها لزميلٍ بالاسم يحتاج قائمةَ موظفين، وحركةُ المكتب
  /// الحقيقية أن يأخذ أحدٌ تذكرة — فالحركتان اللتان لا تحتاجان قائمةً هنا.
  Future<void> _toggleMine(SupportTicket ticket) async {
    final me = sl<Session>().user?.id;
    if (me == null) return;

    await context.read<TicketThreadCubit>().assignTo(ticket.assignedTo == me ? null : me);
  }

  /// يتبع آخرَ الخيط: يفتح عليه، وينزل إلى الرسالة الجديدة إن كان القارئ قريباً من الأسفل.
  void _follow(TicketThreadLoaded state) {
    final count = state.ticket.messages.length;
    final isFirstDraw = _drawn < 0;
    final grew = count > _drawn;

    _drawn = count;
    if (!grew) return;

    final nearBottom = !_scroll.hasClients || _scroll.position.extentAfter < 160.h;
    if (!isFirstDraw && !nearBottom) return;

    final animate = !isFirstDraw && !MediaQuery.disableAnimationsOf(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;

      final end = _scroll.position.maxScrollExtent;

      if (animate) {
        unawaited(
          _scroll.animateTo(end, duration: const Duration(milliseconds: 250), curve: Curves.easeOut),
        );
      } else {
        _scroll.jumpTo(end);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<TicketThreadCubit, TicketThreadState>(
          listenWhen: (previous, current) =>
              current is TicketThreadLoaded && current.lastFailure != null,
          listener: (context, state) {
            if (state case TicketThreadLoaded(:final lastFailure?)) {
              context.showFailure(lastFailure);
            }
          },
        ),
        BlocListener<TicketThreadCubit, TicketThreadState>(
          listenWhen: (previous, current) => current is TicketThreadLoaded,
          listener: (context, state) => _follow(state as TicketThreadLoaded),
        ),
      ],
      child: BlocBuilder<TicketThreadCubit, TicketThreadState>(
        builder: (context, state) => switch (state) {
          TicketThreadLoading() => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
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

          final TicketThreadLoaded loaded => _Loaded(
            state: loaded,
            controller: _reply,
            scroll: _scroll,
            onSend: _send,
            onAttach: _attach,
            onClose: _close,
            onReopen: () => context.read<TicketThreadCubit>().reopenTicket(),
            onToggleMine: () => _toggleMine(loaded.ticket),
          ),
        },
      ),
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({
    required this.state,
    required this.controller,
    required this.scroll,
    required this.onSend,
    required this.onAttach,
    required this.onClose,
    required this.onReopen,
    required this.onToggleMine,
  });

  final TicketThreadLoaded state;
  final TextEditingController controller;
  final ScrollController scroll;
  final Future<void> Function() onSend;
  final Future<void> Function() onAttach;
  final Future<void> Function() onClose;
  final Future<bool> Function() onReopen;
  final VoidCallback onToggleMine;

  @override
  Widget build(BuildContext context) {
    final ticket = state.ticket;
    final canManage = sl<Session>().can(AppPermission.manageSupportTickets);

    return DismissKeyboard(
      child: Scaffold(
        appBar: AppBar(
          title: Text(ticket.subject, maxLines: 1, overflow: TextOverflow.ellipsis),
          actions: [
            if (canManage && !ticket.status.isClosed)
              IconButton(
                icon: Icon(AppIcons.settled),
                tooltip: 'إغلاق التذكرة',
                onPressed: state.isWorking ? null : onClose,
              ),
          ],
        ),
        // **`PopScope` لا رجوعٌ عادي.** الطابور خلف هذه الشاشة يريد التذكرة عائدةً — شارتُها
        // مطفأة على الأقل، وكثيراً بحالةٍ أو مكتبٍ جديد — فلا يعيد قراءة صفحته.
        body: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) Navigator.of(context).pop(ticket);
          },
          child: Column(
            children: [
              _Header(ticket: ticket, canManage: canManage, onToggleMine: onToggleMine),

              Expanded(
                child: ticket.messages.isEmpty
                    ? Center(
                        child: Text(
                          'لا توجد رسائل',
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    // **السحبُ باقٍ وإن صار الخيطُ حيّاً**: هو ما يبقى حين لا يصل المقبس — خادمٌ
                    // بلا Reverb بعد، أو شبكةٌ تحجب المقابس. والقراءةُ تُعلِّم المكتبَ قارئاً،
                    // وهذا صحيح: أحدٌ ينظر.
                    : RefreshIndicator(
                        onRefresh: context.read<TicketThreadCubit>().load,
                        child: ListView.builder(
                          controller: scroll,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
                          itemCount: ticket.messages.length,
                          itemBuilder: (context, index) {
                            final message = ticket.messages[index];

                            return _Bubble(
                              message: message,
                              isRead: _isReadByCustomer(ticket, message),
                            );
                          },
                        ),
                      ),
              ),

              if (canManage && ticket.status.acceptsReplies)
                _Composer(
                  controller: controller,
                  isSending: state.isWorking,
                  onSend: onSend,
                  onAttach: onAttach,
                )
              else if (ticket.status.isClosed)
                _ClosedFooter(
                  canReopen: canManage,
                  isWorking: state.isWorking,
                  onReopen: onReopen,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// ✓✓ على ردّ المحل حين يكون رقمُه ضمن ما رآه العميل. رسالةُ العميل لا علامة عليها هنا.
  static bool _isReadByCustomer(SupportTicket ticket, TicketMessage message) {
    final upTo = ticket.customerReadUpTo;

    return upTo != null && message.id <= upTo;
  }
}

/// من يسأل، وعمّا، وعلى أيّ مكتبٍ هي.
class _Header extends StatelessWidget {
  const _Header({
    required this.ticket,
    required this.canManage,
    required this.onToggleMine,
  });

  final SupportTicket ticket;
  final bool canManage;
  final VoidCallback onToggleMine;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final me = sl<Session>().user?.id;
    final isMine = me != null && ticket.assignedTo == me;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
      color: scheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            [?ticket.customer?.name, ?ticket.customer?.code].join(' · '),
            style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (ticket.customer?.phone case final phone?) ...[
            SizedBox(height: 2.h),
            Text(
              phone,
              // الهاتف يُقرأ من اليسار إلى اليمين حتى في شاشةٍ عربية.
              textDirection: TextDirection.ltr,
              style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
          if (ticket.order case final order?) ...[
            SizedBox(height: 4.h),
            Text(
              'بخصوص الطلبية #${order.code}',
              style: context.textTheme.bodySmall?.copyWith(color: scheme.primary),
            ),
          ],

          SizedBox(height: 10.h),
          Row(
            children: [
              Text(
                ticket.statusLabel,
                style: context.textTheme.labelMedium?.copyWith(
                  color: ticket.status.isClosed ? scheme.onSurfaceVariant : scheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  ticket.assignee?.name ?? 'غير مُسندة',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.labelMedium?.copyWith(
                    color: ticket.assignee == null ? scheme.error : scheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (canManage && !ticket.status.isClosed)
                TextButton(
                  onPressed: onToggleMine,
                  child: Text(isMine ? 'أعدها للطابور' : 'خذها'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.isRead});

  final TicketMessage message;

  /// هل رأى العميلُ هذا الردّ — لا معنى له على رسالة العميل نفسه.
  final bool isRead;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    // **`unknown` يُرسم رسالةَ المحل**، وهي القراءة الآمنة: نسبةُ كلامٍ إلى العميل لم يقله أسوأ
    // الخطأين.
    final fromCustomer = message.from == MessageAuthor.customer;
    final ink = fromCustomer ? scheme.onSurface : scheme.onPrimaryContainer;

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Align(
        alignment: fromCustomer ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 0.78.sw),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: fromCustomer ? scheme.surfaceContainerHighest : scheme.primaryContainer,
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // الزميلُ الذي ردّ، باسمه — «من ردّ عليه؟» سؤالٌ يحقّ للمحل أن يسأله نفسه.
                // تطبيقُ العميل لا يُرسل إليه اسمٌ أصلاً.
                if (!fromCustomer && message.authorName != null) ...[
                  Text(
                    message.authorName!,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: ink.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 3.h),
                ],
                if (message.attachment case final attachment?) ...[
                  _AttachmentTile(messageId: message.id, attachment: attachment, ink: ink),
                  if (message.body != null) SizedBox(height: 8.h),
                ],
                if (message.body case final body?)
                  Text(
                    body,
                    style: context.textTheme.bodyMedium?.copyWith(color: ink, height: 1.5),
                  ),
                SizedBox(height: 4.h),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (message.sentAt case final at?)
                      Text(
                        at.stampLabel,
                        style: context.textTheme.labelSmall?.copyWith(
                          color: ink.withValues(alpha: 0.6),
                        ),
                      ),
                    if (!fromCustomer) ...[
                      SizedBox(width: 6.w),
                      Icon(
                        isRead ? AppIcons.readMark : AppIcons.sentMark,
                        size: 14.sp,
                        color: isRead ? scheme.primary : ink.withValues(alpha: 0.6),
                        semanticLabel: isRead ? 'قرأها العميل' : 'وصلت',
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// الملفُّ المرفق داخل الفقاعة: الصورةُ مصغّرةً، والـ PDF باسمه — وكلاهما يُفتح باللمس.
///
/// **يُخبَّأ برقم الرسالة لا برابطه**: الرابط موقّعٌ ينتهي بعد ساعة ويتغيّر مع كل قراءة، والملفُّ
/// خلف الرسالة لا يتغيّر.
class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({required this.messageId, required this.attachment, required this.ink});

  final int messageId;
  final TicketAttachment attachment;
  final Color ink;

  String get _cacheKey => 'ticket-message-$messageId';

  bool get _isImage => attachment.kind == AttachmentKind.image;

  Future<void> _open(BuildContext context) => showReceipt(
    context,
    Receipt(
      cacheKey: _cacheKey,
      url: attachment.url,
      isImage: _isImage,
      filename: attachment.name,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final url = attachment.url;

    if (_isImage && url != null) {
      return GestureDetector(
        onTap: () => unawaited(_open(context)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10.r),
          child: CachedNetworkImage(
            imageUrl: url,
            cacheKey: _cacheKey,
            width: 220.w,
            height: 160.h,
            fit: BoxFit.cover,
            placeholder: (context, _) => SizedBox(
              width: 220.w,
              height: 160.h,
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            errorWidget: (context, _, _) => SizedBox(
              width: 220.w,
              height: 160.h,
              child: Icon(AppIcons.photos, color: ink.withValues(alpha: 0.6)),
            ),
          ),
        ),
      );
    }

    return InkWell(
      onTap: () => unawaited(_open(context)),
      borderRadius: BorderRadius.circular(10.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.pdf, size: 26.sp, color: ink),
            SizedBox(width: 8.w),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attachment.name ?? attachment.kindLabel ?? 'ملف',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (attachment.sizeBytes case final size?)
                    Text(
                      _sizeLabel(size),
                      style: context.textTheme.labelSmall?.copyWith(
                        color: ink.withValues(alpha: 0.7),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// «٣٫٢ م.ب» أو «٨٤٠ ك.ب» — ما يكفي ليعرف الموظف أنه سينزّل ملفاً ثقيلاً قبل أن يلمسه.
  static String _sizeLabel(int bytes) {
    if (bytes >= 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} م.ب';

    return '${(bytes / 1024).ceil()} ك.ب';
  }
}

/// تحت خيطٍ مغلق: يُقال إنه مغلق، ولمن يملك الرد زرٌّ يعيد فتحه.
///
/// **لا صندوقَ فارغاً في مكان صندوق الرد**: الخادم يرفض ردَّ الموظف على المغلقة، والشاشة تقول
/// ذلك قبل أن يكتب أحدٌ فقرة — وتعطيه الطريق الوحيد إليها.
class _ClosedFooter extends StatelessWidget {
  const _ClosedFooter({
    required this.canReopen,
    required this.isWorking,
    required this.onReopen,
  });

  final bool canReopen;
  final bool isWorking;
  final Future<bool> Function() onReopen;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              canReopen
                  ? 'التذكرة مغلقة. أعد فتحها لتكتب فيها، أو يعيدها ردُّ العميل.'
                  : 'التذكرة مغلقة. ردُّ العميل يعيد فتحها.',
              textAlign: TextAlign.center,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            if (canReopen) ...[
              SizedBox(height: 10.h),
              AppButton.tonal(
                label: 'إعادة فتح التذكرة',
                icon: AppIcons.reopen,
                isLoading: isWorking,
                onPressed: () => unawaited(onReopen()),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.isSending,
    required this.onSend,
    required this.onAttach,
  });

  final TextEditingController controller;
  final bool isSending;
  final Future<void> Function() onSend;
  final Future<void> Function() onAttach;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(8.w, 8.h, 12.w, 8.h),
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              onPressed: isSending ? null : () => unawaited(onAttach()),
              icon: Icon(AppIcons.attach),
              tooltip: 'إرفاق ملف',
            ),
            Expanded(
              child: AppTextField(
                controller: controller,
                hint: 'اكتب ردّك…',
                // يبدأ سطراً ويكبر مع الكلام: صندوقٌ بخمسة أسطرٍ فارغة فوق لوحة المفاتيح يأكل
                // الخيطَ الذي يُردّ عليه.
                minLines: 1,
                maxLines: 5,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
              ),
            ),
            SizedBox(width: 8.w),
            // **منشغلٌ لا معطّل.** زرُّ إرسالٍ يشحب في منتصف الطلب يبدو معطوباً؛ رفضُ الضغطة
            // الثانية عملُ الـ Cubit.
            IconButton.filled(
              onPressed: isSending ? null : () => unawaited(onSend()),
              tooltip: 'إرسال',
              icon: isSending
                  ? SizedBox(
                      height: 18.w,
                      width: 18.w,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(AppIcons.send),
            ),
          ],
        ),
      ),
    );
  }
}
