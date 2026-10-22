import 'dart:async';

import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/features/internal_tickets/models/internal_ticket.dart';
import 'package:dayaa/features/internal_tickets/presentation/viewmodel/internal_tickets_home_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// تذاكرُ الموظفين التي تنتظر ردّي، **على بطاقة الموظف نفسها** تحت رأسها — كبطاقة بريمولا تماماً،
/// طلبُ المالك ٢٠٢٦-١٠-٢٣. كلُّ صفٍّ يُجاب من مكانه بـ«رد»، وفي ذيلها «عرض كل التذاكر» و«تذكرة
/// جديدة».
///
/// **بلا عنوانٍ ولا عدّادات**: الصفوفُ تقول ما هي ومَن ينتظر. والمغلقةُ وما ينتظر زميلاً ليست هنا —
/// هي على بُعد ضغطة.
///
/// يقرأ [InternalTicketsHomeCubit] من فوقه — تملكه الرئيسية، فسحبُ التحديث يعيد قراءته معها.
class InternalTicketsCardSection extends StatefulWidget {
  const InternalTicketsCardSection({super.key});

  /// صفوفُ البطاقة. الخادمُ يرسل حتى عشر؛ والبطاقةُ تبقى قصيرة، والصفُّ المُجاب يُفسح للتالي.
  static const int maxRows = 4;

  @override
  State<InternalTicketsCardSection> createState() => _InternalTicketsCardSectionState();
}

class _InternalTicketsCardSectionState extends State<InternalTicketsCardSection> {
  /// ردٌّ واحدٌ مفتوحٌ في كل مرة: فتحُ ردِّ صفٍّ يغلق غيره.
  int? _replyingTo;

  @override
  Widget build(BuildContext context) {
    final ink = _CardInk.of(context);

    return BlocBuilder<InternalTicketsHomeCubit, InternalTicketsHomeState>(
      builder: (context, state) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 12.h),
          Divider(height: 1, color: ink.edge),
          SizedBox(height: 4.h),
          switch (state) {
            InternalTicketsHomeLoading() => const _SkeletonList(),
            InternalTicketsHomeFailure(:final failure) => _ErrorLine(
              message: failure.message,
              onRetry: context.read<InternalTicketsHomeCubit>().load,
            ),
            InternalTicketsHomeLoaded(:final home) => _TicketList(
              rows: [
                for (final ticket in home.tickets)
                  if (ticket.awaitingMyReply) ticket,
              ].take(InternalTicketsCardSection.maxRows).toList(),
              replyingTo: _replyingTo,
              onToggleReply: (id) => setState(() => _replyingTo = _replyingTo == id ? null : id),
              onSent: () {
                setState(() => _replyingTo = null);
                context.showSuccess('أُرسل الردّ');
              },
            ),
          },
        ],
      ),
    );
  }
}

/// المخارجُ من البطاقة، وبعد كلٍّ منها تُقرأ ثانيةً: ما فُتح أو أُجيب هناك يغيّر صفوفها.
abstract final class _Actions {
  static Future<void> openTicket(BuildContext context, int id) =>
      _thenReload(context, context.push<Object?>(Routes.internalTicket(id)));

  static Future<void> openAll(BuildContext context) =>
      _thenReload(context, context.push<Object?>(Routes.internalTickets));

  static Future<void> newTicket(BuildContext context) =>
      _thenReload(context, context.push<Object?>(Routes.newInternalTicket));

  static Future<void> _thenReload(BuildContext context, Future<Object?> away) async {
    final cubit = context.read<InternalTicketsHomeCubit>();
    await away;
    if (!cubit.isClosed) await cubit.load();
  }
}

/// حبرُ البطاقة. البطاقةُ تدرّجُ العلامة في الوضعين — داكنةٌ في الفاتح وفاتحةٌ في الداكن — فما عليها
/// يُرسم من `onPrimary` بشفافيات، لا من أسطح الصفحة. كـ`OnCardInk` في بريمولا، وأبيضُها هنا `onPrimary`.
class _CardInk {
  _CardInk._(this.strong, this.inverse, {required this.lightCard});

