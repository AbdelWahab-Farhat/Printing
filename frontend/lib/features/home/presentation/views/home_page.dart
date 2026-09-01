import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/features/customers/presentation/widgets/customer_picker_sheet.dart';
import 'package:dayaa/features/home/presentation/viewmodel/home_cubit.dart';
import 'package:dayaa/features/home/presentation/widgets/employee_card.dart';
import 'package:dayaa/features/home/presentation/widgets/payment_board.dart';
import 'package:dayaa/features/home/presentation/widgets/quick_actions.dart';
import 'package:dayaa/features/home/presentation/widgets/status_board.dart';
import 'package:dayaa/features/home/presentation/widgets/summary_tiles.dart';
import 'package:dayaa/features/orders/models/orders_filter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// The first screen of the signed-in app.
///
/// There is no `Scaffold` here and no app bar: this is a *body*. The frame around it — the bar,
/// the tabs, the drawer — belongs to the shell in `RootPage`, which is why switching tabs does
/// not rebuild it.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HomeCubit>(
      // Screen-scoped and closed with the screen; `..load()` so the first frame is already
      // asking rather than waiting for someone to pull down.
      create: (_) => sl<HomeCubit>()..load(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) => switch (state) {
        HomeInitial() || HomeLoading() => const _HomeSkeleton(),
        HomeFailure(:final failure) => _FailureView(
          message: failure.message,
          onRetry: context.read<HomeCubit>().load,
        ),
        HomeLoaded(:final user, :final summary) => RefreshIndicator(
          onRefresh: context.read<HomeCubit>().refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
            children: [
              EmployeeCard(user: user),
              SizedBox(height: 20.h),
              QuickActions(actions: _actionsFor(context)),
              SizedBox(height: 20.h),
              SummaryTiles(
                summary: summary,
                // Two of these switch tabs and two open a screen, and the difference is what
                // the number means: «الطلبات الكلية» *is* the orders tab, while «طلبات اليوم»
                // is a question the tab has no way to ask.
                onAllOrders: () => context.go(Routes.orders),
                onCustomers: () => context.go(Routes.customers),
                onDay: () => _openOrders(
                  context,
                  OrdersFilter(title: 'طلبات اليوم', from: _today, to: _today),
                ),
                onMonth: () => _openOrders(
                  context,
                  OrdersFilter(title: 'طلبات هذا الشهر', from: _firstOfMonth, to: _today),
                ),
              ),
              SizedBox(height: 24.h),
              // **The money first, above the statuses.** It sat under fourteen status cards to
              // begin with, which meant the question the shop opens this screen to ask — «كم
              // طلبية لم تُدفع» — was two screens of scrolling away. Three cards ahead of
              // fourteen also reads better than the other way round.
              //
              // **Its own board, not three more status cards**, because the two axes cross: an
              // order can be finished and unpaid, or paid before it is printed, so this is
              // unanswerable from the statuses however they are arranged.
              PaymentBoard(
                payments: summary.payments,
                onOpen: (payment) => _openOrders(
                  context,
                  // The *payment* axis, so a card reading «غير مدفوعة ١٢» opens every unpaid
                  // order whatever stage each is at — which is what the number counted.
                  OrdersFilter(title: payment.label, paymentStatuses: [payment.status]),
                ),
              ),
              SizedBox(height: 24.h),
              StatusBoard(
                statuses: summary.statuses,
                // The card's own word travels with it: this app holds no table of status names,
                // so the title of the screen it opens can only come from the card that opened it.
                onOpen: (status) => _openOrders(
                  context,
                  OrdersFilter(title: status.label, statuses: [status.status]),
                ),
              ),
            ],
          ),
        ),
      },
    );
  }

  void _openOrders(BuildContext context, OrdersFilter filter) {
    // Pushed over the shell rather than switching to the orders tab: this screen shows exactly
    // what the card counted and titles itself with the card's own word, and the date cards
    // («طلبات اليوم») carry no status for the tab's filter to hold at all. A card that opens a
    // screen contradicting it is worse than a card that does nothing.
    context.push(Routes.ordersFiltered, extra: filter);
  }

  /// Today and the first of this month, as the plain days the API filters on.
  ///
  /// Formatted from the phone's own clock, which is the same day the person reading the screen
  /// is living in. Where that day *begins* is the server's business — it knows the shop's
  /// timezone and this does not.
  static String get _today => _day(DateTime.now());

  static String get _firstOfMonth {
    final now = DateTime.now();

    return _day(DateTime(now.year, now.month));
  }

  static String _day(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// Both shortcuts push over the shell rather than switching tabs.
  ///
  /// **The two things staff start most often, and nothing else.** Each opens the form itself,
  /// not the tab it lives on: a shortcut that lands on a list the user then has to find an "add"
  /// button on has not saved them anything — it has just moved the tap. The المخزن shortcut that
  /// used to sit here was neither of those things (it opened a screen for reading, which the
  /// drawer already offers by name), and taking an order is the errand this shop opens the app
  /// for.
  List<QuickAction> _actionsFor(BuildContext context) {
    return [
      QuickAction(
        label: 'عميل جديد',
        icon: AppIcons.addCustomer,
        onTap: () => context.push(Routes.addCustomer),
      ),
      // Left out entirely without `orders.manage`: the route redirects back to the customer, and
      // a shortcut that bounces the user where they came from reads as a broken button rather
      // than as a permission they do not hold.
      if (sl<Session>().can(AppPermission.manageOrders))
        QuickAction(
          label: 'طلبية جديدة',
          icon: AppIcons.addOrder,
          onTap: () => _takeOrder(context),
        ),
    ];
  }

  /// «طلبية جديدة» from a screen that is about nobody in particular.
  ///
  /// **So it asks who first.** The form itself has no customer field — `customer_id` is read on
  /// create and ignored afterwards, so an order cannot change hands, and naming the customer by
  /// *which screen you are on* is what makes the wrong one unnameable (NEW-ORDER-DESIGN.md §١).
  /// The home screen is about nobody, so the naming happens in the sheet before the form opens,
  /// and the same route does the rest.
  Future<void> _takeOrder(BuildContext context) async {
    final customer = await showCustomerPicker(context: context);

    // Backing out of the sheet is an ordinary ending: no form, no message.
    if (customer == null || !context.mounted) return;

    // The whole customer travels, so the form opens with their name in place instead of a
    // spinner — exactly what their own screen hands it.
    await context.push(Routes.newCustomerOrder(customer.id), extra: customer);
  }
}

