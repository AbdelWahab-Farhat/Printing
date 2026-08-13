import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/access/repositories/access_repository.dart';
import 'package:printing/features/auth/models/auth_user.dart';

/// Corrects an employee's name, email and phone.
///
/// Trimmed here rather than in the form, for the reason `GetCustomers` trims a search: a phone
/// number pasted with a trailing space is a number that fails validation for a reason nobody
/// can see, and every caller would otherwise have to remember it.
class UpdateUser {
  const UpdateUser(this._repository);

  final AccessRepository _repository;

  Future<Either<Failure, AuthUser>> call({
    required int userId,
    required String name,
    required String email,
    required String phone,
  }) {
    return _repository.updateUser(
      userId: userId,
      name: name.trim(),
      email: email.trim(),
      phone: phone.trim(),
    );
  }
}
