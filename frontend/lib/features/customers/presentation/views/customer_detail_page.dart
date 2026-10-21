import 'dart:async';

import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/pagination/changes.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/router/pop_result.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_dialog.dart';
import 'package:dayaa/core/widgets/app_speed_dial.dart';
import 'package:dayaa/core/widgets/copy_text.dart';
import 'package:dayaa/features/audit/models/audit_subject.dart';
import 'package:dayaa/features/customers/models/customer.dart';
import 'package:dayaa/features/customers/presentation/viewmodel/customer_detail_cubit.dart';
import 'package:dayaa/features/customers/presentation/viewmodel/customer_order_counts_cubit.dart';
import 'package:dayaa/features/customers/presentation/widgets/customer_orders_section.dart';
import 'package:dayaa/features/internal_tickets/models/internal_ticket_query.dart';
import 'package:dayaa/features/wallet/presentation/viewmodel/customer_wallet_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// Everything about one customer, and the things staff do to them.
///
/// Reached by tapping a row in the list — the slot was reserved for it: `CustomerCard.onTap`
/// has existed and been passed `null` since the list was written.
///
/// **The two commonest writes sit on the page; the rest are in the speed dial.** Editing opens the same form that registers a
/// customer, because the expensive parts of that form — the shop rows, the map picker, the
/// per-row error mapping — should exist once. Deactivating is its own endpoint and its own
/// action, which is what makes it impossible for saving an edit to switch somebody back on by
/// accident.
class CustomerDetailPage extends StatelessWidget {
  const CustomerDetailPage({required this.customerId, super.key});

  /// البطاقةُ أعلى الصفحة — العميلُ ومحفظتُه — ليجدها الاختبار.
  @visibleForTesting
  static const Key headerKey = Key('customer_header');

  final int customerId;

  @override
  Widget build(BuildContext context) {
    // Not created at all without `orders.view`, rather than created and its 403 swallowed: a
    // request nobody may make is a request not worth sending, and the section it feeds is absent
    // for the same reason «طلبية جديدة» is — see [_MainActions].
    final showsOrders = sl<Session>().can(AppPermission.viewOrders);
    // The wallet card on the same terms: not built without the grant to read it.
    final showsWallet = sl<Session>().can(AppPermission.viewCustomerWallets);

    return MultiBlocProvider(
      providers: [
        BlocProvider<CustomerDetailCubit>(
          create: (_) => sl<CustomerDetailCubit>(param1: customerId)..load(),
        ),
        if (showsOrders)
          BlocProvider<CustomerOrderCountsCubit>(
            create: (_) => sl<CustomerOrderCountsCubit>(param1: customerId)..load(),
          ),
        if (showsWallet)
          BlocProvider<CustomerWalletCubit>(
            create: (_) => sl<CustomerWalletCubit>(param1: customerId)..load(),
          ),
      ],
      child: _CustomerDetailView(showsOrders: showsOrders, showsWallet: showsWallet),
    );
  }
}

class _CustomerDetailView extends StatefulWidget {
  const _CustomerDetailView({required this.showsOrders, required this.showsWallet});

  final bool showsOrders;
  final bool showsWallet;

  @override
  State<_CustomerDetailView> createState() => _CustomerDetailViewState();
}

/// Stateful for one reason: it remembers whether the customer moved while it was open, so the
/// list behind is handed the new row. That is screen lifecycle, not business state — the Cubit
/// owns the customer itself.
class _CustomerDetailViewState extends State<_CustomerDetailView> {
  final _changes = Changes<Customer>();

  bool get showsOrders => widget.showsOrders;
  bool get showsWallet => widget.showsWallet;

