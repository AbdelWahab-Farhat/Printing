// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'new_internal_ticket_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$NewInternalTicketState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NewInternalTicketState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'NewInternalTicketState()';
}


}

/// @nodoc
class $NewInternalTicketStateCopyWith<$Res>  {
$NewInternalTicketStateCopyWith(NewInternalTicketState _, $Res Function(NewInternalTicketState) __);
}


/// Adds pattern-matching-related methods to [NewInternalTicketState].
extension NewInternalTicketStatePatterns on NewInternalTicketState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( NewInternalTicketLoading value)?  loading,TResult Function( NewInternalTicketFailure value)?  failure,TResult Function( NewInternalTicketReady value)?  ready,required TResult orElse(),}){
final _that = this;
switch (_that) {
case NewInternalTicketLoading() when loading != null:
return loading(_that);case NewInternalTicketFailure() when failure != null:
return failure(_that);case NewInternalTicketReady() when ready != null:
return ready(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( NewInternalTicketLoading value)  loading,required TResult Function( NewInternalTicketFailure value)  failure,required TResult Function( NewInternalTicketReady value)  ready,}){
final _that = this;
switch (_that) {
case NewInternalTicketLoading():
return loading(_that);case NewInternalTicketFailure():
return failure(_that);case NewInternalTicketReady():
return ready(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( NewInternalTicketLoading value)?  loading,TResult? Function( NewInternalTicketFailure value)?  failure,TResult? Function( NewInternalTicketReady value)?  ready,}){
final _that = this;
switch (_that) {
case NewInternalTicketLoading() when loading != null:
return loading(_that);case NewInternalTicketFailure() when failure != null:
return failure(_that);case NewInternalTicketReady() when ready != null:
return ready(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( Failure failure)?  failure,TResult Function( List<Colleague> colleagues,  List<InternalCategory> categories,  bool isSubmitting,  Failure? lastFailure,  InternalTicket? created)?  ready,required TResult orElse(),}) {final _that = this;
switch (_that) {
case NewInternalTicketLoading() when loading != null:
return loading();case NewInternalTicketFailure() when failure != null:
return failure(_that.failure);case NewInternalTicketReady() when ready != null:
return ready(_that.colleagues,_that.categories,_that.isSubmitting,_that.lastFailure,_that.created);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( Failure failure)  failure,required TResult Function( List<Colleague> colleagues,  List<InternalCategory> categories,  bool isSubmitting,  Failure? lastFailure,  InternalTicket? created)  ready,}) {final _that = this;
switch (_that) {
case NewInternalTicketLoading():
return loading();case NewInternalTicketFailure():
return failure(_that.failure);case NewInternalTicketReady():
return ready(_that.colleagues,_that.categories,_that.isSubmitting,_that.lastFailure,_that.created);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( Failure failure)?  failure,TResult? Function( List<Colleague> colleagues,  List<InternalCategory> categories,  bool isSubmitting,  Failure? lastFailure,  InternalTicket? created)?  ready,}) {final _that = this;
switch (_that) {
case NewInternalTicketLoading() when loading != null:
return loading();case NewInternalTicketFailure() when failure != null:
return failure(_that.failure);case NewInternalTicketReady() when ready != null:
return ready(_that.colleagues,_that.categories,_that.isSubmitting,_that.lastFailure,_that.created);case _:
  return null;

}
}

}

/// @nodoc


class NewInternalTicketLoading implements NewInternalTicketState {
  const NewInternalTicketLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NewInternalTicketLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'NewInternalTicketState.loading()';
}


}




/// @nodoc


class NewInternalTicketFailure implements NewInternalTicketState {
  const NewInternalTicketFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of NewInternalTicketState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NewInternalTicketFailureCopyWith<NewInternalTicketFailure> get copyWith => _$NewInternalTicketFailureCopyWithImpl<NewInternalTicketFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NewInternalTicketFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'NewInternalTicketState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $NewInternalTicketFailureCopyWith<$Res> implements $NewInternalTicketStateCopyWith<$Res> {
  factory $NewInternalTicketFailureCopyWith(NewInternalTicketFailure value, $Res Function(NewInternalTicketFailure) _then) = _$NewInternalTicketFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$NewInternalTicketFailureCopyWithImpl<$Res>
    implements $NewInternalTicketFailureCopyWith<$Res> {
  _$NewInternalTicketFailureCopyWithImpl(this._self, this._then);

  final NewInternalTicketFailure _self;
  final $Res Function(NewInternalTicketFailure) _then;

/// Create a copy of NewInternalTicketState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(NewInternalTicketFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of NewInternalTicketState
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


class NewInternalTicketReady implements NewInternalTicketState {
  const NewInternalTicketReady({required final  List<Colleague> colleagues, required final  List<InternalCategory> categories, this.isSubmitting = false, this.lastFailure, this.created}): _colleagues = colleagues,_categories = categories;
  

 final  List<Colleague> _colleagues;
 List<Colleague> get colleagues {
  if (_colleagues is EqualUnmodifiableListView) return _colleagues;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_colleagues);
}

 final  List<InternalCategory> _categories;
 List<InternalCategory> get categories {
  if (_categories is EqualUnmodifiableListView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categories);
}

@JsonKey() final  bool isSubmitting;
/// رفضُ الخادم — رسائلُ حقوله تحت حقولها.
 final  Failure? lastFailure;
/// فُتحت — الشاشةُ تنتقل إليها.
 final  InternalTicket? created;

/// Create a copy of NewInternalTicketState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NewInternalTicketReadyCopyWith<NewInternalTicketReady> get copyWith => _$NewInternalTicketReadyCopyWithImpl<NewInternalTicketReady>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NewInternalTicketReady&&const DeepCollectionEquality().equals(other._colleagues, _colleagues)&&const DeepCollectionEquality().equals(other._categories, _categories)&&(identical(other.isSubmitting, isSubmitting) || other.isSubmitting == isSubmitting)&&(identical(other.lastFailure, lastFailure) || other.lastFailure == lastFailure)&&(identical(other.created, created) || other.created == created));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_colleagues),const DeepCollectionEquality().hash(_categories),isSubmitting,lastFailure,created);

@override
String toString() {
  return 'NewInternalTicketState.ready(colleagues: $colleagues, categories: $categories, isSubmitting: $isSubmitting, lastFailure: $lastFailure, created: $created)';
}


}

/// @nodoc
abstract mixin class $NewInternalTicketReadyCopyWith<$Res> implements $NewInternalTicketStateCopyWith<$Res> {
  factory $NewInternalTicketReadyCopyWith(NewInternalTicketReady value, $Res Function(NewInternalTicketReady) _then) = _$NewInternalTicketReadyCopyWithImpl;
@useResult
$Res call({
 List<Colleague> colleagues, List<InternalCategory> categories, bool isSubmitting, Failure? lastFailure, InternalTicket? created
});


$FailureCopyWith<$Res>? get lastFailure;$InternalTicketCopyWith<$Res>? get created;

}
/// @nodoc
class _$NewInternalTicketReadyCopyWithImpl<$Res>
    implements $NewInternalTicketReadyCopyWith<$Res> {
  _$NewInternalTicketReadyCopyWithImpl(this._self, this._then);

  final NewInternalTicketReady _self;
  final $Res Function(NewInternalTicketReady) _then;

/// Create a copy of NewInternalTicketState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? colleagues = null,Object? categories = null,Object? isSubmitting = null,Object? lastFailure = freezed,Object? created = freezed,}) {
  return _then(NewInternalTicketReady(
colleagues: null == colleagues ? _self._colleagues : colleagues // ignore: cast_nullable_to_non_nullable
as List<Colleague>,categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as List<InternalCategory>,isSubmitting: null == isSubmitting ? _self.isSubmitting : isSubmitting // ignore: cast_nullable_to_non_nullable
as bool,lastFailure: freezed == lastFailure ? _self.lastFailure : lastFailure // ignore: cast_nullable_to_non_nullable
as Failure?,created: freezed == created ? _self.created : created // ignore: cast_nullable_to_non_nullable
as InternalTicket?,
  ));
}

/// Create a copy of NewInternalTicketState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res>? get lastFailure {
    if (_self.lastFailure == null) {
    return null;
  }

  return $FailureCopyWith<$Res>(_self.lastFailure!, (value) {
    return _then(_self.copyWith(lastFailure: value));
  });
}/// Create a copy of NewInternalTicketState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InternalTicketCopyWith<$Res>? get created {
    if (_self.created == null) {
    return null;
  }

  return $InternalTicketCopyWith<$Res>(_self.created!, (value) {
    return _then(_self.copyWith(created: value));
  });
}
}

// dart format on
