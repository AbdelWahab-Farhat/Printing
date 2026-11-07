// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'nawris_settlement_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$NawrisSettlementState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NawrisSettlementState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'NawrisSettlementState()';
}


}

/// @nodoc
class $NawrisSettlementStateCopyWith<$Res>  {
$NawrisSettlementStateCopyWith(NawrisSettlementState _, $Res Function(NawrisSettlementState) __);
}


/// Adds pattern-matching-related methods to [NawrisSettlementState].
extension NawrisSettlementStatePatterns on NawrisSettlementState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( NawrisSettlementIdle value)?  idle,TResult Function( NawrisSettlementReading value)?  reading,TResult Function( NawrisSettlementUnreadable value)?  unreadable,TResult Function( NawrisSettlementReady value)?  ready,TResult Function( NawrisSettlementSubmitting value)?  submitting,TResult Function( NawrisSettlementRefused value)?  refused,TResult Function( NawrisSettlementSettled value)?  settled,required TResult orElse(),}){
final _that = this;
switch (_that) {
case NawrisSettlementIdle() when idle != null:
return idle(_that);case NawrisSettlementReading() when reading != null:
return reading(_that);case NawrisSettlementUnreadable() when unreadable != null:
return unreadable(_that);case NawrisSettlementReady() when ready != null:
return ready(_that);case NawrisSettlementSubmitting() when submitting != null:
return submitting(_that);case NawrisSettlementRefused() when refused != null:
return refused(_that);case NawrisSettlementSettled() when settled != null:
return settled(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( NawrisSettlementIdle value)  idle,required TResult Function( NawrisSettlementReading value)  reading,required TResult Function( NawrisSettlementUnreadable value)  unreadable,required TResult Function( NawrisSettlementReady value)  ready,required TResult Function( NawrisSettlementSubmitting value)  submitting,required TResult Function( NawrisSettlementRefused value)  refused,required TResult Function( NawrisSettlementSettled value)  settled,}){
final _that = this;
switch (_that) {
case NawrisSettlementIdle():
return idle(_that);case NawrisSettlementReading():
return reading(_that);case NawrisSettlementUnreadable():
return unreadable(_that);case NawrisSettlementReady():
return ready(_that);case NawrisSettlementSubmitting():
return submitting(_that);case NawrisSettlementRefused():
return refused(_that);case NawrisSettlementSettled():
return settled(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( NawrisSettlementIdle value)?  idle,TResult? Function( NawrisSettlementReading value)?  reading,TResult? Function( NawrisSettlementUnreadable value)?  unreadable,TResult? Function( NawrisSettlementReady value)?  ready,TResult? Function( NawrisSettlementSubmitting value)?  submitting,TResult? Function( NawrisSettlementRefused value)?  refused,TResult? Function( NawrisSettlementSettled value)?  settled,}){
final _that = this;
switch (_that) {
case NawrisSettlementIdle() when idle != null:
return idle(_that);case NawrisSettlementReading() when reading != null:
return reading(_that);case NawrisSettlementUnreadable() when unreadable != null:
return unreadable(_that);case NawrisSettlementReady() when ready != null:
return ready(_that);case NawrisSettlementSubmitting() when submitting != null:
return submitting(_that);case NawrisSettlementRefused() when refused != null:
return refused(_that);case NawrisSettlementSettled() when settled != null:
return settled(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  idle,TResult Function( PickedFile file)?  reading,TResult Function( Failure failure)?  unreadable,TResult Function( PickedFile file,  NawrisSettlementPreview preview)?  ready,TResult Function( PickedFile file,  NawrisSettlementPreview preview)?  submitting,TResult Function( PickedFile file,  NawrisSettlementPreview preview,  Failure failure)?  refused,TResult Function( NawrisSettlementImport batch)?  settled,required TResult orElse(),}) {final _that = this;
switch (_that) {
case NawrisSettlementIdle() when idle != null:
return idle();case NawrisSettlementReading() when reading != null:
return reading(_that.file);case NawrisSettlementUnreadable() when unreadable != null:
return unreadable(_that.failure);case NawrisSettlementReady() when ready != null:
return ready(_that.file,_that.preview);case NawrisSettlementSubmitting() when submitting != null:
return submitting(_that.file,_that.preview);case NawrisSettlementRefused() when refused != null:
return refused(_that.file,_that.preview,_that.failure);case NawrisSettlementSettled() when settled != null:
return settled(_that.batch);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  idle,required TResult Function( PickedFile file)  reading,required TResult Function( Failure failure)  unreadable,required TResult Function( PickedFile file,  NawrisSettlementPreview preview)  ready,required TResult Function( PickedFile file,  NawrisSettlementPreview preview)  submitting,required TResult Function( PickedFile file,  NawrisSettlementPreview preview,  Failure failure)  refused,required TResult Function( NawrisSettlementImport batch)  settled,}) {final _that = this;
switch (_that) {
case NawrisSettlementIdle():
return idle();case NawrisSettlementReading():
return reading(_that.file);case NawrisSettlementUnreadable():
return unreadable(_that.failure);case NawrisSettlementReady():
return ready(_that.file,_that.preview);case NawrisSettlementSubmitting():
return submitting(_that.file,_that.preview);case NawrisSettlementRefused():
return refused(_that.file,_that.preview,_that.failure);case NawrisSettlementSettled():
return settled(_that.batch);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  idle,TResult? Function( PickedFile file)?  reading,TResult? Function( Failure failure)?  unreadable,TResult? Function( PickedFile file,  NawrisSettlementPreview preview)?  ready,TResult? Function( PickedFile file,  NawrisSettlementPreview preview)?  submitting,TResult? Function( PickedFile file,  NawrisSettlementPreview preview,  Failure failure)?  refused,TResult? Function( NawrisSettlementImport batch)?  settled,}) {final _that = this;
switch (_that) {
case NawrisSettlementIdle() when idle != null:
return idle();case NawrisSettlementReading() when reading != null:
return reading(_that.file);case NawrisSettlementUnreadable() when unreadable != null:
return unreadable(_that.failure);case NawrisSettlementReady() when ready != null:
return ready(_that.file,_that.preview);case NawrisSettlementSubmitting() when submitting != null:
return submitting(_that.file,_that.preview);case NawrisSettlementRefused() when refused != null:
return refused(_that.file,_that.preview,_that.failure);case NawrisSettlementSettled() when settled != null:
return settled(_that.batch);case _:
  return null;

}
}

}

/// @nodoc


class NawrisSettlementIdle implements NawrisSettlementState {
  const NawrisSettlementIdle();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NawrisSettlementIdle);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'NawrisSettlementState.idle()';
}


}




