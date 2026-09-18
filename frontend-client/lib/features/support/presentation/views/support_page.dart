import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/core/theme/app_tones.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/utils/dates.dart';
import 'package:dayaa_client/core/widgets/app_button.dart';
import 'package:dayaa_client/core/widgets/app_card.dart';
import 'package:dayaa_client/core/widgets/app_text_field.dart';
import 'package:dayaa_client/core/widgets/filter_option_chip.dart';
import 'package:dayaa_client/core/widgets/paged_list_view.dart';
import 'package:dayaa_client/features/notifications/presentation/views/notifications_button.dart';
import 'package:dayaa_client/features/support/models/support_ticket.dart';
import 'package:dayaa_client/features/support/presentation/viewmodel/support_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// «الدعم» — a thread per question.
///
/// **No employee is ever named.** Which member of staff answered is the shop's internal
/// arrangement, and putting a name on a reply would make one person the target of a complaint
/// about a decision the business made. The server sends `me` or `support` and nothing else.
class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SupportCubit>(
      create: (_) => sl<SupportCubit>()..load(),
      child: const _SupportView(),
    );
  }
}

class _SupportView extends StatelessWidget {
  const _SupportView();

  Future<void> _compose(BuildContext context) async {
    final cubit = context.read<SupportCubit>();

    // The order this thread is about, when the customer came here from one — read from the
    // location so it survives the branch switch, so they do not have to describe which order
    // they mean. A malformed value is simply no order, never a crash.
    final orderId = int.tryParse(
      GoRouterState.of(context).uri.queryParameters['order'] ?? '',
    );

    final ticket = await showModalBottomSheet<SupportTicket>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (sheetContext) => BlocProvider<SupportCubit>.value(
        value: cubit,
        child: _ComposeSheet(orderId: orderId),
      ),
    );

    if (ticket == null || !context.mounted) return;

