import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/customer_messages/models/customer_messages.dart';

/// «رسائل الزبائن» — the wording of the ready and return messages.
abstract interface class CustomerMessagesRepository {
  Future<Either<Failure, CustomerMessages>> messages();

  /// Saves the given texts, keyed by message key. A null text puts the built-in wording back.
  Future<Either<Failure, CustomerMessages>> update(Map<String, String?> bodies);
}