  factory _CardInk.of(BuildContext context) {
    final scheme = context.colorScheme;

    return _CardInk._(
      scheme.onPrimary,
      scheme.primary,
      lightCard: scheme.brightness == Brightness.dark,
    );
  }

  final Color strong;

  /// الحبرُ على الزرّ المقلوب («رد» والإرسال): لونُ البطاقة نفسها.
  final Color inverse;
  final bool lightCard;

  Color get soft => strong.withValues(alpha: 0.86);
  Color get faint => strong.withValues(alpha: 0.66);
  Color get fill => strong.withValues(alpha: 0.10);
  Color get fillStrong => strong.withValues(alpha: 0.20);
  Color get edge => strong.withValues(alpha: 0.16);
  Color get hairline => strong.withValues(alpha: 0.12);

  /// ما تحت الصفّ الذي ينتظرني: يفتح البطاقةَ كما يفتحها أبيضُ بريمولا — على الفاتحة أبيضُ لا حبرٌ
  /// داكن، وإلا صار الصفُّ رمادياً.
  Color get wash => lightCard ? Colors.white.withValues(alpha: 0.30) : strong.withValues(alpha: 0.06);

  /// إنذارُ البطاقة الوحيد — تذكرةٌ تنتظرني. مرجانيُّ بريمولا على البطاقة الداكنة، وأحمرُ أعمق على
  /// الفاتحة كي يبقى خطُّه الرفيع مقروءاً.
  Color get alert => lightCard ? const Color(0xFFC62828) : const Color(0xFFFF7A70);

  /// «قيد المعالجة» — كهرمانيّ «جارِ المعالجة» عند بريمولا، بدرجةٍ تُقرأ على البطاقة.
  Color get processing => lightCard ? const Color(0xFF8A5300) : const Color(0xFFFFC266);
}

/// ردُّ الضغط الوحيد على البطاقة: ما يُضغط يخفت لحظة — كبريمولا. لا `InkWell`: ظلُّه الرماديّ على
/// التدرّج لطخة، والتموّجُ لا سطحَ له هنا.
class _Pressable extends StatefulWidget {
  const _Pressable({required this.onTap, required this.child});

  final VoidCallback? onTap;
  final Widget child;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _pressed = false;

  void _set(bool pressed) => setState(() => _pressed = pressed);

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      onTap: widget.onTap,
      child: AnimatedOpacity(
        opacity: _pressed ? 0.55 : 1,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 90),
        child: widget.child,
      ),
    );
  }
}

/// الصفوف، ثم الذيل: «عرض كل التذاكر» و«تذكرة جديدة» تحت خطٍّ رفيع.
class _TicketList extends StatelessWidget {
  const _TicketList({
    required this.rows,
    this.replyingTo,
    this.onToggleReply,
    this.onSent,
  });

  final List<InternalTicket> rows;
  final int? replyingTo;
  final ValueChanged<int>? onToggleReply;
  final VoidCallback? onSent;

  @override
  Widget build(BuildContext context) {
    final ink = _CardInk.of(context);

    // Material لحقل الردّ (التحديد ومقابض المؤشّر)؛ والصفوفُ تخفت ولا ترسم شيئاً.
    return Material(
      type: MaterialType.transparency,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (rows.isEmpty) const _EmptyLine() else SizedBox(height: 2.h),
          for (final (index, ticket) in rows.indexed) ...[
            if (index > 0) SizedBox(height: 6.h),
            _TicketRow(
              key: ValueKey(ticket.id),
              ticket: ticket,
              replying: replyingTo == ticket.id,
              onToggleReply: () => onToggleReply?.call(ticket.id),
              onSent: onSent,
            ),
          ],
          if (rows.isNotEmpty) SizedBox(height: 6.h),
          Divider(height: 1, thickness: 1, color: ink.hairline),
          SizedBox(height: 6.h),
          const Row(
            children: [
              Expanded(child: _ShowAllButton()),
              _NewTicketButton(),
            ],
          ),
        ],
      ),
    );
  }
}

