// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'customer_designs_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CustomerDesignsState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomerDesignsState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CustomerDesignsState()';
}


}

/// @nodoc
class $CustomerDesignsStateCopyWith<$Res>  {
$CustomerDesignsStateCopyWith(CustomerDesignsState _, $Res Function(CustomerDesignsState) __);
}


/// Adds pattern-matching-related methods to [CustomerDesignsState].
extension CustomerDesignsStatePatterns on CustomerDesignsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CustomerDesignsLoading value)?  loading,TResult Function( CustomerDesignsLoaded value)?  loaded,TResult Function( CustomerDesignsFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CustomerDesignsLoading() when loading != null:
return loading(_that);case CustomerDesignsLoaded() when loaded != null:
return loaded(_that);case CustomerDesignsFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CustomerDesignsLoading value)  loading,required TResult Function( CustomerDesignsLoaded value)  loaded,required TResult Function( CustomerDesignsFailure value)  failure,}){
final _that = this;
switch (_that) {
case CustomerDesignsLoading():
return loading(_that);case CustomerDesignsLoaded():
return loaded(_that);case CustomerDesignsFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CustomerDesignsLoading value)?  loading,TResult? Function( CustomerDesignsLoaded value)?  loaded,TResult? Function( CustomerDesignsFailure value)?  failure,}){
final _that = this;
switch (_that) {
case CustomerDesignsLoading() when loading != null:
return loading(_that);case CustomerDesignsLoaded() when loaded != null:
return loaded(_that);case CustomerDesignsFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( List<CustomerDesign> designs,  List<DesignUpload> uploads,  Set<int> busy)?  loaded,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CustomerDesignsLoading() when loading != null:
return loading();case CustomerDesignsLoaded() when loaded != null:
return loaded(_that.designs,_that.uploads,_that.busy);case CustomerDesignsFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( List<CustomerDesign> designs,  List<DesignUpload> uploads,  Set<int> busy)  loaded,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case CustomerDesignsLoading():
return loading();case CustomerDesignsLoaded():
return loaded(_that.designs,_that.uploads,_that.busy);case CustomerDesignsFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( List<CustomerDesign> designs,  List<DesignUpload> uploads,  Set<int> busy)?  loaded,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case CustomerDesignsLoading() when loading != null:
return loading();case CustomerDesignsLoaded() when loaded != null:
return loaded(_that.designs,_that.uploads,_that.busy);case CustomerDesignsFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class CustomerDesignsLoading implements CustomerDesignsState {
  const CustomerDesignsLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomerDesignsLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CustomerDesignsState.loading()';
}


}




/// @nodoc


class CustomerDesignsLoaded implements CustomerDesignsState {
  const CustomerDesignsLoaded({required final  List<CustomerDesign> designs, final  List<DesignUpload> uploads = const <DesignUpload>[], final  Set<int> busy = const <int>{}}): _designs = designs,_uploads = uploads,_busy = busy;
  

 final  List<CustomerDesign> _designs;
 List<CustomerDesign> get designs {
  if (_designs is EqualUnmodifiableListView) return _designs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_designs);
}

/// Files on their way up, in the order they were chosen. Shown at the top of the grid, so
/// the thing that just happened is where the eye already is.
 final  List<DesignUpload> _uploads;
/// Files on their way up, in the order they were chosen. Shown at the top of the grid, so
/// the thing that just happened is where the eye already is.
@JsonKey() List<DesignUpload> get uploads {
  if (_uploads is EqualUnmodifiableListView) return _uploads;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_uploads);
}

/// Ids of designs being renamed or removed right now. A set rather than a single id
/// because two rows can be worked on at once and each has to show its own state.
 final  Set<int> _busy;
/// Ids of designs being renamed or removed right now. A set rather than a single id
/// because two rows can be worked on at once and each has to show its own state.
@JsonKey() Set<int> get busy {
  if (_busy is EqualUnmodifiableSetView) return _busy;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_busy);
}


/// Create a copy of CustomerDesignsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustomerDesignsLoadedCopyWith<CustomerDesignsLoaded> get copyWith => _$CustomerDesignsLoadedCopyWithImpl<CustomerDesignsLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomerDesignsLoaded&&const DeepCollectionEquality().equals(other._designs, _designs)&&const DeepCollectionEquality().equals(other._uploads, _uploads)&&const DeepCollectionEquality().equals(other._busy, _busy));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_designs),const DeepCollectionEquality().hash(_uploads),const DeepCollectionEquality().hash(_busy));

