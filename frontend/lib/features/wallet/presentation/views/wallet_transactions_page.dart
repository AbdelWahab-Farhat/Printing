import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/widgets/app_tab_bar.dart';
import 'package:dayaa/core/widgets/paged_list_view.dart';
import 'package:dayaa/core/widgets/search_field.dart';
import 'package:dayaa/features/employee_wallet/presentation/widgets/employee_wallet_movements.dart';
import 'package:dayaa/features/investment_fund/presentation/widgets/fund_detail_body.dart';
import 'package:dayaa/features/online_payments/presentation/widgets/online_payments_list.dart';
import 'package:dayaa/features/wallet/models/wallet_models.dart';
import 'package:dayaa/features/wallet/presentation/viewmodel/wallet_entries_cubit.dart';
import 'package:dayaa/features/wallet/presentation/widgets/wallet_entry_filters.dart';
import 'package:dayaa/features/wallet/presentation/widgets/wallet_entry_row.dart';
import 'package:dayaa/features/warehouses/presentation/widgets/day_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// «المعاملات المالية» — كل ما يتحرّك من مال: العملاء والموظفون والمدفوعات الإلكترونية، تبويبات.
/// Docs/payments/CUSTOMER-WALLET.md وEMPLOYEE-WALLET-DESIGN §٥.
///
/// **كانت حركات الموظفين والمدفوعات الإلكترونية صفَّين في القائمة الجانبية**، فانتقلتا إلى هنا بطلب
/// صاحب العمل (٢٠٢٦-١١-٠٧): «كلها معاملات مالية في النهاية».
///
/// **والتبويبات هي ما يملك القارئ فتحه**، كـ«التذاكر»: من يملك صلاحيةً واحدة يرى قائمتها وحدها، لا
/// شريطَ تبويبٍ فوق تبويبٍ واحد، ولا طلبَ يعود بـ403.
///
/// **للقراءة**: اللمسةُ تفتح المحفظة أو المحاولة، وهناك يُحرَّك المال — في سياقه.
class WalletTransactionsPage extends StatelessWidget {
  const WalletTransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = sl<Session>();

    // الصلاحيات تتبدّل والشجرة قائمة — سحبُ الرئيسية يعيد قراءة `/auth/me`.
    return ValueListenableBuilder<int>(
      valueListenable: session.revision,
      builder: (context, _, _) {
        final ledgers = [
          for (final ledger in _Ledger.values)
            if (session.can(ledger.permission)) ledger,
        ];

        return switch (ledgers) {
          // المسارُ لا يُدخل أحداً بلا واحدةٍ منها، لكن `TabController` بطولٍ صفر خطأٌ لا شاشةٌ
          // فارغة، فيُجاب هنا بدل أن ينهار.
          [] => const _Frame(body: SizedBox.shrink()),
          [final only] => _Frame(actions: only.actions, body: only.list),
          _ => _Tabbed(ledgers: ledgers),
        };
      },
    );
  }
}

/// السجلّات، بترتيب التبويبات: الأول يميناً. **بلا كلمة «المعاملات»**: العنوانُ فوقها يقولها مرّة،
/// و«المدفوعات الإلكترونية» كاملةً لا تتسع في ثلث الشاشة.
enum _Ledger {
  customers('العملاء', AppPermission.viewCustomerWallets),
  employees('الموظفون', AppPermission.viewEmployeeWallets),
  online('الإلكترونية', AppPermission.viewOnlinePayments);

  const _Ledger(this.label, this.permission);

  final String label;

  /// ما يُظهر التبويب أصلاً — صلاحيةُ قراءة القائمة نفسها، كما يحجبها الخادم.
  final AppPermission permission;

  Widget get list => switch (this) {
    _Ledger.customers => const _CustomerMovements(),
    _Ledger.employees => const EmployeeWalletMovements(),
    _Ledger.online => const OnlinePaymentsList(),
  };

