import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/comments/models/comment.dart';
import 'package:dayaa/features/comments/models/comment_subject.dart';
import 'package:dayaa/features/comments/usecases/add_comment.dart';
import 'package:dayaa/features/comments/usecases/delete_comment.dart';
import 'package:dayaa/features/comments/usecases/edit_comment.dart';
import 'package:dayaa/features/comments/usecases/get_comments.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'comments_cubit.freezed.dart';
part 'comments_state.dart';

/// ملاحظات الموظفين على سجلٍّ واحد — عميل، أو مورّد — والأشياء الثلاثة التي تُفعل بها.
///
/// **كلّ كتابةٍ تجيب بـ`Failure?` بدل وضع الفشل في الحالة.** وهو تعليل `CustomerDesignsCubit`
/// نفسه في إعادة التسمية والحذف: لم يبقَ على الشاشة شيءٌ يتعلّق به الرفض، وحقلٌ يحمله إمّا أن
/// يتأخّر إلى إعادة البناء التالية أو يمحوه بثٌّ ثانٍ لا يراه أحد. فالشاشة تنتظر النداء وتعرض
/// شريحة، وتحتفظ بما كُتب.
///
/// **ولا شيء هنا يعيد قراءة القائمة بعد كتابة.** كلّ نقطة نهاية تجيب بالصفّ الذي خزّنته، فتُرقّع
/// القائمة من الردّ — ورحلةٌ ثانية لجلب ما هو في اليد أصلاً دوّارةٌ يدفع ثمنها المستخدم مرّتين.
class CommentsCubit extends Cubit<CommentsState> {
  CommentsCubit({
    required CommentSubject subject,
    required GetComments getComments,
    required AddComment addComment,
    required EditComment editComment,
    required DeleteComment deleteComment,
  }) : _subject = subject,
       _getComments = getComments,
       _addComment = addComment,
       _editComment = editComment,
       _deleteComment = deleteComment,
       super(const CommentsState.loading());

  final CommentSubject _subject;
  final GetComments _getComments;
  final AddComment _addComment;
  final EditComment _editComment;
  final DeleteComment _deleteComment;

  Future<void> load() async {
    // من العدم فقط. السحب للتحديث يجب ألّا يُفرغ قائمةً يقرؤها أحد.
    if (state is! CommentsLoaded) emit(const CommentsState.loading());

    final result = await _getComments(_subject);
    if (isClosed) return;

    emit(
      result.fold(CommentsState.failure, (thread) {
        final current = state;

        return current is CommentsLoaded
            // `busy` تبقى عن قصد: تحديثٌ يصل وصفٌّ يُحفظ يجب ألّا يرفع عنه التخفيت — الطلب الذي
            // ينتظره ما يزال خارجاً.
            //
            // وحالُ الخيط تُؤخذ جديدةً في كل مرّة، لأن التحديث هو تحديداً كيف تعرف هذه الشاشة أنّ
            // التذكرة التي تعرضها اعتُمدت قبل دقيقة.
            ? current.copyWith(
                comments: thread.comments,
                canComment: thread.canComment,
                closedNote: thread.closedNote,
              )
            : CommentsState.loaded(
                comments: thread.comments,
                canComment: thread.canComment,
                closedNote: thread.closedNote,
              );
      }),
    );
  }

