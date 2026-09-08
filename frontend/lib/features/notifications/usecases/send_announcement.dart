import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/notifications/repositories/notifications_repository.dart';

/// Puts a message on every phone in the company, or on one role's phones.
///
/// **Cannot be recalled and cannot be scheduled** — the backend offers neither, and no screen
/// built on this may imply otherwise. [roleId] null means everyone.
class SendAnnouncement {
  const SendAnnouncement(this._repository);

  final NotificationsRepository _repository;

  Future<Either<Failure, String>> call({
    required String title,
    required String body,
    int? roleId,
  }) => _repository.sendAnnouncement(title: title, body: body, roleId: roleId);
}
