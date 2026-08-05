// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'save_shipping_company_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SaveShippingCompanyState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveShippingCompanyState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SaveShippingCompanyState()';
}


}

/// @nodoc
class $SaveShippingCompanyStateCopyWith<$Res>  {
$SaveShippingCompanyStateCopyWith(SaveShippingCompanyState _, $Res Function(SaveShippingCompanyState) __);
}


/// Adds pattern-matching-related methods to [SaveShippingCompanyState].
extension SaveShippingCompanyStatePatterns on SaveShippingCompanyState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SaveShippingCompanyInitial value)?  initial,TResult Function( SaveShippingCompanySubmitting value)?  submitting,TResult Function( SaveShippingCompanySuccess value)?  success,TResult Function( SaveShippingCompanyFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SaveShippingCompanyInitial() when initial != null:
return initial(_that);case SaveShippingCompanySubmitting() when submitting != null:
return submitting(_that);case SaveShippingCompanySuccess() when success != null:
return success(_that);case SaveShippingCompanyFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SaveShippingCompanyInitial value)  initial,required TResult Function( SaveShippingCompanySubmitting value)  submitting,required TResult Function( SaveShippingCompanySuccess value)  success,required TResult Function( SaveShippingCompanyFailure value)  failure,}){
final _that = this;
switch (_that) {
case SaveShippingCompanyInitial():
return initial(_that);case SaveShippingCompanySubmitting():
return submitting(_that);case SaveShippingCompanySuccess():
return success(_that);case SaveShippingCompanyFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SaveShippingCompanyInitial value)?  initial,TResult? Function( SaveShippingCompanySubmitting value)?  submitting,TResult? Function( SaveShippingCompanySuccess value)?  success,TResult? Function( SaveShippingCompanyFailure value)?  failure,}){
final _that = this;
switch (_that) {
case SaveShippingCompanyInitial() when initial != null:
return initial(_that);case SaveShippingCompanySubmitting() when submitting != null:
return submitting(_that);case SaveShippingCompanySuccess() when success != null:
return success(_that);case SaveShippingCompanyFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  submitting,TResult Function( ShippingCompany company)?  success,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SaveShippingCompanyInitial() when initial != null:
return initial();case SaveShippingCompanySubmitting() when submitting != null:
return submitting();case SaveShippingCompanySuccess() when success != null:
return success(_that.company);case SaveShippingCompanyFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  submitting,required TResult Function( ShippingCompany company)  success,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case SaveShippingCompanyInitial():
return initial();case SaveShippingCompanySubmitting():
return submitting();case SaveShippingCompanySuccess():
return success(_that.company);case SaveShippingCompanyFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  submitting,TResult? Function( ShippingCompany company)?  success,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case SaveShippingCompanyInitial() when initial != null:
return initial();case SaveShippingCompanySubmitting() when submitting != null:
return submitting();case SaveShippingCompanySuccess() when success != null:
return success(_that.company);case SaveShippingCompanyFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class SaveShippingCompanyInitial implements SaveShippingCompanyState {
  const SaveShippingCompanyInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveShippingCompanyInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SaveShippingCompanyState.initial()';
}


}




/// @nodoc


class SaveShippingCompanySubmitting implements SaveShippingCompanyState {
  const SaveShippingCompanySubmitting();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveShippingCompanySubmitting);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SaveShippingCompanyState.submitting()';
}


}




/// @nodoc


class SaveShippingCompanySuccess implements SaveShippingCompanyState {
  const SaveShippingCompanySuccess(this.company);
  

 final  ShippingCompany company;

/// Create a copy of SaveShippingCompanyState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SaveShippingCompanySuccessCopyWith<SaveShippingCompanySuccess> get copyWith => _$SaveShippingCompanySuccessCopyWithImpl<SaveShippingCompanySuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveShippingCompanySuccess&&(identical(other.company, company) || other.company == company));
}


@override
int get hashCode => Object.hash(runtimeType,company);

@override
String toString() {
  return 'SaveShippingCompanyState.success(company: $company)';
}


}

/// @nodoc
abstract mixin class $SaveShippingCompanySuccessCopyWith<$Res> implements $SaveShippingCompanyStateCopyWith<$Res> {
  factory $SaveShippingCompanySuccessCopyWith(SaveShippingCompanySuccess value, $Res Function(SaveShippingCompanySuccess) _then) = _$SaveShippingCompanySuccessCopyWithImpl;
@useResult
$Res call({
 ShippingCompany company
});


$ShippingCompanyCopyWith<$Res> get company;

}
/// @nodoc
class _$SaveShippingCompanySuccessCopyWithImpl<$Res>
    implements $SaveShippingCompanySuccessCopyWith<$Res> {
  _$SaveShippingCompanySuccessCopyWithImpl(this._self, this._then);

  final SaveShippingCompanySuccess _self;
  final $Res Function(SaveShippingCompanySuccess) _then;

/// Create a copy of SaveShippingCompanyState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? company = null,}) {
  return _then(SaveShippingCompanySuccess(
null == company ? _self.company : company // ignore: cast_nullable_to_non_nullable
as ShippingCompany,
  ));
}

/// Create a copy of SaveShippingCompanyState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ShippingCompanyCopyWith<$Res> get company {
  
  return $ShippingCompanyCopyWith<$Res>(_self.company, (value) {
    return _then(_self.copyWith(company: value));
  });
}
}

/// @nodoc


class SaveShippingCompanyFailure implements SaveShippingCompanyState {
  const SaveShippingCompanyFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of SaveShippingCompanyState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SaveShippingCompanyFailureCopyWith<SaveShippingCompanyFailure> get copyWith => _$SaveShippingCompanyFailureCopyWithImpl<SaveShippingCompanyFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveShippingCompanyFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'SaveShippingCompanyState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $SaveShippingCompanyFailureCopyWith<$Res> implements $SaveShippingCompanyStateCopyWith<$Res> {
  factory $SaveShippingCompanyFailureCopyWith(SaveShippingCompanyFailure value, $Res Function(SaveShippingCompanyFailure) _then) = _$SaveShippingCompanyFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$SaveShippingCompanyFailureCopyWithImpl<$Res>
    implements $SaveShippingCompanyFailureCopyWith<$Res> {
  _$SaveShippingCompanyFailureCopyWithImpl(this._self, this._then);

  final SaveShippingCompanyFailure _self;
  final $Res Function(SaveShippingCompanyFailure) _then;

/// Create a copy of SaveShippingCompanyState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(SaveShippingCompanyFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of SaveShippingCompanyState
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
