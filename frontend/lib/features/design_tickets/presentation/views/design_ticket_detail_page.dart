import 'dart:async';

import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/files/attachment_picker.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/print_colors/print_color.dart';
import 'package:dayaa/core/print_colors/print_colors_editor.dart';
import 'package:dayaa/core/print_colors/print_colors_view.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/theme/app_tones.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/widgets/amount_sheet.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_dialog.dart';
import 'package:dayaa/core/widgets/attachment_sheet.dart';
import 'package:dayaa/core/widgets/image_viewer.dart';
import 'package:dayaa/features/audit/models/audit_subject.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket_file.dart';
import 'package:dayaa/features/design_tickets/models/design_version_rules.dart';
import 'package:dayaa/features/design_tickets/presentation/viewmodel/design_ticket_detail_cubit.dart';
import 'package:dayaa/features/design_tickets/presentation/widgets/accept_ticket_prompt.dart';
import 'package:dayaa/features/design_tickets/presentation/widgets/assign_designer_sheet.dart';
import 'package:dayaa/features/design_tickets/presentation/widgets/design_ticket_attachments.dart';
import 'package:dayaa/features/design_tickets/presentation/widgets/design_ticket_status_pill.dart';
import 'package:dayaa/features/design_tickets/presentation/widgets/design_version_images_sheet.dart';
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

    final acceptance = await confirmTicketAcceptance(context, ticket);

    if (acceptance == null || !context.mounted) return;

    await _run(context, () => cubit.accept(pay: acceptance.pay), 'تم قبول الطلب');
  }

  /// قلم المصمم المسؤول، ولا يملك «تعديل الطلب»: الأجر وحده. السعر المقترح مكتوبٌ في الحقل ما لم
  /// يُكتب أجر، والفراغ يمحوه.
  Future<void> _editPay(BuildContext context, DesignTicket ticket) async {
    final cubit = context.read<DesignTicketDetailCubit>();

    final choice = await showAmountSheet(
      context: context,
      title: 'أجرة المصمم',
      label: 'المبلغ',
      confirmLabel: 'حفظ',
      initial: ticket.designerPay ?? ticket.suggestedPay,
    );

    if (choice == null || !context.mounted) return;

    await _run(context, () => cubit.setPay(choice.amount), 'تم تحديث أجرة المصمم');
  }

  /// ما تقوله نافذة الاعتماد: المبلغ، ومحفظة رافع النسخة — وهو من يستلمه في الخادم.
  ReviewPay? _payOn(DesignTicket ticket, DesignTicketFile version) {
    final pay = ticket.designerPay;

    if (pay == null || (double.tryParse(pay) ?? 0) <= 0) return null;

    return ReviewPay(amount: pay, payee: version.uploader?.name ?? ticket.acceptedBy?.name);
  }

  /// «إضافة مرفق»: briefs and reference files.
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
  /// A version goes through [_uploadVersion] instead: it is gathered on a sheet of its own.
  Future<void> _upload(BuildContext context, {required bool asVersion}) async {
    if (asVersion) return _uploadVersion(context);

    final cubit = context.read<DesignTicketDetailCubit>();

    final source = await showAttachmentSheet(context: context, title: 'إضافة مرفق');

    // Dismissing the sheet is a decision to do nothing, not a failure.
    if (source == null || !context.mounted) return;

    final picked = await sl<AttachmentPicker>().pick(
      source,
      // Anything `config('media.design_tickets.mimes')` takes, which is wider than the customer
      // library's — see the note in that file.
      extensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'],
    );

    // Backing out of the picker is the expected ending of that call, not a failure — nothing is
    // reported about it.
    if (picked.isEmpty || !context.mounted) return;

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

  /// «رفع التصميم».
  ///
  /// **A version is two images or more, judged together** (DESIGN-VERSION-IMAGES.md): the front
  /// of the bag, the back, the logo close-up. They are gathered on «صور التصميم» one pick at a
  /// time, from any source, then sent in one request and shown as one row the review button
  /// reads. The sheet will not hand back fewer than two or more than six; the check below only
  /// guards against a sheet that ever does.
  Future<void> _uploadVersion(BuildContext context) async {
    final cubit = context.read<DesignTicketDetailCubit>();

    final images = await showDesignVersionImagesSheet(context: context);

    // Dismissing the sheet is a decision to do nothing, not a failure.
    if (images == null || !context.mounted) return;

    final refusal = DesignVersionRules.refusal([for (final image in images) image.name]);

    if (refusal != null) {
      context.showError(refusal);

      return;
    }

    // «ألوان الطباعة» this version was drawn in — started from the last version's, or from
    // what the brief asked for, so a round with no change in ink is one tap. Dismissing the
    // sheet calls the upload off, the way dismissing the images does.
    final ticket = cubit.state.ticket;
    final previous = ticket?.latestVersion?.printColors ?? const <PrintColor>[];
    final colors = await showPrintColorsSheet(
      context: context,
      initial: previous.isNotEmpty ? previous : ticket?.printColors ?? const [],
      confirmLabel: 'إرسال للمراجعة',
      // A ticket for a print order: the version cannot go up without its colours, because its
      // approval puts them on the order (PRINT-COLORS.md §10).
      required: ticket?.printColorsRequired ?? false,
    );

    if (colors == null || !context.mounted) return;

    await _run(
      context,
      () => cubit.submit(images: images, printColors: colors),
      'تم إرسال التصميم للمراجعة',
    );
  }

  Future<void> _review(
    BuildContext context,
    DesignTicket ticket,
    DesignTicketFile version,
  ) async {
    final cubit = context.read<DesignTicketDetailCubit>();

    final choice = await showReviewVersionSheet(
      context: context,
      version: version,
      pay: _payOn(ticket, version),
    );

    if (choice == null || !context.mounted) return;

    await _run(
      context,
      () => cubit.review(
        version.id,
        verdict: choice.verdict,
        note: choice.note,
        // المبلغ الذي قُرئ في النافذة، فلا يُدفع غيره إن تغيّر الأجر والنافذة مفتوحة.
        confirmedPay: choice.verdict == DesignSubmissionStatus.approved
            ? ticket.designerPay ?? '0'
            : null,
      ),
      choice.verdict == DesignSubmissionStatus.approved
          ? 'تم اعتماد التصميم وحفظه في حساب الزبون'
          : 'تم إرسال طلب التعديل',
    );
  }

  /// «سحب النسخة» — المصمّم رفع ملفاً خطأً. **يُسأل أولاً**: النسخةُ تخرج من طابور المراجعة.
  Future<void> _withdraw(BuildContext context, DesignTicketFile version) async {
    final cubit = context.read<DesignTicketDetailCubit>();

    final confirmed = await showDestructiveDialog(
      context: context,
      title: 'سحب النسخة',
      description: 'تبقى في السجلّ بعلامة «سحبها المصمّم»، وترفع الملف الصحيح بعدها.',
      confirmLabel: 'سحب',
    );

    if (confirmed != true || !context.mounted) return;

    await _run(context, () => cubit.withdraw(version.id), 'سُحبت النسخة — ارفع الملف الصحيح');
  }

  /// يفتح «الرد داخل التذكرة»، ثم يُحدّث التذكرة عند العودة.
  ///
  /// **التحديث هو نصفُ الشارة.** الشاشةُ التي تفتحها تُعلّم المحادثة مقروءةً على الخادم، فلو
  /// عاد القارئ إلى هذه الصفحة دون إعادة قراءتها لبقيت الشارةُ ترسم رقماً أطفأه صاحبه بنفسه
  /// قبل ثانية — وهو ما يُقرأ كعطبٍ لا كتأخير.
  Future<void> _openConversation(BuildContext context, DesignTicket ticket) async {
    final cubit = context.read<DesignTicketDetailCubit>();

    await context.push(Routes.designTicketComments(ticket.id));

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
      choice.userId == null ? 'تم إلغاء الإسناد — غير مُسنَد لمصمم' : 'تم إسناد التذكرة',
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
        printColors: edit.printColors,
        pay: edit.pay,
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
              if (ticket.canManage)
                IconButton(
                  tooltip: 'تعديل الطلب',
                  onPressed: state.isWorking ? null : () => _edit(context, ticket),
                  icon: Icon(AppIcons.edit),
                )
              else if (ticket.canSetPay)
                IconButton(
                  tooltip: 'تعديل أجرة المصمم',
                  onPressed: state.isWorking ? null : () => _editPay(context, ticket),
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
          // «الرد داخل التذكرة» — زرٌّ عائمٌ باسمه، لا أيقونةٌ في الشريط. كان فقاعتين بين
          // «تعديل» و«إلغاء» و«السجل» فلم يعرف أحدٌ أنّ للتذكرة محادثة؛ والعائمُ يبقى ظاهراً
          // مهما نزلت الصفحة، كـ«اسأل عن الطلبية» في تطبيق العميل. خلف إذن القراءة نفسه، لأنّ
          // كتابة ردٍّ جزءٌ من العمل لا امتيازٌ فوقه.
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'fab-design-ticket-chat',
            onPressed: () => _openConversation(context, ticket),
            // الشارةُ رقمٌ لا نقطة: ردٌّ واحد ونوبةُ ذهابٍ وإياب في عطلةٍ طويلة ليسا خبراً
            // واحداً، والسقفُ «+99» يمنع الزرّ من أن يتّسع.
            icon: Badge(
              isLabelVisible: ticket.unreadComments > 0,
              label: Text(
                ticket.unreadComments > 99 ? '+99' : '${ticket.unreadComments}',
              ),
              child: Icon(AppIcons.comments),
            ),
            label: const Text('المحادثة'),
          ),
          // Design ب (2026-11-15) without its status track: header, the next step, the two ways
          // out, the people, then the brief, the attachments and the versions on a rail.
          body: RefreshIndicator(
            onRefresh: cubit.load,
            child: ListView(
              // 96 at the bottom, not 32: the last row scrolls above the floating button.
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 96.h),
              children: [
                _Header(ticket: ticket),
                if (_NextStep.offers(ticket)) ...[
                  SizedBox(height: 14.h),
                  _NextStep(
                    ticket: ticket,
                    isWorking: state.isWorking,
                    onAccept: () => _accept(context, ticket),
                    onSubmit: () => _upload(context, asVersion: true),
                    onReview: () {
                      final pending = ticket.pendingVersion;

                      if (pending != null) _review(context, ticket, pending);
                    },
                    onWithdraw: () {
                      final pending = ticket.pendingVersion;

                      if (pending != null) _withdraw(context, pending);
                    },
                  ),
                ],
                if (_WaysOut.hasAny(ticket)) ...[
                  SizedBox(height: 14.h),
                  _WaysOut(ticket: ticket),
                ],
                if (_People.hasAny(ticket)) ...[
                  SizedBox(height: 10.h),
                  _People(
                    ticket: ticket,
                    isWorking: state.isWorking,
                    onAssign: () => _assign(context, ticket),
                  ),
                ],
                SizedBox(height: 24.h),
                _Brief(ticket: ticket),
                // Shown to a manager even when empty: the «add» tile lives in it.
                if (ticket.attachments.isNotEmpty || ticket.canManage) ...[
                  SizedBox(height: 24.h),
                  DesignTicketAttachments(
                    files: ticket.attachments,
                    // Null hides the delete affordance rather than drawing one that refuses:
                    // `canManage` is already false on a closed ticket and for a designer.
                    onRemove: ticket.canManage
                        ? (file) => _removeAttachment(context, file)
                        : null,
                    onAdd: ticket.canManage
                        ? () {
                            // A tile has no busy state of its own, so a second tap while an
                            // upload is running is ignored here.
                            if (!state.isWorking) unawaited(_upload(context, asVersion: false));
                          }
                        : null,
                  ),
                ],
                SizedBox(height: 24.h),
                _Versions(
                  ticket: ticket,
                  onReview: (version) => _review(context, ticket, version),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The title, the status beside it, and the customer's name under it.
///
/// **The current status only.** Design ب drew a four-step track here; the owner kept the screen
/// and dropped the track (2026-11-15) — the step the ticket stands on is the whole answer.
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
            Padding(
              padding: EdgeInsets.only(top: 4.h),
              child: DesignTicketStatusPill(status: ticket.status, label: ticket.statusLabel),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        // The snapshot, never a fetched customer: a designer holds no grant on that table.
        Text(
          ticket.customerName,
          style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        if (ticket.cancellationReason case final reason?) ...[
          SizedBox(height: 12.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'سبب الإلغاء',
                  style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
                SizedBox(height: 2.h),
                Text(reason, style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// The move the server offers this reader now, under the header where the eye lands first.
///
/// **Drawn from the `can*` flags, never from the status.** The flags already fold in the reader's
/// role on this ticket and, for the review, whether they uploaded the version themselves — which
/// no status can say.
class _NextStep extends StatelessWidget {
  const _NextStep({
    required this.ticket,
    required this.isWorking,
    required this.onAccept,
    required this.onReview,
    required this.onWithdraw,
    required this.onSubmit,
  });

  final DesignTicket ticket;
  final bool isWorking;
  final VoidCallback onAccept;
  final VoidCallback onReview;
  final VoidCallback onWithdraw;
  final VoidCallback onSubmit;

  /// Whether there is anything to draw. A closed ticket answers no, which is what
  /// «read-only after closing» looks like.
  static bool offers(DesignTicket ticket) =>
      ticket.canAccept || ticket.canReview || ticket.canWithdraw || ticket.canSubmit;

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[
      if (ticket.canAccept)
        AppButton(label: 'قبول الطلب', isLoading: isWorking, onPressed: onAccept),
      if (ticket.canReview)
        AppButton(label: 'مراجعة التصميم', isLoading: isWorking, onPressed: onReview),
      // The designer who uploaded the wrong file takes it back, and the upload button returns.
      if (ticket.canWithdraw)
        AppButton.tonal(label: 'سحب النسخة', isLoading: isWorking, onPressed: onWithdraw),
      if (ticket.canSubmit)
        AppButton(
          label: ticket.versionCount == 0 ? 'رفع التصميم' : 'رفع نسخة معدّلة',
          isLoading: isWorking,
          onPressed: onSubmit,
        ),
    ];

    return Column(
      children: [
        for (var index = 0; index < buttons.length; index++) ...[
          if (index > 0) SizedBox(height: 10.h),
          buttons[index],
        ],
      ],
    );
  }
}

/// The customer and the order: the two places a design ticket leads back to, side by side.
///
/// **A tile opens its page only for a reader holding that page's grant.** The ticket carries the
/// customer as a snapshot precisely so a designer needs no grant on customers, and a link that
/// answers 403 is worse than no link. The order follows the same rule on `orders.view`. Without
/// the grant the tile still names the code, which is what somebody says on the telephone.
class _WaysOut extends StatelessWidget {
  const _WaysOut({required this.ticket});

  final DesignTicket ticket;

  static bool hasAny(DesignTicket ticket) => ticket.customerCode != null || ticket.order != null;

  @override
  Widget build(BuildContext context) {
    final session = sl<Session>();
    final customerCode = ticket.customerCode;
    final order = ticket.order;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (customerCode != null)
          Expanded(
            child: _LinkTile(
              icon: AppIcons.person,
              label: 'العميل',
              value: customerCode,
              onTap: session.can(AppPermission.viewCustomers)
                  ? () => context.push(Routes.customer(ticket.customerId))
                  : null,
            ),
          ),
        if (customerCode != null && order != null) SizedBox(width: 10.w),
        // On approval the design goes onto this order (PRINT-COLORS.md §10).
        if (order != null)
          Expanded(
            child: _LinkTile(
              icon: AppIcons.orders,
              label: 'الطلبية',
              // Bare, like an order number everywhere: the label says what the number is.
              value: order.code,
              onTap: session.can(AppPermission.viewOrders)
                  ? () => context.push(Routes.order(order.id))
                  : null,
            ),
          ),
      ],
    );
  }
}

/// One way out: an icon, what it is, and its code.
///
/// **A link looks like one.** The code takes the primary colour and a chevron follows it; a tile
/// with no [onTap] keeps neither, so a tile that does nothing never invites a tap.
class _LinkTile extends StatelessWidget {
  const _LinkTile({required this.icon, required this.label, required this.value, this.onTap});

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;
    final isLink = onTap != null;

    return Material(
      color: scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(18.r),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              Container(
                width: 40.r,
                height: 40.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isLink ? scheme.primaryContainer : scheme.surfaceContainerHighest,
                ),
                child: Icon(
                  icon,
                  size: 20.r,
                  color: isLink ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isLink ? scheme.primary : scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              if (isLink) Icon(AppIcons.forward, size: 18.r, color: scheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Who holds the ticket — addressed to, taken by, approved by — and the pay that goes with it.
///
/// **[DesignTicket.designer] and [DesignTicket.acceptedBy] are two facts.** The first is who the
/// ticket is addressed to, the second who actually took it; a reassignment moves the first and
/// never the second. They share one row only when they are the same person.
class _People extends StatelessWidget {
  const _People({required this.ticket, required this.isWorking, required this.onAssign});

  final DesignTicket ticket;
  final bool isWorking;
  final VoidCallback onAssign;

  static bool hasAny(DesignTicket ticket) =>
      ticket.isInSharedPool ||
      ticket.designer != null ||
      ticket.acceptedBy != null ||
      ticket.approvedBy != null ||
      ticket.designerPay != null ||
      ticket.canSetPay ||
      ticket.canAssign;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    // The way to the employee's page and wallet, like the customer's tile: only for a reader
    // that page opens for.
    VoidCallback? toEmployee(DesignTicketActor person) =>
        sl<Session>().can(AppPermission.viewUsers)
        ? () => context.push(Routes.employee(person.id))
        : null;

    final designer = ticket.designer;
    final taker = ticket.acceptedBy;

    final rows = <Widget>[
      if (ticket.isInSharedPool)
        const _PersonRow.pool()
      else if (designer != null && taker != null && designer.id == taker.id)
        _PersonRow(person: designer, role: 'المصمم · استلمها', onTap: toEmployee(designer))
      else ...[
        if (designer != null)
          _PersonRow(person: designer, role: 'المصمم', onTap: toEmployee(designer)),
        if (taker != null) _PersonRow(person: taker, role: 'استلمها', onTap: toEmployee(taker)),
      ],
      if (ticket.approvedBy case final approver?) _PersonRow(person: approver, role: 'اعتمدها'),
      // Absent for a reader who neither reads nor writes it; «not set» for one who writes it.
      if (ticket.designerPay != null || ticket.canSetPay)
        _PayRow(
          value: switch (ticket.designerPay) {
            final pay? => '${groupedDecimal(pay)} د.ل',
            null => 'لم يُحدَّد',
          },
        ),
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < rows.length; index++) ...[
            if (index > 0)
              Divider(
                height: 1,
                thickness: 1,
                color: scheme.outlineVariant.withValues(alpha: 0.5),
              ),
            rows[index],
          ],
          if (ticket.canAssign)
            Padding(
              padding: EdgeInsets.only(top: rows.isEmpty ? 16.h : 4.h, bottom: 16.h),
              child: AppButton.tonal(
                label: ticket.isInSharedPool ? 'إسناد إلى مصمم' : 'تغيير المصمم',
                isLoading: isWorking,
                // **Dead while a version is waiting on a verdict.** Moving the ticket at «under
                // review» hands somebody a design they did not draw and are about to be judged
                // on. Judge the version first: approval closes the ticket, a change request
                // sends it back to «in progress» and this button wakes up again.
                onPressed: ticket.status == DesignTicketStatus.underReview ? null : onAssign,
              ),
            ),
        ],
      ),
    );
  }
}

/// One person on the ticket: the initial in a circle, the name, and the role under it.
class _PersonRow extends StatelessWidget {
  const _PersonRow({required DesignTicketActor this.person, required this.role, this.onTap});

  /// Addressed to nobody and taken by nobody — the honest answer to «who is drawing it».
  const _PersonRow.pool() : person = null, role = 'المصمم', onTap = null;

  final DesignTicketActor? person;
  final String role;

  /// Where the name leads, when it leads anywhere. A link takes the primary colour and a chevron.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;
    final name = person?.name ?? 'غير مُسنَد لمصمم';
    final isLink = onTap != null;

    final avatar = person == null
        ? Container(
            width: 40.r,
            height: 40.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: scheme.outline),
            ),
            child: Icon(AppIcons.unassigned, size: 20.r, color: scheme.onSurfaceVariant),
          )
        : Container(
            width: 40.r,
            height: 40.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, color: scheme.secondaryContainer),
            child: Text(
              name.isEmpty ? '' : name.characters.first,
              style: text.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.onSecondaryContainer,
              ),
            ),
          );

    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: 64.h),
        child: Row(
          children: [
            avatar,
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isLink ? scheme.primary : scheme.onSurface,
                    ),
                  ),
                  Text(role, style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
            if (isLink) Icon(AppIcons.forward, size: 18.r, color: scheme.primary),
          ],
        ),
      ),
    );
  }
}