/// تذكرةٌ واحدة على البطاقة: عمّا هي، ومع مَن، ومنذ متى تنتظر، وآخرُ ما قيل. وفي طرفها الحالةُ فوق
/// و«رد» تحت، يفتح حقلاً تحت الصفّ نفسه.
class _TicketRow extends StatelessWidget {
  const _TicketRow({
    required this.ticket,
    required this.replying,
    this.onToggleReply,
    this.onSent,
    super.key,
  });

  final InternalTicket ticket;
  final bool replying;
  final VoidCallback? onToggleReply;
  final VoidCallback? onSent;

  @override
  Widget build(BuildContext context) {
    final other = ticket.otherSideOf(sl<Session>().user?.id);
    final name = other?.name ?? '';

    final row = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ارتفاعٌ واحدٌ للكلام والعمود الطرفي: الحالةُ بمستوى العنوان، و«رد» بمستوى آخر سطر.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _Pressable(
                  onTap: () => unawaited(_Actions.openTicket(context, ticket.id)),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    child: _Lines(ticket: ticket, counterpart: name),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 10.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _StatusTag(
                      label: ticket.statusLabel.isEmpty ? ticket.status.label : ticket.statusLabel,
                    ),
                    if (ticket.awaitingMyReply)
                      _ReplyButton(name: name, expanded: replying, onTap: onToggleReply),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (replying) _InlineReply(key: ValueKey('reply-${ticket.id}'), ticket: ticket, onSent: onSent),
      ],
    );

    return ticket.awaitingMyReply ? _AwaitingHighlight(child: row) : row;
  }
}

/// ما يُرسم تحت الصفّ الذي ينتظرني: لمسةٌ تدفأ من خطّ الإنذار في أوّله. تمتدّ في حشوة البطاقة ولا
/// تدفع الصفَّ إلى الداخل، فيبقى لكل الصفوف خطُّ بدايةٍ واحد.
class _AwaitingHighlight extends StatelessWidget {
  const _AwaitingHighlight({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ink = _CardInk.of(context);
    final bleed = 10.w;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        PositionedDirectional(
          start: -bleed,
          end: -bleed,
          top: 0,
          bottom: 0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14.r),
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: AlignmentDirectional.centerStart,
                      end: AlignmentDirectional.centerEnd,
                      colors: [ink.alert.withValues(alpha: ink.lightCard ? 0.14 : 0.20), ink.wash],
                    ),
                  ),
                ),
                PositionedDirectional(
                  start: 0,
                  top: 0,
                  bottom: 0,
                  width: 3.w,
                  child: ColoredBox(color: ink.alert),
                ),
              ],
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// العنوان؛ ثم الزميلُ وسماً ومعه «بانتظار ردّك» ومنذ متى وغيرُ المقروء؛ ثم آخرُ ما قيل؛ ثم الطلبيةُ
/// أو كودُ العميل إن رُبطت بهما.
class _Lines extends StatelessWidget {
  const _Lines({required this.ticket, required this.counterpart});

  final InternalTicket ticket;
  final String counterpart;

