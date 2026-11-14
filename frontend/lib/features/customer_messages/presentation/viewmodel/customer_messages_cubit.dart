import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/customer_messages/models/customer_messages.dart';
import 'package:dayaa/features/customer_messages/usecases/customer_messages_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Reads and writes «رسائل الزبائن».
///
/// What is shown after a save is the server's answer, not the fields: a text saved equal to the
/// built-in one comes back as «not customised», and the screen should say so.
class CustomerMessagesCubit extends Cubit<CustomerMessagesState> {
  CustomerMessagesCubit({
    required GetCustomerMessages getMessages,
    required UpdateCustomerMessages updateMessages,
  }) : _getMessages = getMessages,
       _updateMessages = updateMessages,
       super(const CustomerMessagesLoading());

  final GetCustomerMessages _getMessages;
  final UpdateCustomerMessages _updateMessages;

  Future<void> load() async {
    emit(const CustomerMessagesLoading());

    final result = await _getMessages();

    if (isClosed) return;

    emit(result.fold(CustomerMessagesFailure.new, CustomerMessagesLoaded.new));
  }

  /// Saves and keeps what the server sent back. Returns the failure to show, or null.
  Future<Failure?> save(Map<String, String?> bodies) async {
    final result = await _updateMessages(bodies);

    if (isClosed) return null;

    return result.fold((failure) => failure, (saved) {
      emit(CustomerMessagesLoaded(saved));

      return null;
    });
  }
}

sealed class CustomerMessagesState {
  const CustomerMessagesState();
}

final class CustomerMessagesLoading extends CustomerMessagesState {
  const CustomerMessagesLoading();
}

final class CustomerMessagesLoaded extends CustomerMessagesState {
  const CustomerMessagesLoaded(this.messages);

  final CustomerMessages messages;
}

final class CustomerMessagesFailure extends CustomerMessagesState {
  const CustomerMessagesFailure(this.failure);

  final Failure failure;
}
