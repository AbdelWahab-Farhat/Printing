import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/customer_messages/models/customer_messages.dart';
import 'package:dayaa/features/customer_messages/repositories/customer_messages_repository.dart';

class GetCustomerMessages {
  const GetCustomerMessages(this._repository);

  final CustomerMessagesRepository _repository;

  Future<Either<Failure, CustomerMessages>> call() => _repository.messages();
}

class UpdateCustomerMessages {
  const UpdateCustomerMessages(this._repository);

  final CustomerMessagesRepository _repository;

  Future<Either<Failure, CustomerMessages>> call(Map<String, String?> bodies) =>
      _repository.update(bodies);
}
