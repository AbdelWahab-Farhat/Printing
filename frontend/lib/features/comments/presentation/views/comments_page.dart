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
import 'package:dayaa/features/comments/usecases/mark_thread_read.dart';
import 'package:dayaa/features/notifications/presentation/viewmodel/unread_badge_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// ما يكتبه الموظفون لبعضهم عن سجلٍّ واحد — عميل، أو مورّد، أو تذكرة تصميم.
///
/// **شاشةٌ واحدة للثلاثة، لأنها ميزةٌ واحدة.** الذي يختلف بينها هو السجلّ الذي تتعلّق به
/// الملاحظات، ويصل كـ[CommentSubject] ولا يتجاوز المستودع — إلا كلامَ الصندوق والصفحة الفارغة،
/// وهو المكان الوحيد الذي يعرف منه القارئ عمّاذا يكتب. انظر GENERAL-COMMENTS.md.
///
/// **وهي مصوغةٌ على شكل تطبيق المحادثة في الهاتف نفسه، عن قصد.** فقاعتان على جهتين، واليوم
/// يُقال مرّةً بين الأيام لا تحت كل جملة، ورسائل الشخص الواحد المتتابعة تحمل اسمه مرّة، ومفتاح
/// إرسالٍ مستدير بجانب الصندوق، وما *يُفعل* بالرسالة خلف ضغطةٍ مطوّلة. ليس في هذا زينة: كلّ من
/// يفتح هذه الشاشة قضى سنواتٍ في تيليغرام وواتساب، والخيط الذي يتصرّف كما يتصرّفان خيطٌ لا يحتاج
/// أحدٌ أن يُعلَّمه.
///
/// **وكتابةُ ملاحظةٍ لا تكلّف أكثر من قراءة السجلّ** — `customers.view` على عميل، و`vendors.view`
/// على مورّد. الملاحظة أداةُ عملٍ لا امتياز: من جاز له أن يبحث عن السجلّ جاز له أن يخبر مَن
/// بعده بما تعلّمه، وهذا سببُ وجود الميزة أصلاً، وإلا قيلت الجملةُ شفاهاً ورحلت مع سامعها.
///
/// **ومَن يُعدّلها جوابُ الخادم، محمولاً على الملاحظة نفسها.** كاتبها، أو مَن يملك
/// `comments.moderate`. والورقة ترسم صفوفها من `canEdit` و`canDelete` لا من مقارنة معرّفات هنا —
/// فنسخةٌ ثانية من قاعدة صلاحيات هي نسخةٌ ستنحرف، ونقاط النهاية ترفض على أي حال.
class CommentsPage extends StatefulWidget {
  const CommentsPage({required this.subject, this.ownerName, super.key});

  /// أيُّ سجلٍّ هذه الملاحظات عنه.
  final CommentSubject subject;

  /// لِمَن هذه الملاحظات. يصل من شاشة السجلّ نفسه ليقوله الشريط بلا طلبٍ ثانٍ؛ و`null` على رابطٍ
  /// عميقٍ بارد، حيث يقف العنوان وحده.
  final String? ownerName;

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  @override
  void initState() {
    super.initState();

    // مرّةً واحدة عند الفتح، لا مع كلّ إعادة بناء — ولهذا صارت هذه الشاشة ذات حالة.
    unawaited(_markRead());
  }

