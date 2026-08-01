// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pick_location_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PickLocationState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PickLocationState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PickLocationState()';
}


}

/// @nodoc
class $PickLocationStateCopyWith<$Res>  {
$PickLocationStateCopyWith(PickLocationState _, $Res Function(PickLocationState) __);
}


/// Adds pattern-matching-related methods to [PickLocationState].
extension PickLocationStatePatterns on PickLocationState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PickLocationIdle value)?  idle,TResult Function( PickLocationSearching value)?  searching,TResult Function( PickLocationResults value)?  results,TResult Function( PickLocationNoResults value)?  noResults,TResult Function( PickLocationSearchFailed value)?  searchFailed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PickLocationIdle() when idle != null:
return idle(_that);case PickLocationSearching() when searching != null:
return searching(_that);case PickLocationResults() when results != null:
return results(_that);case PickLocationNoResults() when noResults != null:
return noResults(_that);case PickLocationSearchFailed() when searchFailed != null:
return searchFailed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PickLocationIdle value)  idle,required TResult Function( PickLocationSearching value)  searching,required TResult Function( PickLocationResults value)  results,required TResult Function( PickLocationNoResults value)  noResults,required TResult Function( PickLocationSearchFailed value)  searchFailed,}){
final _that = this;
switch (_that) {
case PickLocationIdle():
return idle(_that);case PickLocationSearching():
return searching(_that);case PickLocationResults():
return results(_that);case PickLocationNoResults():
return noResults(_that);case PickLocationSearchFailed():
return searchFailed(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PickLocationIdle value)?  idle,TResult? Function( PickLocationSearching value)?  searching,TResult? Function( PickLocationResults value)?  results,TResult? Function( PickLocationNoResults value)?  noResults,TResult? Function( PickLocationSearchFailed value)?  searchFailed,}){
final _that = this;
switch (_that) {
case PickLocationIdle() when idle != null:
return idle(_that);case PickLocationSearching() when searching != null:
return searching(_that);case PickLocationResults() when results != null:
return results(_that);case PickLocationNoResults() when noResults != null:
return noResults(_that);case PickLocationSearchFailed() when searchFailed != null:
return searchFailed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  idle,TResult Function( String term)?  searching,TResult Function( List<Place> places)?  results,TResult Function( String term)?  noResults,TResult Function( Failure failure)?  searchFailed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PickLocationIdle() when idle != null:
return idle();case PickLocationSearching() when searching != null:
return searching(_that.term);case PickLocationResults() when results != null:
return results(_that.places);case PickLocationNoResults() when noResults != null:
return noResults(_that.term);case PickLocationSearchFailed() when searchFailed != null:
return searchFailed(_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  idle,required TResult Function( String term)  searching,required TResult Function( List<Place> places)  results,required TResult Function( String term)  noResults,required TResult Function( Failure failure)  searchFailed,}) {final _that = this;
switch (_that) {
case PickLocationIdle():
return idle();case PickLocationSearching():
return searching(_that.term);case PickLocationResults():
return results(_that.places);case PickLocationNoResults():
return noResults(_that.term);case PickLocationSearchFailed():
return searchFailed(_that.failure);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  idle,TResult? Function( String term)?  searching,TResult? Function( List<Place> places)?  results,TResult? Function( String term)?  noResults,TResult? Function( Failure failure)?  searchFailed,}) {final _that = this;
switch (_that) {
case PickLocationIdle() when idle != null:
return idle();case PickLocationSearching() when searching != null:
return searching(_that.term);case PickLocationResults() when results != null:
return results(_that.places);case PickLocationNoResults() when noResults != null:
return noResults(_that.term);case PickLocationSearchFailed() when searchFailed != null:
return searchFailed(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class PickLocationIdle implements PickLocationState {
  const PickLocationIdle();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PickLocationIdle);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PickLocationState.idle()';
}


}




/// @nodoc


class PickLocationSearching implements PickLocationState {
  const PickLocationSearching(this.term);
  

 final  String term;

/// Create a copy of PickLocationState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PickLocationSearchingCopyWith<PickLocationSearching> get copyWith => _$PickLocationSearchingCopyWithImpl<PickLocationSearching>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PickLocationSearching&&(identical(other.term, term) || other.term == term));
}


@override
int get hashCode => Object.hash(runtimeType,term);

@override
String toString() {
  return 'PickLocationState.searching(term: $term)';
}


}

/// @nodoc
abstract mixin class $PickLocationSearchingCopyWith<$Res> implements $PickLocationStateCopyWith<$Res> {
  factory $PickLocationSearchingCopyWith(PickLocationSearching value, $Res Function(PickLocationSearching) _then) = _$PickLocationSearchingCopyWithImpl;
@useResult
$Res call({
 String term
});




}
/// @nodoc
class _$PickLocationSearchingCopyWithImpl<$Res>
    implements $PickLocationSearchingCopyWith<$Res> {
  _$PickLocationSearchingCopyWithImpl(this._self, this._then);

  final PickLocationSearching _self;
  final $Res Function(PickLocationSearching) _then;

/// Create a copy of PickLocationState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? term = null,}) {
  return _then(PickLocationSearching(
null == term ? _self.term : term // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class PickLocationResults implements PickLocationState {
  const PickLocationResults(final  List<Place> places): _places = places;
  

 final  List<Place> _places;
 List<Place> get places {
  if (_places is EqualUnmodifiableListView) return _places;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_places);
}


/// Create a copy of PickLocationState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PickLocationResultsCopyWith<PickLocationResults> get copyWith => _$PickLocationResultsCopyWithImpl<PickLocationResults>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PickLocationResults&&const DeepCollectionEquality().equals(other._places, _places));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_places));

@override
String toString() {
  return 'PickLocationState.results(places: $places)';
}


}

/// @nodoc
abstract mixin class $PickLocationResultsCopyWith<$Res> implements $PickLocationStateCopyWith<$Res> {
  factory $PickLocationResultsCopyWith(PickLocationResults value, $Res Function(PickLocationResults) _then) = _$PickLocationResultsCopyWithImpl;
@useResult
$Res call({
 List<Place> places
});




}
/// @nodoc
class _$PickLocationResultsCopyWithImpl<$Res>
    implements $PickLocationResultsCopyWith<$Res> {
  _$PickLocationResultsCopyWithImpl(this._self, this._then);

  final PickLocationResults _self;
  final $Res Function(PickLocationResults) _then;

/// Create a copy of PickLocationState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? places = null,}) {
  return _then(PickLocationResults(
null == places ? _self._places : places // ignore: cast_nullable_to_non_nullable
as List<Place>,
  ));
}


}

/// @nodoc


class PickLocationNoResults implements PickLocationState {
  const PickLocationNoResults(this.term);
  

 final  String term;

/// Create a copy of PickLocationState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PickLocationNoResultsCopyWith<PickLocationNoResults> get copyWith => _$PickLocationNoResultsCopyWithImpl<PickLocationNoResults>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PickLocationNoResults&&(identical(other.term, term) || other.term == term));
}


@override
int get hashCode => Object.hash(runtimeType,term);

@override
String toString() {
  return 'PickLocationState.noResults(term: $term)';
}


}