  /// أزرارُ شريط الشاشة وهذا السجلُّ مفتوح.
  List<Widget> get actions => switch (this) {
    _Ledger.online => const [OnlinePaymentMethodsButton()],
    _ => const [],
  };
}

/// عنوانُ الشاشة، واحدٌ مهما كان تحته.
class _Frame extends StatelessWidget {
  const _Frame({required this.body, this.actions = const []});

  final Widget body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المعاملات المالية'), actions: actions),
      body: body,
    );
  }
}

class _Tabbed extends StatelessWidget {
  const _Tabbed({required this.ledgers});

  final List<_Ledger> ledgers;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: ledgers.length,
      child: _Frame(
        actions: [_OpenLedgerActions(ledgers: ledgers)],
        body: Column(
          children: [
            AppTabBar(labels: [for (final ledger in ledgers) ledger.label]),
            Expanded(
              child: TabBarView(
                children: [
                  for (final ledger in ledgers) _KeptAlive(child: ledger.list),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// أزرارُ التبويب المفتوح وحده.
class _OpenLedgerActions extends StatelessWidget {
  const _OpenLedgerActions({required this.ledgers});

  final List<_Ledger> ledgers;

  @override
  Widget build(BuildContext context) {
    final tabs = DefaultTabController.of(context);

    return ListenableBuilder(
      listenable: tabs,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: ledgers[tabs.index].actions,
      ),
    );
  }
}

/// حركات محافظ العملاء كلهم، الأحدث أولاً، يُبحث فيها باسم العميل أو هاتفه أو رمزه، وتُقصر على نوع.
class _CustomerMovements extends StatelessWidget {
  const _CustomerMovements();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<WalletEntriesCubit>()..load(),
      child: const _CustomerMovementsView(),
    );
  }
}

class _CustomerMovementsView extends StatelessWidget {
  const _CustomerMovementsView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<WalletEntriesCubit>();

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
          child: SearchField(hint: 'ابحث باسم العميل أو هاتفه أو رمزه', onChanged: cubit.search),
        ),
        BlocBuilder<WalletEntriesCubit, WalletEntriesState>(
          builder: (context, _) =>
              WalletEntryFilters(selected: cubit.filter, onSelect: cubit.narrowTo),
        ),
        Expanded(
          child: BlocBuilder<WalletEntriesCubit, WalletEntriesState>(
            builder: (context, state) {
              final items = state is PagedLoaded<CustomerWalletEntry>
                  ? state.page.items
                  : const <CustomerWalletEntry>[];

              return PagedListView<CustomerWalletEntry>(
                state: state,
                emptyMessage: 'لا معاملات',
                onLoadMore: cubit.loadMore,
                onRefresh: cubit.refresh,
                skeletonHeight: 96.h,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                // The hairline of the investor's statement, whose rows these are drawn like.
                separatorBuilder: (context, index) => const FundHairline(),
                itemBuilder: (context, entry, index) {
                  final previous = index > 0 && index - 1 < items.length ? items[index - 1] : null;
                  final row = CustomerWalletEntryRow(
                    key: ValueKey(entry.id),
                    entry: entry,
                    showCustomer: true,
                    onTap: () => _openWallet(context, entry),
                  );

                  if (entry.occurredAt case final at? when startsNewDay(previous?.occurredAt, at)) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DayHeader(at: at, first: index == 0),
                        row,
                      ],
                    );
                  }

                  return row;
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// محفظة العميل — وحين يتحرّك فيها مال يُعاد هذا السجل، فالسطر الجديد مكانه أعلاه.
  Future<void> _openWallet(BuildContext context, CustomerWalletEntry entry) async {
    final cubit = context.read<WalletEntriesCubit>();
    final moved = await context.push<bool>(
      Routes.customerWallet(entry.customerId),
      extra: entry.customerName,
    );

    if (moved == true) await cubit.refresh();
  }
}

/// يُبقي القائمة حيّةً حين يُترك تبويبُها: فلترُها وبحثُها وموضعُ التمرير والصفحاتُ المحمّلة.
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