/// @nodoc


class NawrisSettlementReading implements NawrisSettlementState {
  const NawrisSettlementReading(this.file);
  

 final  PickedFile file;

/// Create a copy of NawrisSettlementState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NawrisSettlementReadingCopyWith<NawrisSettlementReading> get copyWith => _$NawrisSettlementReadingCopyWithImpl<NawrisSettlementReading>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NawrisSettlementReading&&(identical(other.file, file) || other.file == file));
}


@override
int get hashCode => Object.hash(runtimeType,file);

@override
String toString() {
  return 'NawrisSettlementState.reading(file: $file)';
}


}

/// @nodoc
abstract mixin class $NawrisSettlementReadingCopyWith<$Res> implements $NawrisSettlementStateCopyWith<$Res> {
  factory $NawrisSettlementReadingCopyWith(NawrisSettlementReading value, $Res Function(NawrisSettlementReading) _then) = _$NawrisSettlementReadingCopyWithImpl;
@useResult
$Res call({
 PickedFile file
});




}
/// @nodoc
class _$NawrisSettlementReadingCopyWithImpl<$Res>
    implements $NawrisSettlementReadingCopyWith<$Res> {
  _$NawrisSettlementReadingCopyWithImpl(this._self, this._then);

  final NawrisSettlementReading _self;
  final $Res Function(NawrisSettlementReading) _then;

/// Create a copy of NawrisSettlementState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? file = null,}) {
  return _then(NawrisSettlementReading(
null == file ? _self.file : file // ignore: cast_nullable_to_non_nullable
as PickedFile,
  ));
}


}

/// @nodoc


class NawrisSettlementUnreadable implements NawrisSettlementState {
  const NawrisSettlementUnreadable(this.failure);
  

