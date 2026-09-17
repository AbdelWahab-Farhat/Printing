import 'package:cached_network_image/cached_network_image.dart';
import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/features/billboards/models/billboard.dart';
import 'package:dayaa_client/features/billboards/presentation/viewmodel/billboard_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// What the shop is showing, at the top of the home screen.
///
/// **A carousel that failed shows nothing at all.** The home screen's job is the shortcuts
/// underneath it, and a red error box across the first thing somebody sees when they open the
/// app would make a marketing banner look like a broken application.
class BillboardCarousel extends StatefulWidget {
  const BillboardCarousel({super.key});

  @override
  State<BillboardCarousel> createState() => _BillboardCarouselState();
}

class _BillboardCarouselState extends State<BillboardCarousel> {
  /// Stateful for this alone — a widget-lifecycle resource that has to be disposed.
  final _controller = PageController(viewportFraction: 0.92);

  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _open(Billboard banner) async {
    switch (banner.target) {
      case BillboardProductTarget(:final productId):
        await context.push(Routes.product(productId));

      case BillboardUrlTarget(:final url):
        final uri = Uri.tryParse(url);
        if (uri == null) return;

        // **Outside the app, and never silently.** `externalApplication` hands it to the
        // browser rather than an in-app view, so the address bar is visible — a banner is the
        // one place the shop can send a customer somewhere the shop does not control.
        final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

        if (!opened && mounted) context.showError('تعذّر فتح الرابط');

      case BillboardNoTarget():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BillboardCubit, BillboardState>(
      builder: (context, state) {
        final banners = state.billboards;

        // Nothing to show, nothing to fail at: no campaign running, or a carousel that did not
        // load. Neither takes any height.
        if (banners.isEmpty) return const SizedBox.shrink();

        return Column(
          children: [
            SizedBox(
              height: 170.h,
              child: PageView.builder(
                controller: _controller,
                itemCount: banners.length,
                onPageChanged: (index) => setState(() => _page = index),
                itemBuilder: (context, index) {
                  final banner = banners[index];

                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: _Banner(banner: banner, onTap: () => _open(banner)),
                  );
                },
              ),
            ),
            if (banners.length > 1) ...[
              SizedBox(height: 10.h),
              _Dots(count: banners.length, current: _page),
            ],
          ],
        );
      },
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.banner, required this.onTap});

  final Billboard banner;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: Material(
        color: scheme.surfaceContainerHighest,
        child: InkWell(
          // A banner that leads nowhere is not tappable — an announcement is allowed to just be
          // an announcement, and a ripple that goes nowhere reads as a broken link.
          onTap: banner.leadsSomewhere ? onTap : null,
          // Cached: a carousel re-fetched on every return to the home screen is the shop
          // paying for the same picture all day, on the customer's data.
          child: CachedNetworkImage(
            imageUrl: banner.imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            placeholder: (context, url) => const SizedBox.shrink(),
            // A picture that will not load leaves the shop's own name rather than a broken
            // icon — the banner still says something.
            errorWidget: (context, url, error) => Center(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Text(
                  banner.title,
                  textAlign: TextAlign.center,
                  style: context.textTheme.titleMedium,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < count; index++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: EdgeInsets.symmetric(horizontal: 3.w),
            height: 6.h,
            width: index == current ? 18.w : 6.w,
            decoration: BoxDecoration(
              color: index == current ? scheme.primary : scheme.outlineVariant,
              borderRadius: BorderRadius.circular(3.r),
            ),
          ),
      ],
    );
  }
}
