import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/core/router/pop_result.dart';
import 'package:dayaa_client/core/widgets/app_snackbar.dart';
import 'package:dayaa_client/features/delivery/models/city.dart';
import 'package:dayaa_client/features/delivery/repositories/delivery_repository.dart';
import 'package:dayaa_client/features/delivery/usecases/list_cities.dart';
import 'package:dayaa_client/features/designs/models/customer_design.dart';
import 'package:dayaa_client/features/designs/presentation/viewmodel/designs_cubit.dart';
import 'package:dayaa_client/features/designs/repositories/design_repository.dart';
import 'package:dayaa_client/features/designs/usecases/list_designs.dart';
import 'package:dayaa_client/features/designs/usecases/remove_design.dart';
import 'package:dayaa_client/features/designs/usecases/rename_design.dart';
import 'package:dayaa_client/features/designs/usecases/upload_design.dart';
import 'package:dayaa_client/features/shops/models/shop.dart';
import 'package:dayaa_client/features/shops/presentation/viewmodel/shop_form_cubit.dart';
import 'package:dayaa_client/features/shops/presentation/viewmodel/shops_cubit.dart';
import 'package:dayaa_client/features/shops/presentation/views/shop_details_page.dart';
import 'package:dayaa_client/features/shops/presentation/views/shop_form_page.dart';
import 'package:dayaa_client/features/shops/presentation/views/shops_page.dart';
import 'package:dayaa_client/features/shops/repositories/shop_repository.dart';
import 'package:dayaa_client/features/shops/usecases/add_shop.dart';
import 'package:dayaa_client/features/shops/usecases/list_business_fields.dart';
import 'package:dayaa_client/features/shops/usecases/list_shops.dart';
import 'package:dayaa_client/features/shops/usecases/remove_shop.dart';
import 'package:dayaa_client/features/shops/usecases/update_shop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockShopRepository extends Mock implements ShopRepository {}

class _MockDeliveryRepository extends Mock implements DeliveryRepository {}

class _MockDesignRepository extends Mock implements DesignRepository {}

