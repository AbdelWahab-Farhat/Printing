import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/features/billboards/models/billboard.dart';
import 'package:dayaa_client/features/billboards/models/house_ad.dart';
import 'package:dayaa_client/features/billboards/presentation/viewmodel/billboard_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// شريط الإعلانات أعلى الرئيسية.
///
/// **لا يبقى فارغاً ولا يعرض خطأً.** إعلانات المتجر حين يعرض شيئاً، وإعلانات التطبيق نفسه
/// ([HouseAd]) حين لا حملة جارية أو لم يُحمَّل الشريط. وأثناء التحميل الأول مكانه محجوزٌ بمقاسه
/// كاملاً، نقاطه معه، فلا تقفز الرئيسية حين يصل الجواب.
///
/// **يتقلّب وحده كل خمس ثوانٍ، ويقف تحت الإصبع**، بـ`carousel_slider`، الحزمة التي في بريمولا.
/// ومع «تقليل الحركة» لا يتقلّب إلا بالإصبع (RULES §7). و`enlargeCenterPage` مطفأ: هو الخيار
/// الوحيد في الحزمة الذي يكبّر ويصغّر، والحركة هنا إزاحةٌ فقط.
class BillboardCarousel extends StatefulWidget {
  const BillboardCarousel({super.key});

  @override
  State<BillboardCarousel> createState() => _BillboardCarouselState();
}

class _BillboardCarouselState extends State<BillboardCarousel> {
  /// الإعلان المعروض، لنقاط الصفحة تحته. حالةٌ بصرية بحتة في ويدجت واحد (RULES §4).
  int _page = 0;

  static double get _height => 176.h;

  /// ما يُرسم: إعلانات المتجر، أو إعلانات التطبيق، أو لا شيء بعد أثناء التحميل الأول.
  List<_Slide> _slidesFor(BillboardState state) {
    if (state.showsHouseAds) {
      return [
        for (final ad in HouseAd.values)
          _Slide(
            key: 'house-${ad.name}',
            title: ad.title,
            image: Image.asset(ad.asset, fit: BoxFit.cover),
            onTap: () => _openHouseAd(ad),
          ),
      ];
    }

    return [
      for (final banner in state.billboards)
        _Slide(
          key: 'shop-${banner.id}',
          title: banner.title,
          // مخزّنة: شريطٌ يُجلب من جديد مع كل عودةٍ إلى الرئيسية هو المتجر يدفع ثمن الصورة نفسها
          // طوال اليوم، من باقة العميل.
          image: CachedNetworkImage(
            imageUrl: banner.imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => const SizedBox.shrink(),
            // صورةٌ لم تُحمَّل تترك عنوان الإعلان لا أيقونة صورةٍ مكسورة: الإعلان ما زال يقول شيئاً.
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
          // إعلانٌ لا يقود إلى شيء لا يُلمس: الإعلان مسموحٌ له أن يكون إعلاناً فقط، وموجةٌ لا تذهب
          // إلى شيءٍ تُقرأ رابطاً مكسوراً.
          onTap: banner.leadsSomewhere ? () => _open(banner) : null,
        ),
    ];
  }

  Future<void> _openHouseAd(HouseAd ad) async {
    switch (ad) {
      // الكتالوج تبويب، فـ`go` تنقل الشريط إليه ولا تكدّس نسخةً ثانية منه فوق الرئيسية.
      case HouseAd.printedBags || HouseAd.volumePricing:
        context.go(Routes.products);

      // والمعاينة أداةٌ لا تبويب لها، فتُدفع ويُرجع منها.
      case HouseAd.bagPreview:
        await context.push(Routes.bagPreview);
    }
  }

  Future<void> _open(Billboard banner) async {
    switch (banner.target) {
      case BillboardProductTarget(:final productId):
        await context.push(Routes.product(productId));

      case BillboardUrlTarget(:final url):
        final uri = Uri.tryParse(url);
        if (uri == null) return;

        // **خارج التطبيق، وأبداً بلا علمه.** `externalApplication` يسلّمه للمتصفح لا لنافذةٍ
        // داخل التطبيق، فيظهر شريط العنوان: الإعلان المكان الوحيد الذي يستطيع منه المتجر أن
        // يرسل العميل إلى مكانٍ لا يملكه.
        final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

        if (!opened && mounted) context.showError('تعذّر فتح الرابط');

      case BillboardNoTarget():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BillboardCubit, BillboardState>(
      // ما يُعرض تغيّر، فالنقطة الأولى هي الحالية من جديد.
      listener: (context, state) => setState(() => _page = 0),
      builder: (context, state) {
        final slides = _slidesFor(state);

        return Column(
          children: [
            SizedBox(
              height: _height,
              child: slides.isEmpty ? const _Placeholder() : _carousel(slides),
            ),
            SizedBox(height: 12.h),
            // النقاط تحجز سطرها ولو لم تُرسم، كي لا يتغيّر ارتفاع الشريط بين التحميل والعرض.
            SizedBox(
              height: _Dots.size,
              child: slides.length > 1 ? _Dots(count: slides.length, current: _page) : null,
            ),
          ],
        );
      },
    );
  }

  Widget _carousel(List<_Slide> slides) {
    final turns = slides.length > 1;
    final still = MediaQuery.disableAnimationsOf(context);

    return CarouselSlider.builder(
      // شريطٌ جديد حين يتغيّر ما يعرضه، لا الشريط نفسه واقفاً على صفحةٍ من القائمة القديمة.
      key: ValueKey(slides.map((slide) => slide.key).join(',')),
      itemCount: slides.length,
      options: CarouselOptions(
        height: _height,
        viewportFraction: 0.92,
        enlargeCenterPage: false,
        enableInfiniteScroll: turns,
        autoPlay: turns && !still,
        autoPlayInterval: const Duration(seconds: 5),
        autoPlayAnimationDuration: const Duration(milliseconds: 700),
        autoPlayCurve: Curves.easeInOutCubic,
        onPageChanged: (index, _) => setState(() => _page = index),
      ),
      itemBuilder: (context, index, _) => Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        child: _SlideView(slide: slides[index]),
      ),
    );
  }
}

/// إعلانٌ واحد كما يرسمه الشريط، من المتجر أو من التطبيق.
class _Slide {
  const _Slide({required this.key, required this.title, required this.image, this.onTap});

