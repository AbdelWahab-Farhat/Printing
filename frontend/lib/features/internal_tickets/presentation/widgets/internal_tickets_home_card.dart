import 'dart:async';

import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/internal_tickets/models/internal_ticket.dart';
import 'package:dayaa/features/internal_tickets/presentation/viewmodel/internal_tickets_home_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// «تنتظر ردّك» في الرئيسية — بطاقةُ بريمولا: حتى عشر تذاكر آخرُ كلامٍ فيها لزميلي، الأحدثُ بكلامه
/// أوّلاً، وفي رأسها «تنتظر ردّك» و«غير مقروءة» و«مفتوحة». لمسةٌ تفتح المحادثة، وزرُّ الردّ يكتب
/// ردّاً سريعاً بلا فتحها.
///
/// **غائبةٌ تماماً** حين لا شيء مفتوحاً، أو لم تصل: الرئيسيةُ لا تُبقي مكاناً فارغاً يُسأل عنه.
class InternalTicketsHomeCard extends StatelessWidget {
  const InternalTicketsHomeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<InternalTicketsHomeCubit>(
      create: (_) => sl<InternalTicketsHomeCubit>()..load(),
      child: const _HomeCardView(),
    );
  }
}

class _HomeCardView extends StatelessWidget {
  const _HomeCardView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InternalTicketsHomeCubit, InternalTicketsHomeState>(
      listenWhen: (previous, current) =>
          current is InternalTicketsHomeLoaded && current.lastFailure != null,
      listener: (context, state) {
        if (state case InternalTicketsHomeLoaded(:final lastFailure?)) {
          context.showFailure(lastFailure);
        }
      },
      builder: (context, state) => switch (state) {
        InternalTicketsHomeLoaded(:final home) when home.totalOpen > 0 => Padding(
          padding: EdgeInsets.only(bottom: 24.h),
          child: _Card(home: home),
        ),
        _ => const SizedBox.shrink(),
      },
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.home});

  final InternalTicketsHome home;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final me = sl<Session>().user?.id;

    return Material(
      color: Theme.of(context).brightness == Brightness.dark
          ? scheme.surfaceContainer
          : scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18.r),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => unawaited(context.push(Routes.internalTickets)),
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 10.h),
              child: Row(
                children: [
                  Icon(AppIcons.internalTickets, color: scheme.primary, size: 22.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'تذاكر الموظفين',
                      style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  _Count(label: 'تنتظر ردّك', value: home.awaitingMyReply, strong: true),
                  SizedBox(width: 10.w),
                  _Count(label: 'غير مقروءة', value: home.unreadTickets),
                  SizedBox(width: 10.w),
                  _Count(label: 'مفتوحة', value: home.totalOpen),
                ],
              ),
            ),
          ),
          if (home.tickets.isEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 14.h),
              child: Text(
                'لا شيء ينتظر ردّك الآن',
                style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
            )
          else ...[
            for (final ticket in home.tickets) _Row(ticket: ticket, me: me),
            if (home.hasMore)
              TextButton(
                onPressed: () => unawaited(context.push(Routes.internalTickets)),
                child: Text('عرض الكل (${home.awaitingMyReply})'),
              ),
          ],
        ],
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.label, required this.value, this.strong = false});

  final String label;
  final int value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Column(
        children: [
          Text(
            '$value',
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: strong && value > 0 ? scheme.error : scheme.onSurface,
            ),
          ),
          Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.ticket, required this.me});

  final InternalTicket ticket;
  final int? me;

  Future<void> _quickReply(BuildContext context) async {
    final cubit = context.read<InternalTicketsHomeCubit>();
    final text = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) => _QuickReplySheet(ticket: ticket),
    );

    if (text == null) return;

    final sent = await cubit.quickReply(ticket.id, text);

    if (sent && context.mounted) context.showSuccess('أُرسل الردّ');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final last = ticket.lastMessage;
    final other = ticket.otherSideOf(me);

    return InkWell(
      onTap: () => unawaited(context.push(Routes.internalTicket(ticket.id))),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 6.w, 8.h),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18.r,
              backgroundColor: scheme.primaryContainer,
              child: Text(
                other?.name.characters.firstOrNull ?? '؟',
                style: TextStyle(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w800),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          other?.name ?? ticket.code,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (last?.sentAt case final at?)
                        Text(
                          at.toLocal().relativeDayLabel,
                          style: context.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                  Text(
                    ticket.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodySmall,
                  ),
                  if (last != null && last.preview.isNotEmpty)
                    Text(
                      last.preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => unawaited(_quickReply(context)),
              tooltip: 'ردّ سريع',
              icon: Icon(AppIcons.reply, color: scheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}

/// الردُّ السريع: حقلٌ وزرّ. **الورقةُ تملك حقلها وتتخلّص منه بنفسها** — حركةُ الخروج ما زالت ترسمه
/// بعد أن تعود.
class _QuickReplySheet extends StatefulWidget {
  const _QuickReplySheet({required this.ticket});

  final InternalTicket ticket;

  @override
  State<_QuickReplySheet> createState() => _QuickReplySheetState();
}

class _QuickReplySheetState extends State<_QuickReplySheet> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.ticket.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 12.h),
              AppTextField(
                controller: _text,
                hint: 'اكتب ردّك…',
                autofocus: true,
                minLines: 1,
                maxLines: 5,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
              ),
              SizedBox(height: 12.h),
              AppButton(
                label: 'إرسال',
                icon: AppIcons.send,
                onPressed: () {
                  if (_text.text.trim().isEmpty) return;

                  Navigator.of(context).pop(_text.text);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
