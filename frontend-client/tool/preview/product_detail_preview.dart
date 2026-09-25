// أداةٌ لا اختبار: ترسم صفحة المنتج صوراً PNG كي يُنظر فيها بلا هاتف. خارج `test/` كي لا
// يجمعها `flutter test`.
//
//   PREVIEW_OUT=<مجلد الصور> PREVIEW_PHOTO=<صورة jpg> flutter test tool/preview/product_detail_preview.dart
//
// على طريقة `home_preview.dart`: آيفون ٣٩٠×٨٤٤ بكثافة ٢، وCairo بأوزانه الستة، وخط أيقونات
// Material من ذاكرة الـ SDK. صورة المنتج تُقرأ من [PREVIEW_PHOTO] وتوضع في ذاكرة الصور تحت
// عنوانها، فلا شبكة ولا مخزن ملفات؛ وبلا صورةٍ يُرسم البديل.
//
// البيانات للرسم وحده: «أكياس شحن - مطبوعة» و«أكياس شفافه - ساده» بأسعارهما من قاعدة البيانات.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/network/paginated.dart';
import 'package:dayaa_client/core/theme/text_theme.dart';
import 'package:dayaa_client/core/theme/theme.dart';
import 'package:dayaa_client/features/catalog/models/product.dart';
import 'package:dayaa_client/features/catalog/presentation/viewmodel/product_detail_cubit.dart';
import 'package:dayaa_client/features/catalog/presentation/views/product_detail_page.dart';
import 'package:dayaa_client/features/catalog/repositories/catalog_repository.dart';
import 'package:dayaa_client/features/catalog/usecases/get_product.dart';
import 'package:dayaa_client/features/catalog/usecases/quote_price.dart';
import 'package:dayaa_client/features/orders/presentation/viewmodel/cart_cubit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

const _photo = 'https://preview.local/product.jpg';

List<PriceTier> _tiers(List<String> prices) => [
  PriceTier(id: 1, minQuantity: '100.000', unitPrice: prices[0]),
  PriceTier(id: 2, minQuantity: '300.000', unitPrice: prices[1]),
  PriceTier(id: 3, minQuantity: '1000.000', unitPrice: prices[2]),
];

final _printed = Product(
  id: 1,
  name: 'أكياس شحن - مطبوعة',
  code: 'P1',
  pricingUnit: 'piece',
  pricingUnitLabel: 'قطعة',
  minOrderQuantity: '100.000',
  images: const [ProductImage(id: 1, url: _photo, isPrimary: true)],
  variants: [
    ProductVariant(id: 1, label: 'صغير', widthCm: 25, heightCm: 35, priceTiers: _tiers(['1.130', '1.030', '0.880'])),
    ProductVariant(id: 2, label: 'متوسط', widthCm: 35, heightCm: 40, priceTiers: _tiers(['1.410', '1.310', '1.160'])),
    ProductVariant(id: 3, label: 'كبير', widthCm: 45, heightCm: 50, priceTiers: _tiers(['1.850', '1.750', '1.600'])),
    ProductVariant(id: 4, label: 'اكسترا', widthCm: 50, heightCm: 60, priceTiers: _tiers(['2.350', '2.250', '2.100'])),
  ],
);

const _plain = Product(
  id: 12,
  name: 'أكياس شفافه - ساده',
  code: 'P12',
  pricingUnit: 'kilogram',
  pricingUnitLabel: 'كجم',
  minOrderQuantity: '1.000',
  images: [
    ProductImage(id: 1, url: _photo, isPrimary: true),
    ProductImage(id: 2, url: 'https://preview.local/second.jpg'),
  ],
  variants: [
    ProductVariant(id: 40, label: 'صغير جدا', widthCm: 20, heightCm: 26, priceTiers: [PriceTier(id: 9, minQuantity: '1.000', unitPrice: '49.000')]),
    ProductVariant(id: 30, label: 'صغير', widthCm: 27, heightCm: 35, priceTiers: [PriceTier(id: 8, minQuantity: '1.000', unitPrice: '49.000')]),
    ProductVariant(id: 32, label: 'متوسط', widthCm: 35, heightCm: 40, priceTiers: [PriceTier(id: 7, minQuantity: '1.000', unitPrice: '49.000')]),
  ],
);

/// يجيب عن السعر كما يجيب الخادم: الكسر الذي بلغته الكمية، والذي يليه، والباقي إليه.
class _Catalog implements CatalogRepository {
  _Catalog(this.item);

  final Product item;

  @override
  Future<Either<Failure, Product>> product(int id) async => Right(item);

