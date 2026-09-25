// أداةٌ لا اختبار: ترسم الطلبية المفتوحة صوراً PNG كي يُنظر فيها بلا هاتف. خارج `test/` كي لا
// يجمعها `flutter test`.
//
//   PREVIEW_OUT=<مجلد الصور> PREVIEW_PHOTO=<صورة المنتج> flutter test tool/preview/order_detail_preview.dart
//
// على مقاس هاتف صاحب العمل: ٤٤٠×٩٥٦ (لقطته ١٣٢٠×٢٨٦٨ بكثافة ٣)، شريط الحالة ٦٢ والمؤشر ٣٤،
// وCairo بأوزانه الستة، وخط أيقونات Material من ذاكرة الـ SDK. صورة المنتج تُقرأ من
// [PREVIEW_PHOTO] وتوضع في ذاكرة الصور تحت عنوانها، فلا شبكة؛ وبلا صورةٍ يُرسم البديل.
//
// الطلبية #1304 كما هي في قاعدة البيانات المحلية: ١٠٠ قطعة بـ1.72، و٦٠ كجم بـ36، إلى طرابلس —
// الفلاح. ما بعد «بانتظار المراجعة» — التواريخ والمدفوع — للرسم وحده.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/network/paginated.dart';
import 'package:dayaa_client/core/theme/text_theme.dart';
import 'package:dayaa_client/core/theme/theme.dart';
import 'package:dayaa_client/features/orders/models/basket_quote.dart';
import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:dayaa_client/features/orders/presentation/viewmodel/order_detail_cubit.dart';
import 'package:dayaa_client/features/orders/presentation/views/order_detail_page.dart';
import 'package:dayaa_client/features/orders/repositories/order_repository.dart';
import 'package:dayaa_client/features/orders/usecases/get_order.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

const _photo = 'https://preview.local/products/2.png';

final _year = DateTime.now().year;

OrderTimelineEntry _at(String stage, String label, int month, int day, [int hour = 12]) =>
    OrderTimelineEntry(
      stage: stage,
      stageLabel: label,
      reachedAt: DateTime(_year, month, day, hour),
    );

CustomerOrderDetail _order1304({
  OrderStage stage = OrderStage.underReview,
  String stageLabel = 'بانتظار المراجعة',
  String paid = '0.00',
  String balance = '2332.00',
  List<OrderTimelineEntry>? timeline,
}) => CustomerOrderDetail(
  id: 1304,
  code: '1304',
  stage: stage,
  stageLabel: stageLabel,
  cityName: 'طرابلس',
  regionName: 'الفلاح',
  recipientPhone: '0910000000',
  fulfilmentTypeLabel: 'توصيل',
  items: const [
    OrderLine(
      id: 158,
      productName: 'أكياس يد خارجية - مطبوعه',
      variantLabel: '30*30',
      quantity: '100.000',
      pricingUnitLabel: 'قطعة',
      unitPrice: '1.720',
      lineTotal: '172.00',
      productImageUrl: _photo,
    ),
    OrderLine(
      id: 159,
      productName: 'أكياس يد خارجية - سادة',
      variantLabel: '50*50',
      quantity: '60.000',
      pricingUnitLabel: 'كجم',
      unitPrice: '36.000',
      lineTotal: '2160.00',
      productImageUrl: _photo,
    ),
  ],
  itemsTotal: '2332.00',
  deliveryPrice: '15.00',
  designFee: '0.00',
  discount: '0.00',
  total: '2332.00',
  paidAmount: paid,
  balance: balance,
  timeline: timeline ?? [_at('under_review', 'بانتظار المراجعة', 9, 25, 14)],
  placedAt: DateTime(_year, 9, 25, 14, 51),
);

class _Orders implements OrderRepository {
  const _Orders(this.order);

  final CustomerOrderDetail order;

  @override
  Future<Either<Failure, CustomerOrderDetail>> detail(int id) async => Right(order);

  @override
  Future<Either<Failure, Paginated<CustomerOrder>>> list({
    int page = 1,
    bool openOnly = false,
    String? stage,
  }) => throw UnimplementedError();

  @override
  Future<Either<Failure, CustomerOrderDetail>> place(NewOrder order) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, BasketQuote>> quote({required List<NewOrderLine> items, int? cityId}) =>
      throw UnimplementedError();
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
    required CustomerOrderDetail order,
    required Brightness brightness,
  }) async {
    await sl.reset();
    sl.registerFactoryParam<OrderDetailCubit, int, void>(
      (orderId, _) => OrderDetailCubit(orderId: orderId, get: GetOrder(_Orders(order))),
    );

    tester.view.physicalSize = const Size(880, 1912);
    tester.view.devicePixelRatio = 2;
    tester.view.padding = const FakeViewPadding(top: 124, bottom: 68);
    tester.view.viewPadding = const FakeViewPadding(top: 124, bottom: 68);
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
              home: const OrderDetailPage(orderId: 1304),
            );
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('$out/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
    });
    debugDisableShadows = true;
  }

  for (final brightness in Brightness.values) {
    testWidgets('draw #1304 under review, ${brightness.name}', (tester) async {
      await draw(
        tester,
        name: 'order-1304-review-${brightness.name}',
        order: _order1304(),
        brightness: brightness,
      );
    });
  }

  testWidgets('draw #1304 being made, light', (tester) async {
    await draw(
      tester,
      name: 'order-1304-producing-light',
      order: _order1304(
        stage: OrderStage.producing,
        stageLabel: 'قيد الإنتاج',
        paid: '1000.00',
        balance: '1332.00',
        timeline: [
          _at('under_review', 'بانتظار المراجعة', 9, 25, 14),
          _at('preparing', 'قيد التجهيز', 9, 26),
          _at('producing', 'قيد الإنتاج', 9, 28),
        ],
      ),
      brightness: Brightness.light,
    );
  });

  testWidgets('draw #1304 delivered, light', (tester) async {
    await draw(
      tester,
      name: 'order-1304-delivered-light',
      order: _order1304(
        stage: OrderStage.delivered,
        stageLabel: 'تم الاستلام',
        paid: '2332.00',
        balance: '0.00',
        timeline: [
          _at('under_review', 'بانتظار المراجعة', 9, 25, 14),
          _at('preparing', 'قيد التجهيز', 9, 26),
          _at('producing', 'قيد الإنتاج', 9, 28),
          _at('ready', 'جاهزة', 9, 30),
          _at('on_the_way', 'جاري التوصيل', 10, 1, 10),
          _at('delivered', 'تم الاستلام', 10, 1, 16),
        ],
      ),
      brightness: Brightness.light,
    );
  });
}