/// The shape of the page, drawn before its contents arrive.
///
/// A skeleton rather than a spinner: the layout does not jump when the data lands, and the wait
/// is spent looking at where the numbers will be rather than at a circle.
class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
      children: [
        _SkeletonBox(height: 108.h, radius: 24.r),
        SizedBox(height: 20.h),
        Row(
          children: [
            Expanded(
              child: _SkeletonBox(height: 76.h, radius: 20.r),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _SkeletonBox(height: 76.h, radius: 20.r),
            ),
          ],
        ),
        SizedBox(height: 20.h),
        // The height of a status card, so the board does not grow under the reader's eyes when
        // the counts land: [StatusBoard] draws each one a little taller than it is wide.
        for (var row = 0; row < 2; row++) ...[
          Row(
            children: [
              Expanded(
                child: _SkeletonBox(height: 148.h, radius: 20.r),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _SkeletonBox(height: 148.h, radius: 20.r),
              ),
            ],
          ),
          SizedBox(height: 12.h),
        ],
      ],
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({required this.height, required this.radius});

  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHigh.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _FailureView extends StatelessWidget {
  const _FailureView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

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
              // The server's own Arabic, not a generic apology: it usually says what to do.
              message,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyLarge?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 20.h),
            FilledButton.icon(
              onPressed: onRetry,
              icon: Icon(AppIcons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}

/// A tab whose screen has not been built yet.
///
/// Shipped on purpose: an empty tab that says so is honest, and the alternative — hiding the
/// destination until its screen exists — hides the shape of the app from the people testing it.
class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({required this.title, required this.icon, super.key});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56.sp, color: context.colorScheme.outline),
          SizedBox(height: 16.h),
          Text(
            title,
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: context.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'قريباً',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
