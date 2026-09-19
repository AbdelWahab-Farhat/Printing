import 'dart:async';

import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/files/attachment_picker.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_dialog.dart';
import 'package:dayaa/core/widgets/attachment_sheet.dart';
import 'package:dayaa/core/widgets/image_viewer.dart';
import 'package:dayaa/features/audit/models/audit_subject.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket_file.dart';
import 'package:dayaa/features/design_tickets/presentation/viewmodel/design_ticket_detail_cubit.dart';
import 'package:dayaa/features/design_tickets/presentation/widgets/assign_designer_sheet.dart';
import 'package:dayaa/features/design_tickets/presentation/widgets/design_ticket_status_pill.dart';
import 'package:dayaa/features/design_tickets/presentation/widgets/design_version_tile.dart';
import 'package:dayaa/features/design_tickets/presentation/widgets/edit_ticket_sheet.dart';
import 'package:dayaa/features/design_tickets/presentation/widgets/review_version_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// One design ticket, read top to bottom as the conversation it is.
///
/// The header, the brief, the employee's attachments, then the versions in order — each with the
/// verdict it got and, where it was turned back, the words saying why.
///
/// **Every button is drawn from a `can*` flag on the ticket, never from a permission.** Whether a
/// person may act here is the permission *and* the status *and* their role on this particular
/// ticket — and for the review buttons it also excludes whoever uploaded the version, which no
/// permission can express. Asking the server once and drawing what it answers is the only way the
/// screen and the API agree.
class DesignTicketDetailPage extends StatelessWidget {
  const DesignTicketDetailPage({required this.ticketId, super.key});

  final int ticketId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DesignTicketDetailCubit>(
      create: (_) => sl<DesignTicketDetailCubit>(param1: ticketId)..load(),
      child: const _DesignTicketDetailView(),
    );
  }
}

class _DesignTicketDetailView extends StatelessWidget {
  const _DesignTicketDetailView();

  /// Runs a write and shows whatever the server said about it.
  ///
  /// **The server's Arabic is shown as sent.** Every refusal this screen can meet says something
  /// different to do — «أخذها فلان», «اكتب ما المطلوب تعديله», «لا يمكن مراجعة تصميم رفعته
  /// بنفسك» — and replacing any of them with «حدث خطأ» would throw away the only useful part.
  Future<void> _run(
    BuildContext context,
    Future<Failure?> Function() action,
    String success,
  ) async {
    final failure = await action();

    if (!context.mounted) return;

    if (failure != null) {
      context.showFailure(failure);
    } else {
      context.showSuccess(success);
    }
  }

  /// Taking the ticket.
  ///
  /// **Asked first, in the same words the list asks it in.** Accepting is the one step in this
  /// flow the person doing it cannot undo: it locks every other designer out and makes this
  /// account the only one allowed to upload. The list grew the confirmation first, and a rule
  /// guarded on one screen and not the other is the kind that gets found by accident.
  Future<void> _accept(BuildContext context, DesignTicket ticket) async {
    final cubit = context.read<DesignTicketDetailCubit>();

    final confirmed = await showCustomDialog(
      context: context,
      title: 'قبول الطلب؟',
      description: 'ستصبح أنت المصمم المسؤول عن «${ticket.title}»، ولن يستطيع مصمم آخر أخذها.',
      confirmLabel: 'قبول الطلب',
    );

    if (!(confirmed ?? false) || !context.mounted) return;

    await _run(context, cubit.accept, 'تم قبول الطلب');
  }

