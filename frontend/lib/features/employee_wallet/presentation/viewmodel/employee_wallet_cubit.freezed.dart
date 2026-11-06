// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'employee_wallet_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$EmployeeWalletState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EmployeeWalletState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EmployeeWalletState()';
}


}

/// @nodoc
class $EmployeeWalletStateCopyWith<$Res>  {
$EmployeeWalletStateCopyWith(EmployeeWalletState _, $Res Function(EmployeeWalletState) __);
}


/// Adds pattern-matching-related methods to [EmployeeWalletState].
extension EmployeeWalletStatePatterns on EmployeeWalletState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( EmployeeWalletLoading value)?  loading,TResult Function( EmployeeWalletFailed value)?  failed,TResult Function( EmployeeWalletLoaded value)?  loaded,required TResult orElse(),}){
final _that = this;
switch (_that) {
case EmployeeWalletLoading() when loading != null:
return loading(_that);case EmployeeWalletFailed() when failed != null:
return failed(_that);case EmployeeWalletLoaded() when loaded != null:
return loaded(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( EmployeeWalletLoading value)  loading,required TResult Function( EmployeeWalletFailed value)  failed,required TResult Function( EmployeeWalletLoaded value)  loaded,}){
final _that = this;
switch (_that) {
case EmployeeWalletLoading():
return loading(_that);case EmployeeWalletFailed():
return failed(_that);case EmployeeWalletLoaded():
return loaded(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( EmployeeWalletLoading value)?  loading,TResult? Function( EmployeeWalletFailed value)?  failed,TResult? Function( EmployeeWalletLoaded value)?  loaded,}){
final _that = this;
switch (_that) {
case EmployeeWalletLoading() when loading != null:
return loading(_that);case EmployeeWalletFailed() when failed != null:
return failed(_that);case EmployeeWalletLoaded() when loaded != null:
return loaded(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( Failure failure)?  failed,TResult Function( EmployeeWallet wallet,  Failure? refreshFailure)?  loaded,required TResult orElse(),}) {final _that = this;
switch (_that) {
case EmployeeWalletLoading() when loading != null:
return loading();case EmployeeWalletFailed() when failed != null:
return failed(_that.failure);case EmployeeWalletLoaded() when loaded != null:
return loaded(_that.wallet,_that.refreshFailure);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( Failure failure)  failed,required TResult Function( EmployeeWallet wallet,  Failure? refreshFailure)  loaded,}) {final _that = this;
switch (_that) {
case EmployeeWalletLoading():
return loading();case EmployeeWalletFailed():
return failed(_that.failure);case EmployeeWalletLoaded():
return loaded(_that.wallet,_that.refreshFailure);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( Failure failure)?  failed,TResult? Function( EmployeeWallet wallet,  Failure? refreshFailure)?  loaded,}) {final _that = this;
switch (_that) {
case EmployeeWalletLoading() when loading != null:
return loading();case EmployeeWalletFailed() when failed != null:
return failed(_that.failure);case EmployeeWalletLoaded() when loaded != null:
return loaded(_that.wallet,_that.refreshFailure);case _:
  return null;

}
}

}

/// @nodoc


class EmployeeWalletLoading implements EmployeeWalletState {
  const EmployeeWalletLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EmployeeWalletLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EmployeeWalletState.loading()';
}


}




/// @nodoc


class EmployeeWalletFailed implements EmployeeWalletState {
  const EmployeeWalletFailed(this.failure);
  

 final  Failure failure;

/// Create a copy of EmployeeWalletState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EmployeeWalletFailedCopyWith<EmployeeWalletFailed> get copyWith => _$EmployeeWalletFailedCopyWithImpl<EmployeeWalletFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EmployeeWalletFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'EmployeeWalletState.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $EmployeeWalletFailedCopyWith<$Res> implements $EmployeeWalletStateCopyWith<$Res> {
  factory $EmployeeWalletFailedCopyWith(EmployeeWalletFailed value, $Res Function(EmployeeWalletFailed) _then) = _$EmployeeWalletFailedCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$EmployeeWalletFailedCopyWithImpl<$Res>
    implements $EmployeeWalletFailedCopyWith<$Res> {
  _$EmployeeWalletFailedCopyWithImpl(this._self, this._then);

  final EmployeeWalletFailed _self;
  final $Res Function(EmployeeWalletFailed) _then;

/// Create a copy of EmployeeWalletState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(EmployeeWalletFailed(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of EmployeeWalletState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res> get failure {
  
  return $FailureCopyWith<$Res>(_self.failure, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}

/// @nodoc


class EmployeeWalletLoaded implements EmployeeWalletState {
  const EmployeeWalletLoaded(this.wallet, {this.refreshFailure});
  

 final  EmployeeWallet wallet;
/// إعادةُ قراءةٍ فشلت والرأس باقٍ على ما قبلها: يقوله توست.
 final  Failure? refreshFailure;

/// Create a copy of EmployeeWalletState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EmployeeWalletLoadedCopyWith<EmployeeWalletLoaded> get copyWith => _$EmployeeWalletLoadedCopyWithImpl<EmployeeWalletLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EmployeeWalletLoaded&&(identical(other.wallet, wallet) || other.wallet == wallet)&&(identical(other.refreshFailure, refreshFailure) || other.refreshFailure == refreshFailure));
}


@override
int get hashCode => Object.hash(runtimeType,wallet,refreshFailure);

@override
String toString() {
  return 'EmployeeWalletState.loaded(wallet: $wallet, refreshFailure: $refreshFailure)';
}


}

/// @nodoc
abstract mixin class $EmployeeWalletLoadedCopyWith<$Res> implements $EmployeeWalletStateCopyWith<$Res> {
  factory $EmployeeWalletLoadedCopyWith(EmployeeWalletLoaded value, $Res Function(EmployeeWalletLoaded) _then) = _$EmployeeWalletLoadedCopyWithImpl;
@useResult
$Res call({
 EmployeeWallet wallet, Failure? refreshFailure
});


$EmployeeWalletCopyWith<$Res> get wallet;$FailureCopyWith<$Res>? get refreshFailure;

}
/// @nodoc
class _$EmployeeWalletLoadedCopyWithImpl<$Res>
    implements $EmployeeWalletLoadedCopyWith<$Res> {
  _$EmployeeWalletLoadedCopyWithImpl(this._self, this._then);

  final EmployeeWalletLoaded _self;
  final $Res Function(EmployeeWalletLoaded) _then;

/// Create a copy of EmployeeWalletState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? wallet = null,Object? refreshFailure = freezed,}) {
  return _then(EmployeeWalletLoaded(
null == wallet ? _self.wallet : wallet // ignore: cast_nullable_to_non_nullable
as EmployeeWallet,refreshFailure: freezed == refreshFailure ? _self.refreshFailure : refreshFailure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}

/// Create a copy of EmployeeWalletState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EmployeeWalletCopyWith<$Res> get wallet {
  
  return $EmployeeWalletCopyWith<$Res>(_self.wallet, (value) {
    return _then(_self.copyWith(wallet: value));
  });
}/// Create a copy of EmployeeWalletState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res>? get refreshFailure {
    if (_self.refreshFailure == null) {
    return null;
  }

  return $FailureCopyWith<$Res>(_self.refreshFailure!, (value) {
    return _then(_self.copyWith(refreshFailure: value));
  });
}
}

// dart format on
