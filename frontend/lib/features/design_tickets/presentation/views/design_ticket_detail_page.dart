import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/files/attachment_picker.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_dialog.dart';
import 'package:dayaa/features/audit/models/audit_subject.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket_file.dart';
import 'package:dayaa/features/design_tickets/presentation/viewmodel/design_ticket_detail_cubit.dart';
import 'package:dayaa/features/design_tickets/presentation/widgets/design_ticket_status_pill.dart';
import 'package:dayaa/features/design_tickets/presentation/widgets/design_version_tile.dart';
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

  Future<void> _accept(BuildContext context) async {
    final cubit = context.read<DesignTicketDetailCubit>();

    await _run(context, cubit.accept, 'تم قبول الطلب');
  }

  Future<void> _upload(BuildContext context, {required bool asVersion}) async {
    final cubit = context.read<DesignTicketDetailCubit>();
    final picker = sl<AttachmentPicker>();

    final picked = await picker.pick(AttachmentSource.documents);

    // Backing out of the picker is the expected ending of that call, not a failure — nothing is
    // reported about it.
    if (picked.isEmpty || !context.mounted) return;

    final file = picked.first;

    await _run(
      context,
      () => asVersion
          ? cubit.submit(path: file.path, filename: file.name)
          : cubit.attach(path: file.path, filename: file.name),
      asVersion ? 'تم إرسال التصميم للمراجعة' : 'تم رفع المرفق',
    );
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
                  tooltip: 'إلغاء التذكرة',
                  onPressed: state.isWorking ? null : () => _cancel(context),
                  icon: Icon(AppIcons.close),
                ),
              IconButton(
                tooltip: 'السجل',
                onPressed: () => context.push(Routes.activityLog(AuditSubject.designTicket, ticket.id)),
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
                  _Attachments(files: ticket.attachments),
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
                  onAccept: () => _accept(context),
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
        SizedBox(height: 10.h),
        Wrap(
          spacing: 16.w,
          runSpacing: 4.h,
          children: [
            if (ticket.requester != null)
              _Fact(label: 'طلبها', value: ticket.requester!.name),
            // **Two facts, not one.** Who it is addressed to, and who actually took it — a
            // reassignment moves the first and never the second.
            if (ticket.designer != null) _Fact(label: 'المصمم', value: ticket.designer!.name),
            if (ticket.acceptedBy != null)
              _Fact(label: 'استلمها', value: ticket.acceptedBy!.name),
            if (ticket.approvedBy != null)
              _Fact(label: 'اعتمدها', value: ticket.approvedBy!.name),
            if (ticket.isInSharedPool) const _Fact(label: 'الحالة', value: 'الطابور المشترك'),
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

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;

    return RichText(
      text: TextSpan(
        style: text.bodySmall?.copyWith(color: context.colorScheme.onSurfaceVariant),
        children: [
          TextSpan(text: '$label: '),
          TextSpan(
            text: value,
            style: text.bodySmall?.copyWith(
              color: context.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
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
        Text('الطلب', style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
        SizedBox(height: 6.h),
        Text(ticket.description, style: text.bodyMedium),
        // Split from the description on the server for exactly this reason: the brief is read on
        // the card, the instructions only once somebody has opened the ticket.
        if (ticket.instructions != null && ticket.instructions!.isNotEmpty) ...[
          SizedBox(height: 12.h),
          Text(
            'الملاحظات والتعليمات',
            style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 6.h),
          Text(ticket.instructions!, style: text.bodyMedium),
        ],
      ],
    );
  }
}

class _Attachments extends StatelessWidget {
  const _Attachments({required this.files});

  final List<DesignTicketFile> files;

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
            itemBuilder: (context, index) =>
                DesignTicketFileThumbnail(file: files[index], size: 72),
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
                if (version.isAwaitingReview && ticket.canReview) onReview(version);
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
    required this.onAccept,
    required this.onSubmit,
    required this.onAttach,
    required this.onReview,
  });

  final DesignTicket ticket;
  final bool isWorking;
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
