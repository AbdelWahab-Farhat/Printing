import 'dart:async';

import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/core/utils/text_direction.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_dialog.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/comments/models/comment.dart';
import 'package:dayaa/features/comments/models/comment_subject.dart';
import 'package:dayaa/features/comments/presentation/viewmodel/comments_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The notes staff leave each other about one record — a customer, a supplier, a design ticket.
///
/// **One screen for both, because it is one feature.** What differs between them is the record
/// the notes hang off, which arrives as a [CommentSubject] and goes no further than the
/// repository — except for the words the box and the empty page say, which are the one place a
/// reader can tell what they are writing about. See GENERAL-COMMENTS.md.
///
/// **It is shaped like the messaging app on the same phone, on purpose.** Bubbles on two sides,
/// the day said once between the days rather than under every sentence, a run from one person
/// carrying their name once, a round send key beside the box, and what can be *done* to a note
/// behind a long press. None of that is decoration: every person opening this screen has spent
/// years in Telegram and WhatsApp, and a thread that behaves the way those do is a thread nobody
/// has to be taught.
///
/// **Writing one costs no more than reading the record does** — `customers.view` on a customer,
/// `vendors.view` on a supplier. A note is a working tool rather than a privilege: anybody who
/// may look a record up may tell the next person what they learned, which is the whole reason
/// this exists, since otherwise that sentence is said out loud and leaves with whoever heard it.
///
/// **Who may change one is the server's answer, carried on the note.** Its author, or somebody
/// holding `comments.moderate`. The sheet draws its rows off `canEdit` and `canDelete` rather
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
      child: _CommentsView(subject: subject, ownerName: ownerName),
    );
  }
}

class _CommentsView extends StatelessWidget {
  const _CommentsView({required this.subject, this.ownerName});

  final CommentSubject subject;
  final String? ownerName;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CommentsCubit>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(subject.kind.threadTitle),
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
                      ? _EmptyView(subject: subject)
                      : ListView.builder(
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
                          // Scrolling away from the box puts the keyboard down — somebody
                          // reaching back through the thread is reading, not typing, and the
                          // keyboard is covering half of what they are reaching for.
                          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 12.h),
                          itemCount: comments.length,
                          // **No `separatorBuilder`.** The gap between two bubbles is not one
                          // number: three pixels inside a run from one person, ten between two
                          // people, and none at all where a day divider already parts them. Each
                          // entry owns the space above itself, because only it knows which of
                          // the three it is.
                          itemBuilder: (context, index) {
                            // Newest first in the data, so the note said *before* this one is
                            // the next index up and the one said after it is the index below.
                            return _ThreadEntry(
                              comment: comments[index],
                              earlier: index + 1 < comments.length ? comments[index + 1] : null,
                              later: index > 0 ? comments[index - 1] : null,
                              isBusy: state.isBusy(comments[index].id),
                            );
                          },
                        ),
                ),
              ),
              // **Gone, not greyed, once the record has ended.** A box somebody can type into
              // and never send is worse than no box: it invites a sentence and then loses it.
              // What takes its place says why, in the record's own words.
              if (state.canComment)
                _Composer(subject: subject, isSending: state.isAdding)
              else
                _ClosedNote(note: state.closedNote),
            ],
          ),
        },
      ),
    );
  }
}

/// One note with its neighbours in hand — which is what it takes to know how to draw it.
///
/// A bubble on its own can say who wrote it and what it says. Everything that makes a column of
/// bubbles read as a conversation — the day said once, a name said once per run, the tail on the
/// last of a run — is a fact about the note *beside* it, so the two neighbours are passed in
/// rather than looked up.
class _ThreadEntry extends StatelessWidget {
  const _ThreadEntry({
    required this.comment,
    required this.earlier,
    required this.later,
    required this.isBusy,
  });

  final Comment comment;

  /// The note said before this one, and the one said after it. Null at the two ends of the
  /// thread.
  final Comment? earlier;
  final Comment? later;

  final bool isBusy;

  /// Whether [comment] is the first thing said on its day.
  ///
  /// A note with no timestamp starts nothing: a divider needs a date to print, and «اليوم» over
  /// a note that may be from last year is worse than no divider at all.
  static bool _opensADay(Comment comment, Comment? previous) {
    final at = comment.createdAt?.toLocal();
    if (at == null) return false;

    final before = previous?.createdAt?.toLocal();

    return before == null ||
        before.year != at.year ||
        before.month != at.month ||
        before.day != at.day;
  }