  /// Every reading at once, so one pull answers the whole screen.
  ///
  /// `Future.wait` rather than one after the other: they are independent requests, and making
  /// the numbers wait on the customer would double how long the spinner sits there.
  Future<void> _refresh(BuildContext context) async {
    await Future.wait([
      context.read<CustomerDetailCubit>().load(),
      if (showsOrders) context.read<CustomerOrderCountsCubit>().load(),
      if (showsWallet) context.read<CustomerWalletCubit>().load(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CustomerDetailCubit>();

    return Scaffold(
      floatingActionButtonLocation: AppSpeedDial.location,
      appBar: AppBar(
        title: BlocBuilder<CustomerDetailCubit, CustomerDetailState>(
          // The name once it is known, so the bar stops saying something generic the moment it
          // can say something useful.
          builder: (context, state) => Text(state.customer?.name ?? 'تفاصيل العميل'),
        ),
      ),
      floatingActionButton: BlocBuilder<CustomerDetailCubit, CustomerDetailState>(
        builder: (context, state) {
          final customer = state.customer;
          if (customer == null) return const SizedBox.shrink();

          return _Actions(customer: customer);
        },
      ),
      body: BlocConsumer<CustomerDetailCubit, CustomerDetailState>(
        listener: (context, state) {
          // Every reading goes past here, whatever produced it — the form, the activation
          // toggle, a pull that picked up somebody else's change. What differs from the first
          // one is what the list behind is handed on the way out.
          context.handBack(_changes.saw(state.customer));

          // Only when there is still a page underneath. With nothing to fall back to the body
          // already shows the failure, and a snackbar over it would say the same thing twice.
          if (state case CustomerDetailFailure(:final failure)) {
            if (state.customer != null) context.showFailure(failure);
          }
        },
        builder: (context, state) => switch (state) {
          CustomerDetailLoading() => const Center(child: CircularProgressIndicator()),
          CustomerDetailFailure(:final failure) => _FailureView(
            message: failure.message,
            onRetry: cubit.load,
          ),
          _ => RefreshIndicator(
            onRefresh: () => _refresh(context),
            child: _Body(
              customer: state.customer!,
              isChanging: state.isChanging,
              showsOrders: showsOrders,
              showsWallet: showsWallet,
            ),
          ),
        },
      ),
    );
  }
}

Future<void> _edit(BuildContext context, Customer customer) async {
  final cubit = context.read<CustomerDetailCubit>();

  final saved = await context.push<Customer>(Routes.editCustomer(customer.id), extra: customer);

  // What the form hands back is the server's own reading of the customer it just stored —
  // the same bytes a re-read would return, a request earlier. Null means it was left without
  // saving, and nothing on this screen has to move.
  if (saved != null) cubit.show(saved);
}

Future<void> _toggleActive(BuildContext context, Customer customer) async {
  final cubit = context.read<CustomerDetailCubit>();

  if (customer.isActive) {
    final confirmed = await showCustomDialog(
      context: context,
      title: 'تعطيل العميل؟',
      description:
          'لن يظهر «${customer.name}» ضمن العملاء النشطين، ويمكن تنشيطه في أي وقت. '
          'بياناته وطلبياته السابقة لا تُحذف.',
      confirmLabel: 'تعطيل',
      cancelLabel: 'إلغاء',
    );

    // Deliberately not `showDestructiveDialog`: that one paints the button in the error
    // colour and stamps a bin on it. Nothing is being destroyed here — the whole reason this
    // API has no delete route is that a customer's history must survive — and a bin over a
    // reversible action is a lie.
    if (confirmed != true) return;
  }

  // Turning somebody back on gets no dialog. A confirmation for an action that costs nothing
  // is a tax on the common case.
  await cubit.setActive(isActive: !customer.isActive);
}

/// What this screen can do besides the two buttons on it, as data.
///
/// «طلبية جديدة» and «تعديل العميل» sit on the page under the status band — see [_MainActions] —
/// and switching the customer off or on sits inside the band itself — see [_StatusBand]. What is
/// left here is everything that leads somewhere else.
///
/// The button itself is [AppSpeedDial] in `core/widgets/` — it filters these by permission,
/// collapses to a plain button when only one survives, and owns the right-to-left handling that
/// every screen would otherwise get wrong on its own.
class _Actions extends StatelessWidget {
  const _Actions({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    return AppSpeedDial(
      actions: [
        // **Here rather than on a list, for the reason «طلبية جديدة» is on this screen.** A
        // design request is always *for* somebody, and naming the customer by which screen you
        // are on is what makes the wrong one unnameable — the argument NEW-ORDER-DESIGN.md §١
        // makes for orders, applied to the other thing raised against a customer.
        //
        // Absent for a deactivated customer, like the order button: this is somebody the shop
        // has stopped selling to.
        if (customer.isActive)
          AppAction(
            label: 'طلب تصميم',
            icon: AppIcons.designs,
            tone: AppActionTone.primary,
            permission: AppPermission.manageDesignTickets,
            onTap: (context) =>
                context.push(Routes.designTicketForm, extra: customer),
          ),
        AppAction(
          label: 'التصاميم',
          icon: AppIcons.designs,
          // `customers.view`, not `manage`: somebody who may only read the customer may still
          // need to see what gets printed on their bags before quoting an order. Adding and
          // removing is gated inside that screen.
          permission: AppPermission.viewCustomers,
          onTap: (context) =>
              context.push(Routes.customerDesigns(customer.id), extra: customer.name),
        ),
        // ما قاله الموظفون بينهم عن هذا العميل، كبريمولا — بلا صلاحية: التذاكرُ الداخلية لكل موظف.
        AppAction(
          label: 'تذاكر الموظفين',
          icon: AppIcons.internalTickets,
          onTap: (context) => context.push(
            Routes.internalTicketsFiltered,
            extra: InternalTicketSubject(customerId: customer.id, customerName: customer.name),
          ),
        ),
        AppAction(
          label: 'الملاحظات',
          icon: AppIcons.comments,
          // `customers.view`, like the designs: leaving the next person a sentence about a
          // customer is part of serving them, not a privilege over them. Who may change a
          // *particular* note is answered per row inside that screen, by the server.
          permission: AppPermission.viewCustomers,
          onTap: (context) =>
              context.push(Routes.customerComments(customer.id), extra: customer.name),
        ),
        AppAction(
          label: 'سجل التعديلات',
          icon: AppIcons.history,
          // `logs.view`, not `customers.view`, and that is the server's own line: a history
          // shows what *everyone* has done, including people and prices the reader may have no
          // other way to see. Editing a customer does not make somebody an auditor.
          permission: AppPermission.viewActivityLogs,
          onTap: (context) => context.push(
            Routes.activityLog(AuditSubject.customer, customer.id),
            extra: customer.name,
          ),
        ),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.customer,
    required this.isChanging,
    required this.showsOrders,
    required this.showsWallet,
  });

  final Customer customer;
  final bool isChanging;
  final bool showsOrders;
  final bool showsWallet;

  @override
  Widget build(BuildContext context) {
    final shops = customer.shops;

    return ListView(
      // `always`, so pull-to-refresh works on a customer with no shops — a short page that
      // cannot scroll is a page that cannot be refreshed.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 96.h),
      children: [
        _HeaderCard(customer: customer, showsWallet: showsWallet),
        SizedBox(height: 14.h),

        _StatusBand(customer: customer, isChanging: isChanging),
        SizedBox(height: 14.h),

        if (_MainActions.showsAny(customer)) ...[
          _MainActions(customer: customer),
          SizedBox(height: 14.h),
        ],

        // **The first thing under the identity, because it is why this screen is opened.**
        // A customer is looked up to answer «ماذا طلب؟» far more often than anything else — the
        // same reasoning that moved the money board above the status board on the home screen.
        //
        // There is no «معلومات الاتصال» card under it any more. It was a titled card, a border
        // and two labelled rows around two values that are one line each, and both of them now
        // sit where they are actually read: the phone under the name, the code in the corner —
        // see [_Identity]. A section is worth its frame when it groups things; this one wrapped
        // the identity in a second copy of itself.
        if (showsOrders) ...[
          BlocBuilder<CustomerOrderCountsCubit, CustomerOrderCountsState>(
            builder: (context, state) => CustomerOrdersSection(
              customerId: customer.id,
              customerName: customer.name,
              state: state,
              // Pushed over the shell, exactly as the home screen's cards are: this is a screen
              // the user is *in*, not a tab they are browsing.
              onOpen: (filter) => context.push(Routes.ordersFiltered, extra: filter),
            ),
          ),
          SizedBox(height: 14.h),
        ],

        // Only when there is one: every customer recorded before the address existed has none,
        // and «لا يوجد عنوان» on all of them would be a screen full of a sentence nobody acts on.
        if (customer.addressLabel case final address?) ...[
          _Section(
            title: 'العنوان',
            child: _CopyRow(
              icon: AppIcons.mapPin,
              label: 'تبدأ منه الطلبيات الجديدة',
              value: address,
              copiedMessage: 'تم نسخ العنوان',
              isLatin: false,
            ),
          ),
          SizedBox(height: 14.h),
        ],

        // Absent, not empty, when the API did not load them — «لا توجد محلات» about a customer
        // whose shops were simply not requested is a lie the model already refuses to tell.
        if (shops != null) _Shops(shops: shops),

        SizedBox(height: 14.h),
        _Meta(customer: customer),
      ],
    );
  }
}

/// العميلُ ومحفظتُه في بطاقةٍ واحدة أعلى الصفحة — بطلب صاحب العمل (٢٠٢٦-١٠-١٧): «خلّي رصيد
/// المحفظة وكود العميل ومعلوماته في بطاقة واحدة وهي بالأعلى».
///
/// من هو فوق، وما في محفظته تحته بعد خطٍّ رفيع. **ورصيدُ المحفظة غائبٌ لا صفر** لمن لا يملك قراءتها:
/// البطاقةُ عندئذٍ العميلُ وحده.
class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.customer, required this.showsWallet});

  final Customer customer;
  final bool showsWallet;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final hairline = scheme.outlineVariant.withValues(alpha: 0.6);

    return Material(
      key: CustomerDetailPage.headerKey,
      color: scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
        side: BorderSide(color: hairline),
      ),
      // يقصّ حبرَ لمسة سطر المحفظة على حوافّ البطاقة.
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(padding: EdgeInsets.all(14.w), child: _Identity(customer: customer)),
          if (showsWallet) ...[
            Divider(height: 1, thickness: 1, color: hairline),
            _WalletRow(customerId: customer.id, customerName: customer.name),
          ],
        ],
      ),
    );
  }
}

