import 'package:dayaa/core/widgets/app_tab_bar.dart';
import 'package:dayaa/features/stock_items/presentation/views/stock_items_page.dart';
import 'package:dayaa/features/warehouses/presentation/views/warehouses_page.dart';
import 'package:flutter/material.dart';

/// المخزون — one tab over the three questions a storekeeper actually asks.
///
/// **They were three doors in two different places, and that was the mistake.** المخازن was a
/// tab; أصناف المخزون and مجموعات الأصناف were rows in the drawer, filed near المنتجات because
/// they are reference data. But they are not three subjects — they are one subject at three
/// zoom levels, and every one of them is about the same heap of bags:
///
///   المخازن  — **أين**: the rooms, and what each holds
///   المواد   — **ماذا**: the shelf itself, a material at a size. What a balance is of.
///
/// That reading is what the three screens teach by being used. None of it is printed on them —
/// see [_tabs].
///
/// Putting the middle one behind a hamburger while its balances sat under a tab meant the
/// screen that *explains* «كيس شحن 25*35» was the hardest of the three to find, and somebody
/// reading أصناف المخزون out of context read it as a duplicate of المنتجات.
///
/// **Tabs rather than nested navigation**, because the lists are siblings and a person moves
/// between them constantly — «هذا الرصيد لأي صنف؟ وهذا الصنف من أي مادة؟» is one train of
/// thought, and it should not cost a back-press each way. **And the same tabs as الجهات** —
/// see [AppTabBar] — because the two are the same shape: a shell tab split into sibling lists.
/// This one used to be a pill switch, and moving between the two tabs read as changing apps.
///
/// The bodies are the real screens, embedded — see [StockItemsPage.isEmbedded]. Nothing here is
/// a second implementation of a list, so a fix to the المواد screen is a fix here too, and the
/// standalone routes a deep link uses keep working unchanged.
class InventoryTabPage extends StatelessWidget {
  const InventoryTabPage({super.key});

  /// **Two words, and nothing under them.** Each tab used to carry a line explaining what it
  /// was — «الرفّ نفسه، وعليه يقوم الرصيد» and the like. Written once they read well; met on
  /// every visit they are a paragraph between the person and the list they came for, and after
  /// the second day nobody reads them.
  ///
  /// **«المواد» is the second one, and that is the whole naming.** What a storekeeper counts,
  /// orders and runs out of is a **مادة** — «كيس شحن 25×35» — and «كيس شحن» on its own is the
  /// **تصنيف** it is filed under. Calling the sized thing «صنف» put the everyday word on the
  /// screen nobody visits and left the screen with the balances named after a category.
  ///
  /// **And التصنيفات is no longer one of them.** A category is a thing the server keeps working
  /// with and nobody is asked about: which product sizes draw on a material is now said on the
  /// material itself, all of them at once, instead of one product at a time. The screen and its
  /// route still exist — a deep link resolves and the data behind it is untouched — but nothing
  /// navigates there.
  ///
  /// المخازن first, and it stays the landing tab: it is the one opened every day, and the other
  /// is consulted when something about a shelf needs explaining.
  ///
  /// **This list and [TabBarView]'s children are one thing in two places.** A label with no body
  /// behind it is an assertion the moment the tab is built — see [_bodies].
  static const List<String> _tabs = ['المخازن', 'المواد'];

  /// One body per label in [_tabs], in that order.
  ///
  /// **Kept beside the labels rather than inline**, because the two drifted apart once already:
  /// a body was removed and its label left in the strip, and the tab looked perfectly correct
  /// until the missing one was tapped. Named together, the mismatch is visible at a glance — and
  /// asserted below.
  static const List<Widget> _bodies = [WarehousesPage(), StockItemsPage(isEmbedded: true)];

  @override
  Widget build(BuildContext context) {
    assert(
      _tabs.length == _bodies.length,
      'every tab needs a body: ${_tabs.length} labels, ${_bodies.length} bodies',
    );

    return DefaultTabController(
      length: _tabs.length,
      child: Column(
        children: [
          const AppTabBar(labels: _tabs),
          Expanded(
            child: TabBarView(children: [for (final body in _bodies) _KeptAlive(child: body)]),
          ),
        ],
      ),
    );
  }
}

/// Keeps a tab's body mounted after it is swiped off screen.
///
/// **Load-bearing here, where الجهات gets away without it.** [TabBarView] disposes a page the
/// moment it leaves the viewport. الجهات survives that because its Cubits sit above the tabs;
/// these bodies each create their own Cubit on build, so without this every swipe would re-fetch
/// the list, empty the search box and throw away the scroll position — the exact cost the
/// `IndexedStack` this replaced was there to avoid, and the same reason the shell keeps every
/// tab alive.
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
