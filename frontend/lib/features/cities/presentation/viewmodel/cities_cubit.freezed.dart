// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cities_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CitiesState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CitiesState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CitiesState()';
}


}

/// @nodoc
class $CitiesStateCopyWith<$Res>  {
$CitiesStateCopyWith(CitiesState _, $Res Function(CitiesState) __);
}


/// Adds pattern-matching-related methods to [CitiesState].
extension CitiesStatePatterns on CitiesState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CitiesInitial value)?  initial,TResult Function( CitiesLoading value)?  loading,TResult Function( CitiesLoaded value)?  loaded,TResult Function( CitiesFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CitiesInitial() when initial != null:
return initial(_that);case CitiesLoading() when loading != null:
return loading(_that);case CitiesLoaded() when loaded != null:
return loaded(_that);case CitiesFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CitiesInitial value)  initial,required TResult Function( CitiesLoading value)  loading,required TResult Function( CitiesLoaded value)  loaded,required TResult Function( CitiesFailure value)  failure,}){
final _that = this;
switch (_that) {
case CitiesInitial():
return initial(_that);case CitiesLoading():
return loading(_that);case CitiesLoaded():
return loaded(_that);case CitiesFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CitiesInitial value)?  initial,TResult? Function( CitiesLoading value)?  loading,TResult? Function( CitiesLoaded value)?  loaded,TResult? Function( CitiesFailure value)?  failure,}){
final _that = this;
switch (_that) {
case CitiesInitial() when initial != null:
return initial(_that);case CitiesLoading() when loading != null:
return loading(_that);case CitiesLoaded() when loaded != null:
return loaded(_that);case CitiesFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( Paginated<City> page,  bool isLoadingMore,  String? search)?  loaded,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CitiesInitial() when initial != null:
return initial();case CitiesLoading() when loading != null:
return loading();case CitiesLoaded() when loaded != null:
return loaded(_that.page,_that.isLoadingMore,_that.search);case CitiesFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( Paginated<City> page,  bool isLoadingMore,  String? search)  loaded,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case CitiesInitial():
return initial();case CitiesLoading():
return loading();case CitiesLoaded():
return loaded(_that.page,_that.isLoadingMore,_that.search);case CitiesFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( Paginated<City> page,  bool isLoadingMore,  String? search)?  loaded,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case CitiesInitial() when initial != null:
return initial();case CitiesLoading() when loading != null:
return loading();case CitiesLoaded() when loaded != null:
return loaded(_that.page,_that.isLoadingMore,_that.search);case CitiesFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class CitiesInitial implements CitiesState {
  const CitiesInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CitiesInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CitiesState.initial()';
}


}




/// @nodoc


class CitiesLoading implements CitiesState {
  const CitiesLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CitiesLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CitiesState.loading()';
}


}




/// @nodoc


class CitiesLoaded implements CitiesState {
  const CitiesLoaded({required this.page, this.isLoadingMore = false, this.search});
  

 final  Paginated<City> page;
/// A further page is on its way. Kept inside `loaded` rather than as its own case,
/// because the list stays on screen while it happens.
@JsonKey() final  bool isLoadingMore;
/// The search term these results belong to — lets a late response for an old term be
/// dropped instead of overwriting a newer one.
 final  String? search;

/// Create a copy of CitiesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CitiesLoadedCopyWith<CitiesLoaded> get copyWith => _$CitiesLoadedCopyWithImpl<CitiesLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CitiesLoaded&&(identical(other.page, page) || other.page == page)&&(identical(other.isLoadingMore, isLoadingMore) || other.isLoadingMore == isLoadingMore)&&(identical(other.search, search) || other.search == search));
}


@override
int get hashCode => Object.hash(runtimeType,page,isLoadingMore,search);

@override
String toString() {
  return 'CitiesState.loaded(page: $page, isLoadingMore: $isLoadingMore, search: $search)';
}


}

