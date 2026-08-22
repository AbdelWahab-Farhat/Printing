import 'package:cached_network_image/cached_network_image.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/files/attachment_picker.dart';
import 'package:dayaa/core/files/picked_file.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_dialog.dart';
import 'package:dayaa/core/widgets/app_speed_dial.dart';
import 'package:dayaa/core/widgets/attachment_sheet.dart';
import 'package:dayaa/features/products/models/product.dart';
import 'package:dayaa/features/products/models/product_image_rules.dart';
import 'package:dayaa/features/products/presentation/viewmodel/product_images_cubit.dart';
import 'package:dayaa/features/products/presentation/widgets/product_gallery.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A product's photographs — the only place they can be changed after it is created.
///
/// **A screen of its own rather than a field on the form, and that is the whole design.** A form
/// gathers changes and writes them when «حفظ» is pressed; an upload writes the moment it
/// finishes. Putting the two together means «رجوع» leaves a product whose pictures already
/// changed — a form lying about what it did. Here every action commits when it is tapped, which
/// is what it actually does.
///
/// Reading needs `products.view`, which is what reached the product at all. Adding, promoting
/// and deleting need `products.manage`; without it the grid is the whole screen and there are no
/// buttons — absent, not greyed.
class ProductImagesPage extends StatelessWidget {
  const ProductImagesPage({required this.productId, this.productName, super.key});

  final int productId;

  /// Whose photographs these are, so the bar can say it without a second request. Null on a
  /// cold deep link, where the heading stands alone.
  final String? productName;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProductImagesCubit>(
      create: (_) => sl<ProductImagesCubit>(param1: productId)..load(),
      child: _ImagesView(productName: productName),
    );
  }
}

class _ImagesView extends StatelessWidget {
  const _ImagesView({this.productName});

  final String? productName;

  /// Asks where the photograph is coming from, opens that picker, and sends what came back.
  ///
  /// **The cap is checked before the sheet opens.** The server refuses the sixth photograph
  /// *after* its bytes have arrived; saying so first spares an upload that was never going to
  /// be kept — the same courtesy the designs library pays.
  ///
  /// Three awaits with a `mounted` check between each, because every one of them is a screen
  /// the user can sit in for a minute — the camera especially — and this one can be popped
  /// while they are there.
  Future<void> _addImage(BuildContext context) async {
    final cubit = context.read<ProductImagesCubit>();

    if (!cubit.state.hasRoomForMore) {
      context.showError(
        'وصل هذا المنتج إلى الحد الأقصى (${ProductImageRules.maxPerProduct} صور). '
        'احذف صورة قديمة لإضافة جديدة.',
      );

      return;
    }

    // The document browser is left out: a product photograph comes off the camera roll or the
    // camera, and that browser's whole purpose is the PDFs this endpoint refuses.
    final source = await showAttachmentSheet(
      context: context,
      sources: const [AttachmentSource.photos, AttachmentSource.camera],
    );
    if (source == null || !context.mounted) return;

    final files = await sl<AttachmentPicker>().pick(source);
    // Cancelling a picker is not a failure and nothing is said about it.
    if (files.isEmpty || !context.mounted) return;

    await _send(context, cubit, files);
  }

  /// Sends the chosen photographs one after another, stopping at the first refusal.
  ///
  /// Sequential rather than concurrent: the cap is five, so this is at most a handful, and two
  /// uploads sharing one uplink means two that crawl. Stopping at the first failure is the
  /// honest reading of a refusal — a full product refuses every one after it too, and five
  /// identical toasts say nothing the first did not.
  Future<void> _send(
    BuildContext context,
    ProductImagesCubit cubit,
    List<PickedFile> files,
  ) async {
    var sent = 0;

    for (final file in files) {
      // Re-read after every upload: the cap is counted against a list that just grew.
      if (!cubit.state.hasRoomForMore) {
        if (context.mounted) {
          context.showError(
            'رُفعت $sent من ${files.length}. الباقي يتجاوز الحد الأقصى '
            '(${ProductImageRules.maxPerProduct} صور).',
          );
        }

        return;
      }

      final failure = await cubit.add(file);
      if (!context.mounted) return;

      if (failure != null) {
        context.showFailure(failure);

        return;
      }

      sent++;
    }

    if (context.mounted) context.showSuccess(sent == 1 ? 'تمت إضافة الصورة' : 'تمت إضافة $sent صور');
  }

  Future<void> _makePrimary(BuildContext context, int imageId) async {
    final failure = await context.read<ProductImagesCubit>().makePrimary(imageId);
    if (!context.mounted) return;

    if (failure != null) {
      context.showFailure(failure);

      return;
    }

    context.showSuccess('صارت هذه الصورة الرئيسية');
  }