/// «متاجري» وصفحة المتجر ونموذجه على الشاشة.
///
/// Arrange - Act - Assert throughout.
void main() {
  const kish = Region(id: 10, cityId: 1, name: 'الكيش');
  const benghazi = City(id: 1, name: 'بنغازي', regions: [kish]);
  const tripoli = City(id: 2, name: 'طرابلس');

  const clothes = BusinessField(id: 3, name: 'ملابس وأحذية');
  const perfume = BusinessField(id: 4, name: 'عطور');

  const noor = Shop(
    id: 5,
    name: 'متجر النور',
    cityId: 1,
    cityName: 'بنغازي',
    regionId: 10,
    regionName: 'الكيش',
    businessFieldId: 3,
    businessFieldName: 'ملابس وأحذية',
    pageUrl: 'https://facebook.com/alnoor',
  );
  const amal = Shop(id: 6, name: 'متجر الأمل', cityId: 2, cityName: 'طرابلس');

  late _MockShopRepository shops;

  /// ما أعاده النموذج لمن فتحه، ليُسأل عنه.
  Shop? returned;

  // قبل كل اختبار لا داخل `open`: الاختبار يضع ما يجيب به المستودع قبل أن يفتح الشاشة.
  setUp(() {
    shops = _MockShopRepository();
    returned = null;

    when(() => shops.list()).thenAnswer((_) async => const Right([noor]));
    when(() => shops.businessFields()).thenAnswer((_) async => const Right([clothes, perfume]));
  });

  tearDown(() async {
    resetSnackBars();
    await sl.reset();
  });

  Future<void> open(WidgetTester tester, {required String at, Object? extra}) async {
    tester.view
      ..physicalSize = const Size(430, 932)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final delivery = _MockDeliveryRepository();
    final designs = _MockDesignRepository();

    when(() => delivery.cities()).thenAnswer((_) async => const Right([benghazi, tripoli]));
    when(() => designs.list()).thenAnswer(
      (_) async => const Right([
        CustomerDesign(id: 1, label: 'شعار المتجر', kind: DesignKind.pdf),
        CustomerDesign(id: 2, label: 'تصميم الكيس', kind: DesignKind.pdf),
      ]),
    );

    sl
      ..registerFactory<DesignsCubit>(
        () => DesignsCubit(
          list: ListDesigns(designs),
          upload: UploadDesign(designs),
          rename: RenameDesign(designs),
          remove: RemoveDesign(designs),
        ),
      )
      ..registerFactory<ShopsCubit>(
        () => ShopsCubit(list: ListShops(shops), remove: RemoveShop(shops)),
      )
      ..registerFactoryParam<ShopFormCubit, Shop?, void>(
        (editing, _) => ShopFormCubit(
          cities: ListCities(delivery),
          businessFields: ListBusinessFields(shops),
          add: AddShop(shops),
          update: UpdateShop(shops),
          editing: editing,
        ),
      );

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        // شاشةٌ تحت النموذج تفتحه وتلتقط ما يعيده، كما تفعل «متاجري» وصفحة المتجر.
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async =>
                    returned = await context.push<Shop>(Routes.shopForm, extra: extra),
                child: const Text('افتح النموذج'),
              ),
            ),
          ),
        ),
        GoRoute(path: Routes.shops, builder: (context, state) => const ShopsPage()),
        GoRoute(
          path: Routes.shopForm,
          builder: (context, state) => ShopFormPage(editing: state.payload as Shop?),
        ),
        GoRoute(
          path: Routes.shopDetails,
          builder: (context, state) => ShopDetailsPage(shop: state.payload! as Shop),
        ),
      ],
    );

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(430, 932),
        builder: (context, _) => MaterialApp.router(
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();

    if (at == Routes.shops) {
      unawaited(router.push(Routes.shops));
    } else {
      await tester.tap(find.text('افتح النموذج'));
    }
    await tester.pumpAndSettle();
  }

  group('«متاجري»', () {
    testWidgets('lists the shops with their place', (tester) async {
      // Arrange & Act
      await open(tester, at: Routes.shops);

      // Assert
      expect(find.text('متجر النور'), findsOneWidget);
      expect(find.text('بنغازي · الكيش'), findsOneWidget);
      expect(find.text('أضف متجراً'), findsOneWidget);
    });

    testWidgets('a shop opens its own page, with its details', (tester) async {
      // Arrange
      await open(tester, at: Routes.shops);

      // Act
      await tester.tap(find.text('متجر النور'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(ShopDetailsPage), findsOneWidget);
      expect(find.text('ملابس وأحذية'), findsOneWidget);
      expect(find.text('بنغازي · الكيش'), findsOneWidget);
      expect(find.text('https://facebook.com/alnoor'), findsOneWidget);
      expect(find.text('تعديل تفاصيل المتجر'), findsOneWidget);
    });

    testWidgets('the shop’s page carries the account’s design library, to edit there', (
      tester,
    ) async {
      // Arrange
      await open(tester, at: Routes.shops);

      // Act
      await tester.tap(find.text('متجر النور'));
      await tester.pumpAndSettle();

      // Assert — التصاميم على الحساب: المكتبة نفسها في صفحة كل متجر.
      expect(find.text('التصاميم'), findsOneWidget);
      expect(find.text('شعار المتجر'), findsOneWidget);
      expect(find.text('تصميم الكيس'), findsOneWidget);
      expect(find.text('أضف تصميماً'), findsOneWidget);
    });

    testWidgets('an edit made on the shop’s page is in the list on the way back', (tester) async {
      // Arrange
      when(
        () => shops.update(
          id: 5,
          name: 'النور الجديد',
          cityId: 1,
          regionId: 10,
          businessFieldId: 3,
          pageUrl: 'https://facebook.com/alnoor',
        ),
      ).thenAnswer((_) async => Right(noor.copyWith(name: 'النور الجديد')));
      await open(tester, at: Routes.shops);
      await tester.tap(find.text('متجر النور'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تعديل تفاصيل المتجر'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, 'متجر النور'), 'النور الجديد');
      await tester.tap(find.text('احفظ التعديل'));
      await tester.pumpAndSettle();

      // Act — الرجوع بإيماءة النظام لا بزرٍّ يحمل نتيجة.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      // Assert — القائمة تحمل الاسم الجديد ولم تُسأل مرةً ثانية.
      expect(find.text('النور الجديد'), findsOneWidget);
      verify(() => shops.list()).called(1);

      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    });

    testWidgets('a shop is removed only after the customer confirms', (tester) async {
      // Arrange
      when(() => shops.remove(5)).thenAnswer((_) async => const Right(unit));
      await open(tester, at: Routes.shops);

      // Act
      await tester.tap(find.byTooltip('حذف'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('حذف').last);
      await tester.pumpAndSettle();

      // Assert
      verify(() => shops.remove(5)).called(1);
      expect(find.text('متجر النور'), findsNothing);
    });

    testWidgets('cancelling the confirmation keeps the shop', (tester) async {
      // Arrange
      await open(tester, at: Routes.shops);

      // Act
      await tester.tap(find.byTooltip('حذف'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('إلغاء'));
      await tester.pumpAndSettle();

      // Assert
      verifyNever(() => shops.remove(any()));
      expect(find.text('متجر النور'), findsOneWidget);
    });
  });

  group('the form', () {
    testWidgets('asks what the staff app asks, in its order', (tester) async {
      // Arrange & Act
      await open(tester, at: Routes.shopForm);

      // Assert
      final labels = [
        for (final label in ['اسم المكان', 'مجال العمل', 'المدينة', 'رابط الصفحة'])
          tester.getTopLeft(find.text(label)).dy,
      ];
      expect(labels, orderedEquals([...labels]..sort()));
      expect(find.text('غير محدد'), findsOneWidget);
    });

    testWidgets('the city and the region sit side by side, the city first', (tester) async {
      // Arrange & Act
      await open(tester, at: Routes.shopForm, extra: noor);

      // Assert — صفٌّ واحد، والمدينة على اليمين حيث يبدأ السطر.
      final city = tester.getRect(find.byType(DropdownButtonFormField<City>));
      final region = tester.getRect(find.byType(DropdownButtonFormField<Region>));
      expect(city.top, closeTo(region.top, 1));
      expect(city.overlaps(region), isFalse);
      expect(city.left, greaterThan(region.left));
    });

    testWidgets('the region box is there before there is any region to choose', (tester) async {
      // Arrange & Act — متجرٌ جديد: لا مدينة مختارة بعد.
      await open(tester, at: Routes.shopForm);

      // Assert — الصفّ بصندوقيه دائماً، والمنطقة تقول لماذا هي فارغة.
      expect(find.byType(DropdownButtonFormField<Region>), findsOneWidget);
      expect(find.text('اختر المدينة أولاً'), findsOneWidget);
    });

    testWidgets('a city with no regions keeps the region box, closed', (tester) async {
      // Arrange
      await open(tester, at: Routes.shopForm);

      // Act — طرابلس بلا مناطق.
      await tester.tap(find.byType(DropdownButtonFormField<City>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('طرابلس').last);
      await tester.pumpAndSettle();

      // Assert
      final region = tester.widget<DropdownButton<Region>>(find.byType(DropdownButton<Region>));
      expect(find.text('لا توجد مناطق'), findsOneWidget);
      expect(region.onChanged, isNull);
    });

    testWidgets('a city with regions opens them in the box beside it', (tester) async {
      // Arrange
      await open(tester, at: Routes.shopForm);
      await tester.tap(find.byType(DropdownButtonFormField<City>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('بنغازي').last);
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byType(DropdownButtonFormField<Region>));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('الكيش'), findsWidgets);
      expect(find.text('بدون تحديد'), findsWidgets);
    });

    testWidgets('an edit opens on the shop’s own name, trade, place and page', (tester) async {
      // Arrange & Act
      await open(tester, at: Routes.shopForm, extra: noor);

      // Assert
      expect(find.text('تعديل المتجر'), findsOneWidget);
      expect(find.text('متجر النور'), findsOneWidget);
      expect(find.text('ملابس وأحذية'), findsWidgets);
      expect(find.text('بنغازي'), findsWidgets);
      expect(find.text('الكيش'), findsWidgets);
      expect(find.text('https://facebook.com/alnoor'), findsOneWidget);
    });

    testWidgets('a new shop is saved and handed back to the screen that opened the form', (
      tester,
    ) async {
      // Arrange
      when(
        () => shops.add(name: 'متجر الأمل', cityId: 2, businessFieldId: 4),
      ).thenAnswer((_) async => const Right(amal));
      await open(tester, at: Routes.shopForm);

      // Act
      await tester.enterText(find.byType(TextFormField).first, 'متجر الأمل');
      await tester.tap(find.byType(DropdownButtonFormField<BusinessField>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('عطور').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<City>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('طرابلس').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('أضف المتجر'));
      await tester.pump();
      await tester.pumpAndSettle();

      // Assert
      expect(returned, amal);
      expect(find.text('افتح النموذج'), findsOneWidget);

      // رسالة النجاح تنصرف بعد ثلاث ثوانٍ؛ يُترك لها وقتها كي لا يبقى مؤقّتها معلّقاً.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    });

    testWidgets('a page link that is not a link is stopped at the field', (tester) async {
      // Arrange
      await open(tester, at: Routes.shopForm, extra: noor);

      // Act
      await tester.enterText(
        find.widgetWithText(TextFormField, 'https://facebook.com/alnoor'),
        'صفحتنا على فيسبوك',
      );
      await tester.tap(find.text('احفظ التعديل'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('الرابط غير صحيح'), findsOneWidget);
      verifyNever(
        () => shops.update(
          id: any(named: 'id'),
          name: any(named: 'name'),
          cityId: any(named: 'cityId'),
          regionId: any(named: 'regionId'),
          businessFieldId: any(named: 'businessFieldId'),
          pageUrl: any(named: 'pageUrl'),
        ),
      );
    });

    testWidgets('a nameless shop is stopped at the field, before anything is sent', (
      tester,
    ) async {
      // Arrange
      await open(tester, at: Routes.shopForm, extra: noor);

      // Act
      await tester.enterText(find.widgetWithText(TextFormField, 'متجر النور'), '');
      await tester.tap(find.text('احفظ التعديل'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('هذا الحقل مطلوب'), findsOneWidget);
      verifyNever(
        () => shops.update(
          id: any(named: 'id'),
          name: any(named: 'name'),
          cityId: any(named: 'cityId'),
          regionId: any(named: 'regionId'),
          businessFieldId: any(named: 'businessFieldId'),
          pageUrl: any(named: 'pageUrl'),
        ),
      );
    });
  });
}
