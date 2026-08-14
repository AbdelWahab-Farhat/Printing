import 'dart:async';

import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_dialog.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/comments/models/comment.dart';
import 'package:dayaa/features/comments/models/comment_subject.dart';
import 'package:dayaa/features/comments/presentation/viewmodel/comments_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The notes staff leave each other about one record — a customer, a supplier.
///
/// **One screen for both, because it is one feature.** What differs between them is the record
/// the notes hang off, which arrives as a [CommentSubject] and goes no further than the
/// repository. See GENERAL-COMMENTS.md.
///
/// **Writing one costs no more than reading the record does** — `customers.view` on a customer,
/// `vendors.view` on a supplier. A note is a working tool rather than a privilege: anybody who
/// may look a record up may tell the next person what they learned, which is the whole reason
/// this exists, since otherwise that sentence is said out loud and leaves with whoever heard it.
///
/// **Who may change one is the server's answer, carried on the note.** Its author, or somebody
/// holding `comments.moderate`. The row draws its buttons off `canEdit` and `canDelete` rather
/// than comparing user ids here — a second copy of an authorization rule is a copy that drifts,
/// and the endpoints refuse regardless.
class CommentsPage extends StatelessWidget {
  const CommentsPage({required this.subject, this.ownerName, super.key});

  /// Which record these notes are about.
  final CommentSubject subject;

  /// Whose notes these are. Passed from the record's own screen so the bar can say it without a
  /// second request; null on a cold deep link, where the heading stands alone.
  final String? ownerName;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CommentsCubit>(
      create: (_) => sl<CommentsCubit>(param1: subject)..load(),
      child: _CommentsView(ownerName: ownerName),
    );
  }
}

class _CommentsView extends StatelessWidget {
  const _CommentsView({this.ownerName});

  final String? ownerName;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CommentsCubit>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('الملاحظات'),
            if (ownerName != null)
              Text(
                ownerName!,
                style: context.textTheme.labelSmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
      body: BlocBuilder<CommentsCubit, CommentsState>(
        builder: (context, state) => switch (state) {
          CommentsLoading() => const Center(child: CircularProgressIndicator()),
          CommentsFailure(:final failure) => _FailureView(
            message: failure.message,
            onRetry: cubit.load,
          ),
          CommentsLoaded(:final comments) => Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: cubit.load,
                  child: comments.isEmpty
                      ? const _EmptyView()
                      : ListView.separated(
                          // `always`, so pull-to-refresh works on a short list too.
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
                          itemCount: comments.length,
                          separatorBuilder: (_, _) => SizedBox(height: 10.h),
                          itemBuilder: (context, index) {
                            final comment = comments[index];

                            return _CommentCard(
                              comment: comment,
                              isBusy: state.isBusy(comment.id),
                            );
                          },
                        ),
                ),
              ),
              _Composer(isSending: state.isAdding),
            ],
          ),
        },
      ),
    );
  }
}

/// Where a note is written, pinned under the list.
///
/// **Its own [StatefulWidget] so the text lives here and nowhere else.** A field whose every
/// keystroke goes through a Cubit is a rebuild of the whole list per character, and this list
/// can be long. The Cubit hears about the sentence once, when it is sent.
class _Composer extends StatefulWidget {
  const _Composer({required this.isSending});

  final bool isSending;

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final failure = await context.read<CommentsCubit>().add(_controller.text);
    if (!mounted) return;

    if (failure != null) {
      // Whatever was typed stays in the box — a refusal that also empties the field costs
      // somebody the sentence they just wrote.
      context.showFailure(failure);

      return;
    }