  /// Uploading, whichever of the two things is being uploaded.
  ///
  /// **The source is asked for first**, through the same sheet the customer's design library
  /// uses. This used to go straight to the document browser, and that made the commonest case
  /// impossible: artwork arrives over WhatsApp far more often than by email, and on iOS a photo
  /// from WhatsApp lands in the photo library — a place the Files app cannot see at all. A
  /// designer with the bag on their camera roll simply found nothing to pick.
  ///
  /// **Several briefs at once, one after another.** The picker has always returned a list and
  /// this screen took `picked.first` and dropped the rest without saying so — somebody
  /// selecting four reference photos got one and no explanation. They go up sequentially rather
  /// than together: each is its own multipart request against a 25 MB cap, and four of those in
  /// flight on shop Wi-Fi is how a batch fails for a reason that has nothing to do with any of
  /// the files.
  ///
  /// **One failure does not end the batch.** The remaining files are still tried and the count
  /// is reported at the end, because the alternative — stopping on the first — leaves the
  /// person guessing which of the four arrived.
  ///
  /// **A version is one file, always**, and that is the model rather than a shortcut: a version
  /// is one piece of artwork put up for one verdict, and `pendingVersion` is the single row the
  /// review button reads. Four at once would queue three that nobody can reach. Picking several
  /// for a version says so instead of silently taking one.
  Future<void> _upload(BuildContext context, {required bool asVersion}) async {
    final cubit = context.read<DesignTicketDetailCubit>();

    final source = await showAttachmentSheet(
      context: context,
      title: asVersion ? 'رفع التصميم' : 'إضافة مرفق',
    );

    // Dismissing the sheet is a decision to do nothing, not a failure.
    if (source == null || !context.mounted) return;

    final picked = await sl<AttachmentPicker>().pick(
      source,
      // Mirrors `config('media.design_tickets.mimes')`, which is wider than the customer
      // library's — see the note in that file.
      extensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'],
    );

    // Backing out of the picker is the expected ending of that call, not a failure — nothing is
    // reported about it.
    if (picked.isEmpty || !context.mounted) return;

    if (asVersion) {
      if (picked.length > 1) {
        // This screen's own rule rather than the server's, so it is said here rather than
        // dressed up as a `Failure` the API never sent.
        context.showError('اختر ملفاً واحداً — كل تصميم يُراجَع على حدة');

        return;
      }

      await _run(
        context,
        () => cubit.submit(path: picked.first.path, filename: picked.first.name),
        'تم إرسال التصميم للمراجعة',
      );

      return;
    }

    Failure? lastFailure;
    var uploaded = 0;

    for (final file in picked) {
      final failure = await cubit.attach(path: file.path, filename: file.name);

      if (failure == null) {
        uploaded++;
      } else {
        lastFailure = failure;
      }

      if (!context.mounted) return;
    }

    // What happened, in the three shapes it can take. The partial case names both numbers,
    // because «فشل الرفع» over a screen that gained two files is the message that sends
    // somebody looking for a bug.
    switch ((uploaded, picked.length)) {
      case (0, _) when lastFailure != null:
        context.showFailure(lastFailure);
      case (final done, final total) when done == total:
        context.showSuccess(total == 1 ? 'تم رفع المرفق' : 'تم رفع $total مرفقات');
      case (final done, final total):
        context.showSuccess('تم رفع $done من $total — أعد المحاولة للباقي');
    }
  }

  Future<void> _review(BuildContext context, DesignTicketFile version) async {
    final cubit = context.read<DesignTicketDetailCubit>();

    final choice = await showReviewVersionSheet(context: context, version: version);

    if (choice == null || !context.mounted) return;

    await _run(
      context,
      () => cubit.review(version.id, verdict: choice.verdict, note: choice.note),
      choice.verdict == DesignSubmissionStatus.approved
          ? 'تم اعتماد التصميم وحفظه في حساب الزبون'
          : 'تم إرسال طلب التعديل',
    );
  }

  /// يفتح «الرد داخل التذكرة»، ثم يُحدّث التذكرة عند العودة.
  ///
  /// **التحديث هو نصفُ الشارة.** الشاشةُ التي تفتحها تُعلّم المحادثة مقروءةً على الخادم، فلو
  /// عاد القارئ إلى هذه الصفحة دون إعادة قراءتها لبقيت الشارةُ ترسم رقماً أطفأه صاحبه بنفسه
  /// قبل ثانية — وهو ما يُقرأ كعطبٍ لا كتأخير.
  Future<void> _openConversation(BuildContext context, DesignTicket ticket) async {
    final cubit = context.read<DesignTicketDetailCubit>();

    await context.push(Routes.designTicketComments(ticket.id), extra: ticket.title);

    await cubit.load();
  }

