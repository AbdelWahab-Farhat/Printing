import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/billboards/models/billboard.dart';
import 'package:dayaa_client/features/billboards/presentation/viewmodel/billboard_cubit.dart';
import 'package:dayaa_client/features/billboards/repositories/billboard_repository.dart';
import 'package:dayaa_client/features/billboards/usecases/get_billboards.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockBillboardRepository extends Mock implements BillboardRepository {}

void main() {
  late _MockBillboardRepository repository;

  const banner = Billboard(
    id: 1,
    title: 'عرض الافتتاح',
    imageUrl: 'https://example.test/a.jpg',
    widthPx: 1200,
    heightPx: 600,
    target: BillboardTarget.product(productId: 12),
  );

  setUp(() => repository = _MockBillboardRepository());

  BillboardCubit build() => BillboardCubit(get: GetBillboards(repository));

  blocTest<BillboardCubit, BillboardState>(
    'emits loading then what the shop is showing',
    build: () {
      when(() => repository.showing()).thenAnswer((_) async => const Right([banner]));

      return build();
    },
    act: (cubit) => cubit.load(),
    expect: () => const [
      BillboardState.loading(),
      BillboardState.loaded([banner]),
    ],
  );

  /// **No campaign running is an answer, not a failure.** The carousel takes no height rather
  /// than drawing an empty box the customer has to scroll past.
  blocTest<BillboardCubit, BillboardState>(
    'an empty billboard is loaded, not a failure',
    build: () {
      when(() => repository.showing()).thenAnswer((_) async => const Right(<Billboard>[]));

      return build();
    },
    act: (cubit) => cubit.load(),
    expect: () => const [
      BillboardState.loading(),
      BillboardState.loaded(<Billboard>[]),
    ],
    verify: (cubit) {
      expect(cubit.state.hasAnything, isFalse);
    },
  );

  blocTest<BillboardCubit, BillboardState>(
    'a carousel that will not load fails without taking the home screen with it',
    build: () {
      when(
        () => repository.showing(),
      ).thenAnswer((_) async => const Left(NetworkFailure(message: 'لا يوجد اتصال')));

      return build();
    },
    act: (cubit) => cubit.load(),
    expect: () => const [
      BillboardState.loading(),
      BillboardState.failure(NetworkFailure(message: 'لا يوجد اتصال')),
    ],
    verify: (cubit) {
      expect(cubit.state.hasAnything, isFalse);
      expect(cubit.state.billboards, isEmpty);
    },
  );

  /// السحب للتحديث لا يطفئ الشريط ثم يعيده: ما يعرضه يبقى حتى يصل الجواب الجديد.
  blocTest<BillboardCubit, BillboardState>(
    'loading again keeps what is showing until the new answer arrives',
    build: () {
      when(() => repository.showing()).thenAnswer((_) async => const Right(<Billboard>[]));

      return build();
    },
    seed: () => const BillboardState.loaded([banner]),
    act: (cubit) => cubit.load(),
    expect: () => const [
      BillboardState.loaded(<Billboard>[]),
    ],
  );

  blocTest<BillboardCubit, BillboardState>(
    'loading again and failing keeps the banners that were showing',
    build: () {
      when(
        () => repository.showing(),
      ).thenAnswer((_) async => const Left(NetworkFailure(message: 'لا يوجد اتصال')));

      return build();
    },
    seed: () => const BillboardState.loaded([banner]),
    act: (cubit) => cubit.load(),
    expect: () => <BillboardState>[],
  );

  /// إعلانات التطبيق الثلاثة تملأ الشريط حين لا يعرض المتجر شيئاً — لا حملة جارية، أو شريطٌ لم
  /// يُحمَّل. وأثناء التحميل لا تظهر، كي لا تومض ثم تختفي تحت إعلانٍ حقيقي.
  group('showsHouseAds', () {
    test('no campaign running fills the carousel with the app\'s own ads', () {
      // Arrange
      const state = BillboardState.loaded(<Billboard>[]);

      // Act
      final shows = state.showsHouseAds;

      // Assert
      expect(shows, isTrue);
    });

    test('a carousel that did not load does too, rather than an error', () {
      // Arrange
      const state = BillboardState.failure(NetworkFailure(message: 'لا يوجد اتصال'));

      // Act
      final shows = state.showsHouseAds;

      // Assert
      expect(shows, isTrue);
    });

    test('the shop\'s own banners replace them', () {
      // Arrange
      const state = BillboardState.loaded([banner]);

      // Act
      final shows = state.showsHouseAds;

      // Assert
      expect(shows, isFalse);
    });

    test('while the answer is on its way, neither is drawn yet', () {
      // Arrange
      const state = BillboardState.loading();

      // Act
      final shows = state.showsHouseAds;

      // Assert
      expect(shows, isFalse);
    });
  });

  group('target', () {
    test('a product banner parses into something the app can navigate with', () {
      final parsed = Billboard.fromJson(const {
        'id': 1,
        'title': 'عرض',
        'image_url': 'https://example.test/a.jpg',
        'target': {'type': 'product', 'product_id': 12},
      });

      expect(parsed.target, const BillboardTarget.product(productId: 12));
      expect(parsed.leadsSomewhere, isTrue);
    });

    test('a link banner keeps the url', () {
      final parsed = Billboard.fromJson(const {
        'id': 2,
        'title': 'إعلان',
        'image_url': 'https://example.test/b.jpg',
        'target': {'type': 'url', 'url': 'https://example.test/promo'},
      });

      expect(parsed.target, const BillboardTarget.url(url: 'https://example.test/promo'));
    });

    test('an announcement leads nowhere and says so', () {
      final parsed = Billboard.fromJson(const {
        'id': 3,
        'title': 'إعلان',
        'image_url': 'https://example.test/c.jpg',
        'target': {'type': 'none'},
      });

      expect(parsed.target, const BillboardTarget.none());
      expect(parsed.leadsSomewhere, isFalse);
    });

    /// **A target type added after this build shipped must not crash the first screen anybody
    /// sees.** It falls back to «leads nowhere», which is exactly how an app that cannot act on
    /// a target should behave.
    test('a target this build has never heard of falls back to leading nowhere', () {
      final parsed = Billboard.fromJson(const {
        'id': 4,
        'title': 'إعلان',
        'image_url': 'https://example.test/d.jpg',
        'target': {'type': 'category', 'category_id': 3},
      });

      expect(parsed.target, const BillboardTarget.none());
      expect(parsed.leadsSomewhere, isFalse);
    });
  });

  group('aspectRatio', () {
    test('uses the dimensions the server sent', () {
      expect(banner.aspectRatio, 2);
    });

    /// A zero would collapse the carousel, and a missing pair is not a reason to.
    test('falls back to a wide banner when the server sent nothing usable', () {
      const noSize = Billboard(id: 5, title: 'إعلان', imageUrl: 'https://example.test/e.jpg');
      const zero = Billboard(
        id: 6,
        title: 'إعلان',
        imageUrl: 'https://example.test/f.jpg',
        widthPx: 0,
        heightPx: 0,
      );

      expect(noSize.aspectRatio, 16 / 9);
      expect(zero.aspectRatio, 16 / 9);
    });
  });
}
