// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'my_wallet_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MyWalletState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MyWalletState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'MyWalletState()';
}


}

/// @nodoc
class $MyWalletStateCopyWith<$Res>  {
$MyWalletStateCopyWith(MyWalletState _, $Res Function(MyWalletState) __);
}


/// Adds pattern-matching-related methods to [MyWalletState].
extension MyWalletStatePatterns on MyWalletState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( MyWalletLoading value)?  loading,TResult Function( MyWalletFailed value)?  failed,TResult Function( MyWalletLoaded value)?  loaded,required TResult orElse(),}){
final _that = this;
switch (_that) {
case MyWalletLoading() when loading != null:
return loading(_that);case MyWalletFailed() when failed != null:
return failed(_that);case MyWalletLoaded() when loaded != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( MyWalletLoading value)  loading,required TResult Function( MyWalletFailed value)  failed,required TResult Function( MyWalletLoaded value)  loaded,}){
final _that = this;
switch (_that) {
case MyWalletLoading():
return loading(_that);case MyWalletFailed():
return failed(_that);case MyWalletLoaded():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( MyWalletLoading value)?  loading,TResult? Function( MyWalletFailed value)?  failed,TResult? Function( MyWalletLoaded value)?  loaded,}){
final _that = this;
switch (_that) {
case MyWalletLoading() when loading != null:
return loading(_that);case MyWalletFailed() when failed != null:
return failed(_that);case MyWalletLoaded() when loaded != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( Failure failure)?  failed,TResult Function( String balance,  Failure? refreshFailure)?  loaded,required TResult orElse(),}) {final _that = this;
switch (_that) {
case MyWalletLoading() when loading != null:
return loading();case MyWalletFailed() when failed != null:
return failed(_that.failure);case MyWalletLoaded() when loaded != null:
return loaded(_that.balance,_that.refreshFailure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( Failure failure)  failed,required TResult Function( String balance,  Failure? refreshFailure)  loaded,}) {final _that = this;
switch (_that) {
case MyWalletLoading():
return loading();case MyWalletFailed():
return failed(_that.failure);case MyWalletLoaded():
return loaded(_that.balance,_that.refreshFailure);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( Failure failure)?  failed,TResult? Function( String balance,  Failure? refreshFailure)?  loaded,}) {final _that = this;
switch (_that) {
case MyWalletLoading() when loading != null:
return loading();case MyWalletFailed() when failed != null:
return failed(_that.failure);case MyWalletLoaded() when loaded != null:
return loaded(_that.balance,_that.refreshFailure);case _:
  return null;

}
}

}

/// @nodoc


class MyWalletLoading implements MyWalletState {
  const MyWalletLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MyWalletLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'MyWalletState.loading()';
}


}




/// @nodoc


class MyWalletFailed implements MyWalletState {
  const MyWalletFailed(this.failure);
  

 final  Failure failure;

/// Create a copy of MyWalletState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MyWalletFailedCopyWith<MyWalletFailed> get copyWith => _$MyWalletFailedCopyWithImpl<MyWalletFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MyWalletFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'MyWalletState.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $MyWalletFailedCopyWith<$Res> implements $MyWalletStateCopyWith<$Res> {
  factory $MyWalletFailedCopyWith(MyWalletFailed value, $Res Function(MyWalletFailed) _then) = _$MyWalletFailedCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$MyWalletFailedCopyWithImpl<$Res>
    implements $MyWalletFailedCopyWith<$Res> {
  _$MyWalletFailedCopyWithImpl(this._self, this._then);

  final MyWalletFailed _self;
  final $Res Function(MyWalletFailed) _then;

/// Create a copy of MyWalletState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(MyWalletFailed(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of MyWalletState
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


class MyWalletLoaded implements MyWalletState {
  const MyWalletLoaded(this.balance, {this.refreshFailure});
  

 final  String balance;
/// إعادةُ قراءةٍ فشلت والرقم باقٍ على ما قبلها.
 final  Failure? refreshFailure;

/// Create a copy of MyWalletState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MyWalletLoadedCopyWith<MyWalletLoaded> get copyWith => _$MyWalletLoadedCopyWithImpl<MyWalletLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MyWalletLoaded&&(identical(other.balance, balance) || other.balance == balance)&&(identical(other.refreshFailure, refreshFailure) || other.refreshFailure == refreshFailure));
}


@override
int get hashCode => Object.hash(runtimeType,balance,refreshFailure);

@override
String toString() {
  return 'MyWalletState.loaded(balance: $balance, refreshFailure: $refreshFailure)';
}


}

/// @nodoc
abstract mixin class $MyWalletLoadedCopyWith<$Res> implements $MyWalletStateCopyWith<$Res> {
  factory $MyWalletLoadedCopyWith(MyWalletLoaded value, $Res Function(MyWalletLoaded) _then) = _$MyWalletLoadedCopyWithImpl;
@useResult
$Res call({
 String balance, Failure? refreshFailure
});


$FailureCopyWith<$Res>? get refreshFailure;

}
/// @nodoc
class _$MyWalletLoadedCopyWithImpl<$Res>
    implements $MyWalletLoadedCopyWith<$Res> {
  _$MyWalletLoadedCopyWithImpl(this._self, this._then);

  final MyWalletLoaded _self;
  final $Res Function(MyWalletLoaded) _then;

/// Create a copy of MyWalletState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? balance = null,Object? refreshFailure = freezed,}) {
  return _then(MyWalletLoaded(
null == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as String,refreshFailure: freezed == refreshFailure ? _self.refreshFailure : refreshFailure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}

/// Create a copy of MyWalletState
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
