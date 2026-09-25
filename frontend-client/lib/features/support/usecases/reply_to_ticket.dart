import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/files/picked_file.dart';
import 'package:dayaa_client/core/files/transfer_cancel.dart';
import 'package:dayaa_client/features/support/models/support_ticket.dart';
import 'package:dayaa_client/features/support/repositories/support_repository.dart';

/// Replies to a thread — كلاماً أو ملفاً. A reply to a closed one reopens it — the server's
/// decision, and the refreshed ticket says so.
class ReplyToTicket {
  const ReplyToTicket(this._repository);

  final SupportRepository _repository;

  Future<Either<Failure, SupportTicket>> call({
    required int id,
    String body = '',
    PickedFile? file,
    String? clientToken,
    void Function(double progress)? onProgress,
    TransferCancel? cancel,
  }) => _repository.reply(
    id: id,
    body: body,
    file: file,
    clientToken: clientToken,
    onProgress: onProgress,
    cancel: cancel,
  );
}
