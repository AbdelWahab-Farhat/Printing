import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/core/theme/theme_mode_cubit.dart';
import 'package:dayaa_client/core/theme/theme_mode_sheet.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/widgets/app_card.dart';
import 'package:dayaa_client/core/widgets/app_dialog.dart';
import 'package:dayaa_client/features/auth/models/customer_account.dart';
import 'package:dayaa_client/features/auth/usecases/get_current_customer.dart';
import 'package:dayaa_client/features/auth/usecases/logout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// «حسابي».
///
/// **No Cubit, deliberately.** What this screen shows is one account that changes when the
/// account does — which is a sign-out. A ViewModel for it would be a stream nothing ever pushes
/// to, and the read is the same `auth/me` the home screen already makes.
///
/// **Three rows the design draws are absent, and each for its own reason**, rather than drawn
/// as buttons that do nothing:
///
/// * «المظهر» — the app has one appearance. A theme switch with a single option is a control
///   that exists to be disappointing.
/// * «الإشعارات» and «حذف الحساب» — neither endpoint exists. «حذف الحساب» is the one worth
///   naming twice: a destructive button that cannot destroy anything is worse than none, and
///   an account a customer believes they deleted is a promise the server never made.
///
/// **And «الحساب موثّق» is absent for a different reason.** `is_active` is not verification —
/// it is whether the shop still sells to this account — and drawing a green «موثّق» badge from
/// it would be the app inventing a status the business does not keep. Every account would wear
/// it, which makes it decoration.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  CustomerAccount? _customer;
  bool _isSigningOut = false;

  @override
  void initState() {
    super.initState();
    _read();
  }

  Future<void> _read() async {
    final result = await sl<GetCurrentCustomer>()();

    if (!mounted) return;

    result.fold((_) {}, (customer) => setState(() => _customer = customer));
  }

  Future<void> _signOut() async {
    final confirmed = await showDestructiveDialog(
      context: context,
      title: 'تسجيل الخروج؟',
      description: 'ستحتاج إلى رقم هاتفك وكلمة المرور للدخول مرة أخرى.',
      confirmLabel: 'خروج',
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isSigningOut = true);

    // **The result is not branched on.** Logout clears the token on this device either way; a
    // network failure means the server was not told, which is the server's problem to age out
    // and not a reason to keep somebody signed in to a phone they are handing back.
    await sl<Logout>()();

    if (!mounted) return;

    context.go(Routes.login);
  }

  @override
  Widget build(BuildContext context) {
    final customer = _customer;
    final shop = customer?.shop;

    return Scaffold(
      appBar: AppBar(
        title: const Text('حسابي'),
        // The design puts leaving in the bar rather than at the foot of a list somebody has to
        // scroll to. It is still behind a confirm dialog.
        leading: IconButton(
          icon: Icon(
            AppIcons.logout,
            color: _isSigningOut ? null : context.colorScheme.error,
          ),
          tooltip: 'تسجيل الخروج',
          onPressed: _isSigningOut ? null : _signOut,
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 32.h),
          children: [
            _Header(customer: customer, shop: shop),
            SizedBox(height: 24.h),

            if (customer != null) ...[
              // The number staff read back on the phone, so the customer has to be able to read
              // it out — and the trade, which is the one fact here the shop keeps about the
              // business rather than the person.
              if (customer.code case final code?)
                _FactRow(icon: AppIcons.customers, label: 'رقم العميل', value: code),
              _FactRow(icon: AppIcons.phone, label: 'رقم الهاتف', value: customer.phone),
              if (shop?.businessField case final field?)
                _FactRow(icon: AppIcons.businessField, label: 'مجال العمل', value: field),
              SizedBox(height: 22.h),
            ],

            // First of the three, because it is the only one that changes the app rather than
            // leaving it: «الدعم» and «سياسة الخصوصية» both take you somewhere else.
            // The singleton is read with an explicit `bloc:` rather than from the tree, exactly
            // as `CartButton` reads the basket: it has no scope, and a `BlocProvider.value` at
            // the top of this screen would be ceremony around something already global.
            BlocBuilder<ThemeModeCubit, ThemeMode>(
              bloc: sl<ThemeModeCubit>(),
              builder: (context, mode) => _ActionRow(
                icon: AppIcons.appearance,
                label: 'مظهر التطبيق',
                // The row says what the app is wearing without being opened, which is most of
                // why somebody taps it — to check, not to change.
                value: mode.label,
                onTap: () => showThemeModeSheet(context).ignore(),
              ),
            ),
            SizedBox(height: 10.h),
            _ActionRow(
              icon: AppIcons.comments,
              label: 'تواصل مع الدعم',
              // **`push`, never `go`.** «الدعم» is not a tab any more — it is pushed over
              // whatever you were doing — and `go` replaces the stack, which leaves the
              // support screen with nothing to go back to.
              onTap: () => context.push(Routes.support),
            ),
            SizedBox(height: 10.h),
            _ActionRow(
              icon: AppIcons.about,
              label: 'سياسة الخصوصية',
              onTap: () => context.showInfo('ستتوفر قريباً'),
            ),
          ],
        ),
      ),
    );
  }
}

/// The avatar, the name, and where the customer trades from.
class _Header extends StatelessWidget {
  const _Header({required this.customer, required this.shop});

  final CustomerAccount? customer;
  final CustomerShop? shop;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final name = customer?.name;

    // «متجر النور · بنغازي», or whichever half of it the account has. A shop with no city still
    // has a name worth drawing.
    final where = [?shop?.name, ?shop?.cityName].join(' · ');

    return Column(
      children: [
        Container(
          height: 94.w,
          width: 94.w,
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(color: scheme.primary, width: 2.w),
          ),
          child: Icon(AppIcons.person, color: scheme.primary, size: 42.sp),
        ),
        SizedBox(height: 14.h),
        Text(
          // A placeholder rather than an empty line while the read is in flight: the column
          // keeps its height, so nothing under it jumps when the name lands.
          name ?? '…',
          textAlign: TextAlign.center,
          style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        if (where.isNotEmpty) ...[
          SizedBox(height: 10.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(999.r),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Text(
              where,
              style: context.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// One labelled fact, in its own card as the design draws it.
class _FactRow extends StatelessWidget {
  const _FactRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: AppCard(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
        child: Row(
          children: [
            _Glyph(icon: icon),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                label,
                style: context.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            Text(
              value,
              // A phone number and a customer code read left to right even here.
              textDirection: TextDirection.ltr,
              style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.value,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// What the row is currently set to, drawn before the chevron.
  ///
  /// Null for a row that goes somewhere rather than holds something — «تواصل مع الدعم» has no
  /// value, and a blank space where one would be is not the same as having none.
  final String? value;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
      child: Row(
        children: [
          _Glyph(icon: icon),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              label,
              style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (value case final value?) ...[
            Text(
              value,
              style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            SizedBox(width: 8.w),
          ],
          Icon(AppIcons.forward, size: 16.sp, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

/// The rounded tile every row on this screen carries on its leading edge.
class _Glyph extends StatelessWidget {
  const _Glyph({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      width: 40.w,
      height: 40.w,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(13.r),
      ),
      child: Icon(icon, size: 19.sp, color: scheme.primary),
    );
  }
}