  /// ما يميّزه عن غيره، ليُعرف متى تغيّر ما يعرضه الشريط.
  final String key;

  /// عنوانه، يقرؤه قارئ الشاشة بدل الصورة.
  final String title;

  final Widget image;

  /// فارغٌ لإعلانٍ لا يقود إلى شيء.
  final VoidCallback? onTap;
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});

  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: slide.title,
      image: true,
      button: slide.onTap != null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: ColoredBox(
          color: context.colorScheme.surfaceContainerHigh,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ExcludeSemantics(child: slide.image),
              // الموجة فوق الصورة لا تحتها، وإلا غطّتها الصورة فلم تُرَ.
              if (slide.onTap case final onTap?)
                Material(
                  type: MaterialType.transparency,
                  child: InkWell(onTap: onTap),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// مكان الإعلان أثناء التحميل الأول، بعرض الإعلان المعروض وزواياه.
class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: 0.92,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(20.r),
          ),
        ),
      ),
    );
  }
}

/// أيّ الإعلانات معروض.
///
/// **النقاط بمقاسٍ واحد، واللون وحده يتبدّل.** نقطةٌ تستطيل حين تنشط تغيّر مقاسها، وقواعد الحركة
/// لا تسمح بذلك (RULES §7). ولقارئ الشاشة جملةٌ لا ثلاث نقاط: «إعلان 2 من 3».
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.current});

  final int count;
  final int current;

  static double get size => 7.w;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Semantics(
      label: 'إعلان ${current + 1} من $count',
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var index = 0; index < count; index++)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 3.w),
                child: SizedBox.square(
                  dimension: size,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == current
                          ? scheme.primary
                          : scheme.outline.withValues(alpha: 0.45),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
