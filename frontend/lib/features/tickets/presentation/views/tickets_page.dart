import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/features/design_tickets/presentation/views/design_tickets_page.dart';
import 'package:dayaa/features/support/presentation/views/support_tickets_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// «التذاكر»: ما طلبه الموظفون من المصمّمين، وما يسأله العملاء من تطبيقهم — تبويبين.
///
/// **كانتا بابين في مكانين** (طلب المستخدم، 2026-09-25): تذاكرُ التصميم أيقونةً في الشريط،
/// وتذاكرُ الدعم صفّاً في الدرج تحت «الدعم». فانتقلت الثانية إلى خانة الأولى، والاسمُ صار عامّاً،
/// والتبويبان «تصميم» و«العملاء» — **بلا كلمة «تذاكر» قبلهما**: العنوانُ فوقهما يقولها مرّةً.
///
/// **الشاشتان كما هما، بلا شريطيهما.** كلٌّ منهما تُبنى هنا بـ`embedded: true`، فتُسقط شريطها
/// العلوي ويبقى كلُّ ما عداه: البحثُ والفلاتر وزرُّ «طلب تصميم» ورسالةُ القائمة الفارغة. وما يُفتح
/// من إحداهما — تذكرةٌ أو محادثة — يُدفع فوق هذه الشاشة ويعود إليها، والقائمةُ في تبويبها تستلم
/// ما عاد به كما كانت تستلمه وحدها.
///
/// **والتبويبان هما ما يملك القارئ فتحه**، كـ«الجهات»: مَن يرى إحداهما وحدها يجدها كما كانت،
/// بعنوانها وشريطها، لا شريطَ تبويبٍ فوق تبويبٍ واحد لا يفعل شيئاً. والمساراتُ القديمة
/// (`/design-tickets` و`/support/tickets`) باقيةٌ لمن يصل إليها من إشعارٍ أو من صفحة عميل.
class TicketsPage extends StatelessWidget {
  const TicketsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = sl<Session>();

    // الصلاحيات تتبدّل والشجرة قائمة — سحبُ الرئيسية يعيد قراءة `/auth/me`.
    return ValueListenableBuilder<int>(
      valueListenable: session.revision,
      builder: (context, _, _) {
        final queues = [
          for (final queue in _Queue.values)
            if (session.can(queue.permission)) queue,
        ];

        // المسارُ لا يُدخل أحداً بلا واحدةٍ منهما، لكن `TabController` بطولٍ صفر خطأٌ لا شاشةٌ
        // فارغة، فيُجاب هنا بدل أن ينهار.
        if (queues.isEmpty) return const Scaffold(body: SizedBox.shrink());

        if (queues.length == 1) return queues.single.page(embedded: false);

        return DefaultTabController(
          length: queues.length,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('التذاكر'),
              bottom: _Tabs(queues: queues),
            ),
            body: TabBarView(
              children: [
                for (final queue in queues) _KeptAlive(child: queue.page(embedded: true)),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// صفّا التذاكر، بترتيب التبويبين: الأول يميناً.
enum _Queue {
  design('تصميم', AppPermission.viewDesignTickets),
  customers('العملاء', AppPermission.viewSupportTickets);

  const _Queue(this.label, this.permission);

  final String label;

  /// ما يُظهر التبويب أصلاً — صلاحيةُ قراءة القائمة نفسها، كما يحجبها مسارُها.
  final AppPermission permission;

  Widget page({required bool embedded}) => switch (this) {
    _Queue.design => DesignTicketsPage(embedded: embedded),
    _Queue.customers => SupportTicketsPage(embedded: embedded),
  };
}

/// شريطُ «الجهات» نفسه: خطٌّ تحت التبويب لا كبسولة، فالتبديلُ بين قائمتين يُقرأ بشكلٍ واحد في
/// التطبيق كلّه.
class _Tabs extends StatelessWidget implements PreferredSizeWidget {
  const _Tabs({required this.queues});

  final List<_Queue> queues;

  @override
  Size get preferredSize => Size.fromHeight(44.h);

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return TabBar(
      isScrollable: false,
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: scheme.outlineVariant.withValues(alpha: 0.5),
      labelColor: scheme.primary,
      unselectedLabelColor: scheme.onSurfaceVariant,
      labelStyle: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
      unselectedLabelStyle: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      tabs: [for (final queue in queues) Tab(height: 44.h, text: queue.label)],
    );
  }
}

/// يُبقي القائمة حيّةً حين يُترك تبويبُها: موضعُ التمرير والصفحاتُ المحمّلة والاستماعُ الحيّ
/// لتذاكر الدعم — بدل أن تُعاد من أولها كلّما رجع إليها القارئ.
class _KeptAlive extends StatefulWidget {
  const _KeptAlive({required this.child});

  final Widget child;

  @override
  State<_KeptAlive> createState() => _KeptAliveState();
}

class _KeptAliveState extends State<_KeptAlive> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return widget.child;
  }
}
