import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// Whether معدلات تكلفة التصنيع appears in the drawer.
///
/// **Hidden, not removed.** The screen, its route, its permissions, its repository and its
/// tests are all still here and still passing — this drawer row is the only door to them, so
/// closing the door is the whole change. Flip this to `true` to reopen it.
///
/// A flag rather than a deleted block: the code stays compiled and covered, so it cannot rot
/// quietly while it is out of sight, and coming back is one word rather than an archaeology
/// exercise in the history.
const bool showManufacturingCostRates = false;

/// The sidebar: everything that is not a tab, filed under headings that open one at a time.
///
/// Signing out used to live at the bottom of this panel. It moved into الإعدادات with the rest
/// of the account, because two ways to do the irreversible thing is one more than necessary —
/// and a drawer is for going somewhere, which is what this now does.
///
/// **Why headings and not a flat list.** Eleven rows in one column is a list you read rather
/// than a list you aim at: nothing groups مدن التوصيل with شركات التوصيل, and المنتجات sits four
/// rows away from تصنيفات المنتجات. Folded, the panel is four lines and a destination is two
/// taps — and the second tap lands in a list of three, which is a glance rather than a search.
///
/// **One open at a time**, so the panel never grows past what a short screen shows: opening a
/// heading is also the gesture that closes the one before it, and nobody has to tidy up after
/// themselves.
///
/// Its own file rather than a private class in `root_page.dart`: the shell needs a
/// [StatefulNavigationShell] to build at all, and this does not — so out here it is testable
/// under a bare router, which is where its permission rules are pinned down.
class RootDrawer extends StatefulWidget {
  const RootDrawer({super.key});

  @override
  State<RootDrawer> createState() => _RootDrawerState();
}

class _RootDrawerState extends State<RootDrawer> {
  /// Which heading the reader opened, and whether they have opened one at all.
  ///
  /// Two fields rather than one nullable, because "closed everything by hand" and "has not
  /// touched it yet" are different answers: the first must stay closed, the second falls back
  /// to the heading holding the screen currently on top.
  int? _open;
  bool _chosen = false;

