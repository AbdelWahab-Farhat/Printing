import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/files/picked_file.dart';
import 'package:dayaa/features/products/models/product.dart';
import 'package:dayaa/features/products/models/product_image_rules.dart';
import 'package:dayaa/features/products/presentation/viewmodel/product_images_cubit.dart';
import 'package:dayaa/features/products/repositories/product_repository.dart';
import 'package:dayaa/features/products/usecases/delete_product_image.dart';
import 'package:dayaa/features/products/usecases/get_product.dart';
import 'package:dayaa/features/products/usecases/set_primary_product_image.dart';
import 'package:dayaa/features/products/usecases/upload_product_image.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// A product's photographs: adding one, promoting one, removing one.
///
/// The behaviour worth pinning here is the **reload after every write**. The API answers a
/// promotion with the promoted image alone and says nothing about the one that lost the badge,
/// so a cubit that patched its own list would draw two primaries. These tests assert the second
/// read happens, which is the only thing that keeps the grid honest.
///
/// Arrange - Act - Assert throughout.
class _MockProductRepository extends Mock implements ProductRepository {}

void main() {
  late _MockProductRepository repository;
  late ProductImagesCubit cubit;

  const productId = 7;

  const first = ProductImage(id: 1, url: 'https://api.test/a.jpg', isPrimary: true);
  const second = ProductImage(id: 2, url: 'https://api.test/b.jpg');

  const photo = PickedFile(path: '/tmp/bag.jpg', name: 'bag.jpg', sizeBytes: 2048);

  /// A product carrying [images]. Only the photographs matter here; the rest is the smallest
  /// shape `Product` will accept.
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

  setUpAll(() {
    registerFallbackValue(photo);
  });

  setUp(() {
    repository = _MockProductRepository();
    cubit = ProductImagesCubit(
      productId: productId,
      getProduct: GetProduct(repository),
      uploadImage: UploadProductImage(repository),
      setPrimary: SetPrimaryProductImage(repository),
      deleteImage: DeleteProductImage(repository),
    );
  });

  tearDown(() async {
    await cubit.close();
  });

  test('load takes the photographs off the product, in the order the server sent them', () async {
    // Arrange — there is no listing endpoint; the images travel inside the product.
    when(
      () => repository.product(any()),
    ).thenAnswer((_) async => Right(productWith([first, second])));

    // Act
    await cubit.load();

    // Assert
    expect(cubit.state, isA<ProductImagesLoaded>());
    expect(cubit.state.images, [first, second]);
    verify(() => repository.product(productId)).called(1);
  });

  test('promoting a photograph re-reads the product rather than patching the list', () async {
    // Arrange — the API answers with the promoted image alone. The one that *lost* the badge is
    // not in that response, so the second read is the only way to learn about it.
    when(() => repository.product(any())).thenAnswer(
      (_) async => Right(productWith([first, second])),
    );
    await cubit.load();

    when(
      () => repository.makeImagePrimary(any(), any()),
    ).thenAnswer((_) async => const Right(ProductImage(id: 2, url: 'b', isPrimary: true)));
    when(() => repository.product(any())).thenAnswer(
      (_) async => Right(productWith([
        const ProductImage(id: 2, url: 'https://api.test/b.jpg', isPrimary: true),
        const ProductImage(id: 1, url: 'https://api.test/a.jpg'),
      ])),
    );

    // Act
    final failure = await cubit.makePrimary(2);

    // Assert — exactly one primary, and it is the promoted one.
    expect(failure, isNull);
    expect(cubit.state.images.where((image) => image.isPrimary).map((image) => image.id), [2]);
    verify(() => repository.makeImagePrimary(productId, 2)).called(1);
    verify(() => repository.product(productId)).called(2);
  });

  test('a refused write leaves the grid alone and hands the failure back', () async {
    // Arrange — deleting the last photograph is the refusal that matters: the server keeps a
    // product from ever having none. Replacing the grid with an error page would be the wrong
    // way to say so, so the state must survive untouched.
    when(() => repository.product(any())).thenAnswer((_) async => Right(productWith([first])));
    await cubit.load();

    const refusal = Failure.server(message: 'لا يمكن حذف الصورة الوحيدة', statusCode: 422);
    when(() => repository.deleteImage(any(), any())).thenAnswer((_) async => const Left(refusal));

    // Act
    final failure = await cubit.remove(1);

    // Assert
    expect(failure, refusal);
    expect(cubit.state.images, [first]);
    // Still one read — the failed delete must not have triggered a reload.
    verify(() => repository.product(productId)).called(1);
  });

  test('a busy photograph refuses a second write until the first is done', () async {
    // Arrange — two taps on «حذف» before the first answers would otherwise send two deletes for
    // one row, and the second would 404 on a record the first removed.
    when(() => repository.product(any())).thenAnswer(
      (_) async => Right(productWith([first, second])),
    );
    await cubit.load();

    when(() => repository.deleteImage(any(), any())).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 20));

      return const Right('تم حذف الصورة بنجاح');
    });

    // Act — both started before either finishes.
    final results = await Future.wait([cubit.remove(2), cubit.remove(2)]);

    // Assert
    expect(results, [null, null]);
    verify(() => repository.deleteImage(productId, 2)).called(1);
  });

  test('a photograph the server would refuse never leaves the phone', () async {
    // Arrange — the local mirror of the API's limits. A 6 MB photo off a modern camera is the
    // ordinary case, and pushing it over a mobile connection to be told 5 MB is the waste this
    // check exists to prevent.
    when(() => repository.product(any())).thenAnswer((_) async => Right(productWith([first])));
    await cubit.load();

    const tooBig = PickedFile(
      path: '/tmp/huge.jpg',
      name: 'huge.jpg',
      sizeBytes: (ProductImageRules.maxKilobytes * 1024) + 1,
    );

    // Act
    final failure = await cubit.add(tooBig);

    // Assert — refused locally, in the server's own words, and no request was made.
    expect(failure, isA<ServerFailure>());
    expect((failure! as ServerFailure).message, contains('ميجابايت'));
    verifyNever(() => repository.uploadImage(any(), image: any(named: 'image')));
  });

  test('a successful upload leaves nothing uploading behind it', () async {
    // Arrange
    when(() => repository.product(any())).thenAnswer((_) async => Right(productWith([first])));
    await cubit.load();

    when(
      () => repository.uploadImage(any(), image: any(named: 'image'), onProgress: any(named: 'onProgress')),
    ).thenAnswer((_) async => const Right(second));
    when(
      () => repository.product(any()),
    ).thenAnswer((_) async => Right(productWith([first, second])));

    // Act
    final failure = await cubit.add(photo);

    // Assert — the new photograph is there, and the progress bar is gone rather than stuck.
    expect(failure, isNull);
    expect(cubit.state.images, [first, second]);
    expect(cubit.state.uploadProgress, isNull);
  });

  test('the cap is what the screen asks before it opens a picker', () async {
    // Arrange — a product carrying exactly the server's cap.
    final full = [
      for (var id = 1; id <= ProductImageRules.maxPerProduct; id++)
        ProductImage(id: id, url: 'https://api.test/$id.jpg', isPrimary: id == 1),
    ];
    when(() => repository.product(any())).thenAnswer((_) async => Right(productWith(full)));

    // Act
    await cubit.load();

    // Assert
    expect(cubit.state.hasRoomForMore, isFalse);
    expect(cubit.state.images, hasLength(ProductImageRules.maxPerProduct));
  });
}