/// @nodoc
abstract mixin class $CitiesLoadedCopyWith<$Res> implements $CitiesStateCopyWith<$Res> {
  factory $CitiesLoadedCopyWith(CitiesLoaded value, $Res Function(CitiesLoaded) _then) = _$CitiesLoadedCopyWithImpl;
@useResult
$Res call({
 Paginated<City> page, bool isLoadingMore, String? search
});




}
/// @nodoc
class _$CitiesLoadedCopyWithImpl<$Res>
    implements $CitiesLoadedCopyWith<$Res> {
  _$CitiesLoadedCopyWithImpl(this._self, this._then);

  final CitiesLoaded _self;
  final $Res Function(CitiesLoaded) _then;

/// Create a copy of CitiesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? page = null,Object? isLoadingMore = null,Object? search = freezed,}) {
  return _then(CitiesLoaded(
page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as Paginated<City>,isLoadingMore: null == isLoadingMore ? _self.isLoadingMore : isLoadingMore // ignore: cast_nullable_to_non_nullable
as bool,search: freezed == search ? _self.search : search // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class CitiesFailure implements CitiesState {
  const CitiesFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of CitiesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CitiesFailureCopyWith<CitiesFailure> get copyWith => _$CitiesFailureCopyWithImpl<CitiesFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CitiesFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'CitiesState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $CitiesFailureCopyWith<$Res> implements $CitiesStateCopyWith<$Res> {
  factory $CitiesFailureCopyWith(CitiesFailure value, $Res Function(CitiesFailure) _then) = _$CitiesFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$CitiesFailureCopyWithImpl<$Res>
    implements $CitiesFailureCopyWith<$Res> {
  _$CitiesFailureCopyWithImpl(this._self, this._then);

  final CitiesFailure _self;
  final $Res Function(CitiesFailure) _then;

/// Create a copy of CitiesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(CitiesFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of CitiesState
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
mixin _$RegionsState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RegionsState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RegionsState()';
}


}

/// @nodoc
class $RegionsStateCopyWith<$Res>  {
$RegionsStateCopyWith(RegionsState _, $Res Function(RegionsState) __);
}


/// Adds pattern-matching-related methods to [RegionsState].
extension RegionsStatePatterns on RegionsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( RegionsInitial value)?  initial,TResult Function( RegionsLoading value)?  loading,TResult Function( RegionsLoaded value)?  loaded,TResult Function( RegionsFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case RegionsInitial() when initial != null:
return initial(_that);case RegionsLoading() when loading != null:
return loading(_that);case RegionsLoaded() when loaded != null:
return loaded(_that);case RegionsFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( RegionsInitial value)  initial,required TResult Function( RegionsLoading value)  loading,required TResult Function( RegionsLoaded value)  loaded,required TResult Function( RegionsFailure value)  failure,}){
final _that = this;
switch (_that) {
case RegionsInitial():
return initial(_that);case RegionsLoading():
return loading(_that);case RegionsLoaded():
return loaded(_that);case RegionsFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( RegionsInitial value)?  initial,TResult? Function( RegionsLoading value)?  loading,TResult? Function( RegionsLoaded value)?  loaded,TResult? Function( RegionsFailure value)?  failure,}){
final _that = this;
switch (_that) {
case RegionsInitial() when initial != null:
return initial(_that);case RegionsLoading() when loading != null:
return loading(_that);case RegionsLoaded() when loaded != null:
return loaded(_that);case RegionsFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( List<Region> regions)?  loaded,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case RegionsInitial() when initial != null:
return initial();case RegionsLoading() when loading != null:
return loading();case RegionsLoaded() when loaded != null:
return loaded(_that.regions);case RegionsFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( List<Region> regions)  loaded,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case RegionsInitial():
return initial();case RegionsLoading():
return loading();case RegionsLoaded():
return loaded(_that.regions);case RegionsFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( List<Region> regions)?  loaded,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case RegionsInitial() when initial != null:
return initial();case RegionsLoading() when loading != null:
return loading();case RegionsLoaded() when loaded != null:
return loaded(_that.regions);case RegionsFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class RegionsInitial implements RegionsState {
  const RegionsInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RegionsInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RegionsState.initial()';
}


}




/// @nodoc


class RegionsLoading implements RegionsState {
  const RegionsLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RegionsLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RegionsState.loading()';
}


}




/// @nodoc


class RegionsLoaded implements RegionsState {
  const RegionsLoaded(final  List<Region> regions): _regions = regions;
  

 final  List<Region> _regions;
 List<Region> get regions {
  if (_regions is EqualUnmodifiableListView) return _regions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_regions);
}


/// Create a copy of RegionsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RegionsLoadedCopyWith<RegionsLoaded> get copyWith => _$RegionsLoadedCopyWithImpl<RegionsLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RegionsLoaded&&const DeepCollectionEquality().equals(other._regions, _regions));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_regions));

@override
String toString() {
  return 'RegionsState.loaded(regions: $regions)';
}


}

/// @nodoc
abstract mixin class $RegionsLoadedCopyWith<$Res> implements $RegionsStateCopyWith<$Res> {
  factory $RegionsLoadedCopyWith(RegionsLoaded value, $Res Function(RegionsLoaded) _then) = _$RegionsLoadedCopyWithImpl;
@useResult
$Res call({
 List<Region> regions
});




}
/// @nodoc
class _$RegionsLoadedCopyWithImpl<$Res>
    implements $RegionsLoadedCopyWith<$Res> {
  _$RegionsLoadedCopyWithImpl(this._self, this._then);

  final RegionsLoaded _self;
  final $Res Function(RegionsLoaded) _then;

/// Create a copy of RegionsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? regions = null,}) {
  return _then(RegionsLoaded(
null == regions ? _self._regions : regions // ignore: cast_nullable_to_non_nullable
as List<Region>,
  ));
}


}

/// @nodoc


class RegionsFailure implements RegionsState {
  const RegionsFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of RegionsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RegionsFailureCopyWith<RegionsFailure> get copyWith => _$RegionsFailureCopyWithImpl<RegionsFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RegionsFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'RegionsState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $RegionsFailureCopyWith<$Res> implements $RegionsStateCopyWith<$Res> {
  factory $RegionsFailureCopyWith(RegionsFailure value, $Res Function(RegionsFailure) _then) = _$RegionsFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$RegionsFailureCopyWithImpl<$Res>
    implements $RegionsFailureCopyWith<$Res> {
  _$RegionsFailureCopyWithImpl(this._self, this._then);

  final RegionsFailure _self;
  final $Res Function(RegionsFailure) _then;

/// Create a copy of RegionsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(RegionsFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of RegionsState
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
