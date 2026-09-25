import 'dart:async';

import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/core/router/pop_result.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/widgets/app_button.dart';
import 'package:dayaa_client/core/widgets/app_card.dart';
import 'package:dayaa_client/features/designs/presentation/viewmodel/designs_cubit.dart';
import 'package:dayaa_client/features/designs/presentation/widgets/design_library.dart';
import 'package:dayaa_client/features/shops/models/shop.dart';
import 'package:dayaa_client/features/shops/presentation/viewmodel/shop_details_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// صفحة متجرٍ واحد: تفاصيله كما في بطاقة المحل عند الموظفين، وتعديلها، ثم مكتبة التصاميم.
///
/// **التصاميم على الحساب لا على المتجر** — قرار صاحب العمل حين سُئل، وقرار الجدول من أوله: شعارٌ
/// واحد لكل الفروع. فالمكتبة هنا هي «تصاميمي» نفسها، تُعدَّل من أيّ متجرٍ فتتعدّل في كلّها.
///
/// **وما يتغيّر هنا يعود إلى «متاجري» مهما غودرت الصفحة** — بالسهم أو بالإيماءة — عبر `handBack`،
/// فتضعه القائمة في مكانه بلا طلبٍ ثانٍ.
class ShopDetailsPage extends StatelessWidget {
  const ShopDetailsPage({required this.shop, super.key});

  final Shop shop;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ShopDetailsCubit>(create: (_) => ShopDetailsCubit(shop)),
        // المكتبة نفسها التي في «تصاميمي»، بـ Cubit الشاشة نفسه وأفعاله.
        BlocProvider<DesignsCubit>(create: (_) => sl<DesignsCubit>()..load()),
      ],
      child: const _ShopDetailsView(),
    );
  }
}

class _ShopDetailsView extends StatelessWidget {
  const _ShopDetailsView();

  Future<void> _edit(BuildContext context) async {
    final cubit = context.read<ShopDetailsCubit>();

    final saved = await context.push<Shop>(Routes.shopForm, extra: cubit.state);

    if (saved == null || !context.mounted) return;

    cubit.edited(saved);
    context.handBack(saved);
  }

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<ShopDetailsCubit>().state;

    return Scaffold(
      appBar: AppBar(title: Text(shop.name)),
      body: SafeArea(
        top: false,
        child: BlocConsumer<DesignsCubit, DesignsState>(
          // كتابةٌ فشلت في المكتبة تُقال بجانب مكتبةٍ ما زالت على الشاشة.
          listener: (context, state) {
            if (state case DesignsLoaded(:final lastFailure?)) context.showFailure(lastFailure);
          },
          builder: (context, library) => CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
                sliver: SliverList.list(
                  children: [
                    _ShopInfoCard(shop: shop),
                    SizedBox(height: 12.h),
                    AppButton.tonal(
                      label: 'تعديل تفاصيل المتجر',
                      icon: AppIcons.edit,
                      onPressed: () => _edit(context),
                    ),
                    SizedBox(height: 24.h),
                    Text(
                      'التصاميم',
                      style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 10.h),
                  ],
                ),
              ),
              ..._designs(context, library),
            ],
          ),
        ),
      ),
    );
  }

  /// مكتبة التصاميم بحالاتها: تحميلٌ، وفشلٌ له «أعد المحاولة»، والشبكة وزرّ الإضافة تحتها.
  List<Widget> _designs(BuildContext context, DesignsState library) {
    final padding = EdgeInsets.symmetric(horizontal: 16.w);

    return switch (library) {
      DesignsLoading() => [
        SliverPadding(
          padding: EdgeInsets.all(24.w),
          sliver: const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
        ),
      ],
      DesignsFailure(:final failure) => [
        SliverPadding(
          padding: padding,
          sliver: SliverList.list(
            children: [
              Text(failure.message, textAlign: TextAlign.center),
              SizedBox(height: 12.h),
              AppButton.outlined(
                label: 'أعد المحاولة',
                onPressed: context.read<DesignsCubit>().load,
              ),
            ],
          ),
        ),
      ],
      DesignsLoaded(:final designs, :final isBusy) => [
        if (designs.isNotEmpty)
          SliverPadding(
            padding: padding,
            // معتمةٌ أثناء الكتابة، والشبكة باقية — كما في «تصاميمي».
            sliver: SliverOpacity(
              opacity: isBusy ? 0.6 : 1,
              sliver: SliverDesignGrid(designs: designs),
            ),
          ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
          sliver: SliverToBoxAdapter(
            child: AppButton.tonal(
              label: 'أضف تصميماً',
              icon: AppIcons.add,
              isLoading: isBusy,
              onPressed: () => addDesign(context),
            ),
          ),
        ),
      ],
    };
  }
}

/// تفاصيل المتجر، صفّاً لكل حقلٍ من حقول بطاقة المحل: مجال العمل، والموقع، ورابط الصفحة.
///
/// **ما لم يُسجَّل يُقال لا يُخفى.** صفحة متجرٍ تعرض حقلين وتسكت عن الثالث تُقرأ كأنها لم تكتمل،
/// و«غير محدد» تقول إن الخانة فارغة وإن «تعديل» هو ما يملؤها.
class _ShopInfoCard extends StatelessWidget {
  const _ShopInfoCard({required this.shop});

  final Shop shop;

  @override
  Widget build(BuildContext context) {
    final link = shop.pageUrl;

    return AppCard(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InfoRow(
            icon: AppIcons.businessField,
            label: 'مجال العمل',
            value: shop.businessFieldName ?? 'غير محدد',
            isEmpty: shop.businessFieldName == null,
          ),
          _InfoRow(
            icon: AppIcons.mapPin,
            label: 'الموقع',
            value: shop.place.isEmpty ? 'لا توجد مدينة مسجّلة' : shop.place,
            isEmpty: shop.place.isEmpty,
          ),
          _InfoRow(
            icon: AppIcons.tag,
            label: 'رابط الصفحة',
            value: link ?? 'لا يوجد',
            isEmpty: link == null,
            // الرابط يُنسخ بلمسة، كما في بطاقة المحل عند الموظفين: هو ما يُرسل في محادثة.
            copyable: link != null,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isEmpty = false,
    this.copyable = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isEmpty;
  final bool copyable;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    final row = Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Icon(icon, size: 20.sp, color: scheme.onSurfaceVariant),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  // الرابط يُقرأ من اليسار حتى في صفٍّ عربي.
                  textDirection: copyable ? TextDirection.ltr : null,
                  textAlign: copyable ? TextAlign.end : null,
                  style: context.textTheme.bodyLarge?.copyWith(
                    fontWeight: isEmpty ? FontWeight.w400 : FontWeight.w600,
                    color: isEmpty ? scheme.onSurfaceVariant : scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          if (copyable) ...[
            SizedBox(width: 8.w),
            Icon(AppIcons.copy, size: 16.sp, color: scheme.outline),
          ],
        ],
      ),
    );

    if (!copyable) return row;

    return InkWell(
      borderRadius: BorderRadius.circular(10.r),
      onTap: () {
        unawaited(Clipboard.setData(ClipboardData(text: value)));
        context.showSuccess('تم نسخ الرابط');
      },
      child: row,
    );
  }
}
