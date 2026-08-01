// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'customer_detail_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CustomerDetailState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomerDetailState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CustomerDetailState()';
}


}

/// @nodoc
class $CustomerDetailStateCopyWith<$Res>  {
$CustomerDetailStateCopyWith(CustomerDetailState _, $Res Function(CustomerDetailState) __);
}


/// Adds pattern-matching-related methods to [CustomerDetailState].
extension CustomerDetailStatePatterns on CustomerDetailState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CustomerDetailLoading value)?  loading,TResult Function( CustomerDetailLoaded value)?  loaded,TResult Function( CustomerDetailChanging value)?  changing,TResult Function( CustomerDetailFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CustomerDetailLoading() when loading != null:
return loading(_that);case CustomerDetailLoaded() when loaded != null:
return loaded(_that);case CustomerDetailChanging() when changing != null:
return changing(_that);case CustomerDetailFailure() when failure != null:
return failure(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CustomerDetailLoading value)  loading,required TResult Function( CustomerDetailLoaded value)  loaded,required TResult Function( CustomerDetailChanging value)  changing,required TResult Function( CustomerDetailFailure value)  failure,}){
final _that = this;
switch (_that) {
case CustomerDetailLoading():
return loading(_that);case CustomerDetailLoaded():
return loaded(_that);case CustomerDetailChanging():
return changing(_that);case CustomerDetailFailure():
return failure(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CustomerDetailLoading value)?  loading,TResult? Function( CustomerDetailLoaded value)?  loaded,TResult? Function( CustomerDetailChanging value)?  changing,TResult? Function( CustomerDetailFailure value)?  failure,}){
final _that = this;
switch (_that) {
case CustomerDetailLoading() when loading != null:
return loading(_that);case CustomerDetailLoaded() when loaded != null:
return loaded(_that);case CustomerDetailChanging() when changing != null:
return changing(_that);case CustomerDetailFailure() when failure != null:
return failure(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( Customer customer)?  loaded,TResult Function( Customer customer)?  changing,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CustomerDetailLoading() when loading != null:
return loading();case CustomerDetailLoaded() when loaded != null:
return loaded(_that.customer);case CustomerDetailChanging() when changing != null:
return changing(_that.customer);case CustomerDetailFailure() when failure != null:
return failure(_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( Customer customer)  loaded,required TResult Function( Customer customer)  changing,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case CustomerDetailLoading():
return loading();case CustomerDetailLoaded():
return loaded(_that.customer);case CustomerDetailChanging():
return changing(_that.customer);case CustomerDetailFailure():
return failure(_that.failure);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( Customer customer)?  loaded,TResult? Function( Customer customer)?  changing,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case CustomerDetailLoading() when loading != null:
return loading();case CustomerDetailLoaded() when loaded != null:
return loaded(_that.customer);case CustomerDetailChanging() when changing != null:
return changing(_that.customer);case CustomerDetailFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class CustomerDetailLoading implements CustomerDetailState {
  const CustomerDetailLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomerDetailLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CustomerDetailState.loading()';
}


}




/// @nodoc


class CustomerDetailLoaded implements CustomerDetailState {
  const CustomerDetailLoaded(this.customer);
  

 final  Customer customer;

/// Create a copy of CustomerDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustomerDetailLoadedCopyWith<CustomerDetailLoaded> get copyWith => _$CustomerDetailLoadedCopyWithImpl<CustomerDetailLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomerDetailLoaded&&(identical(other.customer, customer) || other.customer == customer));
}


@override
int get hashCode => Object.hash(runtimeType,customer);

@override
String toString() {
  return 'CustomerDetailState.loaded(customer: $customer)';
}


}

/// @nodoc
abstract mixin class $CustomerDetailLoadedCopyWith<$Res> implements $CustomerDetailStateCopyWith<$Res> {
  factory $CustomerDetailLoadedCopyWith(CustomerDetailLoaded value, $Res Function(CustomerDetailLoaded) _then) = _$CustomerDetailLoadedCopyWithImpl;
@useResult
$Res call({
 Customer customer
});


$CustomerCopyWith<$Res> get customer;

}
/// @nodoc
class _$CustomerDetailLoadedCopyWithImpl<$Res>
    implements $CustomerDetailLoadedCopyWith<$Res> {
  _$CustomerDetailLoadedCopyWithImpl(this._self, this._then);

  final CustomerDetailLoaded _self;
  final $Res Function(CustomerDetailLoaded) _then;

/// Create a copy of CustomerDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? customer = null,}) {
  return _then(CustomerDetailLoaded(
null == customer ? _self.customer : customer // ignore: cast_nullable_to_non_nullable
as Customer,
  ));
}

/// Create a copy of CustomerDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CustomerCopyWith<$Res> get customer {
  
  return $CustomerCopyWith<$Res>(_self.customer, (value) {
    return _then(_self.copyWith(customer: value));
  });
}
}

