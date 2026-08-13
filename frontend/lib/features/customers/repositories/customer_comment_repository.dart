import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/customers/models/customer_comment.dart';

/// What the app can do about the notes staff leave on a customer.
///
/// Its own contract rather than four more methods on `CustomerRepository`, for the same reason
/// the design library has one: everything here is scoped to a single customer and none of it
/// paginates, while the customer repository is a searchable, paged list of people.
abstract interface class CustomerCommentRepository {
  /// Every note on this customer, newest first.
  ///
  /// A plain list, not a page. Notes accumulate at the speed of conversation, and a load-more
  /// spinner under a list that is already complete is a lie about there being more.
  Future<Either<Failure, List<CustomerComment>>> comments(int customerId);

  /// Leaves a note, and answers with the one the server stored.
  ///
  /// The author is never sent: the backend stamps the signed-in user, which is what makes it
  /// impossible to sign somebody else's name to a sentence.
  Future<Either<Failure, CustomerComment>> add(int customerId, {required String body});

  /// Rewrites one.
  ///
  /// Refused with 403 for a note this user did not write, unless they hold
  /// `customers.comments.moderate` — which is exactly what the note's `canEdit` already says,
  /// so a screen drawing its buttons off that flag will not normally meet the refusal.
  Future<Either<Failure, CustomerComment>> edit(
    int customerId,
    int commentId, {
    required String body,
  });

  /// Removes one. Soft on the server: the list loses it, the history keeps it, and «من حذف
  /// الملاحظة؟» stays answerable. Answers with the server's own message.
  Future<Either<Failure, String>> remove(int customerId, int commentId);
}