  @override
  Widget build(BuildContext context) {
    final ink = _CardInk.of(context);
    final text = context.textTheme;
    final last = ticket.lastMessage;
    final at = last?.sentAt ?? ticket.lastMessageAt;
    final order = ticket.order;
    final customerCode = ticket.customer?.code;
    final faint = text.labelSmall?.copyWith(color: ink.faint);
    final me = sl<Session>().user?.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          ticket.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: text.titleSmall?.copyWith(
            color: ink.strong,
            fontWeight: FontWeight.w800,
            height: 1.3,
          ),
        ),
        SizedBox(height: 5.h),
        // الاسمُ ثم متى — وعلى هاتفٍ ضيّق ينزل النصفُ الثاني تحت الاسم ولا يقطعه.
        Wrap(
          spacing: 8.w,
          runSpacing: 4.h,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (counterpart.isNotEmpty) _PersonTag(name: counterpart),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // «بانتظار ردّك منذ 3 ساعات» تُقرأ جملةً واحدة: كم انتظر الزميلُ هو التنبيه.
                if (ticket.awaitingMyReply) const _AwaitingLabel(),
                if (at != null) ...[
                  if (ticket.awaitingMyReply) SizedBox(width: 4.w),
                  // يُقصّ ولا يفيض: على هاتفٍ ضيّق يكفي أوّلُه.
                  Flexible(
                    child: Text(
                      at.toLocal().agoLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: faint,
                    ),
                  ),
                ],
                if (ticket.unreadCount > 0) ...[
                  SizedBox(width: 6.w),
                  _UnreadBadge(count: ticket.unreadCount),
                ],
              ],
            ),
          ],
        ),
        if (last != null && last.preview.isNotEmpty) ...[
          SizedBox(height: 6.h),
          _LastLine(
            message: last,
            speaker: last.authorId == me ? 'أنا' : (last.authorName ?? counterpart),
            loud: ticket.awaitingMyReply,
          ),
        ],
        // نصٌّ لا رقاقة: الصفُّ يفتح المحادثة، والطلبيةُ والعميلُ يُفتحان من داخلها.
        if (order != null || customerCode != null)
          Padding(
            padding: EdgeInsets.only(top: 4.h),
            child: Row(
              children: [
                if (order != null) _LinkLabel(icon: AppIcons.orders, label: order.code, style: faint),
                if (order != null && customerCode != null) SizedBox(width: 10.w),
                if (customerCode != null)
                  _LinkLabel(icon: AppIcons.person, label: customerCode, style: faint),
              ],
            ),
          ),
      ],
    );
  }
}

