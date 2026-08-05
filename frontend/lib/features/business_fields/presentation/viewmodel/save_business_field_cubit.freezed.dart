// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'save_business_field_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SaveBusinessFieldState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveBusinessFieldState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SaveBusinessFieldState()';
}


}

/// @nodoc
class $SaveBusinessFieldStateCopyWith<$Res>  {
$SaveBusinessFieldStateCopyWith(SaveBusinessFieldState _, $Res Function(SaveBusinessFieldState) __);
}


/// Adds pattern-matching-related methods to [SaveBusinessFieldState].
extension SaveBusinessFieldStatePatterns on SaveBusinessFieldState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SaveBusinessFieldInitial value)?  initial,TResult Function( SaveBusinessFieldSubmitting value)?  submitting,TResult Function( SaveBusinessFieldSuccess value)?  success,TResult Function( SaveBusinessFieldFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SaveBusinessFieldInitial() when initial != null:
return initial(_that);case SaveBusinessFieldSubmitting() when submitting != null:
return submitting(_that);case SaveBusinessFieldSuccess() when success != null:
return success(_that);case SaveBusinessFieldFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SaveBusinessFieldInitial value)  initial,required TResult Function( SaveBusinessFieldSubmitting value)  submitting,required TResult Function( SaveBusinessFieldSuccess value)  success,required TResult Function( SaveBusinessFieldFailure value)  failure,}){
final _that = this;
switch (_that) {
case SaveBusinessFieldInitial():
return initial(_that);case SaveBusinessFieldSubmitting():
return submitting(_that);case SaveBusinessFieldSuccess():
return success(_that);case SaveBusinessFieldFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SaveBusinessFieldInitial value)?  initial,TResult? Function( SaveBusinessFieldSubmitting value)?  submitting,TResult? Function( SaveBusinessFieldSuccess value)?  success,TResult? Function( SaveBusinessFieldFailure value)?  failure,}){
final _that = this;
switch (_that) {
case SaveBusinessFieldInitial() when initial != null:
return initial(_that);case SaveBusinessFieldSubmitting() when submitting != null:
return submitting(_that);case SaveBusinessFieldSuccess() when success != null:
return success(_that);case SaveBusinessFieldFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  submitting,TResult Function( BusinessField field)?  success,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SaveBusinessFieldInitial() when initial != null:
return initial();case SaveBusinessFieldSubmitting() when submitting != null:
return submitting();case SaveBusinessFieldSuccess() when success != null:
return success(_that.field);case SaveBusinessFieldFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  submitting,required TResult Function( BusinessField field)  success,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case SaveBusinessFieldInitial():
return initial();case SaveBusinessFieldSubmitting():
return submitting();case SaveBusinessFieldSuccess():
return success(_that.field);case SaveBusinessFieldFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  submitting,TResult? Function( BusinessField field)?  success,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case SaveBusinessFieldInitial() when initial != null:
return initial();case SaveBusinessFieldSubmitting() when submitting != null:
return submitting();case SaveBusinessFieldSuccess() when success != null:
return success(_that.field);case SaveBusinessFieldFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class SaveBusinessFieldInitial implements SaveBusinessFieldState {
  const SaveBusinessFieldInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveBusinessFieldInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SaveBusinessFieldState.initial()';
}


}




/// @nodoc


class SaveBusinessFieldSubmitting implements SaveBusinessFieldState {
  const SaveBusinessFieldSubmitting();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveBusinessFieldSubmitting);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SaveBusinessFieldState.submitting()';
}


}




/// @nodoc


class SaveBusinessFieldSuccess implements SaveBusinessFieldState {
  const SaveBusinessFieldSuccess(this.field);
  

 final  BusinessField field;

/// Create a copy of SaveBusinessFieldState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SaveBusinessFieldSuccessCopyWith<SaveBusinessFieldSuccess> get copyWith => _$SaveBusinessFieldSuccessCopyWithImpl<SaveBusinessFieldSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveBusinessFieldSuccess&&(identical(other.field, field) || other.field == field));
}


@override
int get hashCode => Object.hash(runtimeType,field);

@override
String toString() {
  return 'SaveBusinessFieldState.success(field: $field)';
}


}

/// @nodoc
abstract mixin class $SaveBusinessFieldSuccessCopyWith<$Res> implements $SaveBusinessFieldStateCopyWith<$Res> {
  factory $SaveBusinessFieldSuccessCopyWith(SaveBusinessFieldSuccess value, $Res Function(SaveBusinessFieldSuccess) _then) = _$SaveBusinessFieldSuccessCopyWithImpl;
@useResult
$Res call({
 BusinessField field
});


$BusinessFieldCopyWith<$Res> get field;

}
/// @nodoc
class _$SaveBusinessFieldSuccessCopyWithImpl<$Res>
    implements $SaveBusinessFieldSuccessCopyWith<$Res> {
  _$SaveBusinessFieldSuccessCopyWithImpl(this._self, this._then);

  final SaveBusinessFieldSuccess _self;
  final $Res Function(SaveBusinessFieldSuccess) _then;

/// Create a copy of SaveBusinessFieldState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field = null,}) {
  return _then(SaveBusinessFieldSuccess(
null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as BusinessField,
  ));
}

/// Create a copy of SaveBusinessFieldState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BusinessFieldCopyWith<$Res> get field {
  
  return $BusinessFieldCopyWith<$Res>(_self.field, (value) {
    return _then(_self.copyWith(field: value));
  });
}
}

/// @nodoc


class SaveBusinessFieldFailure implements SaveBusinessFieldState {
  const SaveBusinessFieldFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of SaveBusinessFieldState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SaveBusinessFieldFailureCopyWith<SaveBusinessFieldFailure> get copyWith => _$SaveBusinessFieldFailureCopyWithImpl<SaveBusinessFieldFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveBusinessFieldFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'SaveBusinessFieldState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $SaveBusinessFieldFailureCopyWith<$Res> implements $SaveBusinessFieldStateCopyWith<$Res> {
  factory $SaveBusinessFieldFailureCopyWith(SaveBusinessFieldFailure value, $Res Function(SaveBusinessFieldFailure) _then) = _$SaveBusinessFieldFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$SaveBusinessFieldFailureCopyWithImpl<$Res>
    implements $SaveBusinessFieldFailureCopyWith<$Res> {
  _$SaveBusinessFieldFailureCopyWithImpl(this._self, this._then);

  final SaveBusinessFieldFailure _self;
  final $Res Function(SaveBusinessFieldFailure) _then;

/// Create a copy of SaveBusinessFieldState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(SaveBusinessFieldFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of SaveBusinessFieldState
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