/// «أجرة المصمم»: a figure that only reads. The pencil in the app bar is the way to change it.
class _PayRow extends StatelessWidget {
  const _PayRow({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: 56.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'أجرة المصمم',
              style: text.bodyMedium?.copyWith(color: context.colorScheme.onSurfaceVariant),
            ),
          ),
          Text(value, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
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
        Text('الطلب', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        SizedBox(height: 6.h),
        Text(ticket.description, style: text.bodyMedium?.copyWith(height: 1.7)),
        // **Drawn under the same heading rather than dropped.** Nothing writes `instructions`
        // any more, but a ticket raised before the merge still carries one, and hiding words
        // somebody typed is worse than an extra paragraph.
        if (ticket.instructions case final instructions? when instructions.isNotEmpty) ...[
          SizedBox(height: 6.h),
          Text(instructions, style: text.bodyMedium?.copyWith(height: 1.7)),
        ],
        // What the customer asked the inks to be. Under the request, because it is part of it;
        // each version below says what it was actually drawn in.
        if (ticket.printColors.isNotEmpty) ...[
          SizedBox(height: 12.h),
          Text(
            'ألوان الطباعة المطلوبة',
            style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 6.h),
          PrintColorsView(colors: ticket.printColors),
        ],
      ],
    );
  }
}

