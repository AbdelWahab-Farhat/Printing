import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/features/shipping_companies/models/shipping_company.dart';
import 'package:printing/features/shipping_companies/presentation/viewmodel/shipping_companies_cubit.dart';
import 'package:printing/features/shipping_companies/repositories/shipping_company_repository.dart';
import 'package:printing/features/shipping_companies/usecases/get_shipping_companies.dart';
import 'package:printing/features/shipping_companies/usecases/save_shipping_company.dart';

class _FakeRepository extends Mock implements ShippingCompanyRepository {}

/// The carriers list, and the one thing that separates its two uses.
///
/// Arrange - Act - Assert throughout.
void main() {
  late _FakeRepository repository;

  setUp(() => repository = _FakeRepository());

  ShippingCompany company({int id = 1, String name = 'درب', bool isActive = true}) =>
      ShippingCompany(id: id, name: name, isActive: isActive);

  void stub({List<ShippingCompany> companies = const []}) {
    when(
      () => repository.companies(
        search: any(named: 'search'),
        isActive: any(named: 'isActive'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer(
      (_) async => Right(
        Paginated<ShippingCompany>(
          items: companies,
          meta: PageMeta(
            currentPage: 1,
            perPage: 20,
            lastPage: 1,
            total: companies.length,
          ),
        ),
      ),
    );
  }

  test('the management screen asks for every company, retired ones included', () async {
    // Arrange — the list is the record of who we have dealt with.
    stub(companies: [company()]);
    final cubit = ShippingCompaniesCubit(getCompanies: GetShippingCompanies(repository));

    // Act
    await cubit.load();

    // Assert — no filter at all, rather than `is_active=0`, which would ask for the opposite.
    final captured = verify(
      () => repository.companies(
        search: any(named: 'search'),
        isActive: captureAny(named: 'isActive'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).captured.last;

    expect(captured, isNull);
  });

  test('the dispatch picker asks only for the ones a parcel may still be handed to', () async {
    // Arrange
    stub(companies: [company()]);
    final cubit = ShippingCompaniesCubit(
      getCompanies: GetShippingCompanies(repository),
      onlyActive: true,
    );

    // Act
    await cubit.load();

    // Assert — offering a retired carrier would be a tap that ends in a 422: the server refuses
    // one too.
    final captured = verify(
      () => repository.companies(
        search: any(named: 'search'),
        isActive: captureAny(named: 'isActive'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).captured.last;

    expect(captured, isTrue);
  });

  test('an empty phone is sent as nothing, not as an empty string', () async {
    // Arrange — the box the user left alone means "there is no number".
    when(
      () => repository.create(
        name: any(named: 'name'),
        phone: any(named: 'phone'),
        notes: any(named: 'notes'),
        isActive: any(named: 'isActive'),
      ),
    ).thenAnswer((_) async => Right(company()));

    // Act
    await SaveShippingCompany(repository)(name: '  درب  ', phone: '   ', notes: '');

    // Assert — and the name arrives trimmed, because a name with a trailing space is a second
    // company as far as the unique index is concerned.
    verify(
      () => repository.create(name: 'درب', phone: null, notes: null, isActive: true),
    ).called(1);
  });

  test('an id turns the same call into a correction rather than a second company', () async {
    // Arrange
    when(
      () => repository.update(
        any(),
        name: any(named: 'name'),
        phone: any(named: 'phone'),
        notes: any(named: 'notes'),
        isActive: any(named: 'isActive'),
      ),
    ).thenAnswer((_) async => Right(company()));

    // Act
    await SaveShippingCompany(repository)(id: 7, name: 'درب للشحن', isActive: false);

    // Assert
    verify(
      () => repository.update(7, name: 'درب للشحن', phone: null, notes: null, isActive: false),
    ).called(1);
    verifyNever(
      () => repository.create(
        name: any(named: 'name'),
        phone: any(named: 'phone'),
        notes: any(named: 'notes'),
        isActive: any(named: 'isActive'),
      ),
    );
  });

  test('a refusal reaches the screen as a failure rather than an empty list', () async {
    // Arrange
    when(
      () => repository.companies(
        search: any(named: 'search'),
        isActive: any(named: 'isActive'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => const Left(ServerFailure(message: 'غير مصرح')));

    final cubit = ShippingCompaniesCubit(getCompanies: GetShippingCompanies(repository));

    // Act
    await cubit.load();

    // Assert — an empty list would read as «لم تُضف شركة توصيل بعد», which is a different fact.
    expect(cubit.state, isA<ShippingCompaniesFailure>());
  });
}
