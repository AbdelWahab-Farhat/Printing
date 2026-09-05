import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_speed_dial.dart';
import 'package:dayaa/features/customers/models/customer.dart';
import 'package:dayaa/features/customers/presentation/viewmodel/customers_cubit.dart';
import 'package:dayaa/features/customers/presentation/views/customers_page.dart';
import 'package:dayaa/features/investors/presentation/viewmodel/investors_cubit.dart';
import 'package:dayaa/features/investors/presentation/views/investors_page.dart';
import 'package:dayaa/features/vendors/presentation/viewmodel/vendors_cubit.dart';
import 'package:dayaa/features/vendors/presentation/views/vendors_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// The three registers of people the business deals with, under one tab.
///
/// **One screen because they are one question asked three ways: «مين؟»** — who buys, who sells to
/// us, and whose money is in the stock. Two of the three used to live behind the drawer, which
/// put a supplier further away than the settings screen, and made «هل هو مورد أم عميل؟» a
/// question you answered by navigating rather than by swiping.
///
/// **The three Cubits are provided here, above the tabs**, and that is load-bearing rather than
/// tidy: the «إضافة» dial belongs to this screen, so it has to be able to put the customer the
/// form just registered into the list one tab over.
///
/// **The tabs are only the ones this reader may open.** A tab the server answers with 403 is a
/// tab nobody should be able to swipe onto, and an empty list under it would read as «لا يوجد
/// موردون» — which is a different and wrong sentence.
class PartiesPage extends StatelessWidget {
  const PartiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<CustomersCubit>(create: (_) => sl<CustomersCubit>()..load()),
        BlocProvider<VendorsCubit>(create: (_) => sl<VendorsCubit>()..load()),
        BlocProvider<InvestorsCubit>(create: (_) => sl<InvestorsCubit>()..load()),
      ],
      child: const _PartiesView(),
    );
  }
}

/// One register: what it is called, what it shows, and what «إضافة» does on it.
class _Register {
  const _Register({
    required this.label,
    required this.icon,
    required this.body,
    required this.addLabel,
    required this.readPermission,
    required this.addPermission,
    required this.onAdd,
  });

  final String label;
  final IconData icon;
  final Widget body;
  final String addLabel;

  /// Whether the tab appears at all.
  final AppPermission readPermission;

  /// Whether the dial offers it. Separate, because reading a register and writing to it are two
  /// grants — a clerk who may look up a supplier is not thereby allowed to invent one.
  final AppPermission addPermission;

  final Future<void> Function(BuildContext context) onAdd;
}

class _PartiesView extends StatelessWidget {
  const _PartiesView();

  /// Registers the customer and puts them at the top of the list.
  ///
  /// Here rather than in [CustomersBody] because the button that starts it is here — the same
  /// reason `addVendor` and `addInvestor` are top-level in their own files.
  static Future<void> _addCustomer(BuildContext context) async {
    final cubit = context.read<CustomersCubit>();

    final created = await context.push<Customer>(Routes.addCustomer);

    if (created != null) cubit.insert(created);
  }

  @override
  Widget build(BuildContext context) {
    final session = sl<Session>();

    // `final`, not `const`: [AppIcons] resolves a Material or a Cupertino glyph at runtime, so
    // the platform gets its own icon rather than Android's on both.
    final registers = [
      _Register(
        label: 'العملاء',
        icon: AppIcons.addCustomer,
        body: const CustomersBody(),
        addLabel: 'إضافة عميل',
        readPermission: AppPermission.viewCustomers,
        addPermission: AppPermission.manageCustomers,
        onAdd: _addCustomer,
      ),
      _Register(
        label: 'الموردون',
        icon: AppIcons.addVendor,
        body: const VendorsBody(),
        addLabel: 'إضافة مورد',
        readPermission: AppPermission.viewVendors,
        addPermission: AppPermission.manageVendors,
        onAdd: addVendor,
      ),
      _Register(
        label: 'المستثمرون',
        icon: AppIcons.investors,
        body: const InvestorsBody(),
        addLabel: 'إضافة مستثمر',
        readPermission: AppPermission.viewInvestors,
        addPermission: AppPermission.manageInvestors,
        onAdd: addInvestor,
      ),
    ];

    final visible = [
      for (final register in registers)
        if (session.can(register.readPermission)) register,
    ];

    // Nothing to show is not a state this screen can reach — the tab itself carries
    // `customers.view` — but a zero-length TabController is an assertion rather than an empty
    // screen, so it is answered here instead of crashing.
    if (visible.isEmpty) return const SizedBox.shrink();

    return DefaultTabController(
      length: visible.length,
      child: Scaffold(
        // Transparent: the shell's Scaffold underneath already paints the background, and a
        // second opaque one here would hide it.
        backgroundColor: Colors.transparent,
        floatingActionButtonLocation: AppSpeedDial.location,
        floatingActionButton: AppSpeedDial(
          actions: [
            for (final register in visible)
              AppAction(
                label: register.addLabel,
                icon: register.icon,
                tone: AppActionTone.primary,
                permission: register.addPermission,
                onTap: register.onAdd,
              ),
          ],
        ),
        body: Column(
          children: [
            // Only when there is a choice to make. One register left is a list, and a tab bar
            // over a single tab is a control that cannot do anything.
            if (visible.length > 1) _Tabs(registers: visible),
            Expanded(
              child: TabBarView(
                children: [for (final register in visible) register.body],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.registers});

  final List<_Register> registers;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return TabBar(
      // Sized to the screen rather than scrolling: three short words fit, and a bar that can be
      // scrolled hides the tab at its end from anybody who never drags it.
      isScrollable: false,
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: scheme.outlineVariant.withValues(alpha: 0.5),
      labelColor: scheme.primary,
      unselectedLabelColor: scheme.onSurfaceVariant,
      labelStyle: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
      unselectedLabelStyle: context.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      tabs: [for (final register in registers) Tab(height: 44.h, text: register.label)],
    );
  }
}