  @override
  Future<Either<Failure, PriceQuote>> quote({
    required int productId,
    required int variantId,
    required String quantity,
  }) async {
    final tiers = item.variants.firstWhere((variant) => variant.id == variantId).tiersInOrder;
    final amount = double.parse(quantity);
    final applied = tiers.lastWhere(
      (tier) => double.parse(tier.minQuantity) <= amount,
      orElse: () => tiers.first,
    );
    final nextIndex = tiers.indexOf(applied) + 1;
    final next = nextIndex < tiers.length ? tiers[nextIndex] : null;

    return Right(
      PriceQuote(
        quantity: quantity,
        unitPrice: applied.unitPrice,
        total: (amount * double.parse(applied.unitPrice)).toStringAsFixed(3),
        appliedTierMinQuantity: applied.minQuantity,
        nextTier: next == null
            ? null
            : NextTier(
                minQuantity: next.minQuantity,
                unitPrice: next.unitPrice,
                quantityToReach: (double.parse(next.minQuantity) - amount).toStringAsFixed(3),
              ),
      ),
    );
  }

  @override
  Future<Either<Failure, Paginated<Product>>> products({
    int page = 1,
    String? search,
    int? categoryId,
  }) => throw UnimplementedError();

  @override
  Future<Either<Failure, List<ProductCategory>>> categories() => throw UnimplementedError();
}

Future<void> _load(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    final bytes = await File(path).readAsBytes();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  final out = Platform.environment['PREVIEW_OUT'] ?? '.';
  final photo = Platform.environment['PREVIEW_PHOTO'];

  setUpAll(() async {
    await _load('Cairo', [
      for (final face in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold', 'Black'])
        'assets/fonts/Cairo-$face.ttf',
    ]);
    final artifacts = File(Platform.resolvedExecutable).parent.parent.parent.path;
    final icons = '$artifacts/material_fonts/MaterialIcons-Regular.otf';
    if (File(icons).existsSync()) await _load('MaterialIcons', [icons]);
  });

  Future<void> draw(
    WidgetTester tester, {
    required String name,
    required Product product,
    required Brightness brightness,
    String? quantity,
    int? size,
    bool scrolled = false,
    bool typing = false,
  }) async {
    await sl.reset();
    final catalog = _Catalog(product);
    final cubit = ProductDetailCubit(getProduct: GetProduct(catalog), quote: QuotePrice(catalog));
    sl
      ..registerFactory<ProductDetailCubit>(() => cubit)
      ..registerLazySingleton<CartCubit>(CartCubit.new);

    // آيفون بجزيرة: ٣٩٠×٨٤٤، شريط الحالة ٥٩، والمؤشر السفلي ٣٤.
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    tester.view.padding = const FakeViewPadding(top: 118, bottom: 68);
    tester.view.viewPadding = const FakeViewPadding(top: 118, bottom: 68);
    addTearDown(tester.view.reset);

    if (photo != null) {
      final image = await tester.runAsync(() async {
        final codec = await ui.instantiateImageCodec(await File(photo).readAsBytes());

        return (await codec.getNextFrame()).image;
      });
      PaintingBinding.instance.imageCache.putIfAbsent(
        const CachedNetworkImageProvider(_photo),
        () => OneFrameImageStreamCompleter(SynchronousFuture(ImageInfo(image: image!))),
      );
    }

    final key = GlobalKey();
    debugDisableShadows = false;
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: ScreenUtilInit(
          designSize: const Size(430, 932),
          builder: (context, _) {
            final theme = MaterialTheme(createTextTheme(context, 'Cairo', 'Cairo'));

            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: brightness == Brightness.light ? theme.light() : theme.dark(),
              locale: const Locale('ar'),
              supportedLocales: const [Locale('ar')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: const ProductDetailPage(productId: 1),
            );
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    if (size != null) cubit.selectVariant(size);
    if (quantity != null) cubit.setQuantity(quantity);
    await tester.pump(const Duration(milliseconds: 50));

    if (scrolled) {
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -700));
      await tester.pump(const Duration(milliseconds: 500));
    }
    if (typing) {
      await tester.tap(find.byKey(const ValueKey('quantity-display')));
      await tester.pump(const Duration(milliseconds: 600));
    }
    await tester.pump(const Duration(milliseconds: 300));

    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('$out/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
    });
    debugDisableShadows = true;
  }

  testWidgets('draw printed, dark, open', (tester) async {
    await draw(tester, name: 'printed-dark-open', product: _printed, brightness: Brightness.dark, size: 2, quantity: '500');
  });

  testWidgets('draw printed, dark, folded', (tester) async {
    await draw(tester, name: 'printed-dark-folded', product: _printed, brightness: Brightness.dark, size: 2, quantity: '500', scrolled: true);
  });

  testWidgets('draw printed, light, open', (tester) async {
    await draw(tester, name: 'printed-light-open', product: _printed, brightness: Brightness.light, size: 2, quantity: '500');
  });

  testWidgets('draw printed, dark, typing', (tester) async {
    await draw(tester, name: 'printed-dark-typing', product: _printed, brightness: Brightness.dark, size: 2, quantity: '500', typing: true);
  });

  testWidgets('draw plain, dark, open', (tester) async {
    await draw(tester, name: 'plain-dark-open', product: _plain, brightness: Brightness.dark, quantity: '10');
  });
}
