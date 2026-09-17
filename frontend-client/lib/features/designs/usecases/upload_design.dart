import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/files/picked_file.dart';
import 'package:dayaa_client/features/designs/models/customer_design.dart';
import 'package:dayaa_client/features/designs/repositories/design_repository.dart';

/// Add a file to the library.
class UploadDesign {
  const UploadDesign(this._repository);

  final DesignRepository _repository;

  Future<Either<Failure, CustomerDesign>> call({
    required PickedFile file,
    String? label,
  }) => _repository.upload(file: file, label: label);
}