    // Straight into the thread — which is what somebody who has just written a question
    // expects to happen next.
    await context.push(Routes.ticket(ticket.id));
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SupportCubit>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('الدعم'),
        actions: const [NotificationsButton()],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 14.h),
              child: const _HoursCard(),
            ),

            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
              child: BlocBuilder<SupportCubit, SupportState>(
                builder: (context, state) => Row(
                  children: [
                    // **Three chips, because the filter has three states.** «الكل» is a real
                    // answer and not the absence of one.
                    FilterOptionChip(
                      label: 'الكل',
                      isSelected: cubit.openOnly == null,
                      onTap: () => cubit.narrowTo(null),
                    ),
                    SizedBox(width: 8.w),
                    FilterOptionChip(
                      label: 'المفتوحة',
                      isSelected: cubit.openOnly == true,
                      onTap: () => cubit.narrowTo(true),
                    ),
                    SizedBox(width: 8.w),
                    FilterOptionChip(
                      label: 'المغلقة',
                      isSelected: cubit.openOnly == false,
                      onTap: () => cubit.narrowTo(false),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: BlocBuilder<SupportCubit, SupportState>(
                builder: (context, state) => PagedListView<SupportTicket>(
                  state: state,
                  onLoadMore: cubit.loadMore,
                  onRefresh: cubit.refresh,
                  emptyMessage: 'لا توجد تذاكر — اسألنا عن أي شيء',
                  padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 16.h),
                  itemBuilder: (context, ticket, index) => _TicketCard(
                    ticket: ticket,
                    onOpen: () async {
                      final updated = await context.push<SupportTicket>(
                        Routes.ticket(ticket.id),
                      );

                      // Patched from what the thread screen was holding — no refetch, and the
                      // scroll position survives.
                      if (updated != null) cubit.absorb(updated);
                    },
                  ),
                ),
              ),
            ),

            // **A button on the floor, not a floating one.** The design draws it full width
            // across the bottom, and it also settles the hero-tag problem the FAB had: «الدعم»
            // is a pushed route now, not a tab, but the two screens can still be alive at once.
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 16.h),
              child: AppButton(
                label: 'تذكرة جديدة',
                icon: AppIcons.add,
                onPressed: () => _compose(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// «الفريق متاح الآن» — when somebody is here to answer.
///
/// **The hours are the shop's, and they are written here.** There is no endpoint for them and
/// inventing one for two lines that change once a decade would be machinery for its own sake.
/// What the card deliberately does *not* claim is that anybody is available right now: the
/// design says «الفريق متاح الآن» in green, and this app has no way to know that — the server
/// sends no presence, and a green dot that is always green is a lie the first evening somebody
/// writes at eleven and hears nothing.
class _HoursCard extends StatelessWidget {
  const _HoursCard();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return AppCard.sunken(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Container(
            width: 46.w,
            height: 46.w,
            decoration: BoxDecoration(
              color: scheme.paidContainer,
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(AppIcons.comments, size: 22.sp, color: scheme.onPaidContainer),
          ),
          SizedBox(width: 13.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'اسألنا عن أي شيء',
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  'السبت–الخميس · 9 ص – 5 م',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
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

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket, required this.onOpen});

  final SupportTicket ticket;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final hasReply = ticket.unreadCount > 0;

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                ticket.subject,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            SizedBox(width: 10.w),
            _StatusPill(ticket: ticket),
          ],
        ),

        if (ticket.order case final order?) ...[
          SizedBox(height: 5.h),
          Text(
            'بخصوص الطلبية #${order.code}',
            style: context.textTheme.bodySmall?.copyWith(color: scheme.primary),
          ),
        ],

        // The last thing anybody said, one line of it. Only the list endpoint sends this — a
        // card patched from the thread screen keeps the preview it was drawn with.
        if (ticket.preview case final preview?) ...[
          SizedBox(height: 9.h),
          Text(
            preview,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.6,
            ),
          ),
        ],

        Divider(height: 22.h, color: scheme.outlineVariant),

        Row(
          children: [
            // **«ردّ جديد», not a red count.** A number in a red circle is a notification
            // badge — the grammar of something gone wrong — and an answer from the shop is the
            // thing the customer came here hoping for. The count is still said, after the words.
            if (hasReply) ...[
              Container(
                width: 8.w,
                height: 8.w,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 7.w),
              Text(
                ticket.unreadCount > 1 ? 'ردود جديدة' : 'ردّ جديد',
                style: context.textTheme.labelSmall?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ] else if (ticket.messagesCount case final count? when count > 0)
              Text(
                count == 1 ? 'رسالة واحدة' : '$count رسائل',
                style: context.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),

            const Spacer(),
            if (ticket.lastMessageAt case final at?)
              Text(
                at.relativeDayLabel,
                style: context.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ],
    );

    return Padding(
      padding: EdgeInsets.only(bottom: 11.h),
      child: Opacity(
        // A closed thread is still readable, and still dimmer than a live one.
        opacity: ticket.isOpen ? 1 : 0.65,
        child: hasReply
            ? AppCard.accent(onTap: onOpen, child: body)
            : AppCard(onTap: onOpen, child: body),
      ),
    );
  }
}

/// «مفتوحة» · «قيد المعالجة» · «مغلقة».
///
/// **The Arabic is the server's and the colour is not.** `status_label` travels with the value
/// so a status added to the business needs no app release; the fill is chosen here, and an
/// unrecognised status gets the neutral one rather than none.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.ticket});

  final SupportTicket ticket;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    final (background, foreground) = switch (ticket.status) {
      TicketStatus.open => (scheme.attentionContainer, scheme.onAttentionContainer),
      TicketStatus.inProgress => (scheme.infoContainer, scheme.onInfoContainer),
      TicketStatus.closed ||
      TicketStatus.unknown => (scheme.surfaceContainerHigh, scheme.onSurfaceVariant),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Text(
        ticket.statusLabel,
        style: context.textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ComposeSheet extends StatefulWidget {
  const _ComposeSheet({this.orderId});

  final int? orderId;

  @override
  State<_ComposeSheet> createState() => _ComposeSheetState();
}

class _ComposeSheetState extends State<_ComposeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _body = TextEditingController();

  bool _isSending = false;

  @override
  void dispose() {
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);

    final result = await context.read<SupportCubit>().submit(
      subject: _subject.text.trim(),
      body: _body.text.trim(),
      orderId: widget.orderId,
    );

    if (!mounted) return;

    setState(() => _isSending = false);

    result.fold(
      context.showFailure,
      (ticket) => Navigator.of(context).pop(ticket),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Lifted above the keyboard, so the send button is never behind it.
      padding: EdgeInsets.only(bottom: context.keyboardInset),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 24.h),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'تذكرة جديدة',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (widget.orderId != null) ...[
                  SizedBox(height: 4.h),
                  Text(
                    'ستُرفق بالطلبية التي كنت تشاهدها.',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                SizedBox(height: 16.h),

                AppTextField(
                  controller: _subject,
                  label: 'الموضوع',
                  validator: (value) =>
                      (value == null || value.trim().isEmpty) ? 'اكتب موضوعاً' : null,
                ),
                SizedBox(height: 12.h),
                AppTextField(
                  controller: _body,
                  label: 'اشرح لنا',
                  maxLines: 5,
                  validator: (value) =>
                      (value == null || value.trim().isEmpty) ? 'اكتب رسالتك' : null,
                ),
                SizedBox(height: 20.h),

                AppButton(label: 'أرسل', isLoading: _isSending, onPressed: _send),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
