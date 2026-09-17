import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/files/picked_file.dart';
import 'package:dayaa_client/features/designs/models/customer_design.dart';
import 'package:dayaa_client/features/designs/presentation/viewmodel/designs_cubit.dart';
import 'package:dayaa_client/features/designs/repositories/design_repository.dart';
import 'package:dayaa_client/features/designs/usecases/list_designs.dart';
import 'package:dayaa_client/features/designs/usecases/remove_design.dart';
import 'package:dayaa_client/features/designs/usecases/rename_design.dart';
import 'package:dayaa_client/features/designs/usecases/upload_design.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDesignRepository extends Mock implements DesignRepository {}

class _FakePickedFile extends Fake implements PickedFile {}

void main() {
  late _MockDesignRepository repository;

  const logo = CustomerDesign(id: 1, label: 'شعار المتجر', kind: DesignKind.image);
  const flyer = CustomerDesign(id: 2, label: 'تصميم الكيس', kind: DesignKind.pdf);

  setUpAll(() => registerFallbackValue(_FakePickedFile()));

  setUp(() => repository = _MockDesignRepository());

  DesignsCubit build() => DesignsCubit(
    list: ListDesigns(repository),
    upload: UploadDesign(repository),
    rename: RenameDesign(repository),
    remove: RemoveDesign(repository),
  );

  group('load', () {
    blocTest<DesignsCubit, DesignsState>(
      'emits loading then the library',
      build: () {
        when(() => repository.list()).thenAnswer((_) async => const Right([logo, flyer]));

        return build();
      },
      act: (cubit) => cubit.load(),
      expect: () => const [
        DesignsState.loading(),
        DesignsState.loaded([logo, flyer]),
      ],
    );

    blocTest<DesignsCubit, DesignsState>(
      'emits a failure when the first load fails — there is no list to keep showing yet',
      build: () {
        when(() => repository.list())
            .thenAnswer((_) async => const Left(NetworkFailure(message: 'لا يوجد اتصال')));

        return build();
      },
      act: (cubit) => cubit.load(),
      expect: () => const [
        DesignsState.loading(),
        DesignsState.failure(NetworkFailure(message: 'لا يوجد اتصال')),
      ],
    );
  });

  group('add', () {
    blocTest<DesignsCubit, DesignsState>(
      'puts a new design at the front — newest first is what somebody is looking for',
      build: () {
        when(() => repository.upload(file: any(named: 'file'), label: any(named: 'label')))
            .thenAnswer((_) async => const Right(flyer));

        return build();
      },
      seed: () => const DesignsState.loaded([logo]),
      act: (cubit) => cubit.add(file: _FakePickedFile()),
      expect: () => const [
        DesignsState.loaded([logo], isBusy: true),
        DesignsState.loaded([flyer, logo]),
      ],
    );

    /// The server answers a file it already holds with the row that exists rather than storing a
    /// second copy — which is what makes a retry after a dropped connection free. The list must
    /// hold one entry, not two.
    blocTest<DesignsCubit, DesignsState>(
      'uploading a file already in the library leaves one entry, not two',
      build: () {
        when(() => repository.upload(file: any(named: 'file'), label: any(named: 'label')))
            .thenAnswer((_) async => const Right(logo));

        return build();
      },
      seed: () => const DesignsState.loaded([logo, flyer]),
      act: (cubit) => cubit.add(file: _FakePickedFile()),
      expect: () => const [
        DesignsState.loaded([logo, flyer], isBusy: true),
        DesignsState.loaded([logo, flyer]),
      ],
    );

    /// A failed upload must not take the library off the screen — it is still perfectly
    /// readable, and a grid that vanishes reads as a broken app.
    blocTest<DesignsCubit, DesignsState>(
      'a failed upload keeps the list and reports beside it',
      build: () {
        when(() => repository.upload(file: any(named: 'file'), label: any(named: 'label')))
            .thenAnswer((_) async => const Left(ServerFailure(message: 'الملف كبير')));

        return build();
      },
      seed: () => const DesignsState.loaded([logo]),
      act: (cubit) => cubit.add(file: _FakePickedFile()),
      expect: () => const [
        DesignsState.loaded([logo], isBusy: true),
        DesignsState.loaded([logo], lastFailure: ServerFailure(message: 'الملف كبير')),
      ],
    );
  });

  blocTest<DesignsCubit, DesignsState>(
    'renaming replaces the row in place and keeps the order',
    build: () {
      when(() => repository.rename(id: any(named: 'id'), label: any(named: 'label')))
          .thenAnswer((_) async => const Right(CustomerDesign(id: 1, label: 'جديد')));

      return build();
    },
    seed: () => const DesignsState.loaded([logo, flyer]),
    act: (cubit) => cubit.renameTo(id: 1, label: 'جديد'),
    expect: () => const [
      DesignsState.loaded([logo, flyer], isBusy: true),
      DesignsState.loaded([CustomerDesign(id: 1, label: 'جديد'), flyer]),
    ],
  );

  blocTest<DesignsCubit, DesignsState>(
    'removing drops the row from the list',
    build: () {
      when(() => repository.remove(any())).thenAnswer((_) async => const Right(unit));

      return build();
    },
    seed: () => const DesignsState.loaded([logo, flyer]),
    act: (cubit) => cubit.removeAt(1),
    expect: () => const [
      DesignsState.loaded([logo, flyer], isBusy: true),
      DesignsState.loaded([flyer]),
    ],
  );

  /// A write before the first load has nothing to mutate, and guessing would be worse than
  /// doing nothing.
  blocTest<DesignsCubit, DesignsState>(
    'a write before anything has loaded is ignored',
    build: build,
    act: (cubit) => cubit.removeAt(1),
    expect: () => const <DesignsState>[],
  );
}