@override
String toString() {
  return 'CustomerDesignsState.loaded(designs: $designs, uploads: $uploads, busy: $busy)';
}


}

/// @nodoc
abstract mixin class $CustomerDesignsLoadedCopyWith<$Res> implements $CustomerDesignsStateCopyWith<$Res> {
  factory $CustomerDesignsLoadedCopyWith(CustomerDesignsLoaded value, $Res Function(CustomerDesignsLoaded) _then) = _$CustomerDesignsLoadedCopyWithImpl;
@useResult
$Res call({
 List<CustomerDesign> designs, List<DesignUpload> uploads, Set<int> busy
});




}
/// @nodoc
class _$CustomerDesignsLoadedCopyWithImpl<$Res>
    implements $CustomerDesignsLoadedCopyWith<$Res> {
  _$CustomerDesignsLoadedCopyWithImpl(this._self, this._then);

  final CustomerDesignsLoaded _self;
  final $Res Function(CustomerDesignsLoaded) _then;

/// Create a copy of CustomerDesignsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? designs = null,Object? uploads = null,Object? busy = null,}) {
  return _then(CustomerDesignsLoaded(
designs: null == designs ? _self._designs : designs // ignore: cast_nullable_to_non_nullable
as List<CustomerDesign>,uploads: null == uploads ? _self._uploads : uploads // ignore: cast_nullable_to_non_nullable
as List<DesignUpload>,busy: null == busy ? _self._busy : busy // ignore: cast_nullable_to_non_nullable
as Set<int>,
  ));
}


}

/// @nodoc