/// @nodoc
abstract mixin class $PickLocationNoResultsCopyWith<$Res> implements $PickLocationStateCopyWith<$Res> {
  factory $PickLocationNoResultsCopyWith(PickLocationNoResults value, $Res Function(PickLocationNoResults) _then) = _$PickLocationNoResultsCopyWithImpl;
@useResult
$Res call({
 String term
});




}
/// @nodoc
class _$PickLocationNoResultsCopyWithImpl<$Res>
    implements $PickLocationNoResultsCopyWith<$Res> {
  _$PickLocationNoResultsCopyWithImpl(this._self, this._then);

  final PickLocationNoResults _self;
  final $Res Function(PickLocationNoResults) _then;

/// Create a copy of PickLocationState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? term = null,}) {
  return _then(PickLocationNoResults(
null == term ? _self.term : term // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class PickLocationSearchFailed implements PickLocationState {
  const PickLocationSearchFailed(this.failure);
  

 final  Failure failure;

/// Create a copy of PickLocationState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PickLocationSearchFailedCopyWith<PickLocationSearchFailed> get copyWith => _$PickLocationSearchFailedCopyWithImpl<PickLocationSearchFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PickLocationSearchFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'PickLocationState.searchFailed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $PickLocationSearchFailedCopyWith<$Res> implements $PickLocationStateCopyWith<$Res> {
  factory $PickLocationSearchFailedCopyWith(PickLocationSearchFailed value, $Res Function(PickLocationSearchFailed) _then) = _$PickLocationSearchFailedCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$PickLocationSearchFailedCopyWithImpl<$Res>
    implements $PickLocationSearchFailedCopyWith<$Res> {
  _$PickLocationSearchFailedCopyWithImpl(this._self, this._then);

  final PickLocationSearchFailed _self;
  final $Res Function(PickLocationSearchFailed) _then;

/// Create a copy of PickLocationState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(PickLocationSearchFailed(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of PickLocationState
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
