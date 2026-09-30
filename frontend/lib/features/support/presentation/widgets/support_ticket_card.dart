import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/features/support/models/support_ticket.dart';
import 'package:dayaa/features/support/presentation/widgets/ticket_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// تذكرةٌ في الطابور، بترتيب بطاقة بريمولا: عمّ هي وأين وصلت، ثم على مكتب من، ثم ما يُنسخ
/// ويُبحث به.
///
/// **شريحتان تحملان اللون، والباقي محايد.** الحالةُ في طرف العنوان، والمكتبُ تحته: أحمرُ ما لم
/// يأخذها أحد، واللونُ الأساسيّ حين تكون لي، ومحايدٌ لاسم زميل. العميلُ والهاتفُ والطلبُ والوقتُ
/// على سطحٍ واحد بكلماتٍ بتمام قوّتها.
///
/// **ما في بريمولا وليس هنا** — التقييم والتصنيف وآخر ما قيل: لا يحملها صفُّ القائمة من الخادم.
class SupportTicketCard extends StatelessWidget {
  const SupportTicketCard({
    required this.ticket,
    required this.onOpen,
    this.me,
    super.key,
  });

  final SupportTicket ticket;
  final VoidCallback onOpen;

  /// رقمُ المستخدم في الجلسة، لتُقرأ تذكرتُه «تذكرتك». فارغٌ حين لا تُعرف الجلسة.
  final int? me;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final unread = ticket.unreadCount;
    final radius = BorderRadius.circular(16.r);

    return Stack(
      // الشارةُ معلّقةٌ على زاوية البطاقة، فلا شيء يقصّها.
      clipBehavior: Clip.none,
      children: [
        Material(
          // في الداكن يجب أن تعلو البطاقةُ الصفحةَ لوناً، وفي الفاتح بيضاءُ على صفحةٍ ملوّنة.
          color: Theme.of(context).brightness == Brightness.dark
              ? scheme.surfaceContainer
              : scheme.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(color: unread > 0 ? scheme.primary : scheme.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onOpen,
            child: Padding(
              padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TitleRow(ticket: ticket),
                  SizedBox(height: 10.h),
                  TicketChip.desk(context, ticket: ticket, me: me),
                  SizedBox(height: 10.h),
                  _Footer(ticket: ticket),
                ],
              ),
            ),
          ),
        ),

        // **من عدّاد الخادم**، المشتقّ من مؤشّر قراءة — لا عدّاد يحفظه هذا التطبيق فينحرف.
        if (unread > 0)
          PositionedDirectional(
            top: -9.h,
            end: -6.w,
            child: _UnreadBadge(count: unread),
          ),
      ],
    );
  }
}

/// العنوان، والحالةُ في طرفه: «أين وصلت؟» تخصّ العنوانَ، فيبقى الصفُّ تحته لسؤالٍ واحد.
class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.ticket});

  final SupportTicket ticket;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            ticket.subject,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
        ),
        SizedBox(width: 8.w),
        // كلمةُ الخادم (`status_label`)، فحالةٌ جديدة تظهر بلا إصدار؛ ولونُها من التطبيق.
        TicketChip.tinted(
          context,
          label: ticket.statusLabel,
          hue: ticketStatusHue(context.colorScheme, ticket.status),
          dot: true,
        ),
      ],
    );
  }
}

/// ما يُنسخ ويُقال في الهاتف ويُبحث به — شريحةٌ لكلٍّ منها، ثم كم مضى على آخر حركة.
class _Footer extends StatelessWidget {
  const _Footer({required this.ticket});

  final SupportTicket ticket;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final customer = ticket.customer;

    // **الكودُ لا الاسم**، كبطاقة تذكرة التصميم: هو ما يُقال في الهاتف ويأخذه البحث. والاسمُ
    // حين لم يُرسل الخادمُ كوداً.
    final who = [customer?.code, customer?.name]
        .map((value) => value?.trim())
        .firstWhere((value) => value != null && value.isNotEmpty, orElse: () => null);
    final phone = customer?.phone?.trim();

    return Wrap(
      spacing: 6.w,
      runSpacing: 6.h,
      children: [
        if (who != null) TicketChip.neutral(context, label: who, icon: AppIcons.customers),
        // من يجيب «أين طلبيتي؟» يمدّ يده إلى الهاتف بعدها.
        if (phone != null && phone.isNotEmpty)
          TicketChip.neutral(context, label: phone, icon: AppIcons.phone),
        // موضوعٌ آخر تتعلّق به التذكرة، فله مسحتُه.
        if (ticket.order case final order?)
          TicketChip(
            label: 'طلب ${order.code}',
            icon: AppIcons.orders,
            background: scheme.secondaryContainer,
            foreground: scheme.onSecondaryContainer,
          ),
        // وقتٌ واحد: متى تحرّكت آخر مرّة.
        if (ticket.lastMessageAt case final at?)
          TicketChip.neutral(context, label: at.agoLabel, icon: AppIcons.elapsed, quiet: true),
      ],
    );
  }
}

/// عددُ غير المقروء، معلّقاً فوق زاوية البطاقة لا داخلها.
class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      constraints: BoxConstraints(minWidth: 26.w),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: scheme.error,
        borderRadius: BorderRadius.circular(999),
        // حلقةٌ بلون الصفحة تجعلها تطفو فوق البطاقة لا ملصقةً على حدّها.
        border: Border.all(color: scheme.surface, width: 2),
      ),
      child: Text(
        count > 99 ? '+99' : '$count',
        textAlign: TextAlign.center,
        style: context.textTheme.labelMedium?.copyWith(
          color: scheme.onError,
          fontWeight: FontWeight.w800,
          height: 1.1,
        ),
      ),
    );
  }
}
