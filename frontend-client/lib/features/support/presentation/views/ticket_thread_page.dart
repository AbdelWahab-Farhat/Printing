import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/utils/dates.dart';
import 'package:dayaa_client/features/badges/models/customer_badge.dart';
import 'package:dayaa_client/features/badges/presentation/viewmodel/badges_cubit.dart';
import 'package:dayaa_client/features/support/models/support_ticket.dart';
import 'package:dayaa_client/features/support/presentation/viewmodel/ticket_thread_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// One conversation with the shop.
///
/// **Opening it is what marks it read**, and the server does that on the same call — so there
/// is no «mark as read» to fire here and no cursor for this app to get wrong.
///
/// **A reply to a closed thread reopens it.** That is the server's decision, not this screen's:
/// a thread somebody is still writing into is closed on paper and open in fact, and that gap is
/// where a customer gets ignored.
class TicketThreadPage extends StatelessWidget {
  const TicketThreadPage({required this.ticketId, super.key});

  final int ticketId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TicketThreadCubit>(
      create: (_) => sl<TicketThreadCubit>(param1: ticketId)..load(),
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

  @override
  void initState() {
    super.initState();

    // **Opening the thread is what marks it read, server-side.** So by the time this screen has
    // drawn, the count the home tile is holding is already stale — clearing it here saves a
    // round trip to learn something this screen just caused.
    //
    // Optimistic on purpose: if the read failed, the next refresh puts the number back. A badge
    // that reappears is a far smaller wrong than one that lingers after the customer has read
    // everything.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<BadgesCubit>().clear(CustomerBadge.support);
    });
  }

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _reply.text.trim();
    if (text.isEmpty) return;

    final cubit = context.read<TicketThreadCubit>();
    final before = cubit.ticket?.messages.length ?? 0;

    await cubit.send(text);

    if (!mounted) return;

    // **Cleared only once the thread actually grew.** Wiping the box on a failed send would
    // lose what the customer wrote, which on a support screen is the worst possible moment to
    // lose it — they would have to type the complaint again.
    if ((cubit.ticket?.messages.length ?? 0) > before) _reply.clear();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TicketThreadCubit, TicketThreadState>(
      listener: (context, state) {
        if (state case TicketThreadLoaded(:final lastFailure?)) {
          context.showFailure(lastFailure);
        }
      },
      builder: (context, state) {
        final ticket = state.ticket;

        // **`canPop: false` so that leaving *always* carries the thread back**, whether the
        // customer used the back button or the system gesture. The list patches itself from it
        // rather than re-reading page one to learn about a badge this screen already cleared —
        // see `SupportCubit.absorb`.
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;

            Navigator.of(context).pop(ticket);
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(ticket?.subject ?? 'المحادثة'),
              actions: [
                if (ticket != null)
                  Padding(
                    padding: EdgeInsets.only(left: 12.w, right: 12.w),
                    child: Center(
                      child: Text(
                        ticket.statusLabel,
                        style: context.textTheme.labelSmall?.copyWith(
                          color: ticket.isOpen
                              ? context.colorScheme.primary
                              : context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            body: SafeArea(
              child: switch (state) {
                TicketThreadLoading() => const Center(child: CircularProgressIndicator()),

                TicketThreadFailure(:final failure) => Center(
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

                TicketThreadLoaded(:final ticket, :final isSending) => Column(
                  children: [
                    if (ticket.order case final order?)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                        color: context.colorScheme.secondaryContainer,
                        child: Text(
                          'بخصوص الطلبية #${order.code}',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),

                    // **Pull down to see whether the shop has answered.**
                    //
                    // This screen had no refresh at all: the only way to see a new reply was to
                    // leave the thread and come back into it. There are no sockets and no push
                    // notifications, so the gesture is the whole of what the customer has.
                    //
                    // **The refresh re-reads the thread, and that read marks it read on the
                    // server.** That is correct here — somebody is looking at the screen — and
                    // it is why the badge is cleared beside it.
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          await context.read<TicketThreadCubit>().load();

                          if (context.mounted) {
                            context.read<BadgesCubit>().clear(CustomerBadge.support);
                          }
                        },
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
                          itemCount: ticket.messages.length,
                          itemBuilder: (context, index) =>
                              _Bubble(message: ticket.messages[index]),
                        ),
                      ),
                    ),

                    if (!ticket.isOpen)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Text(
                          'هذه التذكرة مغلقة — ردُّك سيعيد فتحها.',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),

                    _Composer(
                      controller: _reply,
                      isSending: isSending,
                      onSend: _send,
                    ),
                  ],
                ),
              },
            ),
          ),
        );
      },
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final TicketMessage message;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isMine = message.isMine;

    return Align(
      alignment: isMine ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        constraints: BoxConstraints(maxWidth: 280.w),
        decoration: BoxDecoration(
          color: isMine ? scheme.primaryContainer : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // **«الدعم», never a colleague's name.** Which member of staff answered is the
            // shop's internal arrangement, and naming them would make one person the target of
            // a complaint about a decision the business made.
            if (!isMine)
              Text(
                'الدعم',
                style: context.textTheme.labelSmall?.copyWith(color: scheme.primary),
              ),
            Text(
              message.body,
              style: context.textTheme.bodyMedium?.copyWith(
                color: isMine ? scheme.onPrimaryContainer : scheme.onSurface,
              ),
            ),
            if (message.sentAt case final at?) ...[
              SizedBox(height: 2.h),
              Text(
                at.timeLabel,
                style: context.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
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
  });

  final TextEditingController controller;
  final bool isSending;
  final Future<void> Function() onSend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(hintText: 'اكتب ردك…'),
            ),
          ),
          SizedBox(width: 8.w),
          // A spinner in place of the button, not beside it: the send action is unavailable
          // while one is in flight, and a button that looks pressable but is not reads as a
          // screen that ignored the tap.
          isSending
              ? Padding(
                  padding: EdgeInsets.all(12.w),
                  child: SizedBox(
                    height: 20.h,
                    width: 20.h,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton.filled(
                  onPressed: onSend,
                  icon: Icon(AppIcons.forward),
                  tooltip: 'أرسل',
                ),
        ],
      ),
    );
  }
}
