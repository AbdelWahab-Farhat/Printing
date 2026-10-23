// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'social_links_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SocialLinksState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SocialLinksState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SocialLinksState()';
}


}

/// @nodoc
class $SocialLinksStateCopyWith<$Res>  {
$SocialLinksStateCopyWith(SocialLinksState _, $Res Function(SocialLinksState) __);
}


/// Adds pattern-matching-related methods to [SocialLinksState].
extension SocialLinksStatePatterns on SocialLinksState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SocialLinksLoading value)?  loading,TResult Function( SocialLinksLoaded value)?  loaded,TResult Function( SocialLinksFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SocialLinksLoading() when loading != null:
return loading(_that);case SocialLinksLoaded() when loaded != null:
return loaded(_that);case SocialLinksFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SocialLinksLoading value)  loading,required TResult Function( SocialLinksLoaded value)  loaded,required TResult Function( SocialLinksFailure value)  failure,}){
final _that = this;
switch (_that) {
case SocialLinksLoading():
return loading(_that);case SocialLinksLoaded():
return loaded(_that);case SocialLinksFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SocialLinksLoading value)?  loading,TResult? Function( SocialLinksLoaded value)?  loaded,TResult? Function( SocialLinksFailure value)?  failure,}){
final _that = this;
switch (_that) {
case SocialLinksLoading() when loading != null:
return loading(_that);case SocialLinksLoaded() when loaded != null:
return loaded(_that);case SocialLinksFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( List<SocialLink> links,  bool isSaving,  Failure? lastFailure)?  loaded,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SocialLinksLoading() when loading != null:
return loading();case SocialLinksLoaded() when loaded != null:
return loaded(_that.links,_that.isSaving,_that.lastFailure);case SocialLinksFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( List<SocialLink> links,  bool isSaving,  Failure? lastFailure)  loaded,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case SocialLinksLoading():
return loading();case SocialLinksLoaded():
return loaded(_that.links,_that.isSaving,_that.lastFailure);case SocialLinksFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( List<SocialLink> links,  bool isSaving,  Failure? lastFailure)?  loaded,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case SocialLinksLoading() when loading != null:
return loading();case SocialLinksLoaded() when loaded != null:
return loaded(_that.links,_that.isSaving,_that.lastFailure);case SocialLinksFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class SocialLinksLoading implements SocialLinksState {
  const SocialLinksLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SocialLinksLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SocialLinksState.loading()';
}


}




/// @nodoc


class SocialLinksLoaded implements SocialLinksState {
  const SocialLinksLoaded(final  List<SocialLink> links, {this.isSaving = false, this.lastFailure}): _links = links;
  

/// ما على الخادم، كما قرأه آخر تحميلٍ أو آخر حفظ. السطور التي تُكتب يملكها متحكّمو الشاشة.
 final  List<SocialLink> _links;
/// ما على الخادم، كما قرأه آخر تحميلٍ أو آخر حفظ. السطور التي تُكتب يملكها متحكّمو الشاشة.
 List<SocialLink> get links {
  if (_links is EqualUnmodifiableListView) return _links;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_links);
}

/// حفظٌ في الطريق: الشاشة مقفلة، و«حفظ» يدور.
@JsonKey() final  bool isSaving;
/// آخر حفظٍ رُفض، ويُمسح مع الحالة التالية.
 final  Failure? lastFailure;

/// Create a copy of SocialLinksState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SocialLinksLoadedCopyWith<SocialLinksLoaded> get copyWith => _$SocialLinksLoadedCopyWithImpl<SocialLinksLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SocialLinksLoaded&&const DeepCollectionEquality().equals(other._links, _links)&&(identical(other.isSaving, isSaving) || other.isSaving == isSaving)&&(identical(other.lastFailure, lastFailure) || other.lastFailure == lastFailure));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_links),isSaving,lastFailure);

@override
String toString() {
  return 'SocialLinksState.loaded(links: $links, isSaving: $isSaving, lastFailure: $lastFailure)';
}


}

/// @nodoc
abstract mixin class $SocialLinksLoadedCopyWith<$Res> implements $SocialLinksStateCopyWith<$Res> {
  factory $SocialLinksLoadedCopyWith(SocialLinksLoaded value, $Res Function(SocialLinksLoaded) _then) = _$SocialLinksLoadedCopyWithImpl;
@useResult
$Res call({
 List<SocialLink> links, bool isSaving, Failure? lastFailure
});


$FailureCopyWith<$Res>? get lastFailure;

}
/// @nodoc
class _$SocialLinksLoadedCopyWithImpl<$Res>
    implements $SocialLinksLoadedCopyWith<$Res> {
  _$SocialLinksLoadedCopyWithImpl(this._self, this._then);

  final SocialLinksLoaded _self;
  final $Res Function(SocialLinksLoaded) _then;

/// Create a copy of SocialLinksState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? links = null,Object? isSaving = null,Object? lastFailure = freezed,}) {
  return _then(SocialLinksLoaded(
null == links ? _self._links : links // ignore: cast_nullable_to_non_nullable
as List<SocialLink>,isSaving: null == isSaving ? _self.isSaving : isSaving // ignore: cast_nullable_to_non_nullable
as bool,lastFailure: freezed == lastFailure ? _self.lastFailure : lastFailure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}

/// Create a copy of SocialLinksState
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
}
}

/// @nodoc


class SocialLinksFailure implements SocialLinksState {
  const SocialLinksFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of SocialLinksState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SocialLinksFailureCopyWith<SocialLinksFailure> get copyWith => _$SocialLinksFailureCopyWithImpl<SocialLinksFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SocialLinksFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'SocialLinksState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $SocialLinksFailureCopyWith<$Res> implements $SocialLinksStateCopyWith<$Res> {
  factory $SocialLinksFailureCopyWith(SocialLinksFailure value, $Res Function(SocialLinksFailure) _then) = _$SocialLinksFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$SocialLinksFailureCopyWithImpl<$Res>
    implements $SocialLinksFailureCopyWith<$Res> {
  _$SocialLinksFailureCopyWithImpl(this._self, this._then);

  final SocialLinksFailure _self;
  final $Res Function(SocialLinksFailure) _then;

/// Create a copy of SocialLinksState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(SocialLinksFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of SocialLinksState
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