class CustomerDesignsFailure implements CustomerDesignsState {
  const CustomerDesignsFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of CustomerDesignsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustomerDesignsFailureCopyWith<CustomerDesignsFailure> get copyWith => _$CustomerDesignsFailureCopyWithImpl<CustomerDesignsFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomerDesignsFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'CustomerDesignsState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $CustomerDesignsFailureCopyWith<$Res> implements $CustomerDesignsStateCopyWith<$Res> {
  factory $CustomerDesignsFailureCopyWith(CustomerDesignsFailure value, $Res Function(CustomerDesignsFailure) _then) = _$CustomerDesignsFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$CustomerDesignsFailureCopyWithImpl<$Res>
    implements $CustomerDesignsFailureCopyWith<$Res> {
  _$CustomerDesignsFailureCopyWithImpl(this._self, this._then);

  final CustomerDesignsFailure _self;
  final $Res Function(CustomerDesignsFailure) _then;

/// Create a copy of CustomerDesignsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(CustomerDesignsFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of CustomerDesignsState
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
mixin _$DesignUpload {

 PickedFile get file;/// Bytes acknowledged as sent.
 int get sent;/// True for the one upload currently in flight. They go up one at a time: three at once
/// over a slow connection means three bars that all crawl and none that finishes.
 bool get isUploading;/// Why it stopped, if it did. The row then offers «إعادة المحاولة» — free to take, because
/// the endpoint is idempotent on the file's checksum.
 Failure? get failure;
/// Create a copy of DesignUpload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DesignUploadCopyWith<DesignUpload> get copyWith => _$DesignUploadCopyWithImpl<DesignUpload>(this as DesignUpload, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DesignUpload&&(identical(other.file, file) || other.file == file)&&(identical(other.sent, sent) || other.sent == sent)&&(identical(other.isUploading, isUploading) || other.isUploading == isUploading)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,file,sent,isUploading,failure);

@override
String toString() {
  return 'DesignUpload(file: $file, sent: $sent, isUploading: $isUploading, failure: $failure)';
}


}

/// @nodoc
abstract mixin class $DesignUploadCopyWith<$Res>  {
  factory $DesignUploadCopyWith(DesignUpload value, $Res Function(DesignUpload) _then) = _$DesignUploadCopyWithImpl;
@useResult
$Res call({
 PickedFile file, int sent, bool isUploading, Failure? failure
});


$FailureCopyWith<$Res>? get failure;

}
/// @nodoc
class _$DesignUploadCopyWithImpl<$Res>
    implements $DesignUploadCopyWith<$Res> {
  _$DesignUploadCopyWithImpl(this._self, this._then);

  final DesignUpload _self;
  final $Res Function(DesignUpload) _then;

/// Create a copy of DesignUpload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? file = null,Object? sent = null,Object? isUploading = null,Object? failure = freezed,}) {
  return _then(_self.copyWith(
file: null == file ? _self.file : file // ignore: cast_nullable_to_non_nullable
as PickedFile,sent: null == sent ? _self.sent : sent // ignore: cast_nullable_to_non_nullable
as int,isUploading: null == isUploading ? _self.isUploading : isUploading // ignore: cast_nullable_to_non_nullable
as bool,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}
/// Create a copy of DesignUpload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res>? get failure {
    if (_self.failure == null) {
    return null;
  }

  return $FailureCopyWith<$Res>(_self.failure!, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}


/// Adds pattern-matching-related methods to [DesignUpload].
extension DesignUploadPatterns on DesignUpload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DesignUpload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DesignUpload() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DesignUpload value)  $default,){
final _that = this;
switch (_that) {
case _DesignUpload():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DesignUpload value)?  $default,){
final _that = this;
switch (_that) {
case _DesignUpload() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PickedFile file,  int sent,  bool isUploading,  Failure? failure)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DesignUpload() when $default != null:
return $default(_that.file,_that.sent,_that.isUploading,_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PickedFile file,  int sent,  bool isUploading,  Failure? failure)  $default,) {final _that = this;
switch (_that) {
case _DesignUpload():
return $default(_that.file,_that.sent,_that.isUploading,_that.failure);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PickedFile file,  int sent,  bool isUploading,  Failure? failure)?  $default,) {final _that = this;
switch (_that) {
case _DesignUpload() when $default != null:
return $default(_that.file,_that.sent,_that.isUploading,_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class _DesignUpload extends DesignUpload {
  const _DesignUpload({required this.file, this.sent = 0, this.isUploading = false, this.failure}): super._();
  

@override final  PickedFile file;
/// Bytes acknowledged as sent.
@override@JsonKey() final  int sent;
/// True for the one upload currently in flight. They go up one at a time: three at once
/// over a slow connection means three bars that all crawl and none that finishes.
@override@JsonKey() final  bool isUploading;
/// Why it stopped, if it did. The row then offers «إعادة المحاولة» — free to take, because
/// the endpoint is idempotent on the file's checksum.
@override final  Failure? failure;

/// Create a copy of DesignUpload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DesignUploadCopyWith<_DesignUpload> get copyWith => __$DesignUploadCopyWithImpl<_DesignUpload>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DesignUpload&&(identical(other.file, file) || other.file == file)&&(identical(other.sent, sent) || other.sent == sent)&&(identical(other.isUploading, isUploading) || other.isUploading == isUploading)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,file,sent,isUploading,failure);

@override
String toString() {
  return 'DesignUpload(file: $file, sent: $sent, isUploading: $isUploading, failure: $failure)';
}


}

/// @nodoc
abstract mixin class _$DesignUploadCopyWith<$Res> implements $DesignUploadCopyWith<$Res> {
  factory _$DesignUploadCopyWith(_DesignUpload value, $Res Function(_DesignUpload) _then) = __$DesignUploadCopyWithImpl;
@override @useResult
$Res call({
 PickedFile file, int sent, bool isUploading, Failure? failure
});


@override $FailureCopyWith<$Res>? get failure;

}
/// @nodoc
class __$DesignUploadCopyWithImpl<$Res>
    implements _$DesignUploadCopyWith<$Res> {
  __$DesignUploadCopyWithImpl(this._self, this._then);

  final _DesignUpload _self;
  final $Res Function(_DesignUpload) _then;

/// Create a copy of DesignUpload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? file = null,Object? sent = null,Object? isUploading = null,Object? failure = freezed,}) {
  return _then(_DesignUpload(
file: null == file ? _self.file : file // ignore: cast_nullable_to_non_nullable
as PickedFile,sent: null == sent ? _self.sent : sent // ignore: cast_nullable_to_non_nullable
as int,isUploading: null == isUploading ? _self.isUploading : isUploading // ignore: cast_nullable_to_non_nullable
as bool,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}

/// Create a copy of DesignUpload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res>? get failure {
    if (_self.failure == null) {
    return null;
  }

  return $FailureCopyWith<$Res>(_self.failure!, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}

// dart format on