/// مع مَن التذكرة، وسماً صغيراً — الاسمُ الوحيد على الصفّ.
class _PersonTag extends StatelessWidget {
  const _PersonTag({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final ink = _CardInk.of(context);

    return Container(
      padding: EdgeInsetsDirectional.fromSTEB(6.w, 2.h, 8.w, 2.h),
      decoration: BoxDecoration(
        color: ink.fill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: ink.edge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.person, size: 12.r, color: ink.soft),
          SizedBox(width: 3.w),
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.labelSmall?.copyWith(
                color: ink.strong,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// «بانتظار ردّك» خلف نقطة الإنذار — بالكلمة واللون معاً.
class _AwaitingLabel extends StatelessWidget {
  const _AwaitingLabel();

  @override
  Widget build(BuildContext context) {
    final ink = _CardInk.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7.r,
          height: 7.r,
          decoration: BoxDecoration(color: ink.alert, shape: BoxShape.circle),
        ),
        SizedBox(width: 4.w),
        Text(
          'بانتظار ردّك',
          maxLines: 1,
          style: context.textTheme.labelSmall?.copyWith(
            color: ink.strong,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

/// «هدى: النصّ» — المتكلّمُ وحده في عنصر، فلا يقلبه نصٌّ لاتينيٌّ أو رقمٌ إلى الطرف الآخر.
class _LastLine extends StatelessWidget {
  const _LastLine({required this.message, required this.speaker, required this.loud});

  final InternalLastMessage message;
  final String speaker;

  /// ما يُجاب عنه: بالحبر الكامل وسطرين قبل أن يُقطع.
  final bool loud;

  @override
  Widget build(BuildContext context) {
    final ink = _CardInk.of(context);
    final style = context.textTheme.bodyMedium?.copyWith(
      color: loud ? ink.strong : ink.soft,
      height: 1.45,
    );
    final voice = message.kind == 'voice';
    // الخادمُ يكتب «🎤 رسالة صوتية»؛ والأيقونةُ هنا ترسم الميكروفون، كبريمولا.
    final words = voice ? message.preview.replaceFirst('🎤', '').trim() : message.preview;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$speaker:',
          style: style?.copyWith(color: ink.strong, fontWeight: FontWeight.w800),
        ),
        SizedBox(width: 4.w),
        if (voice)
          Padding(
            padding: EdgeInsets.only(top: 3.h),
            child: Icon(AppIcons.mic, size: 16.r, color: style?.color),
          ),
        Expanded(
          child: Text(
            words,
            maxLines: loud ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ],
    );
  }
}

class _LinkLabel extends StatelessWidget {
  const _LinkLabel({required this.icon, required this.label, this.style});

  final IconData icon;
  final String label;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.r, color: style?.color),
          SizedBox(width: 3.w),
          Flexible(
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: style),
          ),
        ],
      ),
    );
  }
}

/// حالةُ التذكرة بلونها، وحلقةٌ قبلها — «قيد المعالجة» كـ«جارِ المعالجة» عند بريمولا.
class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = _CardInk.of(context).processing;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8.r,
          height: 8.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
        ),
        SizedBox(width: 4.w),
        Text(
          label,
          style: context.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

/// «رد» — الزرُّ المصمتُ الوحيد على البطاقة، ومرفوعٌ عنها، فينتهي الصفُّ الذي ينتظرني بشيءٍ واضحٍ أنه
/// يُضغط.
class _ReplyButton extends StatelessWidget {
  const _ReplyButton({required this.name, required this.expanded, this.onTap});

  final String name;
  final bool expanded;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ink = _CardInk.of(context);

    return Semantics(
      button: true,
      expanded: expanded,
      label: 'رد على $name',
      child: _Pressable(
        onTap: onTap,
        child: Container(
          padding: EdgeInsetsDirectional.fromSTEB(14.w, 8.h, 18.w, 8.h),
          decoration: BoxDecoration(
            color: ink.strong,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(AppIcons.reply, size: 20.r, color: ink.inverse),
              SizedBox(width: 6.w),
              Text(
                'رد',
                style: context.textTheme.titleMedium?.copyWith(
                  color: ink.inverse,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// الردُّ المفتوح تحت صفّه: حقلٌ وزرُّ إرسال. ما يُجاب عنه هو سطرُ الصفّ الأخير فوقه مباشرة، فلا
/// يُقتبس ثانية.
class _InlineReply extends StatefulWidget {
  const _InlineReply({required this.ticket, this.onSent, super.key});

  final InternalTicket ticket;
  final VoidCallback? onSent;

  @override
  State<_InlineReply> createState() => _InlineReplyState();
}

class _InlineReplyState extends State<_InlineReply> {
  final _text = TextEditingController();

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final sent = await context.read<InternalTicketsHomeCubit>().quickReply(
      widget.ticket.id,
      _text.text,
    );

    if (sent && mounted) widget.onSent?.call();
  }

  @override
  Widget build(BuildContext context) {
    final ink = _CardInk.of(context);
    final text = context.textTheme;
    final state = context.watch<InternalTicketsHomeCubit>().state;
    final sending =
        state is InternalTicketsHomeLoaded && state.replyingTo == widget.ticket.id;
    final failure = state is InternalTicketsHomeLoaded ? state.lastFailure : null;
    final canSend = _text.text.trim().isNotEmpty && !sending;
    final name = widget.ticket.otherSideOf(sl<Session>().user?.id)?.name;

    final radius = BorderRadius.circular(21.r);
    OutlineInputBorder border(Color color) =>
        OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: color));

    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: 10.h),
      // زرُّ الإرسال أوّلُ السطر — يمينَ الحقل بالعربية، كصندوق المحادثة (طلبُ المالك ٢٠٢٦-١٠-٢٣).
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SendButton(
            sending: sending,
            retry: failure != null,
            onPressed: canSend ? () => unawaited(_send()) : null,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: TextField(
              controller: _text,
              autofocus: true,
              minLines: 1,
              maxLines: 4,
              enabled: !sending,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => canSend ? unawaited(_send()) : null,
              cursorColor: ink.strong,
              style: text.bodyMedium?.copyWith(color: ink.strong),
              decoration: InputDecoration(
                isDense: true,
                hintText: name == null ? 'اكتب ردّك…' : 'اكتب ردّك لـ$name…',
                hintStyle: text.bodyMedium?.copyWith(color: ink.strong.withValues(alpha: 0.62)),
                errorText: failure?.message,
                errorMaxLines: 3,
                errorStyle: text.labelSmall?.copyWith(color: ink.alert),
                filled: true,
                fillColor: ink.strong.withValues(alpha: 0.14),
                contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
                border: border(ink.strong.withValues(alpha: 0.30)),
                enabledBorder: border(ink.strong.withValues(alpha: 0.30)),
                disabledBorder: border(ink.strong.withValues(alpha: 0.18)),
                focusedBorder: border(ink.strong.withValues(alpha: 0.70)),
                errorBorder: border(ink.alert),
                focusedErrorBorder: border(ink.alert),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.sending, required this.retry, this.onPressed});

  final bool sending;
  final bool retry;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final ink = _CardInk.of(context);
    final size = 42.r;
    final enabled = onPressed != null;

    return Semantics(
      button: true,
      enabled: enabled,
      label: sending
          ? 'جارٍ الإرسال'
          : retry
          ? 'إعادة الإرسال'
          : 'إرسال الرد',
      excludeSemantics: true,
      child: _Pressable(
        onTap: onPressed,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: enabled || sending ? ink.strong : ink.strong.withValues(alpha: 0.55),
            shape: BoxShape.circle,
          ),
          child: sending
              ? SizedBox.square(
                  dimension: 18.r,
                  child: CircularProgressIndicator(strokeWidth: 2.2, color: ink.inverse),
                )
              : Icon(retry ? AppIcons.refresh : AppIcons.send, size: 18.r, color: ink.inverse),
        ),
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$count غير مقروءة',
      excludeSemantics: true,
      child: Container(
        constraints: BoxConstraints(minWidth: 18.r, minHeight: 18.r),
        padding: EdgeInsets.symmetric(horizontal: 5.w),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFE5383B),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '$count',
          style: context.textTheme.labelSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 10.sp,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}

class _ShowAllButton extends StatelessWidget {
  const _ShowAllButton();

  @override
  Widget build(BuildContext context) {
    final ink = _CardInk.of(context);

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: _Pressable(
        onTap: () => unawaited(_Actions.openAll(context)),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'عرض كل التذاكر',
                style: context.textTheme.labelLarge?.copyWith(
                  color: ink.strong,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 2.w),
              Icon(AppIcons.forward, size: 18.r, color: ink.strong),
            ],
          ),
        ),
      ),
    );
  }
}

/// «تذكرة جديدة»: تذكرةٌ يعبرها زائد، بخطٍّ على دائرةٍ زجاجية — بحبر البطاقة نفسها، كبريمولا.
class _NewTicketButton extends StatelessWidget {
  const _NewTicketButton();

  @override
  Widget build(BuildContext context) {
    final ink = _CardInk.of(context);
    final size = 40.r;

    return Tooltip(
      message: 'تذكرة جديدة',
      child: Semantics(
        button: true,
        label: 'تذكرة جديدة',
        excludeSemantics: true,
        child: _Pressable(
          onTap: () => unawaited(_Actions.newTicket(context)),
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ink.fillStrong,
              shape: BoxShape.circle,
              border: Border.all(color: ink.strong.withValues(alpha: 0.28)),
            ),
            child: CustomPaint(
              size: Size.square(22.r),
              painter: _TicketPlusPainter(ink.strong),
            ),
          ),
        ),
      ),
    );
  }
}

