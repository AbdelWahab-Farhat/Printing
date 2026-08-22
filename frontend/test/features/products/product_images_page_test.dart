import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/files/attachment_picker.dart';
import 'package:dayaa/core/files/picked_file.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/products/models/product.dart';
import 'package:dayaa/features/products/models/product_image_rules.dart';
import 'package:dayaa/features/products/presentation/viewmodel/product_images_cubit.dart';
import 'package:dayaa/features/products/presentation/views/product_images_page.dart';
import 'package:dayaa/features/products/repositories/product_repository.dart';
import 'package:dayaa/features/products/usecases/delete_product_image.dart';
import 'package:dayaa/features/products/usecases/get_product.dart';
import 'package:dayaa/features/products/usecases/set_primary_product_image.dart';
import 'package:dayaa/features/products/usecases/upload_product_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// The screen that manages a product's photographs.
///
/// Real Cubit, real use cases, fake repository and fake picker — so the pre-flight cap, the
/// permission gates and the local size check are all exercised, and nothing reaches a platform
/// channel that does not exist here.
///
/// Arrange - Act - Assert throughout.
class _MockProductRepository extends Mock implements ProductRepository {}

/// Answers with whatever the test put in it, without opening anything.
class _FakePicker implements AttachmentPicker {
  List<PickedFile> answer = const [];
  AttachmentSource? asked;

  @override
  Future<List<PickedFile>> pick(AttachmentSource source) async {
    asked = source;

    return answer;
  }
}

