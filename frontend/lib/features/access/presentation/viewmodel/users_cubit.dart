import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/core/pagination/paged_cubit.dart';
import 'package:printing/core/pagination/paged_state.dart';
import 'package:printing/features/access/usecases/get_users.dart';
import 'package:printing/features/auth/models/auth_user.dart';

/// The staff screen's ViewModel.
///
/// The debounce, the out-of-order guard and appending pages all come from [PagedCubit]. What is
/// left is the one thing that is about staff: which use case fetches them.
///
/// **Assigning roles is not here.** It belongs to one person at a time and has its own failure
/// to show, so it lives in `UserRolesCubit` — this one only ever lists.
class UsersCubit extends PagedCubit<AuthUser> {
  UsersCubit({required GetUsers getUsers}) : _getUsers = getUsers;

  final GetUsers _getUsers;

  @override
  Future<Either<Failure, Paginated<AuthUser>>> fetchPage({
    String? search,
    required int page,
  }) {
    return _getUsers(search: search, page: page);
  }
}

/// A name for `PagedState<AuthUser>`, so the view reads as a staff screen.
typedef UsersState = PagedState<AuthUser>;
typedef UsersInitial = PagedInitial<AuthUser>;
typedef UsersLoading = PagedLoading<AuthUser>;
typedef UsersLoaded = PagedLoaded<AuthUser>;
typedef UsersFailure = PagedFailure<AuthUser>;
