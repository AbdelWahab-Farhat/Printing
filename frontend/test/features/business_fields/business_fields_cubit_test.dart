import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/features/business_fields/models/business_field.dart';
import 'package:printing/features/business_fields/presentation/viewmodel/business_fields_cubit.dart';
import 'package:printing/features/business_fields/repositories/business_field_repository.dart';
import 'package:printing/features/business_fields/usecases/delete_business_field.dart';
import 'package:printing/features/business_fields/usecases/get_business_fields.dart';
import 'package:printing/features/business_fields/usecases/set_business_field_activation.dart';

/// مجالات العمل — the management screen's ViewModel.
///
/// The repository is faked, nothing touches Dio, and the assertions are on the sequence of
/// states the screen would have rendered.
///
/// Arrange - Act - Assert throughout.
class _MockBusinessFieldRepository extends Mock implements BusinessFieldRepository {}

void main() {
  late _MockBusinessFieldRepository repository;
  late BusinessFieldsCubit cubit;

  const shipping = BusinessField(id: 1, name: 'شحن وتوصيل', sortOrder: 10, shopsCount: 4);
  const clothes = BusinessField(id: 2, name: 'بيع ملابس', sortOrder: 20, shopsCount: 0);

  Paginated<BusinessField> pageOf(
    List<BusinessField> fields, {
    int currentPage = 1,
    int lastPage = 1,
  }) {
    return Paginated<BusinessField>(
      items: fields,
      meta: PageMeta(
        currentPage: currentPage,
        perPage: 20,
        lastPage: lastPage,
        total: fields.length,
      ),
    );
  }

  /// Every page this fake is asked for, whatever the filters.
  void answerWith(Either<Failure, Paginated<BusinessField>> result) {
    when(
      () => repository.fields(
        search: any(named: 'search'),
        isActive: any(named: 'isActive'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => result);
  }

  setUp(() {
    repository = _MockBusinessFieldRepository();
    cubit = BusinessFieldsCubit(
      getBusinessFields: GetBusinessFields(repository),
      setActivation: SetBusinessFieldActivation(repository),
      deleteBusinessField: DeleteBusinessField(repository),
    );
  });

  tearDown(() => cubit.close());

  group('load', () {
    blocTest<BusinessFieldsCubit, BusinessFieldsState>(
      'goes loading then loaded when the list answers',
      setUp: () {
        // Arrange
        answerWith(Right(pageOf(const [shipping, clothes])));
      },
      build: () => cubit,
      // Act
      act: (cubit) => cubit.load(),
      // Assert
      expect: () => [
        const BusinessFieldsState.loading(),
        isA<BusinessFieldsLoaded>().having(
          (state) => state.page.items.map((field) => field.name),
          'names',
          ['شحن وتوصيل', 'بيع ملابس'],
        ),
      ],
    );

    blocTest<BusinessFieldsCubit, BusinessFieldsState>(
      'the server\'s own message is what a failure carries',
      setUp: () {
        // Arrange
        answerWith(const Left(Failure.server(message: 'ليس لديك صلاحية')));
      },
      build: () => cubit,
      // Act
      act: (cubit) => cubit.load(),
      // Assert — never replaced with a generic sentence: the server took the trouble to say
      // which refusal it was.
      expect: () => [
        const BusinessFieldsState.loading(),
        isA<BusinessFieldsFailure>().having(
          (state) => state.failure.message,
          'message',
          'ليس لديك صلاحية',
        ),
      ],
    );

    blocTest<BusinessFieldsCubit, BusinessFieldsState>(
      'the management screen asks for the stopped fields too',
      setUp: () {
        // Arrange
        answerWith(Right(pageOf(const [shipping])));
      },
      build: () => cubit,
      // Act
      act: (cubit) => cubit.load(),
      // Assert — a screen for *curating* the list has to show what is no longer offered.
      verify: (_) {
        verify(
          () => repository.fields(
            search: null,
            isActive: null,
            page: 1,
            perPage: any(named: 'perPage'),
          ),
        ).called(1);
      },
    );

    blocTest<BusinessFieldsCubit, BusinessFieldsState>(
      'a picker narrows to the fields still on offer',
      setUp: () {
        // Arrange
        answerWith(Right(pageOf(const [shipping])));
      },
      build: () => cubit,
      // Act
      act: (cubit) => cubit.filterByActivity(true),
      // Assert
      verify: (_) {
        verify(
          () => repository.fields(
            search: null,
            isActive: true,
            page: 1,
            perPage: any(named: 'perPage'),
          ),
        ).called(1);
      },
    );

    blocTest<BusinessFieldsCubit, BusinessFieldsState>(
      'the search term survives a change of filter',
      setUp: () {
        // Arrange
        answerWith(Right(pageOf(const [clothes])));
      },
      build: () => cubit,
      // Act — somebody who typed a word and then tapped a chip is narrowing, not restarting.
      act: (cubit) async {
        await cubit.load(search: 'ملابس');
        await cubit.filterByActivity(true);
      },
      // Assert
      verify: (_) {
        verify(
          () => repository.fields(
            search: 'ملابس',
            isActive: true,
            page: 1,
            perPage: any(named: 'perPage'),
          ),
        ).called(1);
      },
    );
  });

  group('stopping a field', () {
    test('the list is re-read from the server rather than patched in place', () async {
      // Arrange — deactivating changes what a filtered list should contain, so a locally edited
      // copy would disagree with the server the moment it happened.
      answerWith(Right(pageOf(const [shipping, clothes])));
      when(
        () => repository.setActivation(any(), isActive: any(named: 'isActive')),
      ).thenAnswer((_) async => const Right(shipping));
      await cubit.load();

      // Act
      final failure = await cubit.setActivation(shipping, isActive: false);

      // Assert
      expect(failure, isNull);
      verify(() => repository.setActivation(1, isActive: false)).called(1);
      verify(
        () => repository.fields(
          search: any(named: 'search'),
          isActive: any(named: 'isActive'),
          page: 1,
          perPage: any(named: 'perPage'),
        ),
      ).called(2);
    });

    test('a refusal comes back to the screen and the list is left alone', () async {
      // Arrange
      answerWith(Right(pageOf(const [shipping])));
      when(
        () => repository.setActivation(any(), isActive: any(named: 'isActive')),
      ).thenAnswer((_) async => const Left(Failure.forbidden(message: 'لا صلاحية')));
      await cubit.load();

      // Act
      final failure = await cubit.setActivation(shipping, isActive: false);

      // Assert — the screen says why nothing changed, in the server's words.
      expect(failure?.message, 'لا صلاحية');
      verify(
        () => repository.fields(
          search: any(named: 'search'),
          isActive: any(named: 'isActive'),
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        ),
      ).called(1);
    });
  });

  group('deleting a field', () {
    test('an unused field is removed and the list re-read', () async {
      // Arrange
      answerWith(Right(pageOf(const [clothes])));
      when(() => repository.delete(any())).thenAnswer((_) async => const Right('تم الحذف'));
      await cubit.load();

      // Act
      final failure = await cubit.remove(clothes);

      // Assert
      expect(failure, isNull);
      verify(() => repository.delete(2)).called(1);
    });

    test('«مرتبط بمحلات» comes back as the failure the sheet shows', () async {
      // Arrange — the server refuses a field any shop points at, and says what to do instead.
      answerWith(Right(pageOf(const [shipping])));
      when(() => repository.delete(any())).thenAnswer(
        (_) async => const Left(
          Failure.server(message: 'لا يمكن حذف «شحن وتوصيل» لارتباطه بـ 4 من محلات العملاء'),
        ),
      );
      await cubit.load();

      // Act
      final failure = await cubit.remove(shipping);

      // Assert — the app does not invent its own sentence for a rule the server owns.
      expect(failure?.message, contains('لارتباطه'));
    });
  });

  group('the field itself', () {
    test('a field with shops on it knows it cannot be deleted', () {
      // Arrange & Act — read off the model, so the sheet and the list agree without either
      // re-deriving the rule.
      const inUse = shipping;
      const free = clothes;

      // Assert
      expect(inUse.isInUse, isTrue);
      expect(free.isInUse, isFalse);
    });

    test('a field whose count was never asked for is assumed to be in use', () {
      // Arrange
      const unknown = BusinessField(id: 9, name: 'أخرى');

      // Act & Assert — refusing a delete wrongly is recoverable; the opposite is a 422 the user
      // cannot act on.
      expect(unknown.isInUse, isTrue);
    });
  });
}