  @override
  Widget build(BuildContext context) {
    final opensADay = _opensADay(comment, earlier);
    // Same person, same day, nothing between them: one person talking, not two.
    final opensARun = opensADay || earlier == null || earlier!.author.id != comment.author.id;
    final closesARun =
        later == null || later!.author.id != comment.author.id || _opensADay(later!, comment);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (opensADay) _DayDivider(at: comment.createdAt!),
        // The divider brings its own room; a new voice needs air, and a second sentence from
        // the same one needs almost none.
        if (!opensADay) SizedBox(height: opensARun ? 10.h : 3.h),
        _CommentCard(
          comment: comment,
          isBusy: isBusy,
          showsAuthor: opensARun,
          hasTail: closesARun,
        ),
      ],
    );
  }
}

/// «اليوم» · «أمس» · «18 سبتمبر» — said once, between the days.
///
/// The date used to sit inside every bubble, which meant a morning's ten notes printed the same
/// date ten times and the thread still never said where one day ended. One centred line does
/// both jobs and takes the date out of the sentences.
class _DayDivider extends StatelessWidget {
  const _DayDivider({required this.at});

  final DateTime at;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Text(
            at.relativeDayLabel,
            style: context.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
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
  const _Composer({required this.subject, required this.isSending});

  final CommentSubject subject;
  final bool isSending;

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  final TextEditingController _controller = TextEditingController();

  /// Whether there is anything to send. Local [State] rather than anything the Cubit hears
  /// about: it changes on the first and last keystroke only, and it lights one button.
  bool _hasText = false;

  /// Which way what is being typed runs — see [ReadingDirection]. Null until the first letter,
  /// so an empty box keeps the app's own direction and its Arabic hint reads correctly.
  TextDirection? _direction;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTyped);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onTyped)
      ..dispose();
    super.dispose();
  }

  void _onTyped() {
    final text = _controller.text;
    final hasText = text.trim().isNotEmpty;
    final direction = text.readingDirection;

    // Two facts, one rebuild, and only when one of them actually moved: this runs on every
    // keystroke, and the field below it is the most expensive thing on the screen to rebuild.
    if (hasText == _hasText && direction == _direction) return;

    setState(() {
      _hasText = hasText;
      _direction = direction;
    });
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
    final canSend = _hasText && !widget.isSending;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        border: Border(top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 8.h),
          child: Row(
            // **Centred against the box, not pinned to its last line.** The two are one control
            // and they read as one when their middles agree; hung off the bottom, the key drifts
            // away from the field the moment a second line is typed.
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: AppTextField(
                  controller: _controller,
                  hint: widget.subject.kind.composerHint,
                  // The box turns with the language being typed into it, the way a message box
                  // does. The hint keeps the ambient direction until then — it is Arabic, and a
                  // hint is not what the person is writing.
                  textDirection: _direction,
                  // One line to start with, growing to five and then scrolling. The box used to
                  // open four lines tall, which is a form asking for a paragraph rather than a
                  // message box — and it pushed the last thing said off the screen to do it.
                  minLines: 1,
                  maxLines: 5,
                  maxLength: 2000,
                  textInputAction: TextInputAction.newline,
                  keyboardType: TextInputType.multiline,
                  enabled: !widget.isSending,
                ),
              ),
              SizedBox(width: 8.w),
              _SendKey(
                isSending: widget.isSending,
                onPressed: canSend ? () => unawaited(_send()) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What stands where the box was, once nothing more may be said.
///
/// **It keeps the same footprint the composer had**, so a thread that closes while somebody is
/// reading it does not jump under them. The words are the server's — «اعتُمد التصميم وأُغلقت
/// المحادثة» — because only the record knows which of its endings it reached; the fallback is
/// for a build of the API that closed a thread without saying why, and it says no more than it
/// knows.
class _ClosedNote extends StatelessWidget {
  const _ClosedNote({required this.note});

  final String? note;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        border: Border(top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(AppIcons.threadClosed, size: 18.sp, color: scheme.onSurfaceVariant),
              SizedBox(width: 8.w),
              Flexible(
                child: Text(
                  note ?? 'أُغلقت المحادثة',
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
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

/// The round key at the end of the box.
///
/// **The one button in this app that is not full width**, and the exception is the reference
/// rather than a whim: a message box with a full-width bar under it is a form, and the bar costs
/// a line of the conversation on every screen. It is dark until there is something to send, so
/// the button answers «اكتب الملاحظة قبل الحفظ» before somebody taps it and reads it as a
/// refusal.
class _SendKey extends StatelessWidget {
  const _SendKey({required this.isSending, required this.onPressed});

  final bool isSending;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return IconButton.filled(
      onPressed: isSending ? null : onPressed,
      tooltip: 'إرسال',
      iconSize: 20.sp,
      style: IconButton.styleFrom(
        minimumSize: Size(46.w, 46.w),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        disabledBackgroundColor: scheme.surfaceContainerHighest,
        disabledForegroundColor: scheme.onSurfaceVariant.withValues(alpha: 0.5),
      ),
      icon: isSending
          ? SizedBox(
              width: 18.w,
              height: 18.w,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: scheme.onSurfaceVariant,
              ),
            )
          : Icon(AppIcons.send),
    );
  }
}

/// One note: who wrote it, when, and what it says.
///
/// **Nothing hangs off it.** What can be done to a note lives behind a long press, the way it
/// does in every messaging app — a pair of text buttons under every bubble was a thread whose
/// controls outnumbered its sentences, and they were drawn whether or not anybody was about to
/// use them.
class _CommentCard extends StatelessWidget {
  const _CommentCard({
    required this.comment,
    required this.isBusy,
    required this.showsAuthor,
    required this.hasTail,
  });

  final Comment comment;
  final bool isBusy;

  /// Whether this is the first of a run from one person — the only one that says their name.
  final bool showsAuthor;

  /// Whether this is the last of that run: the squared corner that points at the speaker's edge
  /// belongs to the bottom of a run, not to every bubble in it.
  final bool hasTail;

  Future<void> _hold(BuildContext context) async {
    // A note mid-request has nothing to offer: its body is about to be replaced or gone.
    if (isBusy) return;

    final action = await _showNoteActions(context, comment: comment);
    if (action == null || !context.mounted) return;

    switch (action) {
      case _NoteAction.copy:
        await Clipboard.setData(ClipboardData(text: comment.body));
        if (context.mounted) context.showSuccess('نُسخت الملاحظة');
      case _NoteAction.edit:
        await _edit(context);
      case _NoteAction.remove:
        await _remove(context);
    }
  }

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

    // **Who wrote it, asked of the session rather than inferred from `canEdit`.** That flag is
    // true for a moderator too, so drawing a moderator's view of somebody else's note as their
    // own would put the wrong name and the wrong side on it.
    final isMine = sl<Session>().isSelf(comment.author.id);
    final onBubble = isMine ? scheme.onPrimaryContainer : scheme.onSurface;

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
          child: GestureDetector(
            onLongPress: () => unawaited(_hold(context)),
            child: Container(
              padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 6.h),
              decoration: BoxDecoration(
                color: isMine ? scheme.primaryContainer : scheme.surfaceContainerHighest,
                borderRadius: BorderRadiusDirectional.only(
                  topStart: Radius.circular(16.r),
                  topEnd: Radius.circular(16.r),
                  // The squared corner is the tail: it points at the edge the speaker is on,
                  // and it is drawn once per run — under the last thing they said — which is
                  // what makes a run read as one turn rather than as four separate ones.
                  bottomStart: Radius.circular(isMine || !hasTail ? 16.r : 4.r),
                  bottomEnd: Radius.circular(!isMine || !hasTail ? 16.r : 4.r),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // **Only on somebody else's, and only once per run.** You know who you are,
                  // and a name over every line one colleague wrote in a row is the noise a chat
                  // layout exists to drop.
                  if (!isMine && showsAuthor) ...[
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
                    // **Each sentence runs the way it was typed.** A Latin reply in an Arabic
                    // thread — «ok», a file name, a brief pasted from the customer — comes out
                    // with its full stop at the wrong end when the bubble forces the app's own
                    // direction onto it. Null on a sentence with no letters in it, which keeps
                    // a phone number reading the way the rest of the screen does.
                    textDirection: comment.body.readingDirection,
                    style: text.bodyMedium?.copyWith(color: onBubble),
                  ),
                  SizedBox(height: 2.h),
                  // The clock and «عُدّلت» tucked into the trailing corner, the way every chat
                  // app puts them — the *day* is not here any more: the divider above the run
                  // already said it.
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (comment.wasEdited) ...[
                          Text(
                            'عُدّلت',
                            style: text.labelSmall?.copyWith(
                              color: onBubble.withValues(alpha: 0.7),
                            ),
                          ),
                          SizedBox(width: 6.w),
                        ],
                        if (comment.createdAt case final at?)
                          Text(
                            at.timeLabel,
                            style: text.labelSmall?.copyWith(
                              color: onBubble.withValues(alpha: 0.7),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// What holding a note offers.
enum _NoteAction { copy, edit, remove }

/// The sheet a long press opens.
///
/// **Copying is offered on every note, including a colleague's.** It is the one thing anybody
/// who may read a note may also do with it, and it is most of what a long press is for — a phone
/// number or an address written in here is meant to be lifted out and used.
///
/// The other two rows are the server's answers, drawn from `can_edit` and `can_delete`. Absent
/// rather than disabled: there is nothing the reader can do to that note, and a greyed bin
/// invites a tap that only ever produces a refusal.
Future<_NoteAction?> _showNoteActions(BuildContext context, {required Comment comment}) {
  return showModalBottomSheet<_NoteAction>(
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 8.h),
          // The note itself at the top, clipped to two lines: a sheet opened by holding one
          // bubble in a long thread has to say which bubble it is about.
          ListTile(
            title: Text(
              comment.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: sheetContext.textTheme.bodyMedium,
            ),
            subtitle: Text(comment.author.displayName),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(AppIcons.copy),
            title: const Text('نسخ'),
            onTap: () => Navigator.of(sheetContext).pop(_NoteAction.copy),
          ),
          if (comment.canEdit)
            ListTile(
              leading: Icon(AppIcons.edit),
              title: const Text('تعديل'),
              onTap: () => Navigator.of(sheetContext).pop(_NoteAction.edit),
            ),
          if (comment.canDelete)
            ListTile(
              leading: Icon(AppIcons.delete, color: sheetContext.colorScheme.error),
              title: Text(
                'حذف',
                style: TextStyle(color: sheetContext.colorScheme.error),
              ),
              onTap: () => Navigator.of(sheetContext).pop(_NoteAction.remove),
            ),
          SizedBox(height: 8.h),
        ],
      ),
    ),
  );
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
        minLines: 1,
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
  const _EmptyView({required this.subject});

  final CommentSubject subject;

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
          subject.kind.emptyTitle,
          textAlign: TextAlign.center,
          style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 8.h),
        Text(
          subject.kind.emptyInvitation,
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

/// What this screen calls itself, and what it asks for, on each of the three records.
///
/// **One screen, three vocabularies.** The box said «اكتب ملاحظة عن هذا العميل» on a design
/// ticket, where there is no customer in the room and what is being written is a reply to the
/// designer. The wording is the only thing on this screen that differs per subject, and it is
/// the one thing a reader uses to know what they are writing.
extension on CommentSubjectKind {
  String get threadTitle => switch (this) {
    CommentSubjectKind.customer || CommentSubjectKind.vendor => 'الملاحظات',
    CommentSubjectKind.designTicket => 'المحادثة',
  };

  String get composerHint => switch (this) {
    CommentSubjectKind.customer => 'اكتب ملاحظة عن هذا العميل…',
    CommentSubjectKind.vendor => 'اكتب ملاحظة عن هذا المورّد…',
    CommentSubjectKind.designTicket => 'اكتب رسالة في هذه التذكرة…',
  };

  String get emptyTitle => switch (this) {
    CommentSubjectKind.customer => 'لا توجد ملاحظات على هذا العميل',
    CommentSubjectKind.vendor => 'لا توجد ملاحظات على هذا المورّد',
    CommentSubjectKind.designTicket => 'لا توجد رسائل في هذه التذكرة',
  };

  String get emptyInvitation => switch (this) {
    CommentSubjectKind.customer =>
      'اكتب ما يحتاج زميلك معرفته عنه قبل أن يخدمه — موعد التسليم الذي يفضّله، '
          'أو الرقم الذي يردّ عليه.',
    CommentSubjectKind.vendor =>
      'اكتب ما يحتاج زميلك معرفته عنه قبل أن يشتري منه — المدّة التي يلتزم بها، '
          'أو الرقم الذي يردّ عليه.',
    CommentSubjectKind.designTicket =>
      'هنا يتّفق الموظّف والمصمّم — ما المطلوب بالضبط، وما الذي تغيّر في النسخة الأخيرة.',
  };
}
