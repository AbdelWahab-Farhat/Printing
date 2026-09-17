import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/core/widgets/app_dialog.dart';
import 'package:dayaa/core/widgets/dismiss_keyboard.dart';
import 'package:dayaa/features/support/models/support_ticket.dart';
import 'package:dayaa/features/support/presentation/viewmodel/ticket_thread_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// One conversation with one customer.
///
/// **Opening it marks the desk's side read**, server-side, on the GET. So the screen is not safe
/// to prefetch and the badge clears because somebody looked — which is the honest meaning of a
/// read receipt.
///
/// **Everything that writes is behind `support.manage`.** Reading the queue is something a whole
/// shift may need; answering, assigning and closing is a job. The gate is a courtesy — the
/// boundary is `can:` on the route — but a reply box shown to somebody whose reply will be
/// refused is a worse courtesy than no box.
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

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final sent = await context.read<TicketThreadCubit>().send(_reply.text);

    // **Cleared only on success.** A reply that failed leaves the sentence in the box, because
    // the person is about to be asked to send it again.
    if (sent) _reply.clear();
  }

  Future<void> _close() async {
    final confirmed = await showDestructiveDialog(
      context: context,
      title: 'إغلاق التذكرة؟',
      description: 'لن تستطيع الرد بعدها. ردّ العميل يعيد فتحها.',
      confirmLabel: 'إغلاق',
    );

    if (confirmed != true || !mounted) return;

    await context.read<TicketThreadCubit>().closeTicket();
  }

  /// Takes the ticket, or puts it back.
  ///
  /// **Only «خذها» and «أعدها للطابور».** Handing a ticket to a *named* colleague needs a user
  /// picker, and the desk's real move is taking one — so the two moves that need no list are
  /// here, and assigning to somebody else stays a job for the queue screen when it grows one.
  Future<void> _toggleMine(SupportTicket ticket) async {
    final me = sl<Session>().user?.id;
    if (me == null) return;

    await context.read<TicketThreadCubit>().assignTo(
      ticket.assignedTo == me ? null : me,
    );
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
                  OutlinedButton(
                    onPressed: context.read<TicketThreadCubit>().load,
                    child: const Text('أعد المحاولة'),
                  ),
                ],
              ),
            ),
          ),
        ),

        final TicketThreadLoaded loaded => _Loaded(
          state: loaded,
          controller: _reply,
          onSend: _send,
          onClose: _close,
          onToggleMine: () => _toggleMine(loaded.ticket),
        ),
      },
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({
    required this.state,
    required this.controller,
    required this.onSend,
    required this.onClose,
    required this.onToggleMine,
  });

  final TicketThreadLoaded state;
  final TextEditingController controller;
  final Future<void> Function() onSend;
  final Future<void> Function() onClose;
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
        // **`PopScope` rather than a plain back.** The queue behind this screen wants the ticket
        // back — at minimum with its unread count cleared by the read, and often with a new
        // status or assignee on it. Returning it is what saves the list a refetch.
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
                    // **Pull down to see whether the customer has written again.**
                    //
                    // This screen had no refresh at all: the only way to see a new message was
                    // to leave the thread and come back. The desk has the same gap the customer
                    // does, and the same cheap answer.
                    //
                    // The refresh re-reads the thread, and that read marks the desk's side read
                    // on the server — which is correct, because somebody is looking at it.
                    : RefreshIndicator(
                        onRefresh: context.read<TicketThreadCubit>().load,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
                          itemCount: ticket.messages.length,
                          itemBuilder: (context, index) =>
                              _Bubble(message: ticket.messages[index]),
                        ),
                      ),
              ),

              if (canManage && ticket.status.acceptsReplies)
                _Composer(
                  controller: controller,
                  isSending: state.isWorking,
                  onSend: onSend,
                )
              else if (ticket.status.isClosed)
                // Said rather than left as an empty space where a box used to be: the server
                // refuses a reply on a closed ticket, and the screen should say so before
                // somebody types a paragraph.
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 20.h),
                  child: Text(
                    'التذكرة مغلقة. ردّ العميل يعيد فتحها.',
                    textAlign: TextAlign.center,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Who is asking, about what, and whose desk it is.
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
              // A phone number reads left to right even in this RTL screen.
              textDirection: TextDirection.ltr,
              style: context.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
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
  const _Bubble({required this.message});

  final TicketMessage message;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    // **`unknown` is drawn as the shop's**, which is the safe reading: attributing a sentence to
    // the customer that was not theirs is the worse of the two mistakes.
    final fromCustomer = message.from == MessageAuthor.customer;

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
                // The colleague who answered, named — «من ردّ عليه؟» is a question the shop is
                // entitled to ask of itself. The customer's app is sent no name at all.
                if (!fromCustomer && message.authorName != null) ...[
                  Text(
                    message.authorName!,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: scheme.onPrimaryContainer.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 3.h),
                ],
                Text(
                  message.body,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: fromCustomer ? scheme.onSurface : scheme.onPrimaryContainer,
                    height: 1.5,
                  ),
                ),
                if (message.sentAt case final at?) ...[
                  SizedBox(height: 4.h),
                  Text(
                    at.stampLabel,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: (fromCustomer ? scheme.onSurface : scheme.onPrimaryContainer)
                          .withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
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
  });

  final TextEditingController controller;
  final bool isSending;
  final Future<void> Function() onSend;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 8.h),
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText: 'اكتب ردّك…',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            SizedBox(width: 8.w),
            // **Busy rather than disabled.** A send button that greys out halfway through the
            // request looks like it broke; refusing the second tap is `_write`'s job.
            IconButton.filled(
              onPressed: isSending ? null : onSend,
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