  Future<void> _delete(BuildContext context, ProductImage image) async {
    final confirmed = await showDestructiveDialog(
      context: context,
      title: 'حذف هذه الصورة؟',
      // Said plainly, because it is the one thing here that cannot be taken back: the row is
      // soft-deleted like every record in this app, but the file itself is removed for good.
      description: 'تُحذف الصورة نهائياً ولا يمكن استرجاعها.',
    );

    if (confirmed != true || !context.mounted) return;

    final failure = await context.read<ProductImagesCubit>().remove(image.id);
    if (!context.mounted) return;

    if (failure != null) {
      // The server's own Arabic — most often «لا يمكن حذف الصورة الوحيدة», which is a rule this
      // app deliberately does not restate in its own words.
      context.showFailure(failure);

      return;
    }

    context.showSuccess('تم حذف الصورة');
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProductImagesCubit>();
    final canManage = sl<Session>().can(AppPermission.manageProducts);

    return BlocBuilder<ProductImagesCubit, ProductImagesState>(
      builder: (context, state) => Scaffold(
        floatingActionButtonLocation: AppSpeedDial.location,
        appBar: AppBar(
          title: Column(
            children: [
              const Text('صور المنتج'),
              if (productName != null)
                Text(
                  productName!,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          // The bar carries the count, because «كم صورة بقيت لي؟» is the question the cap makes
          // people ask, and a number is a shorter answer than discovering the refusal.
          bottom: state is ProductImagesLoaded
              ? PreferredSize(
                  preferredSize: Size.fromHeight(state.isUploading ? 22.h : 4.h),
                  child: Column(
                    children: [
                      if (state.isUploading)
                        Padding(
                          padding: EdgeInsets.only(bottom: 6.h),
                          child: LinearProgressIndicator(value: state.uploadProgress),
                        ),
                      SizedBox(height: 2.h),
                    ],
                  ),
                )
              : null,
        ),
        floatingActionButton: AppSpeedDial(
          actions: [
            AppAction(
              label: 'إضافة صورة',
              icon: AppIcons.add,
              tone: AppActionTone.primary,
              permission: AppPermission.manageProducts,
              onTap: _addImage,
            ),
          ],
        ),
        body: switch (state) {
          ProductImagesLoading() => const Center(child: CircularProgressIndicator()),
          ProductImagesFailure(:final failure) => _FailureView(
            message: failure.message,
            onRetry: cubit.load,
          ),
          ProductImagesLoaded() => RefreshIndicator(
            onRefresh: cubit.load,
            child: _Grid(
              state: state,
              canManage: canManage,
              onMakePrimary: (image) => _makePrimary(context, image.id),
              onDelete: (image) => _delete(context, image),
            ),
          ),
        },
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({
    required this.state,
    required this.canManage,
    required this.onMakePrimary,
    required this.onDelete,
  });

  final ProductImagesLoaded state;
  final bool canManage;
  final void Function(ProductImage image) onMakePrimary;
  final void Function(ProductImage image) onDelete;

  @override
  Widget build(BuildContext context) {
    // The primary first, then the rest exactly as the server sent them — the same order the
    // product screen's gallery uses, and the same function, so the two can never disagree.
    final ordered = galleryOrder(state.images);

    return CustomScrollView(
      // `always`, so pull-to-refresh works on a short page too.
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (ordered.isEmpty)
          const SliverFillRemaining(hasScrollBody: false, child: _NoPhotographs())
        else ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 0),
              child: Text(
                '${ordered.length} من ${ProductImageRules.maxPerProduct} صور',
                style: context.textTheme.labelMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 96.h),
            sliver: SliverGrid.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12.h,
                crossAxisSpacing: 12.w,
                // Taller than square: the photograph is the square, and the two buttons live
                // under it rather than over the picture — which is the one thing on the tile
                // that must not be covered.
                childAspectRatio: canManage ? 0.74 : 1,
              ),
              itemCount: ordered.length,
              itemBuilder: (context, index) => _PhotoTile(
                key: ValueKey(ordered[index].id),
                image: ordered[index],
                canManage: canManage,
                isBusy: state.busy.contains(ordered[index].id),
                onMakePrimary: () => onMakePrimary(ordered[index]),
                onDelete: () => onDelete(ordered[index]),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// One photograph: the picture, whether it is the primary, and what may be done to it.
class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.image,
    required this.canManage,
    required this.isBusy,
    required this.onMakePrimary,
    required this.onDelete,
    super.key,
  });

  final ProductImage image;
  final bool canManage;
  final bool isBusy;
  final VoidCallback onMakePrimary;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final radius = BorderRadius.circular(12.r);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: radius,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: image.url,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => ColoredBox(color: scheme.surfaceContainerHigh),
                  errorWidget: (context, url, error) => ColoredBox(
                    color: scheme.surfaceContainerHigh,
                    child: Center(child: Icon(AppIcons.error, color: scheme.onSurfaceVariant)),
                  ),
                ),
                if (image.isPrimary)
                  Positioned(
                    top: 6.h,
                    right: 6.w,
                    child: const _PrimaryBadge(),
                  ),
                // Over the picture rather than replacing the tile: a promotion takes a moment
                // and the photograph it is about should stay visible while it does.
                if (isBusy)
                  ColoredBox(
                    color: scheme.scrim.withValues(alpha: 0.45),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
        ),
        if (canManage) ...[
          SizedBox(height: 4.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Absent on the primary rather than disabled: «اجعلها الرئيسية» on the photograph
              // that already is one is a button that can only do nothing.
              if (!image.isPrimary)
                IconButton(
                  tooltip: 'اجعلها الرئيسية',
                  onPressed: isBusy ? null : onMakePrimary,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(AppIcons.makePrimary, size: 20.sp, color: scheme.onSurfaceVariant),
                ),
              IconButton(
                tooltip: 'حذف الصورة',
                onPressed: isBusy ? null : onDelete,
                visualDensity: VisualDensity.compact,
                icon: Icon(AppIcons.delete, size: 20.sp, color: scheme.error),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// «الرئيسية» — a word, not a coloured border on its own.
class _PrimaryBadge extends StatelessWidget {
  const _PrimaryBadge();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        'الرئيسية',
        style: context.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

/// Only reachable for a product from before a photograph was required — or one whose images
/// failed to come back with it.
class _NoPhotographs extends StatelessWidget {
  const _NoPhotographs();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Text(
          'لا توجد صور لهذا المنتج',
          textAlign: TextAlign.center,
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
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
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center, style: context.textTheme.bodyMedium),
            SizedBox(height: 12.h),
            FilledButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
          ],
        ),
      ),
    );
  }
}