 final  Failure failure;

/// Create a copy of NawrisSettlementState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NawrisSettlementUnreadableCopyWith<NawrisSettlementUnreadable> get copyWith => _$NawrisSettlementUnreadableCopyWithImpl<NawrisSettlementUnreadable>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NawrisSettlementUnreadable&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'NawrisSettlementState.unreadable(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $NawrisSettlementUnreadableCopyWith<$Res> implements $NawrisSettlementStateCopyWith<$Res> {
  factory $NawrisSettlementUnreadableCopyWith(NawrisSettlementUnreadable value, $Res Function(NawrisSettlementUnreadable) _then) = _$NawrisSettlementUnreadableCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$NawrisSettlementUnreadableCopyWithImpl<$Res>
    implements $NawrisSettlementUnreadableCopyWith<$Res> {
  _$NawrisSettlementUnreadableCopyWithImpl(this._self, this._then);

  final NawrisSettlementUnreadable _self;
  final $Res Function(NawrisSettlementUnreadable) _then;

/// Create a copy of NawrisSettlementState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(NawrisSettlementUnreadable(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of NawrisSettlementState
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


class NawrisSettlementReady implements NawrisSettlementState {
  const NawrisSettlementReady({required this.file, required this.preview});
  

 final  PickedFile file;
 final  NawrisSettlementPreview preview;

/// Create a copy of NawrisSettlementState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NawrisSettlementReadyCopyWith<NawrisSettlementReady> get copyWith => _$NawrisSettlementReadyCopyWithImpl<NawrisSettlementReady>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NawrisSettlementReady&&(identical(other.file, file) || other.file == file)&&(identical(other.preview, preview) || other.preview == preview));
}


@override
int get hashCode => Object.hash(runtimeType,file,preview);

@override
String toString() {
  return 'NawrisSettlementState.ready(file: $file, preview: $preview)';
}


}

/// @nodoc
abstract mixin class $NawrisSettlementReadyCopyWith<$Res> implements $NawrisSettlementStateCopyWith<$Res> {
  factory $NawrisSettlementReadyCopyWith(NawrisSettlementReady value, $Res Function(NawrisSettlementReady) _then) = _$NawrisSettlementReadyCopyWithImpl;
@useResult
$Res call({
 PickedFile file, NawrisSettlementPreview preview
});


$NawrisSettlementPreviewCopyWith<$Res> get preview;

}
/// @nodoc
class _$NawrisSettlementReadyCopyWithImpl<$Res>
    implements $NawrisSettlementReadyCopyWith<$Res> {
  _$NawrisSettlementReadyCopyWithImpl(this._self, this._then);

  final NawrisSettlementReady _self;
  final $Res Function(NawrisSettlementReady) _then;

/// Create a copy of NawrisSettlementState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? file = null,Object? preview = null,}) {
  return _then(NawrisSettlementReady(
file: null == file ? _self.file : file // ignore: cast_nullable_to_non_nullable
as PickedFile,preview: null == preview ? _self.preview : preview // ignore: cast_nullable_to_non_nullable
as NawrisSettlementPreview,
  ));
}

/// Create a copy of NawrisSettlementState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NawrisSettlementPreviewCopyWith<$Res> get preview {
  
  return $NawrisSettlementPreviewCopyWith<$Res>(_self.preview, (value) {
    return _then(_self.copyWith(preview: value));
  });
}
}

/// @nodoc


class NawrisSettlementSubmitting implements NawrisSettlementState {
  const NawrisSettlementSubmitting({required this.file, required this.preview});
  

 final  PickedFile file;
 final  NawrisSettlementPreview preview;

/// Create a copy of NawrisSettlementState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NawrisSettlementSubmittingCopyWith<NawrisSettlementSubmitting> get copyWith => _$NawrisSettlementSubmittingCopyWithImpl<NawrisSettlementSubmitting>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NawrisSettlementSubmitting&&(identical(other.file, file) || other.file == file)&&(identical(other.preview, preview) || other.preview == preview));
}


@override
int get hashCode => Object.hash(runtimeType,file,preview);

@override
String toString() {
  return 'NawrisSettlementState.submitting(file: $file, preview: $preview)';
}


}

/// @nodoc
abstract mixin class $NawrisSettlementSubmittingCopyWith<$Res> implements $NawrisSettlementStateCopyWith<$Res> {
  factory $NawrisSettlementSubmittingCopyWith(NawrisSettlementSubmitting value, $Res Function(NawrisSettlementSubmitting) _then) = _$NawrisSettlementSubmittingCopyWithImpl;
@useResult
$Res call({
 PickedFile file, NawrisSettlementPreview preview
});


$NawrisSettlementPreviewCopyWith<$Res> get preview;

}
/// @nodoc
class _$NawrisSettlementSubmittingCopyWithImpl<$Res>
    implements $NawrisSettlementSubmittingCopyWith<$Res> {
  _$NawrisSettlementSubmittingCopyWithImpl(this._self, this._then);

  final NawrisSettlementSubmitting _self;
  final $Res Function(NawrisSettlementSubmitting) _then;

/// Create a copy of NawrisSettlementState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? file = null,Object? preview = null,}) {
  return _then(NawrisSettlementSubmitting(
file: null == file ? _self.file : file // ignore: cast_nullable_to_non_nullable
as PickedFile,preview: null == preview ? _self.preview : preview // ignore: cast_nullable_to_non_nullable
as NawrisSettlementPreview,
  ));
}