/// @nodoc


class CustomerDetailChanging implements CustomerDetailState {
  const CustomerDetailChanging(this.customer);
  

 final  Customer customer;

/// Create a copy of CustomerDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustomerDetailChangingCopyWith<CustomerDetailChanging> get copyWith => _$CustomerDetailChangingCopyWithImpl<CustomerDetailChanging>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomerDetailChanging&&(identical(other.customer, customer) || other.customer == customer));
}


@override
int get hashCode => Object.hash(runtimeType,customer);

@override
String toString() {
  return 'CustomerDetailState.changing(customer: $customer)';
}


}

/// @nodoc
abstract mixin class $CustomerDetailChangingCopyWith<$Res> implements $CustomerDetailStateCopyWith<$Res> {
  factory $CustomerDetailChangingCopyWith(CustomerDetailChanging value, $Res Function(CustomerDetailChanging) _then) = _$CustomerDetailChangingCopyWithImpl;
@useResult
$Res call({
 Customer customer
});


$CustomerCopyWith<$Res> get customer;

}
/// @nodoc
class _$CustomerDetailChangingCopyWithImpl<$Res>
    implements $CustomerDetailChangingCopyWith<$Res> {
  _$CustomerDetailChangingCopyWithImpl(this._self, this._then);

  final CustomerDetailChanging _self;
  final $Res Function(CustomerDetailChanging) _then;

/// Create a copy of CustomerDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? customer = null,}) {
  return _then(CustomerDetailChanging(
null == customer ? _self.customer : customer // ignore: cast_nullable_to_non_nullable
as Customer,
  ));
}

/// Create a copy of CustomerDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CustomerCopyWith<$Res> get customer {
  
  return $CustomerCopyWith<$Res>(_self.customer, (value) {
    return _then(_self.copyWith(customer: value));
  });
}
}

/// @nodoc


class CustomerDetailFailure implements CustomerDetailState {
  const CustomerDetailFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of CustomerDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustomerDetailFailureCopyWith<CustomerDetailFailure> get copyWith => _$CustomerDetailFailureCopyWithImpl<CustomerDetailFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomerDetailFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'CustomerDetailState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $CustomerDetailFailureCopyWith<$Res> implements $CustomerDetailStateCopyWith<$Res> {
  factory $CustomerDetailFailureCopyWith(CustomerDetailFailure value, $Res Function(CustomerDetailFailure) _then) = _$CustomerDetailFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$CustomerDetailFailureCopyWithImpl<$Res>
    implements $CustomerDetailFailureCopyWith<$Res> {
  _$CustomerDetailFailureCopyWithImpl(this._self, this._then);

  final CustomerDetailFailure _self;
  final $Res Function(CustomerDetailFailure) _then;

/// Create a copy of CustomerDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(CustomerDetailFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of CustomerDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res> get failure {
  
  return $FailureCopyWith<$Res>(_self.failure, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}

// dart format on