/// تذكرةٌ — قسيمةٌ بزوايا مدوّرة ومحزوزةٌ من الجانبين — في وسطها زائد. مرسومةٌ كبريمولا: خطُّ
/// الأيقونات لا تذكرةَ جديدةً فيه.
class _TicketPlusPainter extends CustomPainter {
  const _TicketPlusPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // على شبكةٍ من ٢٤ وحدة، كخطّ الأيقونات بجانبها.
    final u = size.width / 24;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 * u
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    const left = 2.5, top = 5.5, right = 21.5, bottom = 18.5;
    const corner = 3.0, notch = 2.3, mid = 12.0;
    Offset p(double x, double y) => Offset(x * u, y * u);
    final r = Radius.circular(corner * u);
    final n = Radius.circular(notch * u);

    final slip = Path()
      ..moveTo((left + corner) * u, top * u)
      ..lineTo((right - corner) * u, top * u)
      ..arcToPoint(p(right, top + corner), radius: r)
      ..lineTo(right * u, (mid - notch) * u)
      // الحزّان إلى الداخل — عكس عقارب الساعة على الحافّتين.
      ..arcToPoint(p(right, mid + notch), radius: n, clockwise: false)
      ..lineTo(right * u, (bottom - corner) * u)
      ..arcToPoint(p(right - corner, bottom), radius: r)
      ..lineTo((left + corner) * u, bottom * u)
      ..arcToPoint(p(left, bottom - corner), radius: r)
      ..lineTo(left * u, (mid + notch) * u)
      ..arcToPoint(p(left, mid - notch), radius: n, clockwise: false)
      ..lineTo(left * u, (top + corner) * u)
      ..arcToPoint(p(left + corner, top), radius: r)
      ..close();
    canvas
      ..drawPath(slip, stroke)
      ..drawLine(p(mid - 3.4, mid), p(mid + 3.4, mid), stroke)
      ..drawLine(p(mid, mid - 3.4), p(mid, mid + 3.4), stroke);
  }

  @override
  bool shouldRepaint(_TicketPlusPainter old) => old.color != color;
}

