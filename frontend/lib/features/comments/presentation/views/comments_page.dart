import 'dart:async';

import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/session/session.dart';
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
                          /*
                           * **Oldest at the top, newest at the bottom — read as a conversation.**
                           *
                           * `reverse: true` rather than reversing the list, and it buys two
                           * things at once. The data stays exactly as the server sends it
                           * (newest first), so `add()` still puts a new note at index 0 and it
                           * still lands where the eye is — now the bottom. And a reversed list
                           * opens already scrolled to index 0, so the screen arrives showing the
                           * last thing said instead of making somebody scroll a year of notes to
                           * find it.
                           *
                           * Reversing the *data* instead would have done neither: the list would
                           * open at the oldest note, and every new one would arrive off-screen.
                           *
                           * The trade is that pull-to-refresh now lives at the top edge, which in
                           * a reversed list is the oldest end — which is where «load older» would
                           * go if this ever paginates, so it is the right edge for it anyway.
                           */
                          reverse: true,
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
    final text = context.textTheme;
    final canChange = comment.canEdit || comment.canDelete;

    // **Who wrote it, asked of the session rather than inferred from `canEdit`.** That flag is
    // true for a moderator too, so drawing a moderator's view of somebody else's note as their
    // own would put the wrong name and the wrong side on it.
    final isMine = sl<Session>().isSelf(comment.author.id);

    return Opacity(
      // Greyed while its own request is out, so the row says it is working without the list
      // moving under anybody.
      opacity: isBusy ? 0.5 : 1,
      child: Align(
        /*
         * **Mine at the end, theirs at the start — and never «left» or «right».**
         *
         * This app is Arabic and runs right-to-left, where a chat mirrors: outgoing sits on the
         * left and incoming on the right, the opposite of an English one. Writing
         * `Alignment.centerRight` would have hard-coded the English answer and put both sides of
         * the conversation on the wrong edge. `AlignmentDirectional` resolves against the
         * ambient direction, so this reads correctly in either without a branch.
         */
        alignment: isMine
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: ConstrainedBox(
          // **The whole of what was asked for.** A note used to fill the screen edge to edge,
          // so a three-word reply looked like a paragraph and nothing said who was talking
          // without reading. Capped at ~78%, a bubble is as wide as what is in it, and the gap
          // on the other side is what makes the two sides legible at a glance.
          constraints: BoxConstraints(maxWidth: 0.78.sw),
          child: Column(
            crossAxisAlignment: isMine
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.fromLTRB(12.w, 9.h, 12.w, 7.h),
                decoration: BoxDecoration(
                  color: isMine ? scheme.primaryContainer : scheme.surfaceContainerHighest,
                  borderRadius: BorderRadiusDirectional.only(
                    topStart: Radius.circular(16.r),
                    topEnd: Radius.circular(16.r),
                    // The squared corner is the tail: it points at the edge the speaker is on,
                    // which is what makes a run of messages from one person read as one run.
                    bottomStart: Radius.circular(isMine ? 16.r : 4.r),
                    bottomEnd: Radius.circular(isMine ? 4.r : 16.r),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // **Only on somebody else's.** You know who you are, and repeating your own
                    // name above every line you wrote is the noise a chat layout exists to drop.
                    if (!isMine) ...[
                      Text(
                        comment.author.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.labelMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: scheme.primary,
                        ),
                      ),
                      SizedBox(height: 4.h),
                    ],
                    Text(
                      comment.body,
                      style: text.bodyMedium?.copyWith(
                        color: isMine ? scheme.onPrimaryContainer : scheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    // The time and «عُدّلت» on one line under the text, the way every chat app
                    // puts them — small, quiet, and never pushing the sentence around.
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (comment.wasEdited) ...[
                          Text(
                            'عُدّلت',
                            style: text.labelSmall?.copyWith(
                              color: (isMine ? scheme.onPrimaryContainer : scheme.onSurfaceVariant)
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                          SizedBox(width: 6.w),
                        ],
                        if (comment.createdAt case final at?)
                          Text(
                            // The year dropped when it is this one: a column of notes from this
                            // month repeating «2026» twenty times says nothing twenty times.
                            at.shortDayLabel,
                            style: text.labelSmall?.copyWith(
                              color: (isMine ? scheme.onPrimaryContainer : scheme.onSurfaceVariant)
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Absent, not disabled, for a note this reader may not touch. There is nothing they
              // can do to it, and a greyed-out bin invites a tap that only ever produces a
              // refusal.
              //
              // **Text buttons rather than icons in the bubble**: the bubble is sized to its
              // sentence, and hanging controls inside it would make a two-word reply as wide as
              // its own toolbar.
              if (canChange && !isBusy)
                Padding(
                  padding: EdgeInsets.only(top: 2.h),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (comment.canEdit)
                        TextButton(
                          onPressed: () => unawaited(_edit(context)),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 8.w),
                            minimumSize: Size(0, 28.h),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text('تعديل', style: text.labelSmall),
                        ),
                      if (comment.canDelete)
                        TextButton(
                          onPressed: () => unawaited(_remove(context)),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 8.w),
                            minimumSize: Size(0, 28.h),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'حذف',
                            style: text.labelSmall?.copyWith(color: scheme.error),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
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
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => _EditBodyDialog(initial: initial),
  );
}

/// The dialog's content, as a `StatefulWidget` **so that it owns its controller**.
///
/// **This is the fix for a real crash, not a style preference.** The controller used to live in
/// [_promptForBody] and be disposed with `.whenComplete(controller.dispose)`. That future
/// completes the instant `Navigator.pop` is called — while the dialog is still animating out and
/// its `EditableText` is still rebuilding against the controller it was handed. The next frame
/// touched a disposed `ChangeNotifier`:
///
///     A TextEditingController was used after being disposed.
///
/// and the tree unwound from there into a second, louder assertion about an inherited element
/// unmounting with live dependents — which is what actually reached the screen, and which is why
/// the message named a part of Flutter that had nothing to do with the mistake.
///
/// A `State` disposes after its element is unmounted, which is after the route is gone. So the
/// controller outlives every frame that can still read it, by construction rather than by timing.
class _EditBodyDialog extends StatefulWidget {
  const _EditBodyDialog({required this.initial});

  final String initial;

  @override
  State<_EditBodyDialog> createState() => _EditBodyDialogState();
}

class _EditBodyDialogState extends State<_EditBodyDialog> {
  late final TextEditingController _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تعديل الملاحظة'),
      content: AppTextField(
        controller: _controller,
        maxLines: 5,
        maxLength: 2000,
        autofocus: true,
        textInputAction: TextInputAction.newline,
        keyboardType: TextInputType.multiline,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('حفظ'),
        ),
      ],
    );
  }
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