/// Who this is, in one row: the avatar, the name over the phone, and the code.
///
/// **It carries what the «معلومات الاتصال» card used to.** That card put a title, a border and a
/// row label around two values one line long each; here the phone reads directly under the name
/// — which is how somebody says it out loud — and the code takes the far corner, where a
/// three-character string is found without being read past.
///
/// Both are still tap-to-copy. That was the only thing the card did that the frame was not doing
/// for it, and it is the reason this screen exists on a phone at all: the number gets pasted
/// into WhatsApp, the code gets pasted into a message about an order.
class _Identity extends StatelessWidget {
  const _Identity({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isActive = customer.isActive;

    return Row(
      children: [
        CircleAvatar(
          radius: 30.r,
          backgroundColor: isActive ? scheme.primaryContainer : scheme.surfaceContainerHigh,
          child: Text(
            // The same first letter the list card shows, so the two read as the same person.
            customer.name.characters.firstOrNull ?? '؟',
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: isActive ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                customer.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 2.h),
              CopyText(
                value: customer.phone,
                copiedMessage: 'تم نسخ رقم الهاتف',
                icon: AppIcons.phone,
                style: context.textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 10.w),
        // Last child of an RTL row, so it lands in the far corner — not an alignment, which is
        // what stops it drifting when a long name grows. The same placement the list card gives
        // it, so the two screens agree on where a code is found.
        _CodeBadge(code: customer.code, isActive: isActive),
      ],
    );
  }
}

/// The customer's code, big enough to read across a counter.
///
/// **Bigger than it was, because it is what the customer is quoted by.** It used to be a line of
/// `labelLarge` under the name, competing with the name for the same edge; sized up and moved to
/// the corner it stops being read *through* on the way to something else.
class _CodeBadge extends StatelessWidget {
  const _CodeBadge({required this.code, required this.isActive});

  final String code;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final radius = BorderRadius.circular(16.r);

    return Material(
      color: isActive ? scheme.primaryContainer : scheme.surfaceContainerHigh,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: () {
          unawaited(Clipboard.setData(ClipboardData(text: code)));
          context.showSuccess('تم نسخ رمز العميل');
        },
        child: Container(
          height: 58.w,
          constraints: BoxConstraints(minWidth: 58.w, maxWidth: 108.w),
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          // Codes are 'C' + the row id, so they grow: C10 today, C1284 in two years. Scaled
          // down to fit rather than clipped — half a code is worse than a small one, because
          // «C12…» and «C128…» read as the same customer.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              code,
              // A Latin letter and digits: they read left-to-right even inside this RTL row.
              textDirection: TextDirection.ltr,
              style: context.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: isActive ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Whether this customer is being sold to — the one fact that changes what everything below it
/// means, so it is the only loud thing on the screen.
class _StatusBand extends StatelessWidget {
  const _StatusBand({required this.customer, required this.isChanging});

  final Customer customer;
  final bool isChanging;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isActive = customer.isActive;
    final canToggle = sl<Session>().can(AppPermission.manageCustomers);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isActive ? scheme.surfaceContainerLow : scheme.errorContainer,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          Icon(
            isActive ? AppIcons.activate : AppIcons.deactivate,
            size: 20.sp,
            color: isActive ? scheme.primary : scheme.onErrorContainer,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              isActive
                  ? 'عميل نشِط'
                  : 'هذا العميل موقوف — بياناته وطلبياته السابقة محفوظة، ويمكن تنشيطه في أي وقت.',
              style: context.textTheme.bodyMedium?.copyWith(
                color: isActive ? scheme.onSurface : scheme.onErrorContainer,
              ),
            ),
          ),
          // **The switch lives on the fact it changes.** Last child of an RTL row, so it lands
          // at the far end of the line it flips. While the request runs the spinner takes its
          // slot, which is also what stops a second tap; the slot's height is fixed so the
          // swap does not move the band.
          if (isChanging || canToggle) ...[
            SizedBox(width: 10.w),
            SizedBox(
              height: 32.h,
              child: isChanging
                  ? Center(
                      child: SizedBox(
                        height: 18.h,
                        width: 18.h,
                        child: const CircularProgressIndicator(strokeWidth: 2.2),
                      ),
                    )
                  : TextButton.icon(
                      onPressed: () => _toggleActive(context, customer),
                      icon: Icon(
                        isActive ? AppIcons.deactivate : AppIcons.activate,
                        size: 18.sp,
                      ),
                      label: Text(isActive ? 'تعطيل' : 'تنشيط'),
                      style: TextButton.styleFrom(
                        // Only the direction that takes something away wears the warning
                        // colour; on the red band the way back reads in the band's own ink.
                        foregroundColor: isActive ? scheme.error : scheme.onErrorContainer,
                        textStyle: context.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The two things done *to* this customer most: take an order, correct their details.
///
/// **On the page rather than in the dial**, side by side under the status band, because they are
/// why somebody opens a customer — a dial costs a tap and a search before every one of them.
/// Each is as wide as half the screen, or the whole of it when the other is not allowed.
class _MainActions extends StatelessWidget {
  const _MainActions({required this.customer});

  final Customer customer;

  /// Absent for a deactivated customer: this is somebody the shop has stopped selling to, and
  /// turning them back on is one tap away in the band above. `CreateOrder` refuses the request
  /// as well — a hidden button is a suggestion, a refused request is a rule.
  static bool _offersOrder(Customer customer) =>
      customer.isActive && sl<Session>().can(AppPermission.manageOrders);

  static bool _offersEdit() => sl<Session>().can(AppPermission.manageCustomers);

  /// Whether the row has anything in it, so the page does not keep a gap for an empty one.
  static bool showsAny(Customer customer) => _offersOrder(customer) || _offersEdit();

  @override
  Widget build(BuildContext context) {
    final offersOrder = _offersOrder(customer);
    final offersEdit = _offersEdit();

    return Row(
      children: [
        // **First, so it is read first in RTL, and filled, because this is where taking an
        // order begins.** The form it opens has no field for the customer: an order
        // does not change hands — the server reads `customer_id` on create and ignores it
        // afterwards — so the only correction for the wrong one is to cancel the order and take
        // it again. Naming the customer by *which screen you are on* is what makes the wrong one
        // unnameable. See NEW-ORDER-DESIGN.md §١.
        if (offersOrder)
          Expanded(
            child: AppButton(
              label: 'طلبية جديدة',
              icon: AppIcons.addOrder,
              onPressed: () =>
                  context.push(Routes.newCustomerOrder(customer.id), extra: customer),
            ),
          ),
        if (offersOrder && offersEdit) SizedBox(width: 10.w),
        if (offersEdit)
          Expanded(
            child: AppButton.tonal(
              label: 'تعديل العميل',
              icon: AppIcons.edit,
              onPressed: () => _edit(context, customer),
            ),
          ),
      ],
    );
  }
}

class _Shops extends StatelessWidget {
  const _Shops({required this.shops});

  final List<CustomerShop> shops;

  @override
  Widget build(BuildContext context) {
    // The count is in the heading because «المحلات» over nothing and «المحلات» over three cards
    // are different facts, and only one of them needs reading.
    return _Section(
      title: shops.isEmpty ? 'المحلات' : 'المحلات (${shops.length})',
      child: shops.isEmpty
          ? Text(
              'لا توجد محلات مسجّلة لهذا العميل',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            )
          : Column(
              children: [
                for (var index = 0; index < shops.length; index++) ...[
                  if (index > 0) Divider(height: 20.h),
                  _ShopRow(shop: shops[index]),
                ],
              ],
            ),
    );
  }
}

class _ShopRow extends StatelessWidget {
  const _ShopRow({required this.shop});

  final CustomerShop shop;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                shop.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            // مجال العمل beside the name, because it is what the name only hints at: «فرع سوق
            // الجمعة» says where, this says what they sell. Absent — not «غير محدد» — for the
            // shops recorded before the list existed: a row of nulls on every old customer
            // would be a screen full of a word that means nothing.
            if (shop.businessField case final field?) ...[
              SizedBox(width: 8.w),
              Text(
                '· ${field.name}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
        // «طرابلس · سوق الجمعة» — the address as somebody would say it out loud, which is the
        // whole reason it replaced a pair of coordinates nobody could read back.
        if (shop.placeLabel case final place?) ...[
          SizedBox(height: 6.h),
          _CopyRow(
            icon: AppIcons.mapPin,
            label: 'الموقع',
            value: place,
            copiedMessage: 'تم نسخ الموقع',
            isLatin: false,
          ),
        ],
        if (shop.pageUrl case final url? when url.isNotEmpty) ...[
          SizedBox(height: 6.h),
          _CopyRow(
            icon: AppIcons.tag,
            label: 'رابط الصفحة',
            value: url,
            copiedMessage: 'تم نسخ الرابط',
          ),
        ],
        if (shop.placeLabel == null) ...[
          SizedBox(height: 6.h),
          Text(
            // A shop whose city was deleted off the map, or one recorded before the form asked
            // for one. Saying so is what gets it fixed — opening the customer and saving is all
            // it takes.
            'لا توجد مدينة مسجّلة لهذا المحل',
            style: context.textTheme.bodySmall?.copyWith(color: scheme.tertiary),
          ),
        ],
      ],
    );
  }
}

/// A label, a value, and a way to get the value out of the app.
///
/// Copy rather than "call" or "open": there is no `url_launcher` in this project, and a row that
/// looks tappable and does nothing is worse than one that plainly copies.
class _CopyRow extends StatelessWidget {
  const _CopyRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.copiedMessage,
    this.isLatin = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final String copiedMessage;

  /// False for an Arabic value such as «طرابلس · سوق الجمعة»: forced left-to-right, its two
  /// halves swap places on screen.
  final bool isLatin;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return InkWell(
      onTap: () {
        unawaited(Clipboard.setData(ClipboardData(text: value)));
        context.showSuccess(copiedMessage);
      },
      borderRadius: BorderRadius.circular(10.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: Row(
          children: [
            Icon(icon, size: 18.sp, color: scheme.onSurfaceVariant),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    value,
                    // Latin runs — a phone number, a code, coordinates, a URL — read
                    // left-to-right even here.
                    textDirection: isLatin ? TextDirection.ltr : null,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Icon(AppIcons.copy, size: 16.sp, color: scheme.outline),
          ],
        ),
      ),
    );
  }
}

/// «رصيد المحفظة» في أسفل بطاقة العميل، واللمسةُ تفتح المحفظة — سجلّها والشحن والتعديل. يُعاد
/// الرصيد حين يعود منها وقد تحرّك فيها مال.
///
/// **الأيقونةُ في خانةٍ بعرض الصورة الرمزية فوقها**، فيبدأ «رصيد المحفظة» من حيث يبدأ الاسم: كتلةٌ
/// واحدة لا سطران متجاوران. ولا جملةَ تحت الرقم — السهمُ يقول إنه يُفتح.
class _WalletRow extends StatelessWidget {
  const _WalletRow({required this.customerId, required this.customerName});

  final int customerId;
  final String customerName;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return InkWell(
      onTap: () async {
        final cubit = context.read<CustomerWalletCubit>();
        final moved = await context.push<bool>(
          Routes.customerWallet(customerId),
          extra: customerName,
        );

        if (moved == true) await cubit.load();
      },
      child: Padding(
        padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 14.h),
        child: Row(
          children: [
            SizedBox(
              width: 60.r,
              child: Center(
                child: Container(
                  height: 44.w,
                  width: 44.w,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.secondaryContainer,
                  ),
                  child: Icon(AppIcons.wallet, size: 20.sp, color: scheme.onSecondaryContainer),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'رصيد المحفظة',
                    style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  SizedBox(height: 2.h),
                  BlocBuilder<CustomerWalletCubit, CustomerWalletState>(
                    builder: (context, state) => switch (state) {
                      CustomerWalletLoaded(:final balance) => Text(
                        '${balance.grouped} د.ل',
                        // أرقامٌ لاتينية: تُقرأ من اليسار حتى في هذا السطر العربي.
                        textDirection: TextDirection.ltr,
                        maxLines: 1,
                        style: context.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      CustomerWalletLoading() => Text(
                        'يُحمَّل…',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      CustomerWalletFailed() => Text(
                        'تعذّر تحميل الرصيد — اسحب للتحديث',
                        style: context.textTheme.bodySmall?.copyWith(color: scheme.error),
                      ),
                    },
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Icon(AppIcons.forward, size: 20.sp, color: scheme.outline),
          ],
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    final created = customer.createdAt;
    if (created == null) return const SizedBox.shrink();

    return Text(
      'أُضيف في ${created.dayLabel}',
      textAlign: TextAlign.center,
      style: context.textTheme.bodySmall?.copyWith(color: context.colorScheme.onSurfaceVariant),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: context.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: scheme.primary,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
          ),
          child: child,
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