void main() {
  late _MockProductRepository repository;
  late _FakePicker picker;
  late Session session;

  const productId = 7;

  const front = ProductImage(id: 1, url: 'https://cdn.test/front.jpg', isPrimary: true);
  const back = ProductImage(id: 2, url: 'https://cdn.test/back.jpg');

  Product productWith(List<ProductImage> images) => Product(
    id: productId,
    code: 'P7',
    slug: 'shipping-bag',
    name: 'كيس شحن',
    pricingUnit: 'piece',
    pricingUnitLabel: 'قطعة',
    stockUnit: 'piece',
    stockUnitLabel: 'قطعة',
    pricingMode: 'listed',
    pricingModeLabel: 'سعر معلن',
    hasListedPrices: true,
    minOrderQuantity: '100.000',
    images: images,
  );

  AuthUser userWith(List<String> permissions) =>
      AuthUser(id: 1, name: 'عبدالوهاب', phone: '0911234567', permissions: permissions);

  setUpAll(() {
    registerFallbackValue(
      const PickedFile(path: '/tmp/a.jpg', name: 'a.jpg', sizeBytes: 1),
    );
  });

  setUp(() async {
    await Injector.reset();

    repository = _MockProductRepository();
    picker = _FakePicker();
    session = Session();

    when(
      () => repository.product(productId),
    ).thenAnswer((_) async => Right(productWith([front, back])));

    sl
      ..registerSingleton<Session>(session)
      ..registerSingleton<AttachmentPicker>(picker)
      ..registerFactoryParam<ProductImagesCubit, int, void>(
        (id, _) => ProductImagesCubit(
          productId: id,
          getProduct: GetProduct(repository),
          uploadImage: UploadProductImage(repository),
          setPrimary: SetPrimaryProductImage(repository),
          deleteImage: DeleteProductImage(repository),
        ),
      );
  });

  tearDown(Injector.reset);

  Widget host() => ScreenUtilInit(
    designSize: const Size(430, 932),
    builder: (context, _) => const MaterialApp(
      locale: Locale('ar'),
      supportedLocales: [Locale('ar')],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: ProductImagesPage(productId: productId, productName: 'كيس شحن'),
    ),
  );

  testWidgets('says whose photographs these are, and how many of the allowance are used', (
    tester,
  ) async {
    // Arrange — the count is on screen because the cap is what makes people ask.
    session.adopt(userWith(['products.view']));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('كيس شحن'), findsOneWidget);
    expect(find.text('2 من ${ProductImageRules.maxPerProduct} صور'), findsOneWidget);
    expect(find.text('الرئيسية'), findsOneWidget);
  });

  testWidgets('somebody who may only read is offered nothing to press', (tester) async {
    // Arrange — a courtesy, never a boundary: the server refuses either way, and hiding the
    // buttons spares them work they cannot finish.
    session.adopt(userWith(['products.view']));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('إضافة صورة'), findsNothing);
    expect(find.byTooltip('حذف الصورة'), findsNothing);
    expect(find.byTooltip('اجعلها الرئيسية'), findsNothing);
  });

  testWidgets('the primary photograph is not offered a button to promote itself', (
    tester,
  ) async {
    // Arrange — one of the two photographs is already primary, so exactly one tile may be
    // promoted. A button that can only do nothing is a button to leave out.
    session.adopt(userWith(['products.view', 'products.manage']));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.byTooltip('اجعلها الرئيسية'), findsOneWidget);
    expect(find.byTooltip('حذف الصورة'), findsNWidgets(2));
  });

  testWidgets('a full product refuses before it opens a picker', (tester) async {
    // Arrange — the server refuses the sixth photograph after its bytes arrive. Saying so first
    // spares an upload that was never going to be kept, so no picker may open at all.
    when(() => repository.product(productId)).thenAnswer(
      (_) async => Right(
        productWith([
          for (var id = 1; id <= ProductImageRules.maxPerProduct; id++)
            ProductImage(id: id, url: 'https://cdn.test/$id.jpg', isPrimary: id == 1),
        ]),
      ),
    );
    session.adopt(userWith(['products.view', 'products.manage']));

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('إضافة صورة'));
    await tester.pumpAndSettle();

    // Assert — the message names the cap, and the picker was never reached.
    expect(
      find.textContaining('الحد الأقصى (${ProductImageRules.maxPerProduct} صور)'),
      findsOneWidget,
    );
    expect(picker.asked, isNull);
    verifyNever(() => repository.uploadImage(any(), image: any(named: 'image')));

    // The toast holds a three-second dismissal timer of its own, and a timer still pending when
    // the tree is torn down fails the test. Let it run out.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('the sheet, the picker and the upload are one flow', (tester) async {
    // Arrange
    session.adopt(userWith(['products.view', 'products.manage']));
    picker.answer = const [
      PickedFile(path: '/tmp/side.jpg', name: 'side.jpg', sizeBytes: 2048),
    ];

    const added = ProductImage(id: 3, url: 'https://cdn.test/side.jpg');
    when(
      () => repository.uploadImage(
        any(),
        image: any(named: 'image'),
        onProgress: any(named: 'onProgress'),
      ),
    ).thenAnswer((_) async => const Right(added));

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act — the button opens the sheet, the sheet answers a source, the picker answers a file.
    await tester.tap(find.text('إضافة صورة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('صور'));
    await tester.pumpAndSettle();

    // Assert
    expect(picker.asked, AttachmentSource.photos);
    verify(
      () => repository.uploadImage(
        productId,
        image: any(named: 'image'),
        onProgress: any(named: 'onProgress'),
      ),
    ).called(1);

    // The success toast's own dismissal timer — see the note above.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('deleting asks first, and says the file does not come back', (tester) async {
    // Arrange — the row is soft-deleted like every record here, but the stored file is removed
    // for good. That asymmetry is the reason the dialog says so in words.
    session.adopt(userWith(['products.view', 'products.manage']));
    when(
      () => repository.deleteImage(any(), any()),
    ).thenAnswer((_) async => const Right('تم حذف الصورة بنجاح'));

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.byTooltip('حذف الصورة').first);
    await tester.pumpAndSettle();

    // Assert — asked, not done: nothing has been sent yet.
    expect(find.textContaining('لا يمكن استرجاعها'), findsOneWidget);
    verifyNever(() => repository.deleteImage(any(), any()));
  });

  testWidgets('the server refusing the last photograph is shown in its own words', (
    tester,
  ) async {
    // Arrange — a product may never be left without a picture, and that rule lives on the
    // server. The app repeats its Arabic rather than inventing a second wording.
    when(
      () => repository.product(productId),
    ).thenAnswer((_) async => Right(productWith([front])));
    when(() => repository.deleteImage(any(), any())).thenAnswer(
      (_) async => const Left(
        Failure.server(message: 'لا يمكن حذف الصورة الوحيدة للمنتج', statusCode: 422),
      ),
    );
    session.adopt(userWith(['products.view', 'products.manage']));

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.byTooltip('حذف الصورة'));
    await tester.pumpAndSettle();
    // The dialog's confirm button, which is the `FilledButton` — the tile's own control is an
    // `IconButton` and carries no text.
    await tester.tap(find.widgetWithText(FilledButton, 'حذف'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('لا يمكن حذف الصورة الوحيدة للمنتج'), findsOneWidget);

    // The toast's own dismissal timer — see the note above.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });
}