  /// يترك ملاحظة. `null` حين تحطّ، والفشلُ حين لا تحطّ.
  ///
  /// **الملاحظة الجديدة تذهب إلى مقدّمة القائمة، وهي أسفل الشاشة.** الخادم يرسل الأحدث أولاً وهذه
  /// تحفظ ذلك الترتيب، فالقائمة هنا هي نفسها التي سينتجها `load()` التالي — وهذا ما يمنع الشاشة
  /// من إعادة ترتيب نفسها تحت القارئ بعد ثانية. والشاشة ترسمها معكوسة، فتُرسم «مقدّمة القائمة»
  /// «آخر ما قيل»، وهو تماماً حيث تضعه المحادثة.
  Future<Failure?> add(String body) async {
    final current = state;
    if (current is! CommentsLoaded) return null;

    final text = body.trim();
    if (text.isEmpty) {
      // الخادم يرفض هذه أيضاً — سطرٌ من الفراغات يُرضي `required` ولا يقول للقارئ التالي شيئاً —
      // فهذه توفّر الرحلة فقط، وهي مصوغةٌ على شكل الـ422 التي كانت الواجهة سترسلها، ليكون للشاشة
      // نوعٌ واحد من الرفض ترسمه.
      return const Failure.server(message: 'اكتب الملاحظة قبل الحفظ', statusCode: 422);
    }

    emit(current.copyWith(isAdding: true));

    final result = await _addComment(_subject, body: text);
    if (isClosed) return null;

    return result.fold(
      (failure) {
        _patch((loaded) => loaded.copyWith(isAdding: false));

        return failure;
      },
      (comment) {
        _patch(
          (loaded) => loaded.copyWith(
            comments: [comment, ...loaded.comments],
            isAdding: false,
          ),
        );

        return null;
      },
    );
  }

  /// يعيد كتابة واحدة، في مكانها.
  ///
  /// **في مكانها، لا تُنقل إلى الأعلى.** التصحيح ليس شيئاً جديداً قيل، وملاحظةٌ تقفز في القائمة
  /// كلّما صُحّح خطأٌ مطبعيّ كانت ستُعيد ترتيب صفحةٍ يقرؤها الناس محادثة.
  Future<Failure?> edit(int commentId, String body) async {
    final current = state;
    if (current is! CommentsLoaded) return null;

    final text = body.trim();
    if (text.isEmpty) {
      // 422 بكلمات الخادم نفسها، فتعرض الشاشة رفضاً يُقرأ تماماً كالذي كانت الواجهة سترسله —
      // انظر فحص `UploadCustomerDesign` القَبْلي.
      return const Failure.server(message: 'اكتب الملاحظة قبل الحفظ', statusCode: 422);
    }

    emit(current.copyWith(busy: {...current.busy, commentId}));

    final result = await _editComment(_subject, commentId, body: text);
    if (isClosed) return null;

    return result.fold(
      (failure) {
        _release(commentId);

        return failure;
      },
      (updated) {
        _patch(
          (loaded) => loaded.copyWith(
            comments: [
              for (final comment in loaded.comments)
                if (comment.id == commentId) updated else comment,
            ],
            busy: {...loaded.busy}..remove(commentId),
          ),
        );

        return null;
      },
    );
  }

  /// يرفع واحدةً عن السجلّ.
  ///
  /// الصفّ يغادر القائمة بعد موافقة الخادم لا قبلها. وحذفه أولاً كان سيُقرأ أفضلَ ثانيةً ثم
  /// يناقضه التحديثُ التالي — ونقطة النهاية هذه ترفض ملاحظة الزميل، وهي تحديداً الحالة التي كانت
  /// سترتجف.
  Future<Failure?> remove(int commentId) async {
    final current = state;
    if (current is! CommentsLoaded) return null;

    emit(current.copyWith(busy: {...current.busy, commentId}));

    final result = await _deleteComment(_subject, commentId);
    if (isClosed) return null;

    return result.fold(
      (failure) {
        _release(commentId);

        return failure;
      },
      (_) {
        _patch(
          (loaded) => loaded.copyWith(
            comments: [
              for (final comment in loaded.comments)
                if (comment.id != commentId) comment,
            ],
            busy: {...loaded.busy}..remove(commentId),
          ),
        );

        return null;
      },
    );
  }

  /// يطبّق تغييراً على الحالة المحمَّلة، ولا يفعل شيئاً البتّة إن كانت الشاشة قد مضت.
  ///
  /// تُقرأ جديدةً بدل الإغلاق على الحالة الملتقطة قبل الطلب: قد يكون تحديثٌ قد حطّ وهو في الطريق،
  /// وإعادةُ كتابة القائمة القديمة فوقه تُبطله.
  void _patch(CommentsLoaded Function(CommentsLoaded loaded) change) {
    final current = state;
    if (current is! CommentsLoaded) return;

    emit(change(current));
  }

  void _release(int commentId) {
    _patch((loaded) => loaded.copyWith(busy: {...loaded.busy}..remove(commentId)));
  }
}