  Future<void> _assign(BuildContext context, DesignTicket ticket) async {
    final cubit = context.read<DesignTicketDetailCubit>();

    final choice = await showAssignDesignerSheet(
      context: context,
      currentDesignerId: ticket.designer?.id,
    );

    if (choice == null || !context.mounted) return;

    await _run(
      context,
      () => cubit.assign(choice.userId),
      choice.userId == null ? 'تم إرجاع التذكرة إلى الطابور المشترك' : 'تم إسناد التذكرة',
    );
  }

  Future<void> _edit(BuildContext context, DesignTicket ticket) async {
    final cubit = context.read<DesignTicketDetailCubit>();

    final edit = await showEditTicketSheet(context: context, ticket: ticket);

    if (edit == null || !context.mounted) return;

    await _run(
      context,
      () => cubit.update(
        title: edit.title,
        description: edit.description,
        instructions: edit.instructions,
      ),
      'تم تحديث الطلب',
    );
  }

  /// Removing one of the employee's reference files.
  ///
  /// **Destructive-styled, though the file itself survives.** What is lost is the designer's
  /// access to a picture they may be working from, and that is worth a deliberate tap — the
  /// object staying on disk is a property of the storage layer, not something the person
  /// removing it is thinking about.
  Future<void> _removeAttachment(BuildContext context, DesignTicketFile file) async {
    final cubit = context.read<DesignTicketDetailCubit>();

    final confirmed = await showDestructiveDialog(
      context: context,
      title: 'حذف المرفق',
      description: 'سيختفي من التذكرة. لن يراه المصمم بعد الآن.',
    );

    if (confirmed != true || !context.mounted) return;

    await _run(context, () => cubit.removeAttachment(file.id), 'تم حذف المرفق');
  }

