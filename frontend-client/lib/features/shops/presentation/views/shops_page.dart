import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/core/router/pop_result.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/widgets/app_button.dart';
import 'package:dayaa_client/core/widgets/app_dialog.dart';
import 'package:dayaa_client/features/shops/models/shop.dart';
import 'package:dayaa_client/features/shops/presentation/viewmodel/shops_cubit.dart';
import 'package:dayaa_client/features/shops/presentation/widgets/shop_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// «متاجري» — متاجر العميل، يضيف منها ما يشاء، ومنها تختار السلة وجهة الطلبية.
///
/// المتجر يُلمس فتُفتح صفحته — تفاصيله وتعديلها والتصاميم — وسلّة الحذف في طرفه خلف حوار تأكيد.
/// والقائمة تُرقَّع بما يعود من الصفحة ومن النموذج، ولا تُعاد قراءتها.
class ShopsPage extends StatelessWidget {
  const ShopsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ShopsCubit>(
      create: (_) => sl<ShopsCubit>()..load(),
      child: const _ShopsView(),
    );
  }
}

class _ShopsView extends StatelessWidget {
  const _ShopsView();

  /// متجرٌ جديد: النموذج فارغاً، وما يعود منه يُضاف آخر القائمة.
  Future<void> _add(BuildContext context) async {
    final added = await context.push<Shop>(Routes.shopForm);

    if (added == null || !context.mounted) return;

    context.read<ShopsCubit>().saved(added);
  }

  /// صفحة المتجر، وما عُدِّل فيها يعود مهما غودرت — بالسهم أو بالإيماءة.
  Future<void> _open(BuildContext context, Shop shop) async {
    final changed = await context.pushForResult<Shop>(Routes.shopDetails, extra: shop);

    if (changed == null || !context.mounted) return;

    context.read<ShopsCubit>().saved(changed);
  }

  Future<void> _remove(BuildContext context, Shop shop) async {
    final confirmed = await showDestructiveDialog(
      context: context,
      title: 'حذف المتجر',
      description: 'سيُحذف «${shop.name}» من متاجرك، وتبقى الطلبيات التي ذهبت إليه كما هي.',
    );

    if (confirmed != true || !context.mounted) return;

    await context.read<ShopsCubit>().remove(shop.id);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ShopsCubit, ShopsState>(
      listener: (context, state) {
        if (state case ShopsLoaded(:final lastFailure?)) context.showFailure(lastFailure);
      },
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('متاجري')),
        body: switch (state) {
          ShopsLoading() => const Center(child: CircularProgressIndicator()),
          ShopsFailure(:final failure) => Center(
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(failure.message, textAlign: TextAlign.center),
                  SizedBox(height: 16.h),
                  AppButton.outlined(
                    label: 'أعد المحاولة',
                    onPressed: context.read<ShopsCubit>().load,
                  ),
                ],
              ),
            ),
          ),
          ShopsLoaded(:final shops) when shops.isEmpty => Center(
            child: Text(
              'لم تُضف متجراً بعد',
              style: context.textTheme.bodyLarge?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ShopsLoaded(:final shops, :final isBusy) => ListView.separated(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
            itemCount: shops.length,
            separatorBuilder: (_, _) => SizedBox(height: 10.h),
            itemBuilder: (context, index) {
              final shop = shops[index];

              return ShopCard(
                shop: shop,
                onTap: isBusy ? null : () => _open(context, shop),
                trailing: IconButton(
                  icon: Icon(
                    AppIcons.delete,
                    size: 20.sp,
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                  tooltip: 'حذف',
                  onPressed: isBusy ? null : () => _remove(context, shop),
                ),
              );
            },
          ),
        },
        bottomNavigationBar: state is ShopsLoaded
            ? SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
                  child: AppButton(
                    label: 'أضف متجراً',
                    icon: AppIcons.add,
                    onPressed: () => _add(context),
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