/// عظامُ صفٍّ بشكله، كي لا تقفز البطاقةُ حين تصل الصفوف.
class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    final ink = _CardInk.of(context);

    Widget bone(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: ink.fillStrong, borderRadius: BorderRadius.circular(6.r)),
    );

    return ExcludeSemantics(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            bone(170.w, 14.h),
            SizedBox(height: 8.h),
            bone(120.w, 10.h),
            SizedBox(height: 8.h),
            bone(220.w, 12.h),
          ],
        ),
      ),
    );
  }
}

class _EmptyLine extends StatelessWidget {
  const _EmptyLine();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Text(
        'لا تذاكر بانتظار ردّك',
        style: context.textTheme.bodySmall?.copyWith(color: _CardInk.of(context).soft),
      ),
    );
  }
}

class _ErrorLine extends StatelessWidget {
  const _ErrorLine({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final ink = _CardInk.of(context);

    return Padding(
      padding: EdgeInsets.only(top: 6.h),
      child: Row(
        children: [
          Icon(AppIcons.error, size: 16.r, color: ink.soft),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(
              message.trim().isEmpty ? 'تعذّر تحميل تذاكر الموظفين' : message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodySmall?.copyWith(color: ink.soft),
            ),
          ),
          TextButton(
            onPressed: () => unawaited(onRetry()),
            style: TextButton.styleFrom(
              // على التدرّج: حبرُ الثيم الأساسيّ يختفي.
              foregroundColor: ink.strong,
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('إعادة'),
          ),
        ],
      ),
    );
  }
}