  /// **فتحُ المحادثة هو قراءتها.** لا انتظار لتمرير القارئ إلى آخرها: الخيط قصير، ومَن فتحه
  /// جاء لأجله.
  ///
  /// ويُطفئ الجرسَ معه، لأن الشارة وصفوف الجرس شيءٌ واحد على الخادم. والرقم يصل في الجواب
  /// فيُوضع كما هو — رحلةٌ ثانية لسؤال `unread-count` عمّا قيل لنا للتوّ تأخيرٌ بلا مقابل، وهي
  /// الحجّة نفسها التي يسوقها `UnreadBadgeCubit.clear()`.
  ///
  /// **والفشل يُبتلع عن قصد.** شارةٌ لم تنطفئ ليست خطأً يستحقّ شريطاً أحمر فوق محادثةٍ فُتحت كما
  /// ينبغي — والنداء يتكرّر في المرّة القادمة على أي حال، وهو عديم الأثر عند التكرار.
  Future<void> _markRead() async {
    final result = await sl<MarkThreadRead>()(widget.subject);
    if (!mounted) return;

    result.fold((_) {}, sl<UnreadBadgeCubit>().setCount);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CommentsCubit>(
      create: (_) => sl<CommentsCubit>(param1: widget.subject)..load(),
      child: _CommentsView(subject: widget.subject, ownerName: widget.ownerName),
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
                           * **الأقدم فوق والأحدث تحت — تُقرأ كمحادثة.**
                           *
                           * `reverse: true` بدل عكس القائمة، وهي تشتري أمرين معاً. البيانات تبقى
                           * كما أرسلها الخادم (الأحدث أولاً)، فـ`add()` تضع الملاحظة الجديدة في
                           * الموضع صفر وتظلّ تحطّ حيث العين — وهو الآن الأسفل. والقائمة المعكوسة
                           * تُفتح وهي عند الموضع صفر أصلاً، فتصل الشاشة عارضةً آخر ما قيل بدل أن
                           * تُجبر أحداً على تمرير سنةٍ من الملاحظات ليبلغه.
                           *
                           * وعكسُ *البيانات* ما كان ليفعل أياً منهما: القائمة تُفتح على الأقدم،
                           * وكلّ جديدةٍ تصل خارج الشاشة.
                           *
                           * والثمن أنّ السحب للتحديث صار على الحافة العليا، وهي في قائمةٍ معكوسة
                           * طرفُ الأقدم — وهو مكان «حمّل الأقدم» إن صُفّحت هذه يوماً، فهي الحافة
                           * الصحيحة له على أي حال.
                           */
                          reverse: true,
                          // `always`، ليعمل السحب للتحديث على قائمةٍ قصيرة أيضاً.
                          physics: const AlwaysScrollableScrollPhysics(),
                          // التمرير بعيداً عن الصندوق يُنزل لوحة المفاتيح — مَن يعود في الخيط
                          // إلى الوراء يقرأ ولا يكتب، ولوحة المفاتيح تغطّي نصف ما يمدّ يده إليه.
                          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 12.h),
                          itemCount: comments.length,
                          // **لا `separatorBuilder`.** الفجوة بين فقاعتين ليست رقماً واحداً:
                          // ثلاثة داخل رسائل الشخص الواحد، وعشرة بين شخصين، ولا شيء حيث يفصل
                          // فاصلُ اليوم أصلاً. كلّ مُدخلٍ يملك المسافة فوقه، لأنه وحده يعرف أيَّ
                          // الثلاث هو.
                          itemBuilder: (context, index) {
                            // الأحدث أولاً في البيانات، فالرسالة التي قيلت *قبل* هذه هي الموضع
                            // التالي، والتي قيلت بعدها هي الموضع السابق.
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
              // **يختفي ولا يُعطَّل حين ينتهي السجلّ.** صندوقٌ يُكتب فيه ولا يُرسل أسوأ من لا
              // صندوق: يدعو إلى جملةٍ ثم يضيّعها. والذي يحلّ محلّه يقول السبب، بكلمات السجلّ.
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

/// ملاحظةٌ واحدة وجارتاها في اليد — وهذا ما يلزم لمعرفة كيف تُرسم.
///
/// الفقاعة وحدها تستطيع أن تقول مَن كتبها وما تقول. أمّا ما يجعل عموداً من الفقاعات يُقرأ
/// محادثةً — اليومُ يُقال مرّة، والاسمُ مرّةً لكلّ سلسلة، والذيلُ على آخرها — فحقائقُ عن الرسالة
/// *المجاورة*، ولذلك تصل الجارتان معها بدل أن تُبحث عنهما.
class _ThreadEntry extends StatelessWidget {
  const _ThreadEntry({
    required this.comment,
    required this.earlier,
    required this.later,
    required this.isBusy,
  });

  final Comment comment;

  /// الرسالة التي قيلت قبل هذه، والتي قيلت بعدها. `null` عند طرفَي الخيط.
  final Comment? earlier;
  final Comment? later;

  final bool isBusy;

  /// هل [comment] أوّلُ ما قيل في يومه.
  ///
  /// ملاحظةٌ بلا وقتٍ لا تبدأ شيئاً: الفاصل يحتاج تاريخاً يطبعه، و«اليوم» فوق ملاحظةٍ قد تكون من
  /// العام الماضي أسوأ من لا فاصل.
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
    // الشخص نفسه، واليوم نفسه، ولا شيء بينهما: شخصٌ واحد يتكلّم، لا اثنان.
    final opensARun = opensADay || earlier == null || earlier!.author.id != comment.author.id;
    final closesARun =
        later == null || later!.author.id != comment.author.id || _opensADay(later!, comment);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (opensADay) _DayDivider(at: comment.createdAt!),
        // الفاصل يحمل مساحته معه؛ والصوت الجديد يحتاج هواءً، والجملة الثانية من الصوت نفسه لا
        // تكاد تحتاج شيئاً.
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

/// «اليوم» · «أمس» · «18 سبتمبر» — يُقال مرّةً، بين الأيام.
///
/// كان التاريخ داخل كلّ فقاعة، فعشرُ ملاحظاتٍ في صباحٍ واحد تطبع التاريخ نفسه عشراً، والخيط مع
/// ذلك لا يقول أين انتهى يومٌ وبدأ آخر. سطرٌ واحد في الوسط يؤدّي الأمرين ويخرج التاريخ من الجُمل.
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

/// حيث تُكتب الرسالة، مثبَّتاً تحت القائمة.
///
/// **[StatefulWidget] خاصّ به ليعيش النصّ هنا ولا مكان سواه.** حقلٌ تمرّ كلُّ ضغطة مفتاحٍ فيه
/// عبر الـCubit يعني إعادةَ بناء القائمة كلّها لكل حرف، وهذه القائمة قد تطول. الـCubit يسمع
/// بالجملة مرّةً واحدة: حين تُرسل.
class _Composer extends StatefulWidget {
  const _Composer({required this.subject, required this.isSending});

  final CommentSubject subject;
  final bool isSending;

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  final TextEditingController _controller = TextEditingController();

  /// هل هناك ما يُرسل. حالةٌ محليّة لا شيء يسمع بها في الـCubit: تتغيّر عند أول حرفٍ وآخره فقط،
  /// وهي تُضيء زرّاً واحداً.
  bool _hasText = false;

  /// اتجاه ما يُكتب الآن — انظر [ReadingDirection]. `null` حتى أول حرف، فيبقى الصندوق الفارغ على
  /// اتجاه التطبيق ويُقرأ تلميحه العربي كما ينبغي.
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

    // حقيقتان، وإعادةُ بناءٍ واحدة، ولا تقع إلا إذا تحرّكت إحداهما فعلاً: هذه تعمل مع كل ضغطة
    // مفتاح، والحقل تحتها أغلى ما يُعاد بناؤه في الشاشة.
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
      // ما كُتب يبقى في الصندوق — رفضٌ يُفرغ الحقل معه يكلّف صاحبه الجملة التي كتبها للتوّ.
      context.showFailure(failure);

      return;
    }

    _controller.clear();
    // تُنزَّل لوحة المفاتيح لتُرى الملاحظة التي كُتبت للتوّ: على الهاتف تغطّي اللوحةُ معظم
    // القائمة، والغاية من الإرسال أن يراه صاحبه يحطّ.
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
            // **متوسّطٌ مقابل الصندوق، لا معلَّقٌ بسطره الأخير.** الاثنان أداةٌ واحدة، ويُقرآن
            // واحداً حين يتفق منتصفاهما؛ ومعلَّقاً بالأسفل ينزاح المفتاح عن الحقل بمجرد كتابة
            // سطرٍ ثانٍ.
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: AppTextField(
                  controller: _controller,
                  hint: widget.subject.kind.composerHint,
                  // الصندوق يستدير مع اللغة التي تُكتب فيه، كما يفعل صندوق الرسائل. والتلميح
                  // يبقى على اتجاه الشاشة حتى ذلك الحين — فهو عربي، وليس هو ما يكتبه الشخص.
                  textDirection: _direction,
                  // يبدأ بسطرٍ ويكبر إلى خمسة ثم يُمرَّر. كان يُفتح بأربعة أسطر، وهذا نموذجٌ
                  // يطلب فقرة لا صندوقُ رسائل — وكان يدفع آخر ما قيل خارج الشاشة ليفعلها.
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

/// ما يقف مكان الصندوق حين لا يبقى ما يُقال.
///
/// **يحتفظ بمساحة الصندوق نفسها**، فالخيط الذي يُغلق وأحدهم يقرؤه لا يقفز تحته. والكلام كلام
/// الخادم — «اعتُمد التصميم وأُغلقت المحادثة» — لأن السجلّ وحده يعرف أيَّ نهايتيه بلغ؛ والبديل
/// لإصدارٍ من الواجهة أغلق خيطاً دون أن يقول لماذا، وهو لا يقول أكثر مما يعرف.
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

/// المفتاح المستدير في طرف الصندوق.
///
/// **الزرّ الوحيد في هذا التطبيق الذي لا يأخذ عرض الشاشة**، والاستثناء هو المرجع لا المزاج:
/// صندوقُ رسائلٍ تحته شريطٌ بعرض الشاشة نموذجٌ لا محادثة، والشريط يكلّف سطراً من الكلام في كل
/// شاشة. وهو مطفأ ما لم يكن هناك ما يُرسل، فيجيب الزرّ عن «اكتب الملاحظة قبل الحفظ» قبل أن
/// يضغطه أحدٌ ويقرأها رفضاً.
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

/// رسالةٌ واحدة: مَن كتبها، ومتى، وما تقول.
///
/// **ولا شيء معلَّقٌ بها.** ما يُفعل بالرسالة يعيش خلف ضغطةٍ مطوّلة، كما في كل تطبيق محادثة —
/// فزوجُ أزرارٍ تحت كل فقاعة كان خيطاً تفوق أدواتُه جُمَله، وكانت تُرسم سواء همّ أحدٌ باستعمالها
/// أم لا.
class _CommentCard extends StatelessWidget {
  const _CommentCard({
    required this.comment,
    required this.isBusy,
    required this.showsAuthor,
    required this.hasTail,
  });

  final Comment comment;
  final bool isBusy;

  /// هل هذه أوّلُ سلسلةٍ من شخصٍ واحد — وهي وحدها التي تقول اسمه.
  final bool showsAuthor;

  /// هل هذه آخرُ تلك السلسلة: الزاوية المربّعة التي تشير إلى جهة المتكلّم تخصّ أسفلَ السلسلة، لا
  /// كلَّ فقاعةٍ فيها.
  final bool hasTail;

  Future<void> _hold(BuildContext context) async {
    // رسالةٌ في منتصف طلبها لا تعرض شيئاً: نصّها على وشك أن يُستبدل أو يذهب.
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

    // **مَن كتبها يُسأل عنه الجلسة، لا يُستنتج من `canEdit`.** تلك الراية صحيحةٌ للمشرف أيضاً،
    // فرسمُ ملاحظةِ زميلٍ في يد مشرفٍ كأنها ملاحظته يضع عليها الاسم الخطأ والجهة الخطأ.
    final isMine = sl<Session>().isSelf(comment.author.id);
    final onBubble = isMine ? scheme.onPrimaryContainer : scheme.onSurface;

    return Opacity(
      // تُخفَّت ما دام طلبها خارجاً، فيقول الصفّ إنه يعمل دون أن تتحرّك القائمة تحت أحد.
      opacity: isBusy ? 0.5 : 1,
      child: Align(
        /*
         * **رسائلي في النهاية ورسائلهم في البداية — ولا «يسار» ولا «يمين» أبداً.**
         *
         * هذا التطبيق عربيٌّ يجري من اليمين إلى اليسار، وفيه تنعكس المحادثة: الصادر يسارٌ
         * والوارد يمين، عكسَ الإنجليزية. وكتابة `Alignment.centerRight` كانت ستُثبّت الجواب
         * الإنجليزي وتضع طرفَي المحادثة على الحافة الخطأ. أما `AlignmentDirectional` فتُحلّ
         * مقابل الاتجاه المحيط، فيُقرأ هذا صحيحاً في الحالتين بلا تفرّع.
         */
        alignment: isMine
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: ConstrainedBox(
          // **هذا كلّ ما طُلب.** كانت الملاحظة تملأ الشاشة من حافةٍ إلى حافة، فيبدو ردٌّ من ثلاث
          // كلماتٍ فقرةً ولا شيء يقول مَن المتكلّم قبل القراءة. وبسقفٍ عند ٧٨٪ تصير الفقاعة
          // بعرض ما فيها، والفراغُ على الجهة الأخرى هو الذي يجعل الطرفين يُقرآن بنظرة.
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
                  // الزاوية المربّعة هي الذيل: تشير إلى الحافة التي عليها المتكلّم، وتُرسم مرّةً
                  // لكل سلسلة — تحت آخر ما قاله — وهذا ما يجعل السلسلة تُقرأ دوراً واحداً بدل
                  // أربعة أدوارٍ منفصلة.
                  bottomStart: Radius.circular(isMine || !hasTail ? 16.r : 4.r),
                  bottomEnd: Radius.circular(!isMine || !hasTail ? 16.r : 4.r),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // **على رسائل غيري فقط، ومرّةً لكل سلسلة.** أنت تعرف مَن أنت، واسمٌ فوق كل
                  // سطرٍ كتبه زميلٌ تباعاً هو الضجيج الذي جاء شكلُ المحادثة ليُسقطه.
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
                    // **كلّ جملةٍ تجري كما كُتبت.** ردٌّ لاتينيّ في خيطٍ عربي — «ok»، أو اسم
                    // ملف، أو وصفٌ منسوخٌ من العميل — يخرج ونقطتُه في الطرف الخطأ حين تفرض
                    // الفقاعة عليه اتجاه التطبيق. و`null` لجملةٍ لا حرف فيها، فيبقى رقم الهاتف
                    // على اتجاه بقية الشاشة.
                    textDirection: comment.body.readingDirection,
                    style: text.bodyMedium?.copyWith(color: onBubble),
                  ),
                  SizedBox(height: 2.h),
                  // الساعة و«عُدّلت» مدسوستان في الزاوية الخلفية، كما يفعل كل تطبيق محادثة —
                  // و*اليوم* لم يعد هنا: الفاصل فوق السلسلة قاله.
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

/// ما تعرضه الضغطة المطوّلة على رسالة.
enum _NoteAction { copy, edit, remove }

/// الورقة التي تفتحها الضغطة المطوّلة.
///
/// **النسخ معروضٌ على كل رسالة، بما فيها رسالة الزميل.** هو الشيء الوحيد الذي يجوز لمن يقرأ
/// الرسالة أن يفعله بها، وهو أكثر ما تُستعمل له الضغطة المطوّلة — رقمُ هاتفٍ أو عنوانٌ مكتوبٌ
/// هنا كُتب ليُؤخذ ويُستعمل.
///
/// والصفّان الآخران جوابُ الخادم، يُرسمان من `can_edit` و`can_delete`. غائبان لا معطَّلان: ليس
/// في يد القارئ شيءٌ يفعله بتلك الرسالة، وسلّةٌ رماديّة تدعو إلى ضغطةٍ لا تُنتج إلا رفضاً.
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
          // الرسالة نفسها في أعلاها، مقصوصةً إلى سطرين: ورقةٌ فُتحت بضغطِ فقاعةٍ واحدة في خيطٍ
          // طويل عليها أن تقول أيَّ فقاعةٍ تخصّ.
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

/// صندوق التعديل، حواريّةً لا حقلاً في مكان الصفّ.
///
/// التعديل في المكان كان سيُلزم القائمة بحملِ متحكّمٍ لكل صفّ وبمعرفةِ أيُّ صفٍّ مفتوح؛ والحواريّة
/// حقلٌ واحد فيه الجملة أصلاً، ثم يُغلق.
Future<String?> _promptForBody(BuildContext context, {required String initial}) {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => _EditBodyDialog(initial: initial),
  );
}

/// محتوى الحواريّة، `StatefulWidget` **لتملك متحكّمها بنفسها**.
///
/// **هذا إصلاحُ انهيارٍ حقيقي، لا تفضيلُ أسلوب.** كان المتحكّم يعيش في [_promptForBody] ويُتلَف
/// بـ`.whenComplete(controller.dispose)`. ذلك المستقبَل يكتمل لحظةَ استدعاء `Navigator.pop` —
/// والحواريّة ما تزال تخرج بحركةٍ و`EditableText` فيها ما يزال يُعاد بناؤه مقابل المتحكّم الذي
/// أُعطيه. فيلمس الإطار التالي `ChangeNotifier` متلَفاً:
///
///     A TextEditingController was used after being disposed.
///
/// ثم تتفكّك الشجرة من هناك إلى تأكيدٍ ثانٍ أعلى صوتاً عن عنصرٍ موروثٍ يُفكّ وله تابعون أحياء —
/// وهو ما بلغ الشاشة فعلاً، ولهذا سمّت الرسالةُ جزءاً من فلاتر لا علاقة له بالخطأ.
///
/// و`State` تُتلِف بعد فكّ عنصرها، وذلك بعد ذهاب المسار. فيعيش المتحكّم أطولَ من كل إطارٍ قد
/// يقرؤه، بالبنية لا بالتوقيت.
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
      // قائمةٌ لا `Center`، ليبقى السحب للتحديث ممكناً على شاشةٍ فارغة.
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

/// بماذا تُسمّي هذه الشاشة نفسها، وعمّاذا تسأل، في كلٍّ من السجلات الثلاثة.
///
/// **شاشةٌ واحدة، وثلاثُ مفردات.** كان الصندوق يقول «اكتب ملاحظة عن هذا العميل» داخل تذكرة
/// تصميم، حيث لا عميل في الغرفة وحيث المكتوب ردٌّ على المصمّم. والكلام هو الشيء الوحيد في هذه
/// الشاشة الذي يختلف باختلاف السجلّ، وهو الشيء الذي يعرف به القارئ ما الذي يكتبه.
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
