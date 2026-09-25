import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/delivery/models/city.dart';
import 'package:dayaa_client/features/delivery/repositories/delivery_repository.dart';
import 'package:dayaa_client/features/delivery/usecases/list_cities.dart';
import 'package:dayaa_client/features/shops/models/shop.dart';
import 'package:dayaa_client/features/shops/presentation/viewmodel/shop_form_cubit.dart';
import 'package:dayaa_client/features/shops/repositories/shop_repository.dart';
import 'package:dayaa_client/features/shops/usecases/add_shop.dart';
import 'package:dayaa_client/features/shops/usecases/list_business_fields.dart';
import 'package:dayaa_client/features/shops/usecases/update_shop.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockShopRepository extends Mock implements ShopRepository {}

class _MockDeliveryRepository extends Mock implements DeliveryRepository {}

/// نموذج المتجر بحقول نموذج الموظفين الأربعة: إضافةٌ حين لا يُمرَّر متجر، وتعديلٌ حين يُمرَّر.
///
/// Arrange - Act - Assert throughout.
void main() {
  late _MockShopRepository shops;
  late _MockDeliveryRepository delivery;

  const kish = Region(id: 10, cityId: 1, name: 'الكيش');
  const benghazi = City(id: 1, name: 'بنغازي', regions: [kish]);
  const tripoli = City(id: 2, name: 'طرابلس');
  const cities = [benghazi, tripoli];

  const clothes = BusinessField(id: 3, name: 'ملابس وأحذية');
  const perfume = BusinessField(id: 4, name: 'عطور');
  const trades = [clothes, perfume];

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

  setUp(() {
    shops = _MockShopRepository();
    delivery = _MockDeliveryRepository();

    when(() => delivery.cities()).thenAnswer((_) async => const Right(cities));
    when(() => shops.businessFields()).thenAnswer((_) async => const Right(trades));
  });

  ShopFormCubit build({Shop? editing}) => ShopFormCubit(
    cities: ListCities(delivery),
    businessFields: ListBusinessFields(shops),
    add: AddShop(shops),
    update: UpdateShop(shops),
    editing: editing,
  );

  group('load', () {
    blocTest<ShopFormCubit, ShopFormState>(
      'a new shop starts with nothing chosen, and the trades on offer beside the cities',
      // Arrange
      build: build,
      // Act
      act: (cubit) => cubit.load(),
      // Assert
      expect: () => const [
        ShopFormState.loading(),
        ShopFormState.ready(cities: cities, businessFields: trades),
      ],
    );

    blocTest<ShopFormCubit, ShopFormState>(
      'an edit opens on the shop’s own trade, city and region',
      // Arrange
      build: () => build(editing: noor),
      // Act
      act: (cubit) => cubit.load(),
      // Assert
      expect: () => const [
        ShopFormState.loading(),
        ShopFormState.ready(
          cities: cities,
          businessFields: trades,
          businessFieldId: 3,
          cityId: 1,
          regionId: 10,
        ),
      ],
    );

    blocTest<ShopFormCubit, ShopFormState>(
      'a trade no longer on offer stays selectable on the shop that already has it',
      // Arrange — كما في منتقي الموظفين: فتحُ متجرٍ قديم لا يمحو مجالاً سُجّل له يوماً.
      build: () {
        when(() => shops.businessFields()).thenAnswer((_) async => const Right([perfume]));

        return build(editing: noor);
      },
      // Act
      act: (cubit) => cubit.load(),
      // Assert
      expect: () => const [
        ShopFormState.loading(),
        ShopFormState.ready(
          cities: cities,
          businessFields: [perfume, clothes],
          businessFieldId: 3,
          cityId: 1,
          regionId: 10,
        ),
      ],
    );

    blocTest<ShopFormCubit, ShopFormState>(
      'the trades failing to load does not stop the form — the field is optional',
      // Arrange
      build: () {
        when(() => shops.businessFields())
            .thenAnswer((_) async => const Left(NetworkFailure(message: 'لا يوجد اتصال')));

        return build();
      },
      // Act
      act: (cubit) => cubit.load(),
      // Assert
      expect: () => const [
        ShopFormState.loading(),
        ShopFormState.ready(cities: cities),
      ],
    );

    blocTest<ShopFormCubit, ShopFormState>(
      'a city taken off the map since is not preselected — the picker would show a blank anyway',
      // Arrange
      build: () => build(editing: noor.copyWith(cityId: 99, regionId: null)),
      // Act
      act: (cubit) => cubit.load(),
      // Assert
      expect: () => const [
        ShopFormState.loading(),
        ShopFormState.ready(cities: cities, businessFields: trades, businessFieldId: 3),
      ],
    );

    blocTest<ShopFormCubit, ShopFormState>(
      'the city list failing is the whole form failing — a shop needs a city',
      // Arrange
      build: () {
        when(() => delivery.cities())
            .thenAnswer((_) async => const Left(NetworkFailure(message: 'لا يوجد اتصال')));

        return build();
      },
      // Act
      act: (cubit) => cubit.load(),
      // Assert
      expect: () => const [
        ShopFormState.loading(),
        ShopFormState.failure(NetworkFailure(message: 'لا يوجد اتصال')),
      ],
    );
  });

  group('choosing', () {
    blocTest<ShopFormCubit, ShopFormState>(
      'another city clears the region — a neighbourhood belongs to the city it was picked in',
      // Arrange
      build: build,
      seed: () => const ShopFormState.ready(cities: cities, cityId: 1, regionId: 10),
      // Act
      act: (cubit) => cubit.chooseCity(2),
      // Assert
      expect: () => const [
        ShopFormState.ready(cities: cities, cityId: 2),
      ],
    );

    blocTest<ShopFormCubit, ShopFormState>(
      'a region can be chosen inside the city',
      // Arrange
      build: build,
      seed: () => const ShopFormState.ready(cities: cities, cityId: 1),
      // Act
      act: (cubit) => cubit.chooseRegion(10),
      // Assert
      expect: () => const [
        ShopFormState.ready(cities: cities, cityId: 1, regionId: 10),
      ],
    );

    blocTest<ShopFormCubit, ShopFormState>(
      'a trade can be chosen, and «غير محدد» put back',
      // Arrange
      build: build,
      seed: () => const ShopFormState.ready(cities: cities, businessFields: trades),
      // Act
      act: (cubit) => cubit
        ..chooseBusinessField(4)
        ..chooseBusinessField(null),
      // Assert
      expect: () => const [
        ShopFormState.ready(cities: cities, businessFields: trades, businessFieldId: 4),
        ShopFormState.ready(cities: cities, businessFields: trades),
      ],
    );
  });

  group('save', () {
    test('a new shop is added with all four fields, and handed back to the opener', () async {
      // Arrange
      const added = Shop(id: 9, name: 'متجر الأمل', cityId: 2, businessFieldId: 4);
      when(
        () => shops.add(
          name: 'متجر الأمل',
          cityId: 2,
          regionId: null,
          businessFieldId: 4,
          pageUrl: 'https://instagram.com/alamal',
        ),
      ).thenAnswer((_) async => const Right(added));
      final cubit = build()
        ..emit(
          const ShopFormState.ready(cities: cities, businessFields: trades, businessFieldId: 4),
        )
        ..chooseCity(2);

      // Act
      final saved = await cubit.save(name: 'متجر الأمل', pageUrl: 'https://instagram.com/alamal');

      // Assert
      expect(saved, added);
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

    test('an edit updates the same shop rather than adding a second one', () async {
      // Arrange
      when(
        () => shops.update(
          id: 5,
          name: 'النور',
          cityId: 1,
          regionId: 10,
          businessFieldId: 3,
          pageUrl: null,
        ),
      ).thenAnswer((_) async => Right(noor.copyWith(name: 'النور', pageUrl: null)));
      final cubit = build(editing: noor)
        ..emit(
          const ShopFormState.ready(
            cities: cities,
            businessFields: trades,
            businessFieldId: 3,
            cityId: 1,
            regionId: 10,
          ),
        );

      // Act
      final saved = await cubit.save(name: 'النور');

      // Assert
      expect(saved?.name, 'النور');
      verifyNever(
        () => shops.add(
          name: any(named: 'name'),
          cityId: any(named: 'cityId'),
          regionId: any(named: 'regionId'),
          businessFieldId: any(named: 'businessFieldId'),
          pageUrl: any(named: 'pageUrl'),
        ),
      );
    });

    blocTest<ShopFormCubit, ShopFormState>(
      'shows the button busy, then lets go of it',
      // Arrange
      build: () {
        when(
          () => shops.add(name: 'متجر الأمل', cityId: 2),
        ).thenAnswer((_) async => const Right(Shop(id: 9, name: 'متجر الأمل', cityId: 2)));

        return build();
      },
      seed: () => const ShopFormState.ready(cities: cities, cityId: 2),
      // Act
      act: (cubit) => cubit.save(name: 'متجر الأمل'),
      // Assert
      expect: () => const [
        ShopFormState.ready(cities: cities, cityId: 2, isSaving: true),
        ShopFormState.ready(cities: cities, cityId: 2),
      ],
    );

    test('a refusal keeps what was chosen and puts each message under its own field', () async {
      // Arrange
      const refusal = ServerFailure(
        message: 'رابط الصفحة غير صحيح',
        statusCode: 422,
        fieldErrors: {
          'name': ['اسم المكان مطلوب'],
          'page_url': ['رابط الصفحة غير صحيح'],
        },
      );
      when(
        () => shops.add(name: '', cityId: 2, pageUrl: 'صفحتنا'),
      ).thenAnswer((_) async => const Left(refusal));
      final cubit = build()..emit(const ShopFormState.ready(cities: cities, cityId: 2));

      // Act
      final saved = await cubit.save(name: ' ', pageUrl: 'صفحتنا');

      // Assert
      expect(saved, isNull);
      expect(
        cubit.state,
        const ShopFormState.ready(cities: cities, cityId: 2, lastFailure: refusal),
      );
      expect(cubit.state.nameError, 'اسم المكان مطلوب');
      expect(cubit.state.pageUrlError, 'رابط الصفحة غير صحيح');
      expect(cubit.state.hasUnplacedFailure, isFalse);
    });

    test('a refusal with nowhere on the form to sit is said in a message', () async {
      // Arrange
      when(
        () => shops.add(name: 'متجر', cityId: 2),
      ).thenAnswer((_) async => const Left(NetworkFailure(message: 'لا يوجد اتصال')));
      final cubit = build()..emit(const ShopFormState.ready(cities: cities, cityId: 2));

      // Act
      await cubit.save(name: 'متجر');

      // Assert
      expect(cubit.state.hasUnplacedFailure, isTrue);
    });

    test('spaces are neither a name nor a link — an empty link is sent as no link', () async {
      // Arrange
      when(
        () => shops.add(name: 'متجر الأمل', cityId: 2),
      ).thenAnswer((_) async => const Right(Shop(id: 9, name: 'متجر الأمل', cityId: 2)));
      final cubit = build()..emit(const ShopFormState.ready(cities: cities, cityId: 2));

      // Act
      final saved = await cubit.save(name: '  متجر الأمل ', pageUrl: '   ');

      // Assert
      expect(saved, isNotNull);
      verify(() => shops.add(name: 'متجر الأمل', cityId: 2)).called(1);
    });

    test('nothing is sent without a city', () async {
      // Arrange
      final cubit = build()..emit(const ShopFormState.ready(cities: cities));

      // Act
      final saved = await cubit.save(name: 'متجر الأمل');

      // Assert
      expect(saved, isNull);
      verifyZeroInteractions(shops);
    });

    test('a city that requires a region is not saved without one', () async {
      // Arrange — بنغازي تطلب منطقة، ومتجرٌ فيها بلا منطقة يوقف كل طلبيةٍ إليه.
      const strict = City(id: 1, name: 'بنغازي', isRegionRequired: true, regions: [kish]);
      final cubit = build()..emit(const ShopFormState.ready(cities: [strict], cityId: 1));

      // Act
      final saved = await cubit.save(name: 'متجر النور');

      // Assert
      expect(saved, isNull);
      expect(cubit.state.canSave, isFalse);
      verifyZeroInteractions(shops);
    });
  });
}
