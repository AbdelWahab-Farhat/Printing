import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/social_links/models/social_link.dart';
import 'package:dayaa_client/features/social_links/presentation/viewmodel/social_links_cubit.dart';
import 'package:dayaa_client/features/social_links/repositories/social_link_repository.dart';
import 'package:dayaa_client/features/social_links/usecases/list_social_links.dart';
import 'package:dayaa_client/features/social_links/usecases/save_social_links.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSocialLinkRepository extends Mock implements SocialLinkRepository {}

/// «روابط التواصل» — تُقرأ مرة، وتُحفظ مجموعةً واحدة.
///
/// Arrange - Act - Assert throughout.
void main() {
  late _MockSocialLinkRepository repository;

  const facebook = SocialLink(id: 12, url: 'https://facebook.com/alnoor.print');
  const instagram = SocialLink(id: 13, url: 'https://instagram.com/alnoor.print');

  setUpAll(() => registerFallbackValue(<SocialLinkInput>[]));

  setUp(() => repository = _MockSocialLinkRepository());

  SocialLinksCubit build() => SocialLinksCubit(
    list: ListSocialLinks(repository),
    save: SaveSocialLinks(repository),
  );

  group('load', () {
    blocTest<SocialLinksCubit, SocialLinksState>(
      'emits loading then the links, in the order they were added',
      // Arrange
      build: () {
        when(() => repository.list()).thenAnswer((_) async => const Right([facebook, instagram]));

        return build();
      },
      // Act
      act: (cubit) => cubit.load(),
      // Assert
      expect: () => const [
        SocialLinksState.loading(),
        SocialLinksState.loaded([facebook, instagram]),
      ],
    );

    blocTest<SocialLinksCubit, SocialLinksState>(
      'an account with no links is an empty list, not an error',
      // Arrange
      build: () {
        when(() => repository.list()).thenAnswer((_) async => const Right(<SocialLink>[]));

        return build();
      },
      // Act
      act: (cubit) => cubit.load(),
      // Assert
      expect: () => const [
        SocialLinksState.loading(),
        SocialLinksState.loaded(<SocialLink>[]),
      ],
    );

    blocTest<SocialLinksCubit, SocialLinksState>(
      'shows the server’s own words when the load fails',
      // Arrange
      build: () {
        when(
          () => repository.list(),
        ).thenAnswer((_) async => const Left(NetworkFailure(message: 'لا يوجد اتصال')));

        return build();
      },
      // Act
      act: (cubit) => cubit.load(),
      // Assert
      expect: () => const [
        SocialLinksState.loading(),
        SocialLinksState.failure(NetworkFailure(message: 'لا يوجد اتصال')),
      ],
    );
  });

  group('save', () {
    test('sends every link normalised — a link typed without https gets it', () async {
      // Arrange
      when(() => repository.list()).thenAnswer((_) async => const Right([facebook]));
      when(() => repository.save(any())).thenAnswer((_) async => const Right([facebook, instagram]));
      final cubit = build();
      await cubit.load();

      // Act
      await cubit.save(const [
        (id: 12, url: ' https://facebook.com/alnoor.print '),
        (id: null, url: 'instagram.com/alnoor.print'),
      ]);

      // Assert
      final sent = verify(() => repository.save(captureAny())).captured.single as List<SocialLinkInput>;
      expect(sent, const [
        (id: 12, url: 'https://facebook.com/alnoor.print'),
        (id: null, url: 'https://instagram.com/alnoor.print'),
      ]);
      await cubit.close();
    });

    blocTest<SocialLinksCubit, SocialLinksState>(
      'holds the list while saving, then shows what the server stored',
      // Arrange
      build: () {
        when(() => repository.list()).thenAnswer((_) async => const Right([facebook]));
        when(
          () => repository.save(any()),
        ).thenAnswer((_) async => const Right([facebook, instagram]));

        return build();
      },
      seed: () => const SocialLinksState.loaded([facebook]),
      // Act
      act: (cubit) => cubit.save(const [
        (id: 12, url: 'https://facebook.com/alnoor.print'),
        (id: null, url: 'https://instagram.com/alnoor.print'),
      ]),
      // Assert
      expect: () => const [
        SocialLinksState.loaded([facebook], isSaving: true),
        SocialLinksState.loaded([facebook, instagram]),
      ],
    );

    test('answers the saved list to the screen, so it can leave', () async {
      // Arrange
      when(() => repository.save(any())).thenAnswer((_) async => const Right([instagram]));
      final cubit = build()..emit(const SocialLinksState.loaded([facebook]));

      // Act
      final saved = await cubit.save(const [(id: null, url: 'https://instagram.com/alnoor.print')]);

      // Assert
      expect(saved, const [instagram]);
      await cubit.close();
    });

    blocTest<SocialLinksCubit, SocialLinksState>(
      'a refused save keeps the list and says why',
      // Arrange
      build: () {
        when(() => repository.save(any())).thenAnswer(
          (_) async => const Left(
            ServerFailure(
              message: 'الرابط مكرر',
              statusCode: 422,
              fieldErrors: {
                'social_links.1.url': ['الرابط مكرر'],
              },
            ),
          ),
        );

        return build();
      },
      seed: () => const SocialLinksState.loaded([facebook]),
      // Act
      act: (cubit) => cubit.save(const [
        (id: 12, url: 'https://facebook.com/alnoor.print'),
        (id: null, url: 'https://facebook.com/alnoor.print'),
      ]),
      // Assert
      expect: () => const [
        SocialLinksState.loaded([facebook], isSaving: true),
        SocialLinksState.loaded(
          [facebook],
          lastFailure: ServerFailure(
            message: 'الرابط مكرر',
            statusCode: 422,
            fieldErrors: {
              'social_links.1.url': ['الرابط مكرر'],
            },
          ),
        ),
      ],
    );

    test('a second tap while saving sends nothing more', () async {
      // Arrange
      when(() => repository.save(any())).thenAnswer((_) async => const Right([facebook]));
      final cubit = build()..emit(const SocialLinksState.loaded([facebook], isSaving: true));

      // Act
      final saved = await cubit.save(const [(id: 12, url: 'https://facebook.com/alnoor.print')]);

      // Assert
      expect(saved, isNull);
      verifyNever(() => repository.save(any()));
      await cubit.close();
    });
  });

  group('errors on the screen', () {
    const refused = SocialLinksState.loaded(
      [facebook],
      lastFailure: ServerFailure(
        message: 'الرابط غير صحيح',
        statusCode: 422,
        fieldErrors: {
          'social_links.0.url': ['الرابط غير صحيح'],
          'social_links.2.id': ['الرابط المحدد غير موجود'],
        },
      ),
    );

    test('a row’s complaint is read by its index, whether about its link or its id', () {
      // Arrange — the refused state above.

      // Act
      final errors = [for (var index = 0; index < 3; index++) refused.rowError(index)];

      // Assert
      expect(errors, ['الرابط غير صحيح', null, 'الرابط المحدد غير موجود']);
      expect(refused.hasUnplacedFailure, isFalse);
    });

    test('a refusal no row can carry — the cap of ten, a dropped line — is said in a message', () {
      // Arrange
      const capped = SocialLinksState.loaded(
        [facebook],
        lastFailure: ServerFailure(
          message: 'لا يمكن إضافة أكثر من 10 روابط',
          statusCode: 422,
          fieldErrors: {
            'social_links': ['لا يمكن إضافة أكثر من 10 روابط'],
          },
        ),
      );
      const offline = SocialLinksState.loaded(
        [facebook],
        lastFailure: NetworkFailure(message: 'لا يوجد اتصال'),
      );

      // Act
      final unplaced = [capped.hasUnplacedFailure, offline.hasUnplacedFailure];

      // Assert
      expect(unplaced, [isTrue, isTrue]);
    });
  });
}
