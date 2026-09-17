import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/features/auth/models/customer_account.dart';
import 'package:dayaa_client/features/auth/usecases/get_current_customer.dart';
import 'package:dayaa_client/features/badges/models/customer_badge.dart';
import 'package:dayaa_client/features/badges/presentation/viewmodel/badges_cubit.dart';
import 'package:dayaa_client/features/badges/presentation/views/badge_count.dart';
import 'package:dayaa_client/features/billboards/presentation/viewmodel/billboard_cubit.dart';
import 'package:dayaa_client/features/billboards/presentation/views/billboard_carousel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// The screen the app opens on: who you are, what the shop is showing, and the way into
/// everything else.
///
/// **Three groups, following the design**: the brand card, «الخدمات», and «المتاجر». The flat
/// grid this replaced gave «تصاميمي» and «الدعم» the same weight as «اطلب أكياسك», which is the
/// one thing a customer opens this app to do.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BillboardCubit>(
      create: (_) => sl<BillboardCubit>()..load(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  CustomerAccount? _customer;

  @override
  void initState() {
    super.initState();
    _readCustomer();
  }

  Future<void> _readCustomer() async {
    final result = await sl<GetCurrentCustomer>()();

    if (!mounted) return;

    // **A greeting that failed is simply not drawn.** The home screen is perfectly usable
    // without a name on it, and «مرحباً» alone is warmer than an error where a name should be.
    result.fold((_) {}, (customer) => setState(() => _customer = customer));
  }

  @override
  Widget build(BuildContext context) {
    final name = _customer?.name;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              context.read<BillboardCubit>().load(),
              _readCustomer(),
              // **The one way to learn of a reply without leaving the app.** The badge is
              // otherwise fetched on launch and on resume only, so an app left open on this
              // screen would never hear that the shop had answered. Pulling down is the
              // gesture people already make when they want to know if anything is new.
              context.read<BadgesCubit>().refresh(),
            ]);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
            children: [
              _Greeting(
                name: name,
                code: _customer?.code,
                shop: _customer?.shop,
              ),
              SizedBox(height: 18.h),

              const _BrandCard(),
              SizedBox(height: 14.h),

              const BillboardCarousel(),

              SizedBox(height: 22.h),
              const _SectionHeading('الخدمات'),
              SizedBox(height: 12.h),

              // The one thing a customer opens this app to do, given the width to say so.
              _HeroCard(
                title: 'اطلب أكياسك',
                caption: 'اختر المقاس والكمية، وسعرك يظهر فوراً',
                onTap: () => context.go(Routes.products),
              ),
              SizedBox(height: 12.h),

              Row(
                children: [
                  Expanded(
                    child: _ServiceTile(
                      icon: AppIcons.designs,
                      label: 'تصاميمي',
                      onTap: () => context.go(Routes.designs),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _ServiceTile(
                      icon: AppIcons.qrCode,
                      label: 'الأدوات',
                      // Pushed, not `go`: the tools belong to no tab.
                      onTap: () => context.push(Routes.qrTool),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    // **The only badged tile for now.** «تصاميمي» and «الأدوات» have nothing
                    // waiting in them — a badge is something the shop is holding for the
                    // customer, not a count of what they own.
                    child: BadgedTile(
                      badge: CustomerBadge.support,
                      child: _ServiceTile(
                        icon: AppIcons.comments,
                        label: 'الدعم',
                        onTap: () => context.push(Routes.support),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 22.h),
              const _SectionHeading('المتاجر'),
              SizedBox(height: 12.h),

              Row(
                children: [
                  Expanded(
                    child: _StoreTile(
                      icon: AppIcons.products,
                      label: 'متجر المنتجات',
                      onTap: () => context.go(Routes.products),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  // **«قريباً», and it is honest.** Prepaid cards are a decided *not yet* — the
                  // supply model and the money model are both open questions, see the design
                  // doc §٩. Saying so is better than the section not existing: a customer who
                  // was told about the cards has somewhere to look.
                  Expanded(
                    child: _StoreTile(
                      icon: AppIcons.payment,
                      label: 'متجر الكروت',
                      badge: 'قريباً',
                      onTap: null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The bar the app opens with: who you are, and the number you read out when you ring.
///
/// **No notification bell.** The design draws one, with an orange dot on it. There is no
/// notifications endpoint and no screen behind it, so a bell here would be a button whose only
/// behaviour is to disappoint — and a dot that is always lit is worse, because it teaches people
/// to ignore the one that will mean something later.
class _Greeting extends StatelessWidget {
  const _Greeting({required this.name, required this.code, required this.shop});

  final String? name;
  final String? code;
  final CustomerShop? shop;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    // «متجر النور · بنغازي» when the account has a shop, and the app's own line when it does
    // not: a second line that vanishes would make the bar change height once the read lands.
    final under = [?shop?.name, ?shop?.cityName];

    return Row(
      children: [
        Container(
          height: 46.w,
          width: 46.w,
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            shape: BoxShape.circle,
            border: Border.all(color: scheme.primary, width: 1.5.w),
          ),
          child: Icon(AppIcons.person, color: scheme.primary, size: 22.sp),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name == null ? 'مرحباً' : 'مرحباً $name',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                under.isEmpty ? 'عميل لدى دعاية' : under.join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        // The customer's own code, which is what they read out when they ring. Drawn only once
        // it has arrived — a placeholder box would be a number that is not theirs.
        if (code case final code?) ...[
          SizedBox(width: 10.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(999.r),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Text(
              code,
              textDirection: TextDirection.ltr,
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

/// What the shop is and what it sells, in one card — the design opens on this.
class _BrandCard extends StatelessWidget {
  const _BrandCard();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.printedProduct, size: 22.sp, color: scheme.primary),
              SizedBox(width: 8.w),
              Text(
                'FlyerX',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            'أكياس شحن فلاير · إغلاق مُحكم · فتح لمرة واحدة',
            style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: const [
              _Pill('جملة وتجزئة'),
              _Pill('طباعة بالشعار'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Text(
        label,
        style: context.textTheme.labelSmall?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
  );
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.title, required this.caption, required this.onTap});

  final String title;
  final String caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Material(
      color: scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          padding: EdgeInsets.all(18.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      caption,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              Container(
                height: 40.w,
                width: 40.w,
                decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
                // `forward`, which Flutter mirrors under RTL to point left — the way this
                // language reads onward. `back` would point right, at where you came from.
                child: Icon(AppIcons.forward, color: scheme.onPrimary, size: 18.sp),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Material(
      color: scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            children: [
              Icon(icon, size: 24.sp, color: scheme.primary),
              SizedBox(height: 8.h),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.labelLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoreTile extends StatelessWidget {
  const _StoreTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;

  /// Null makes the tile inert — «قريباً» is not a thing to tap.
  final VoidCallback? onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isComingSoon = onTap == null;

    return Opacity(
      opacity: isComingSoon ? 0.6 : 1,
      child: Material(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  size: 24.sp,
                  color: isComingSoon ? scheme.onSurfaceVariant : scheme.primary,
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.labelLarge,
                      ),
                    ),
                    if (badge case final badge?) ...[
                      SizedBox(width: 6.w),
                      _Pill(badge),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