  /// The rows, in the order they appear, grouped as the panel groups them.
  ///
  /// Declared as data rather than as a column of widgets so the two rules that used to live in
  /// prose — the permission each row needs, and which heading it belongs under — are readable
  /// in one place, and so a heading can count its surviving rows before deciding to appear.
  static const List<_Section> _sections = [
    // المخزن sat in this group until it traded places with the المنتجات tab: the catalogue is
    // opened once in a while, the stock every day.
    //
    // **أصناف المخزون and مجموعات الأصناف are not here.** They were rows in this drawer while
    // their balances sat under a tab, which put the screen that *explains* «كيس شحن 25*35»
    // further away than the numbers it explains. They are segments of the المخزون tab now; see
    // [InventoryTabPage].
    _Section(
      title: 'المنتجات والخدمات',
      icon: _SectionIcon.products,
      items: [
        _Link(
          icon: _LinkIcon.products,
          label: 'المنتجات',
          route: Routes.products,
          permission: AppPermission.viewProducts,
        ),
        // Gated on *reading* products, not on managing them: somebody who may see the
        // catalogue may see how it is organised. Adding and renaming is hidden inside.
        _Link(
          icon: _LinkIcon.productCategory,
          label: 'تصنيفات المنتجات',
          route: Routes.productCategories,
          permission: AppPermission.viewProducts,
        ),
        // Not gated: `business_fields.view` is granted to every role, because the customer
        // form cannot be filled in without this list. The screen itself hides the controls an
        // account without `business_fields.manage` cannot use.
        _Link(
          icon: _LinkIcon.businessField,
          label: 'مجالات العمل',
          route: Routes.businessFields,
        ),
      ],
    ),
    // **A section of one, and it earns it.** The rule a few lines up — «a heading exists to
    // group rows, one row does not earn one» — is about a row that belongs beside its
    // neighbours. This one belongs beside nothing here: every other section is the shop looking
    // at its own paperwork, and this is the only place in the staff app where a customer is
    // talking to us. Filing it under «المنتجات» or «المشتريات» would bury it.
    _Section(
      title: 'الدعم',
      icon: _SectionIcon.support,
      items: [
        _Link(
          icon: _LinkIcon.support,
          label: 'تذاكر الدعم',
          route: Routes.supportTickets,
          permission: AppPermission.viewSupportTickets,
        ),
      ],
    ),
    _Section(
      title: 'المشتريات والتوصيل',
      icon: _SectionIcon.purchaseOrders,
      items: [
        // The paperwork raised against the suppliers. Its own grant, not vendors.*: agreeing
        // terms with a supplier and raising an order against them are two jobs.
        _Link(
          icon: _LinkIcon.purchaseOrders,
          label: 'أوامر الشراء',
          route: Routes.purchaseOrders,
          permission: AppPermission.viewPurchaseOrders,
        ),
        // **النواقص belongs beside أوامر الشراء, not in a section of its own.** A shortage is
        // something to go out and buy; it sits in the same person's day as the paperwork above
        // it. And a heading exists to group rows — one row does not earn one.
        _Link(
          icon: _LinkIcon.shortages,
          label: 'النواقص',
          route: Routes.shortages,
          permission: AppPermission.viewShortages,
        ),
        // Gated: unlike the map of cities below, this list is not needed to fill any form in —
        // a carrier is chosen from the dispatch screen's own picker.
        _Link(
          icon: _LinkIcon.warehouse,
          label: 'شركات التوصيل',
          route: Routes.shippingCompanies,
          permission: AppPermission.viewShippingCompanies,
        ),
        _Link(icon: _LinkIcon.city, label: 'مدن التوصيل', route: Routes.cities),
        // Filed here because it is the same kind of back-office reference data as أوامر
        // الشراء: a standing figure curated once and read by every order that reaches الطباعة.
        //
        // Hidden for now — see [showManufacturingCostRates].
        _Link(
          icon: _LinkIcon.manufacturingCostRates,
          label: 'معدلات تكلفة التصنيع',
          route: Routes.manufacturingCostRates,
          permission: AppPermission.viewManufacturingCostRates,
          shown: showManufacturingCostRates,
        ),
      ],
    ),
    // **المستثمرون themselves are not here.** They are a tab of «الجهات», with العملاء and
    // الموردون — one screen for the three registers of people. صفقات المستثمرين stays a row,
    // because a deal is not a person, and it reads beside the money rather than beside a
    // register of names.
    _Section(
      title: 'الاستثمار والمالية',
      icon: _SectionIcon.investorDeals,
      items: [
        _Link(
          icon: _LinkIcon.investorDeals,
          label: 'صفقات المستثمرين',
          route: Routes.investorDeals,
          permission: AppPermission.viewInvestors,
        ),
        // The one screen in the panel that is read rather than curated.
        _Link(
          icon: _LinkIcon.report,
          label: 'الأرباح والخسائر',
          route: Routes.profitAndLoss,
          permission: AppPermission.viewProfitAndLossReport,
        ),
        // Beside it rather than under it: the two are read together, and a person may hold
        // either grant without the other.
        _Link(
          icon: _LinkIcon.salesStatistics,
          label: 'إحصائيات المبيعات',
          route: Routes.salesStatistics,
          permission: AppPermission.viewSalesStatisticsReport,
        ),
      ],
    ),
    _Section(
      title: 'الإدارة والصلاحيات',
      icon: _SectionIcon.employees,
      items: [
        _Link(
          icon: _LinkIcon.employees,
          label: 'الموظفون',
          route: Routes.employees,
          permission: AppPermission.viewUsers,
        ),
        _Link(
          icon: _LinkIcon.roles,
          label: 'الأدوار والصلاحيات',
          route: Routes.roles,
          permission: AppPermission.manageRoles,
        ),
      ],
    ),
    // **عنوانٌ بصفٍّ واحد، وهو يخالف قاعدة الشريط عمداً** — قرار المستخدم، ٢٠٢٦-٠٩-١٠. البديل
    // كان دفنَه تحت «الإدارة والصلاحيات» بجانب «الموظفون» و«الأدوار»، ورُفض: الأرشيف بابٌ يُقصد
    // لذاته لا صنفٌ من الشاشات، ومن يفتحه إنما يفتحه للبحث عن طلبيةٍ ضائعة — فإخفاؤه خلف عنوانٍ
    // عن الموظفين يجعل الشاشة التي تُفتح في لحظة ارتباك أبعدَ ما تكون عن اليد.
    //
    // **آخر العناوين**، منذ خرجت «الأدوات» من هذا الدرج إلى جانب الجرس — انظر
    // [ToolsMenuButton]. والدرج كلّه اليوم خريطةُ النظام: كل عنوانٍ فيه يصنّف سجلّاً، والأرشيف
    // سجلّ. وهو كذلك يترك البابَ مفتوحاً لأرشيف العملاء والمنتجات لاحقاً، صفّاً يُضاف هنا بلا
    // إعادة ترتيب أيّ عنوانٍ آخر.
    //
    // وبصلاحيته وحده: من يقرأ الأرشيف ليس بالضرورة من يحذف منه أو يستعيد إليه.
    _Section(
      title: 'الأرشيف',
      icon: _SectionIcon.archive,
      items: [
        _Link(
          icon: _LinkIcon.orderArchive,
          label: 'أرشيف الطلبيات',
          route: Routes.archivedOrders,
          permission: AppPermission.viewOrderArchive,
        ),
      ],
    ),
  ];

