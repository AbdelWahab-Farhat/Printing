// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'attachment_files_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AttachmentFile {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AttachmentFile);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AttachmentFile()';
}


}

/// @nodoc
class $AttachmentFileCopyWith<$Res>  {
$AttachmentFileCopyWith(AttachmentFile _, $Res Function(AttachmentFile) __);
}


/// Adds pattern-matching-related methods to [AttachmentFile].
extension AttachmentFilePatterns on AttachmentFile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AttachmentRemote value)?  remote,TResult Function( AttachmentDownloading value)?  downloading,TResult Function( AttachmentLocal value)?  local,TResult Function( AttachmentDownloadFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AttachmentRemote() when remote != null:
return remote(_that);case AttachmentDownloading() when downloading != null:
return downloading(_that);case AttachmentLocal() when local != null:
return local(_that);case AttachmentDownloadFailed() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AttachmentRemote value)  remote,required TResult Function( AttachmentDownloading value)  downloading,required TResult Function( AttachmentLocal value)  local,required TResult Function( AttachmentDownloadFailed value)  failed,}){
final _that = this;
switch (_that) {
case AttachmentRemote():
return remote(_that);case AttachmentDownloading():
return downloading(_that);case AttachmentLocal():
return local(_that);case AttachmentDownloadFailed():
return failed(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AttachmentRemote value)?  remote,TResult? Function( AttachmentDownloading value)?  downloading,TResult? Function( AttachmentLocal value)?  local,TResult? Function( AttachmentDownloadFailed value)?  failed,}){
final _that = this;
switch (_that) {
case AttachmentRemote() when remote != null:
return remote(_that);case AttachmentDownloading() when downloading != null:
return downloading(_that);case AttachmentLocal() when local != null:
return local(_that);case AttachmentDownloadFailed() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  remote,TResult Function( double progress)?  downloading,TResult Function( String path)?  local,TResult Function( Failure failure)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AttachmentRemote() when remote != null:
return remote();case AttachmentDownloading() when downloading != null:
return downloading(_that.progress);case AttachmentLocal() when local != null:
return local(_that.path);case AttachmentDownloadFailed() when failed != null:
return failed(_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  remote,required TResult Function( double progress)  downloading,required TResult Function( String path)  local,required TResult Function( Failure failure)  failed,}) {final _that = this;
switch (_that) {
case AttachmentRemote():
return remote();case AttachmentDownloading():
return downloading(_that.progress);case AttachmentLocal():
return local(_that.path);case AttachmentDownloadFailed():
return failed(_that.failure);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  remote,TResult? Function( double progress)?  downloading,TResult? Function( String path)?  local,TResult? Function( Failure failure)?  failed,}) {final _that = this;
switch (_that) {
case AttachmentRemote() when remote != null:
return remote();case AttachmentDownloading() when downloading != null:
return downloading(_that.progress);case AttachmentLocal() when local != null:
return local(_that.path);case AttachmentDownloadFailed() when failed != null:
return failed(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class AttachmentRemote implements AttachmentFile {
  const AttachmentRemote();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AttachmentRemote);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AttachmentFile.remote()';
}


}




/// @nodoc


class AttachmentDownloading implements AttachmentFile {
  const AttachmentDownloading({this.progress = 0});
  

@JsonKey() final  double progress;

/// Create a copy of AttachmentFile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AttachmentDownloadingCopyWith<AttachmentDownloading> get copyWith => _$AttachmentDownloadingCopyWithImpl<AttachmentDownloading>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AttachmentDownloading&&(identical(other.progress, progress) || other.progress == progress));
}


@override
int get hashCode => Object.hash(runtimeType,progress);

@override
String toString() {
  return 'AttachmentFile.downloading(progress: $progress)';
}


}

/// @nodoc
abstract mixin class $AttachmentDownloadingCopyWith<$Res> implements $AttachmentFileCopyWith<$Res> {
  factory $AttachmentDownloadingCopyWith(AttachmentDownloading value, $Res Function(AttachmentDownloading) _then) = _$AttachmentDownloadingCopyWithImpl;
@useResult
$Res call({
 double progress
});




}
/// @nodoc
class _$AttachmentDownloadingCopyWithImpl<$Res>
    implements $AttachmentDownloadingCopyWith<$Res> {
  _$AttachmentDownloadingCopyWithImpl(this._self, this._then);

  final AttachmentDownloading _self;
  final $Res Function(AttachmentDownloading) _then;

/// Create a copy of AttachmentFile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? progress = null,}) {
  return _then(AttachmentDownloading(
progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc


class AttachmentLocal implements AttachmentFile {
  const AttachmentLocal(this.path);
  

 final  String path;

/// Create a copy of AttachmentFile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AttachmentLocalCopyWith<AttachmentLocal> get copyWith => _$AttachmentLocalCopyWithImpl<AttachmentLocal>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AttachmentLocal&&(identical(other.path, path) || other.path == path));
}


@override
int get hashCode => Object.hash(runtimeType,path);

@override
String toString() {
  return 'AttachmentFile.local(path: $path)';
}


}

/// @nodoc
abstract mixin class $AttachmentLocalCopyWith<$Res> implements $AttachmentFileCopyWith<$Res> {
  factory $AttachmentLocalCopyWith(AttachmentLocal value, $Res Function(AttachmentLocal) _then) = _$AttachmentLocalCopyWithImpl;
@useResult
$Res call({
 String path
});




}
/// @nodoc
class _$AttachmentLocalCopyWithImpl<$Res>
    implements $AttachmentLocalCopyWith<$Res> {
  _$AttachmentLocalCopyWithImpl(this._self, this._then);

  final AttachmentLocal _self;
  final $Res Function(AttachmentLocal) _then;

/// Create a copy of AttachmentFile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? path = null,}) {
  return _then(AttachmentLocal(
null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class AttachmentDownloadFailed implements AttachmentFile {
  const AttachmentDownloadFailed(this.failure);
  

 final  Failure failure;

/// Create a copy of AttachmentFile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AttachmentDownloadFailedCopyWith<AttachmentDownloadFailed> get copyWith => _$AttachmentDownloadFailedCopyWithImpl<AttachmentDownloadFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AttachmentDownloadFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'AttachmentFile.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $AttachmentDownloadFailedCopyWith<$Res> implements $AttachmentFileCopyWith<$Res> {
  factory $AttachmentDownloadFailedCopyWith(AttachmentDownloadFailed value, $Res Function(AttachmentDownloadFailed) _then) = _$AttachmentDownloadFailedCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$AttachmentDownloadFailedCopyWithImpl<$Res>
    implements $AttachmentDownloadFailedCopyWith<$Res> {
  _$AttachmentDownloadFailedCopyWithImpl(this._self, this._then);

  final AttachmentDownloadFailed _self;
  final $Res Function(AttachmentDownloadFailed) _then;

/// Create a copy of AttachmentFile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(AttachmentDownloadFailed(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of AttachmentFile
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
mixin _$AttachmentFilesState {

 Map<int, AttachmentFile> get files;
/// Create a copy of AttachmentFilesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AttachmentFilesStateCopyWith<AttachmentFilesState> get copyWith => _$AttachmentFilesStateCopyWithImpl<AttachmentFilesState>(this as AttachmentFilesState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AttachmentFilesState&&const DeepCollectionEquality().equals(other.files, files));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(files));

@override
String toString() {
  return 'AttachmentFilesState(files: $files)';
}


}

/// @nodoc
abstract mixin class $AttachmentFilesStateCopyWith<$Res>  {
  factory $AttachmentFilesStateCopyWith(AttachmentFilesState value, $Res Function(AttachmentFilesState) _then) = _$AttachmentFilesStateCopyWithImpl;
@useResult
$Res call({
 Map<int, AttachmentFile> files
});




}
/// @nodoc
class _$AttachmentFilesStateCopyWithImpl<$Res>
    implements $AttachmentFilesStateCopyWith<$Res> {
  _$AttachmentFilesStateCopyWithImpl(this._self, this._then);

  final AttachmentFilesState _self;
  final $Res Function(AttachmentFilesState) _then;

/// Create a copy of AttachmentFilesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? files = null,}) {
  return _then(_self.copyWith(
files: null == files ? _self.files : files // ignore: cast_nullable_to_non_nullable
as Map<int, AttachmentFile>,
  ));
}

}


/// Adds pattern-matching-related methods to [AttachmentFilesState].
extension AttachmentFilesStatePatterns on AttachmentFilesState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AttachmentFilesState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AttachmentFilesState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AttachmentFilesState value)  $default,){
final _that = this;
switch (_that) {
case _AttachmentFilesState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AttachmentFilesState value)?  $default,){
final _that = this;
switch (_that) {
case _AttachmentFilesState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<int, AttachmentFile> files)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AttachmentFilesState() when $default != null:
return $default(_that.files);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<int, AttachmentFile> files)  $default,) {final _that = this;
switch (_that) {
case _AttachmentFilesState():
return $default(_that.files);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<int, AttachmentFile> files)?  $default,) {final _that = this;
switch (_that) {
case _AttachmentFilesState() when $default != null:
return $default(_that.files);case _:
  return null;

}
}

}

/// @nodoc


class _AttachmentFilesState implements AttachmentFilesState {
  const _AttachmentFilesState({final  Map<int, AttachmentFile> files = const <int, AttachmentFile>{}}): _files = files;
  

 final  Map<int, AttachmentFile> _files;
@override@JsonKey() Map<int, AttachmentFile> get files {
  if (_files is EqualUnmodifiableMapView) return _files;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_files);
}


/// Create a copy of AttachmentFilesState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AttachmentFilesStateCopyWith<_AttachmentFilesState> get copyWith => __$AttachmentFilesStateCopyWithImpl<_AttachmentFilesState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AttachmentFilesState&&const DeepCollectionEquality().equals(other._files, _files));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_files));

@override
String toString() {
  return 'AttachmentFilesState(files: $files)';
}


}

/// @nodoc
abstract mixin class _$AttachmentFilesStateCopyWith<$Res> implements $AttachmentFilesStateCopyWith<$Res> {
  factory _$AttachmentFilesStateCopyWith(_AttachmentFilesState value, $Res Function(_AttachmentFilesState) _then) = __$AttachmentFilesStateCopyWithImpl;
@override @useResult
$Res call({
 Map<int, AttachmentFile> files
});




}
/// @nodoc
class __$AttachmentFilesStateCopyWithImpl<$Res>
    implements _$AttachmentFilesStateCopyWith<$Res> {
  __$AttachmentFilesStateCopyWithImpl(this._self, this._then);

  final _AttachmentFilesState _self;
  final $Res Function(_AttachmentFilesState) _then;

/// Create a copy of AttachmentFilesState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? files = null,}) {
  return _then(_AttachmentFilesState(
files: null == files ? _self._files : files // ignore: cast_nullable_to_non_nullable
as Map<int, AttachmentFile>,
  ));
}


}

// dart format on