/// Create a copy of NawrisSettlementState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NawrisSettlementPreviewCopyWith<$Res> get preview {
  
  return $NawrisSettlementPreviewCopyWith<$Res>(_self.preview, (value) {
    return _then(_self.copyWith(preview: value));
  });
}
}

/// @nodoc


class NawrisSettlementRefused implements NawrisSettlementState {
  const NawrisSettlementRefused({required this.file, required this.preview, required this.failure});
  

 final  PickedFile file;
 final  NawrisSettlementPreview preview;
 final  Failure failure;

/// Create a copy of NawrisSettlementState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NawrisSettlementRefusedCopyWith<NawrisSettlementRefused> get copyWith => _$NawrisSettlementRefusedCopyWithImpl<NawrisSettlementRefused>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NawrisSettlementRefused&&(identical(other.file, file) || other.file == file)&&(identical(other.preview, preview) || other.preview == preview)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,file,preview,failure);

@override
String toString() {
  return 'NawrisSettlementState.refused(file: $file, preview: $preview, failure: $failure)';
}


}

/// @nodoc
abstract mixin class $NawrisSettlementRefusedCopyWith<$Res> implements $NawrisSettlementStateCopyWith<$Res> {
  factory $NawrisSettlementRefusedCopyWith(NawrisSettlementRefused value, $Res Function(NawrisSettlementRefused) _then) = _$NawrisSettlementRefusedCopyWithImpl;
@useResult
$Res call({
 PickedFile file, NawrisSettlementPreview preview, Failure failure
});


$NawrisSettlementPreviewCopyWith<$Res> get preview;$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$NawrisSettlementRefusedCopyWithImpl<$Res>
    implements $NawrisSettlementRefusedCopyWith<$Res> {
  _$NawrisSettlementRefusedCopyWithImpl(this._self, this._then);

  final NawrisSettlementRefused _self;
  final $Res Function(NawrisSettlementRefused) _then;

/// Create a copy of NawrisSettlementState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? file = null,Object? preview = null,Object? failure = null,}) {
  return _then(NawrisSettlementRefused(
file: null == file ? _self.file : file // ignore: cast_nullable_to_non_nullable
as PickedFile,preview: null == preview ? _self.preview : preview // ignore: cast_nullable_to_non_nullable
as NawrisSettlementPreview,failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of NawrisSettlementState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NawrisSettlementPreviewCopyWith<$Res> get preview {
  
  return $NawrisSettlementPreviewCopyWith<$Res>(_self.preview, (value) {
    return _then(_self.copyWith(preview: value));
  });
}/// Create a copy of NawrisSettlementState
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


class NawrisSettlementSettled implements NawrisSettlementState {
  const NawrisSettlementSettled(this.batch);
  

 final  NawrisSettlementImport batch;

/// Create a copy of NawrisSettlementState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NawrisSettlementSettledCopyWith<NawrisSettlementSettled> get copyWith => _$NawrisSettlementSettledCopyWithImpl<NawrisSettlementSettled>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NawrisSettlementSettled&&(identical(other.batch, batch) || other.batch == batch));
}


@override
int get hashCode => Object.hash(runtimeType,batch);

@override
String toString() {
  return 'NawrisSettlementState.settled(batch: $batch)';
}


}

/// @nodoc
abstract mixin class $NawrisSettlementSettledCopyWith<$Res> implements $NawrisSettlementStateCopyWith<$Res> {
  factory $NawrisSettlementSettledCopyWith(NawrisSettlementSettled value, $Res Function(NawrisSettlementSettled) _then) = _$NawrisSettlementSettledCopyWithImpl;
@useResult
$Res call({
 NawrisSettlementImport batch
});


$NawrisSettlementImportCopyWith<$Res> get batch;

}
/// @nodoc
class _$NawrisSettlementSettledCopyWithImpl<$Res>
    implements $NawrisSettlementSettledCopyWith<$Res> {
  _$NawrisSettlementSettledCopyWithImpl(this._self, this._then);

  final NawrisSettlementSettled _self;
  final $Res Function(NawrisSettlementSettled) _then;

/// Create a copy of NawrisSettlementState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? batch = null,}) {
  return _then(NawrisSettlementSettled(
null == batch ? _self.batch : batch // ignore: cast_nullable_to_non_nullable
as NawrisSettlementImport,
  ));
}

/// Create a copy of NawrisSettlementState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NawrisSettlementImportCopyWith<$Res> get batch {
  
  return $NawrisSettlementImportCopyWith<$Res>(_self.batch, (value) {
    return _then(_self.copyWith(batch: value));
  });
}
}

// dart format on
