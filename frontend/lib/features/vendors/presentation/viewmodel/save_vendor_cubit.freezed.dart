// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'save_vendor_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SaveVendorState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveVendorState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SaveVendorState()';
}


}

/// @nodoc
class $SaveVendorStateCopyWith<$Res>  {
$SaveVendorStateCopyWith(SaveVendorState _, $Res Function(SaveVendorState) __);
}


/// Adds pattern-matching-related methods to [SaveVendorState].
extension SaveVendorStatePatterns on SaveVendorState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SaveVendorInitial value)?  initial,TResult Function( SaveVendorSubmitting value)?  submitting,TResult Function( SaveVendorSuccess value)?  success,TResult Function( SaveVendorFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SaveVendorInitial() when initial != null:
return initial(_that);case SaveVendorSubmitting() when submitting != null:
return submitting(_that);case SaveVendorSuccess() when success != null:
return success(_that);case SaveVendorFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SaveVendorInitial value)  initial,required TResult Function( SaveVendorSubmitting value)  submitting,required TResult Function( SaveVendorSuccess value)  success,required TResult Function( SaveVendorFailure value)  failure,}){
final _that = this;
switch (_that) {
case SaveVendorInitial():
return initial(_that);case SaveVendorSubmitting():
return submitting(_that);case SaveVendorSuccess():
return success(_that);case SaveVendorFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SaveVendorInitial value)?  initial,TResult? Function( SaveVendorSubmitting value)?  submitting,TResult? Function( SaveVendorSuccess value)?  success,TResult? Function( SaveVendorFailure value)?  failure,}){
final _that = this;
switch (_that) {
case SaveVendorInitial() when initial != null:
return initial(_that);case SaveVendorSubmitting() when submitting != null:
return submitting(_that);case SaveVendorSuccess() when success != null:
return success(_that);case SaveVendorFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  submitting,TResult Function( Vendor vendor)?  success,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SaveVendorInitial() when initial != null:
return initial();case SaveVendorSubmitting() when submitting != null:
return submitting();case SaveVendorSuccess() when success != null:
return success(_that.vendor);case SaveVendorFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  submitting,required TResult Function( Vendor vendor)  success,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case SaveVendorInitial():
return initial();case SaveVendorSubmitting():
return submitting();case SaveVendorSuccess():
return success(_that.vendor);case SaveVendorFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  submitting,TResult? Function( Vendor vendor)?  success,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case SaveVendorInitial() when initial != null:
return initial();case SaveVendorSubmitting() when submitting != null:
return submitting();case SaveVendorSuccess() when success != null:
return success(_that.vendor);case SaveVendorFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class SaveVendorInitial implements SaveVendorState {
  const SaveVendorInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveVendorInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SaveVendorState.initial()';
}


}




/// @nodoc


class SaveVendorSubmitting implements SaveVendorState {
  const SaveVendorSubmitting();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveVendorSubmitting);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SaveVendorState.submitting()';
}


}




/// @nodoc


class SaveVendorSuccess implements SaveVendorState {
  const SaveVendorSuccess(this.vendor);
  

 final  Vendor vendor;

/// Create a copy of SaveVendorState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SaveVendorSuccessCopyWith<SaveVendorSuccess> get copyWith => _$SaveVendorSuccessCopyWithImpl<SaveVendorSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveVendorSuccess&&(identical(other.vendor, vendor) || other.vendor == vendor));
}


@override
int get hashCode => Object.hash(runtimeType,vendor);

@override
String toString() {
  return 'SaveVendorState.success(vendor: $vendor)';
}


}

/// @nodoc
abstract mixin class $SaveVendorSuccessCopyWith<$Res> implements $SaveVendorStateCopyWith<$Res> {
  factory $SaveVendorSuccessCopyWith(SaveVendorSuccess value, $Res Function(SaveVendorSuccess) _then) = _$SaveVendorSuccessCopyWithImpl;
@useResult
$Res call({
 Vendor vendor
});


$VendorCopyWith<$Res> get vendor;

}
/// @nodoc
class _$SaveVendorSuccessCopyWithImpl<$Res>
    implements $SaveVendorSuccessCopyWith<$Res> {
  _$SaveVendorSuccessCopyWithImpl(this._self, this._then);

  final SaveVendorSuccess _self;
  final $Res Function(SaveVendorSuccess) _then;

/// Create a copy of SaveVendorState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? vendor = null,}) {
  return _then(SaveVendorSuccess(
null == vendor ? _self.vendor : vendor // ignore: cast_nullable_to_non_nullable
as Vendor,
  ));
}

/// Create a copy of SaveVendorState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VendorCopyWith<$Res> get vendor {
  
  return $VendorCopyWith<$Res>(_self.vendor, (value) {
    return _then(_self.copyWith(vendor: value));
  });
}
}

/// @nodoc


class SaveVendorFailure implements SaveVendorState {
  const SaveVendorFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of SaveVendorState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SaveVendorFailureCopyWith<SaveVendorFailure> get copyWith => _$SaveVendorFailureCopyWithImpl<SaveVendorFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveVendorFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'SaveVendorState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $SaveVendorFailureCopyWith<$Res> implements $SaveVendorStateCopyWith<$Res> {
  factory $SaveVendorFailureCopyWith(SaveVendorFailure value, $Res Function(SaveVendorFailure) _then) = _$SaveVendorFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$SaveVendorFailureCopyWithImpl<$Res>
    implements $SaveVendorFailureCopyWith<$Res> {
  _$SaveVendorFailureCopyWithImpl(this._self, this._then);

  final SaveVendorFailure _self;
  final $Res Function(SaveVendorFailure) _then;

/// Create a copy of SaveVendorState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(SaveVendorFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of SaveVendorState
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
