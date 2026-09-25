import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/files/picked_file.dart';
import 'package:dayaa_client/features/designs/models/customer_design.dart';

/// The customer's own artwork library.
abstract interface class DesignRepository {
  /// Everything in the library, newest first.
  ///
  /// **Not paginated, and the server agrees**: a customer holds at most fifty designs, so there
  /// is nothing to page through and a cursor would be ceremony.
  Future<Either<Failure, List<CustomerDesign>>> list();

  /// Adds a file to the library.
  ///
  /// **Idempotent at the server.** Sending a file already held answers with the design that
  /// exists rather than storing a second copy — a dropped connection on a phone leaves this app
  /// unable to know whether the upload landed, so the retry has to be free.
  Future<Either<Failure, CustomerDesign>> upload({
    required PickedFile file,
    String? label,
  });

  /// Renames one. The file itself is never swapped — a new version is a new upload, because an
  /// order points at a design and replacing the bytes under a stable id would change what an old
  /// order says was printed.
  Future<Either<Failure, CustomerDesign>> rename({
    required int id,
    required String label,
  });

  /// Hides one from the library. The file is kept, so an order that used it still resolves.
  Future<Either<Failure, Unit>> remove(int id);

  /// بايتات الملف نفسه، من رابطه الموقَّع — لـ«تحميل».
  ///
  /// **الرابط يُمرَّر ولا يُخزَّن**: يُوقَّع مع كل طلب وتنتهي صلاحيته، فيُجلب بما تحمله الشاشة
  /// الآن.
  Future<Either<Failure, Uint8List>> fileBytes(String fileUrl);
}