    _controller.clear();
    // Dismissed so the note that was just written is visible: on a phone the keyboard covers
    // most of the list, and the point of sending is seeing it land.
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        border: Border(top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 10.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                controller: _controller,
                hint: 'اكتب ملاحظة عن هذا العميل…',
                // Grows with the sentence and then scrolls: a one-line box for something
                // somebody is meant to explain is a box that discourages explaining.
                maxLines: 4,
                maxLength: 2000,
                textInputAction: TextInputAction.newline,
                keyboardType: TextInputType.multiline,
                enabled: !widget.isSending,
              ),
              SizedBox(height: 8.h),
              AppButton(
                label: 'إضافة ملاحظة',
                icon: AppIcons.comments,
                isLoading: widget.isSending,
                onPressed: widget.isSending ? null : () => unawaited(_send()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One note: who wrote it, when, what it says, and — only for the reader who may — how to
/// change it.
class _CommentCard extends StatelessWidget {
  const _CommentCard({required this.comment, required this.isBusy});

  final Comment comment;
  final bool isBusy;

  Future<void> _edit(BuildContext context) async {
    final cubit = context.read<CommentsCubit>();

    final body = await _promptForBody(context, initial: comment.body);
    if (body == null || !context.mounted) return;

    final failure = await cubit.edit(comment.id, body);
    if (failure != null && context.mounted) context.showFailure(failure);
  }

  Future<void> _remove(BuildContext context) async {
    final cubit = context.read<CommentsCubit>();

    final confirmed = await showDestructiveDialog(
      context: context,
      title: 'حذف الملاحظة؟',
      description: 'ستختفي من هذه القائمة. يبقى أثرها في سجل التعديلات.',
      confirmLabel: 'حذف',
    );
    if (confirmed != true || !context.mounted) return;

    final failure = await cubit.remove(comment.id);
    if (failure != null && context.mounted) context.showFailure(failure);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final canChange = comment.canEdit || comment.canDelete;

    return Opacity(
      // Greyed while its own request is out, so the row says it is working without the list
      // moving under anybody.
      opacity: isBusy ? 0.5 : 1,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14.r,
                  backgroundColor: scheme.primaryContainer,
                  child: Text(
                    comment.author.displayName.characters.firstOrNull ?? '؟',
                    style: context.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    comment.author.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                if (comment.createdAt case final at?)
                  Text(
                    // The year dropped when it is this one: a column of notes from this
                    // month repeating «2026» twenty times says nothing twenty times.
                    at.shortDayLabel,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 10.h),
            Text(comment.body, style: context.textTheme.bodyMedium),

            // Said plainly rather than hidden: a sentence that quietly became a different
            // sentence is worse than no note at all.
            if (comment.wasEdited) ...[
              SizedBox(height: 6.h),
              Text(
                'عُدّلت',
                style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],

            // Absent, not disabled, for a colleague's note. There is nothing this reader can do
            // to it, and a greyed-out bin invites a tap that only ever produces a refusal.
            if (canChange && !isBusy) ...[
              SizedBox(height: 6.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (comment.canEdit)
                    TextButton.icon(
                      onPressed: () => unawaited(_edit(context)),
                      icon: Icon(AppIcons.edit, size: 16.sp),
                      label: const Text('تعديل'),
                    ),
                  if (comment.canDelete)
                    TextButton.icon(
                      onPressed: () => unawaited(_remove(context)),
                      icon: Icon(AppIcons.delete, size: 16.sp, color: scheme.error),
                      label: Text('حذف', style: TextStyle(color: scheme.error)),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The edit box, as a dialog rather than as an inline field.
///
/// Inline editing would need the list to hold a controller per row and to know which row is
/// open; a dialog is one field with the sentence already in it, and it closes.
Future<String?> _promptForBody(BuildContext context, {required String initial}) {
  final controller = TextEditingController(text: initial);

  return showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('تعديل الملاحظة'),
      content: AppTextField(
        controller: controller,
        maxLines: 5,
        maxLength: 2000,
        autofocus: true,
        textInputAction: TextInputAction.newline,
        keyboardType: TextInputType.multiline,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('إلغاء'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(controller.text),
          child: const Text('حفظ'),
        ),
      ],
    ),
  ).whenComplete(controller.dispose);
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return ListView(
      // A list rather than a Center, so an empty screen can still be pulled to refresh.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 64.h),
      children: [
        Icon(AppIcons.comments, size: 48.sp, color: scheme.outline),
        SizedBox(height: 16.h),
        Text(
          'لا توجد ملاحظات على هذا العميل',
          textAlign: TextAlign.center,
          style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 8.h),
        Text(
          'اكتب ما يحتاج زميلك معرفته عنه قبل أن يخدمه — موعد التسليم الذي يفضّله، '
          'أو الرقم الذي يردّ عليه.',
          textAlign: TextAlign.center,
          style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _FailureView extends StatelessWidget {
  const _FailureView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.error, size: 48.sp, color: context.colorScheme.error),
            SizedBox(height: 16.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyLarge?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 20.h),
            AppButton.outlined(
              label: 'إعادة المحاولة',
              icon: AppIcons.refresh,
              onPressed: () => unawaited(onRetry()),
            ),
          ],
        ),
      ),
    );
  }
}