  Future<void> _cancel(BuildContext context) async {
    final cubit = context.read<DesignTicketDetailCubit>();
    final controller = TextEditingController();

    final confirmed = await showDestructiveDialog(
      context: context,
      title: 'إلغاء التذكرة',
      description: 'سيتم إغلاق الطلب. النسخ المرفوعة تبقى محفوظة في السجل.',
      confirmLabel: 'إلغاء التذكرة',
    );

    if (confirmed != true || !context.mounted) {
      controller.dispose();

      return;
    }

    // The reason is required by the server and by the database under it, so it is asked for
    // rather than defaulted — a cancellation with no words is the one thing the designer whose
    // job disappeared cannot work with.
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('سبب الإلغاء'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 2,
          decoration: const InputDecoration(hintText: 'الزبون غيّر رأيه'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('تراجع'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (reason == null || !context.mounted) return;

    await _run(context, () => cubit.cancel(reason), 'تم إلغاء التذكرة');
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DesignTicketDetailCubit>();

    return BlocBuilder<DesignTicketDetailCubit, DesignTicketDetailState>(
      builder: (context, state) {
        final ticket = state.ticket;

        if (ticket == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('تذكرة تصميم')),
            body: switch (state) {
              DesignTicketDetailFailure(:final failure) => _Failure(
                failure: failure,
                onRetry: cubit.load,
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(ticket.code),
            actions: [
              // «الرد داخل التذكرة» — behind the same grant as reading it, because writing a note
              // is part of doing the work rather than a privilege over it.
              IconButton(
                tooltip: 'المحادثة',
                onPressed: () => _openConversation(context, ticket),
                // الشارةُ رقمٌ لا نقطة، كشارة الجرس بجوارها: ردٌّ واحد ونوبةُ ذهابٍ وإياب في
                // عطلةٍ طويلة ليسا خبراً واحداً، والسقفُ «+99» يمنع الشريط من إعادة التوزيع.
                icon: Badge(
                  isLabelVisible: ticket.unreadComments > 0,
                  label: Text(
                    ticket.unreadComments > 99 ? '+99' : '${ticket.unreadComments}',
                  ),
                  child: Icon(AppIcons.comments),
                ),
              ),
              if (ticket.canManage)
                IconButton(
                  tooltip: 'تعديل الطلب',
                  onPressed: state.isWorking ? null : () => _edit(context, ticket),
                  icon: Icon(AppIcons.edit),
                ),
              if (ticket.canManage)
                IconButton(
                  tooltip: 'إلغاء التذكرة',
                  onPressed: state.isWorking ? null : () => _cancel(context),
                  icon: Icon(AppIcons.close),
                ),
              // **Gated, like the same button on every other detail screen in this app.** It
              // was the one that was not, so a designer — whose three grants are view, accept
              // and submit — was offered «السجل» and answered with a 403 by the endpoint
              // behind it. Who edited a ticket and when is a supervisor's question.
              if (sl<Session>().can(AppPermission.viewActivityLogs))
                IconButton(
                  tooltip: 'السجل',
                  onPressed: () =>
                      context.push(Routes.activityLog(AuditSubject.designTicket, ticket.id)),
                  icon: Icon(AppIcons.history),
                ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: cubit.load,
            child: ListView(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 32.h),
              children: [
                _Header(ticket: ticket),
                SizedBox(height: 16.h),
                _Brief(ticket: ticket),
                if (ticket.attachments.isNotEmpty) ...[
                  SizedBox(height: 16.h),
                  _Attachments(
                    files: ticket.attachments,
                    // Null hides the delete affordance rather than drawing one that refuses:
                    // `canManage` is already false on a closed ticket and for a designer.
                    onRemove: ticket.canManage
                        ? (file) => _removeAttachment(context, file)
                        : null,
                  ),
                ],
                SizedBox(height: 16.h),
                _Versions(
                  ticket: ticket,
                  onReview: (version) => _review(context, version),
                ),
                SizedBox(height: 20.h),
                _Actions(
                  ticket: ticket,
                  isWorking: state.isWorking,
                  onAssign: () => _assign(context, ticket),
                  onAccept: () => _accept(context, ticket),
                  onSubmit: () => _upload(context, asVersion: true),
                  onAttach: () => _upload(context, asVersion: false),
                  onReview: () {
                    final pending = ticket.pendingVersion;

                    if (pending != null) _review(context, pending);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.ticket});

  final DesignTicket ticket;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                ticket.title,
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            SizedBox(width: 8.w),
            DesignTicketStatusPill(status: ticket.status, label: ticket.statusLabel),
          ],
        ),
        SizedBox(height: 8.h),
        // The snapshot, never a fetched customer: a designer holds no grant on that table.
        Text(
          ticket.customerName,
          style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        SizedBox(height: 14.h),
        // **Two to a line, label over value, at reading size.** These were a `Wrap` of
        // «العميل: A713   المصمم: محمد علي   استلمها: …» in `bodySmall` — four facts crushed
        // onto one 12sp line where the labels and the names ran together and nothing could be
        // found by glancing. Paired rows give each one a column of its own and let the value
        // take body size, which is what every other list in this app settled on.
        _Facts(
          facts: [
            // **The customer's code, and it is the way back to them.** «طلبها: فرحات» stood
            // here — who keyed the request in, which the history already records and which
            // nobody on this screen has to act on. «A713» is what somebody says on the
            // telephone, and tapping it opens the account the design will land on.
            //
            // The tap is offered only to a reader holding `customers.view`: the ticket carries
            // the customer as a snapshot precisely so a designer needs no grant on that table,
            // and a link that 403s is worse than no link.
            if (ticket.customerCode case final code?)
              _Fact(
                label: 'العميل',
                value: code,
                onTap: sl<Session>().can(AppPermission.viewCustomers)
                    ? () => context.push(Routes.customer(ticket.customerId))
                    : null,
              ),
            // **Two facts, not one.** Who it is addressed to, and who actually took it — a
            // reassignment moves the first and never the second.
            if (ticket.designer != null) _Fact(label: 'المصمم', value: ticket.designer!.name),
            if (ticket.acceptedBy != null)
              _Fact(label: 'استلمها', value: ticket.acceptedBy!.name),
            if (ticket.approvedBy != null)
              _Fact(label: 'اعتمدها', value: ticket.approvedBy!.name),
            // **«المصمم», not «الحالة».** It was labelled «الحالة» and sat a centimetre under
            // the pill that says «جديد» — which is the status — so one screen used the same
            // word for two different things. This answers who is drawing it, and the honest
            // answer while nobody has claimed it is that it is still in the pool.
            if (ticket.isInSharedPool)
              const _Fact(label: 'المصمم', value: 'الطابور المشترك'),
          ],
        ),
        if (ticket.cancellationReason != null) ...[
          SizedBox(height: 12.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Text('سبب الإلغاء: ${ticket.cancellationReason}', style: text.bodySmall),
          ),
        ],
      ],
    );
  }
}

/// The header's facts, two to a line.
///
/// A `Column` of `Row`s rather than a `Wrap`: a wrap sizes each child to its own text, so
/// «العميل: A713» and «اعتمدها: عبدالوهاب فرحات» end up different widths and the second column
/// never lines up. Pairs of `Expanded` give every fact the same half of the row.
class _Facts extends StatelessWidget {
  const _Facts({required this.facts});

  final List<_Fact> facts;

  @override
  Widget build(BuildContext context) {
    if (facts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var row = 0; row < facts.length; row += 2) ...[
          if (row > 0) SizedBox(height: 12.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: facts[row]),
              SizedBox(width: 12.w),
              // An empty half rather than a stretched one: a lone fact on the last line keeps
              // the column it would have had if there were two.
              Expanded(
                child: row + 1 < facts.length ? facts[row + 1] : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// One fact: what it is, then what it says.
class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value, this.onTap});

  final String label;
  final String value;

  /// Where the value leads, when it leads anywhere. Null leaves the fact as plain text — and it
  /// is null on most of them, so the one that *is* a link has to look like one: it takes the
  /// primary colour and an underline rather than only becoming tappable, which nothing on a
  /// line of grey text advertises.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    final scheme = context.colorScheme;

    final fact = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
        SizedBox(height: 2.h),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: text.bodyMedium?.copyWith(
            color: onTap == null ? scheme.onSurface : scheme.primary,
            fontWeight: FontWeight.w700,
            decoration: onTap == null ? null : TextDecoration.underline,
            decorationColor: scheme.primary,
          ),
        ),
      ],
    );

    return onTap == null
        ? fact
        : InkWell(onTap: onTap, borderRadius: BorderRadius.circular(6.r), child: fact);
  }
}

class _Brief extends StatelessWidget {
  const _Brief({required this.ticket});

  final DesignTicket ticket;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // **One heading, not two.** «الطلب» and «الملاحظات والتعليمات» were separate on the
        // argument that the first is read on the card and the second only once the ticket is
        // opened — a split nobody filling the form could act on, so it got the request cut down
        // the middle and made the designer read two blocks to know what was asked. The form
        // asks one question now; see `DesignTicketFormPage`.
        Text('الطلب', style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
        SizedBox(height: 6.h),
        Text(ticket.description, style: text.bodyMedium),
        // **Drawn under the same heading rather than dropped.** Nothing writes `instructions`
        // any more, but a ticket raised before the merge still carries one, and hiding words
        // somebody typed is worse than an extra paragraph.
        if (ticket.instructions case final instructions? when instructions.isNotEmpty) ...[
          SizedBox(height: 6.h),
          Text(instructions, style: text.bodyMedium),
        ],
      ],
    );
  }
}

class _Attachments extends StatelessWidget {
  const _Attachments({required this.files, this.onRemove});

  final List<DesignTicketFile> files;

  /// Null when this reader may not remove one — see the call site.
  final void Function(DesignTicketFile file)? onRemove;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('المرفقات', style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
        SizedBox(height: 8.h),
        SizedBox(
          height: 76.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: files.length,
            separatorBuilder: (_, _) => SizedBox(width: 8.w),
            itemBuilder: (context, index) {
              final file = files[index];

              return GestureDetector(
                // A long press rather than a badge on every tile: removing a reference file is
                // rare, and an X on each thumbnail would put a destructive tap next to the one
                // people actually make, which is opening it.
                onLongPress: onRemove == null ? null : () => onRemove!(file),
                child: DesignTicketFileThumbnail(file: file, size: 72),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Versions extends StatelessWidget {
  const _Versions({required this.ticket, required this.onReview});

  final DesignTicket ticket;
  final void Function(DesignTicketFile version) onReview;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'التصاميم (${ticket.versionCount})',
          style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 8.h),
        if (ticket.versions.isEmpty)
          Text(
            'لم يُرفع أي تصميم بعد',
            style: text.bodySmall?.copyWith(color: context.colorScheme.onSurfaceVariant),
          )
        else
          // **Every version ever uploaded, oldest first, and none is ever removed.** That is what
          // «الاحتفاظ بجميع نسخ التصميم السابقة» looks like on a screen.
          for (final version in ticket.versions)
            DesignVersionTile(
              version: version,
              onTap: () {
                if (version.isAwaitingReview && ticket.canReview) {
                  onReview(version);

                  return;
                }

                // **Every other tap opens the picture**, through the same viewer the list card
                // uses. A tile that did nothing at all for anybody who could not judge it —
                // the designer who drew it, or anybody reading a closed ticket — was a
                // thumbnail too small to see and no way to make it bigger.
                //
                // The whole conversation is handed over rather than the one tile, so the
                // reviewer swipes between rounds instead of closing and reopening: comparing
                // «قبل» with «بعد» is the reason to open one at all.
                final pictures = [
                  for (final file in ticket.versions)
                    if (file.thumbnailUrl ?? file.fileUrl case final url?) (file, url),
                ];

                unawaited(
                  openImageViewer(
                    context,
                    urls: [for (final (_, url) in pictures) url],
                    initialIndex: pictures.indexWhere((pair) => pair.$1.id == version.id),
                    cacheKeys: [
                      for (final (file, _) in pictures) 'design-ticket-file-${file.id}',
                    ],
                  ),
                );
              },
            ),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.ticket,
    required this.isWorking,
    required this.onAssign,
    required this.onAccept,
    required this.onSubmit,
    required this.onAttach,
    required this.onReview,
  });

  final DesignTicket ticket;
  final bool isWorking;
  final VoidCallback onAssign;
  final VoidCallback onAccept;
  final VoidCallback onSubmit;
  final VoidCallback onAttach;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    // Nothing the server says this reader may do — so nothing is drawn. A closed ticket lands
    // here too, which is what «بعد الإغلاق: قراءة فقط» looks like.
    if (!ticket.canAccept && !ticket.canSubmit && !ticket.canReview && !ticket.canManage) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        if (ticket.canAccept)
          AppButton(label: 'قبول الطلب', isLoading: isWorking, onPressed: onAccept),
        if (ticket.canSubmit) ...[
          SizedBox(height: 10.h),
          AppButton(
            label: ticket.versionCount == 0 ? 'رفع التصميم' : 'رفع نسخة معدّلة',
            isLoading: isWorking,
            onPressed: onSubmit,
          ),
        ],
        if (ticket.canReview) ...[
          SizedBox(height: 10.h),
          AppButton(label: 'مراجعة التصميم', isLoading: isWorking, onPressed: onReview),
        ],
        if (ticket.canAssign) ...[
          SizedBox(height: 10.h),
          AppButton.tonal(
            label: ticket.isInSharedPool ? 'إسناد إلى مصمم' : 'تغيير المصمم',
            isLoading: isWorking,
            // **Dead while a version is waiting on a verdict.** Moving the ticket to somebody
            // else at «بانتظار المراجعة» hands them a design they did not draw and are about
            // to be judged on, and leaves the person who did draw it holding nothing. Judge
            // the version first — «اعتماد» closes the ticket, «تعديل مطلوب» sends it back to
            // «قيد التصميم» and this button wakes up again.
            onPressed: ticket.status == DesignTicketStatus.underReview ? null : onAssign,
          ),
        ],
        if (ticket.canManage) ...[
          SizedBox(height: 10.h),
          AppButton.tonal(label: 'إضافة مرفق', isLoading: isWorking, onPressed: onAttach),
        ],
      ],
    );
  }
}

/// What the screen shows when the ticket itself could not be read.
///
/// **The server's own sentence**, including «ليست لك» arriving as a 404 — deliberately not
/// replaced with a blanket message, because the reader holds the grant the endpoint asks for and
/// is being refused by a fact about this row.
class _Failure extends StatelessWidget {
  const _Failure({required this.failure, required this.onRetry});

  final Failure failure;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              failure.message,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyLarge,
            ),
            SizedBox(height: 16.h),
            FilledButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
          ],
        ),
      ),
    );
  }
}