/// Every version ever uploaded, newest first, on a rail — each dot coloured by its verdict.
class _Versions extends StatelessWidget {
  const _Versions({required this.ticket, required this.onReview});

  final DesignTicket ticket;
  final void Function(DesignTicketFile version) onReview;

  Color _dot(ColorScheme scheme, DesignTicketFile version) => switch (version.status) {
    DesignSubmissionStatus.approved => scheme.paid,
    DesignSubmissionStatus.changesRequested => scheme.error,
    DesignSubmissionStatus.proposed => scheme.tertiary,
    _ => scheme.outline,
  };

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;

    // **None is ever removed.** That is what «keep every earlier version» looks like on a
    // screen. The API sends them oldest first — `newestVersion` reads `.last` — so the flip is
    // here and only here.
    final versions = ticket.versions.reversed.toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'التصاميم (${ticket.versionCount})',
          style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 12.h),
        if (versions.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 22.h, horizontal: 12.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Text(
              'لم يُرفع أي تصميم بعد',
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          )
        else
          for (var index = 0; index < versions.length; index++)
            _railed(
              context,
              version: versions[index],
              isFirst: index == 0,
              isLast: index == versions.length - 1,
              tile: Opacity(
                // Kept in the record under its number, but no longer in play.
                opacity: versions[index].isWithdrawn ? 0.55 : 1,
                child: DesignVersionTile(
                  version: versions[index],
                  onTap: () => _open(context, versions[index]),
                ),
              ),
            ),
      ],
    );
  }

  /// The rail is drawn beside the tile rather than measured against it: a `Stack` sized by the
  /// tile, so no intrinsic-height pass runs over the thumbnail and the colour chips.
  Widget _railed(
    BuildContext context, {
    required DesignTicketFile version,
    required bool isFirst,
    required bool isLast,
    required Widget tile,
  }) {
    final scheme = context.colorScheme;
    final dotTop = 22.h;
    final dotSize = 12.r;
    final dotCentre = dotTop + dotSize / 2;
    final rail = scheme.surfaceContainerHighest;

    return Stack(
      children: [
        if (!(isFirst && isLast))
          PositionedDirectional(
            start: 5.w,
            top: isFirst ? dotCentre : 0,
            bottom: isLast ? null : 0,
            height: isLast ? dotCentre : null,
            child: Container(width: 2, color: rail),
          ),
        PositionedDirectional(
          start: 0,
          top: dotTop,
          child: Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(shape: BoxShape.circle, color: _dot(scheme, version)),
          ),
        ),
        Padding(padding: EdgeInsetsDirectional.only(start: 24.w), child: tile),
      ],
    );
  }

  void _open(BuildContext context, DesignTicketFile version) {
    if (version.isAwaitingReview && ticket.canReview) {
      onReview(version);

      return;
    }

    // **Every other tap opens the picture**, through the same viewer the list card uses. A tile
    // that did nothing for anybody who could not judge it — the designer who drew it, or anybody
    // reading a closed ticket — was a thumbnail too small to see and no way to make it bigger.
    //
    // The whole conversation is handed over rather than the one tile, so the reviewer swipes
    // between rounds instead of closing and reopening: comparing «before» with «after» is the
    // reason to open one at all.
    //
    // **Every image of every version** (DESIGN-VERSION-IMAGES.md), face by face, opening on the
    // first image of the version tapped.
    final pictures = [
      for (final file in ticket.versions.reversed)
        for (final face in file.images)
          if (face.fileUrl case final url?) (file, face.position, url),
    ];

    unawaited(
      openImageViewer(
        context,
        urls: [for (final (_, _, url) in pictures) url],
        initialIndex: pictures.indexWhere((picture) => picture.$1.id == version.id),
        cacheKeys: [
          for (final (file, position, _) in pictures) designVersionFaceCacheKey(file, position),
        ],
      ),
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