  /// Where the router is, so a row can say «this is the screen you are reading».
  ///
  /// `maybeOf`, and the top state rather than this widget's own: a pushed screen is what the
  /// reader is looking at, and it is the row for *that* which has to light up.
  String get _location => GoRouter.maybeOf(context)?.state.uri.path ?? '';

  @override
  Widget build(BuildContext context) {
    final session = sl<Session>();

    return Drawer(
      backgroundColor: context.colorScheme.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 16.h),
              child: Row(
                children: [
                  Image.asset('assets/images/logo.png', height: 44.w, width: 44.w),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'دعاية',
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: context.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Rebuilt when the session changes, for the same reason [PermissionGate] listens: a
            // permission set really does change with the tree mounted — pulling to refresh the
            // home screen re-reads `/auth/me`, and so does the healing refresh after a 403.
            Expanded(
              child: ValueListenableBuilder<int>(
                valueListenable: session.revision,
                builder: (context, _, _) => _sectionList(session),
              ),
            ),
            const Divider(height: 1),
            // Outside the headings and last, because it is where the panel ends rather than one
            // more place to go: the account, the theme, and the way out.
            _LinkTile(
              icon: AppIcons.settings,
              label: 'الإعدادات',
              route: Routes.settings,
              active: _isActive(Routes.settings),
            ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }

  /// The headings, each with the rows this account may actually open.
  ///
  /// A list rather than a column: with a heading open on a short phone the panel is taller than
  /// the screen, and a drawer that clips its last row is a row nobody can reach.
  Widget _sectionList(Session session) {
    // Gated, not greyed: a link that only ever leads to a screen this account cannot read is a
    // row to leave out, not one to explain. The route guards it again — this is the courtesy,
    // that is the boundary. And a heading whose every row went that way is a heading that
    // promises nothing, so it goes too.
    final visible = [
      for (final section in _sections)
        if (section.itemsFor(session) case final items when items.isNotEmpty)
          (section: section, items: items),
    ];

    // Untouched, the panel opens itself on whatever screen is being read — so a reload or a
    // deep link lands with its own heading already unfolded, and the row beneath the finger.
    final holdingCurrent = visible.indexWhere((s) => s.items.any((i) => _isActive(i.route)));
    final open = _chosen ? _open : (holdingCurrent >= 0 ? holdingCurrent : null);

    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      itemCount: visible.length,
      itemBuilder: (context, index) {
        final (:section, :items) = visible[index];
        final isOpen = index == open;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              leading: Icon(section.icon.data, color: context.colorScheme.onSurfaceVariant),
              title: Text(
                section.title,
                style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              // Turned rather than swapped: the arrow travelling from ‹ to ⌄ is what says the
              // heading moved, where two different glyphs would only say it changed.
              trailing: AnimatedRotation(
                turns: isOpen ? 0 : (Directionality.of(context) == TextDirection.rtl ? .25 : -.25),
                duration: const Duration(milliseconds: 180),
                child: Icon(AppIcons.expand, color: context.colorScheme.onSurfaceVariant),
              ),
              onTap: () => setState(() {
                _chosen = true;
                _open = isOpen ? null : index;
              }),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: isOpen
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final item in items)
                          _LinkTile(
                            icon: item.icon.data,
                            label: item.label,
                            route: item.route,
                            active: _isActive(item.route),
                            nested: true,
                          ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }

  /// Whether [route] is the screen on top — or the one it was pushed from.
  ///
  /// The prefix arm is what keeps «أوامر الشراء» lit while a single order is open on top of the
  /// list: a detail screen is somewhere *inside* its row, not somewhere else. The trailing
  /// slash is load-bearing — without it `/products` would claim `/product-categories`.
  bool _isActive(String route) =>
      _location == route || _location.startsWith('$route/');
}

/// One heading and the rows filed under it.
class _Section {
  const _Section({required this.title, required this.icon, required this.items});

  final String title;
  final _SectionIcon icon;
  final List<_Link> items;

  /// The rows this account may open. Empty means the heading itself is not drawn.
  List<_Link> itemsFor(Session session) => [
    for (final item in items)
      if (item.shown && (item.permission == null || session.can(item.permission!))) item,
  ];
}

/// One row: where it goes, and what it takes to be allowed there.
class _Link {
  const _Link({
    required this.icon,
    required this.label,
    required this.route,
    this.permission,
    this.shown = true,
  });

  final _LinkIcon icon;
  final String label;
  final String route;

  /// What reading the screen needs, when it needs anything. Null for the lists every role may
  /// read — a form somewhere cannot be filled in without them.
  final AppPermission? permission;

  /// Whether the row is offered at all, permissions aside. See [showManufacturingCostRates].
  final bool shown;
}

/// The glyphs, behind an enum because [AppIcons] resolves per platform at runtime and the rows
/// above are `const`.
enum _SectionIcon {
  products,
  purchaseOrders,
  investorDeals,
  employees,
  archive,
  support;

  IconData get data => switch (this) {
    _SectionIcon.products => AppIcons.products,
    _SectionIcon.purchaseOrders => AppIcons.purchaseOrders,
    _SectionIcon.investorDeals => AppIcons.investorDeals,
    _SectionIcon.employees => AppIcons.employees,
    _SectionIcon.support => AppIcons.comments,
    // The same glyph the row under it carries. A heading of one row is the one place in this
    // panel where two icons would say the same thing twice, and picking a *different* one to
    // avoid the repetition would be inventing a distinction that is not there.
    _SectionIcon.archive => AppIcons.archive,
  };
}

/// The same trick for the rows. Each keeps the glyph it had as a row of the flat drawer.
enum _LinkIcon {
  products,
  productCategory,
  businessField,
  purchaseOrders,
  shortages,
  warehouse,
  city,
  manufacturingCostRates,
  investorDeals,
  report,
  salesStatistics,
  employees,
  roles,
  orderArchive,
  support;

  IconData get data => switch (this) {
    _LinkIcon.products => AppIcons.products,
    _LinkIcon.productCategory => AppIcons.productCategory,
    _LinkIcon.businessField => AppIcons.businessField,
    _LinkIcon.purchaseOrders => AppIcons.purchaseOrders,
    _LinkIcon.shortages => AppIcons.error,
    _LinkIcon.support => AppIcons.comments,
    _LinkIcon.warehouse => AppIcons.warehouse,
    _LinkIcon.city => AppIcons.city,
    _LinkIcon.manufacturingCostRates => AppIcons.manufacturingCostRates,
    _LinkIcon.investorDeals => AppIcons.investorDeals,
    _LinkIcon.report => AppIcons.report,
    _LinkIcon.salesStatistics => AppIcons.products,
    _LinkIcon.employees => AppIcons.employees,
    _LinkIcon.roles => AppIcons.roles,
    _LinkIcon.orderArchive => AppIcons.archive,
  };
}

/// A row that goes somewhere: under a heading, or — for الإعدادات — on its own at the foot.
class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.icon,
    required this.label,
    required this.route,
    required this.active,
    this.nested = false,
  });

  final IconData icon;
  final String label;
  final String route;

  /// Whether this is the screen being read. Drawn as a tint rather than a bolder weight, so the
  /// row does not change width when the reader arrives on it.
  final bool active;

  /// Whether it sits under a heading — indented and a shade quieter, so the eye reads the
  /// headings as the list and the rows as its contents.
  final bool nested;

  @override
  Widget build(BuildContext context) {
    final tint = active ? context.colorScheme.primary : null;

    return ListTile(
      selected: active,
      selectedTileColor: context.colorScheme.primaryContainer.withValues(alpha: .35),
      // Directional, because the indent belongs on the side the text starts from, and this app
      // is read from the right.
      contentPadding: nested
          ? EdgeInsetsDirectional.only(start: 32.w, end: 16.w)
          : EdgeInsetsDirectional.symmetric(horizontal: 16.w),
      leading: Icon(
        icon,
        size: nested ? 20.w : null,
        color: tint ?? context.colorScheme.onSurfaceVariant,
      ),
      title: Text(
        label,
        style: nested
            ? context.textTheme.bodyMedium?.copyWith(
                color: tint ?? context.colorScheme.onSurfaceVariant,
              )
            : context.textTheme.bodyLarge?.copyWith(color: tint),
      ),
      onTap: () {
        // Closed first: leaving the drawer open behind the screen it opened means finding it
        // still there on the way back.
        Navigator.of(context).pop();
        context.push(route);
      },
    );
  }
}
