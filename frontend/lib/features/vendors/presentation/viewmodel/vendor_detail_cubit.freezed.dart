// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'vendor_detail_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$VendorDetailState {

 Vendor? get vendor;
/// Create a copy of VendorDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VendorDetailStateCopyWith<VendorDetailState> get copyWith => _$VendorDetailStateCopyWithImpl<VendorDetailState>(this as VendorDetailState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VendorDetailState&&(identical(other.vendor, vendor) || other.vendor == vendor));
}


@override
int get hashCode => Object.hash(runtimeType,vendor);

@override
String toString() {
  return 'VendorDetailState(vendor: $vendor)';
}


}

/// @nodoc
abstract mixin class $VendorDetailStateCopyWith<$Res>  {
  factory $VendorDetailStateCopyWith(VendorDetailState value, $Res Function(VendorDetailState) _then) = _$VendorDetailStateCopyWithImpl;
@useResult
$Res call({
 Vendor vendor
});


$VendorCopyWith<$Res>? get vendor;

}
/// @nodoc
class _$VendorDetailStateCopyWithImpl<$Res>
    implements $VendorDetailStateCopyWith<$Res> {
  _$VendorDetailStateCopyWithImpl(this._self, this._then);

  final VendorDetailState _self;
  final $Res Function(VendorDetailState) _then;

/// Create a copy of VendorDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? vendor = null,}) {
  return _then(_self.copyWith(
vendor: null == vendor ? _self.vendor! : vendor // ignore: cast_nullable_to_non_nullable
as Vendor,
  ));
}
/// Create a copy of VendorDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VendorCopyWith<$Res>? get vendor {
    if (_self.vendor == null) {
    return null;
  }

  return $VendorCopyWith<$Res>(_self.vendor!, (value) {
    return _then(_self.copyWith(vendor: value));
  });
}
}


/// Adds pattern-matching-related methods to [VendorDetailState].
extension VendorDetailStatePatterns on VendorDetailState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( VendorDetailLoading value)?  loading,TResult Function( VendorDetailReady value)?  ready,TResult Function( VendorDetailWorking value)?  working,TResult Function( VendorDetailFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case VendorDetailLoading() when loading != null:
return loading(_that);case VendorDetailReady() when ready != null:
return ready(_that);case VendorDetailWorking() when working != null:
return working(_that);case VendorDetailFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( VendorDetailLoading value)  loading,required TResult Function( VendorDetailReady value)  ready,required TResult Function( VendorDetailWorking value)  working,required TResult Function( VendorDetailFailure value)  failure,}){
final _that = this;
switch (_that) {
case VendorDetailLoading():
return loading(_that);case VendorDetailReady():
return ready(_that);case VendorDetailWorking():
return working(_that);case VendorDetailFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( VendorDetailLoading value)?  loading,TResult? Function( VendorDetailReady value)?  ready,TResult? Function( VendorDetailWorking value)?  working,TResult? Function( VendorDetailFailure value)?  failure,}){
final _that = this;
switch (_that) {
case VendorDetailLoading() when loading != null:
return loading(_that);case VendorDetailReady() when ready != null:
return ready(_that);case VendorDetailWorking() when working != null:
return working(_that);case VendorDetailFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( Vendor? vendor)?  loading,TResult Function( Vendor vendor)?  ready,TResult Function( Vendor vendor)?  working,TResult Function( Failure failure,  Vendor? vendor)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case VendorDetailLoading() when loading != null:
return loading(_that.vendor);case VendorDetailReady() when ready != null:
return ready(_that.vendor);case VendorDetailWorking() when working != null:
return working(_that.vendor);case VendorDetailFailure() when failure != null:
return failure(_that.failure,_that.vendor);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( Vendor? vendor)  loading,required TResult Function( Vendor vendor)  ready,required TResult Function( Vendor vendor)  working,required TResult Function( Failure failure,  Vendor? vendor)  failure,}) {final _that = this;
switch (_that) {
case VendorDetailLoading():
return loading(_that.vendor);case VendorDetailReady():
return ready(_that.vendor);case VendorDetailWorking():
return working(_that.vendor);case VendorDetailFailure():
return failure(_that.failure,_that.vendor);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( Vendor? vendor)?  loading,TResult? Function( Vendor vendor)?  ready,TResult? Function( Vendor vendor)?  working,TResult? Function( Failure failure,  Vendor? vendor)?  failure,}) {final _that = this;
switch (_that) {
case VendorDetailLoading() when loading != null:
return loading(_that.vendor);case VendorDetailReady() when ready != null:
return ready(_that.vendor);case VendorDetailWorking() when working != null:
return working(_that.vendor);case VendorDetailFailure() when failure != null:
return failure(_that.failure,_that.vendor);case _:
  return null;

}
}

}

/// @nodoc


class VendorDetailLoading implements VendorDetailState {
  const VendorDetailLoading({this.vendor});
  

@override final  Vendor? vendor;

/// Create a copy of VendorDetailState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VendorDetailLoadingCopyWith<VendorDetailLoading> get copyWith => _$VendorDetailLoadingCopyWithImpl<VendorDetailLoading>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VendorDetailLoading&&(identical(other.vendor, vendor) || other.vendor == vendor));
}


@override
int get hashCode => Object.hash(runtimeType,vendor);

@override
String toString() {
  return 'VendorDetailState.loading(vendor: $vendor)';
}


}

/// @nodoc
abstract mixin class $VendorDetailLoadingCopyWith<$Res> implements $VendorDetailStateCopyWith<$Res> {
  factory $VendorDetailLoadingCopyWith(VendorDetailLoading value, $Res Function(VendorDetailLoading) _then) = _$VendorDetailLoadingCopyWithImpl;
@override @useResult
$Res call({
 Vendor? vendor
});


@override $VendorCopyWith<$Res>? get vendor;

}
/// @nodoc
class _$VendorDetailLoadingCopyWithImpl<$Res>
    implements $VendorDetailLoadingCopyWith<$Res> {
  _$VendorDetailLoadingCopyWithImpl(this._self, this._then);

  final VendorDetailLoading _self;
  final $Res Function(VendorDetailLoading) _then;

/// Create a copy of VendorDetailState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? vendor = freezed,}) {
  return _then(VendorDetailLoading(
vendor: freezed == vendor ? _self.vendor : vendor // ignore: cast_nullable_to_non_nullable
as Vendor?,
  ));
}

/// Create a copy of VendorDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VendorCopyWith<$Res>? get vendor {
    if (_self.vendor == null) {
    return null;
  }

  return $VendorCopyWith<$Res>(_self.vendor!, (value) {
    return _then(_self.copyWith(vendor: value));
  });
}
}

/// @nodoc


class VendorDetailReady implements VendorDetailState {
  const VendorDetailReady(this.vendor);
  

@override final  Vendor vendor;

/// Create a copy of VendorDetailState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VendorDetailReadyCopyWith<VendorDetailReady> get copyWith => _$VendorDetailReadyCopyWithImpl<VendorDetailReady>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VendorDetailReady&&(identical(other.vendor, vendor) || other.vendor == vendor));
}


@override
int get hashCode => Object.hash(runtimeType,vendor);

@override
String toString() {
  return 'VendorDetailState.ready(vendor: $vendor)';
}


}

/// @nodoc
abstract mixin class $VendorDetailReadyCopyWith<$Res> implements $VendorDetailStateCopyWith<$Res> {
  factory $VendorDetailReadyCopyWith(VendorDetailReady value, $Res Function(VendorDetailReady) _then) = _$VendorDetailReadyCopyWithImpl;
@override @useResult
$Res call({
 Vendor vendor
});


@override $VendorCopyWith<$Res> get vendor;

}
/// @nodoc
class _$VendorDetailReadyCopyWithImpl<$Res>
    implements $VendorDetailReadyCopyWith<$Res> {
  _$VendorDetailReadyCopyWithImpl(this._self, this._then);

  final VendorDetailReady _self;
  final $Res Function(VendorDetailReady) _then;

/// Create a copy of VendorDetailState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? vendor = null,}) {
  return _then(VendorDetailReady(
null == vendor ? _self.vendor : vendor // ignore: cast_nullable_to_non_nullable
as Vendor,
  ));
}

/// Create a copy of VendorDetailState
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


class VendorDetailWorking implements VendorDetailState {
  const VendorDetailWorking(this.vendor);
  

@override final  Vendor vendor;

/// Create a copy of VendorDetailState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VendorDetailWorkingCopyWith<VendorDetailWorking> get copyWith => _$VendorDetailWorkingCopyWithImpl<VendorDetailWorking>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VendorDetailWorking&&(identical(other.vendor, vendor) || other.vendor == vendor));
}


@override
int get hashCode => Object.hash(runtimeType,vendor);

@override
String toString() {
  return 'VendorDetailState.working(vendor: $vendor)';
}


}

/// @nodoc
abstract mixin class $VendorDetailWorkingCopyWith<$Res> implements $VendorDetailStateCopyWith<$Res> {
  factory $VendorDetailWorkingCopyWith(VendorDetailWorking value, $Res Function(VendorDetailWorking) _then) = _$VendorDetailWorkingCopyWithImpl;
@override @useResult
$Res call({
 Vendor vendor
});


@override $VendorCopyWith<$Res> get vendor;

}
/// @nodoc
class _$VendorDetailWorkingCopyWithImpl<$Res>
    implements $VendorDetailWorkingCopyWith<$Res> {
  _$VendorDetailWorkingCopyWithImpl(this._self, this._then);

  final VendorDetailWorking _self;
  final $Res Function(VendorDetailWorking) _then;

/// Create a copy of VendorDetailState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? vendor = null,}) {
  return _then(VendorDetailWorking(
null == vendor ? _self.vendor : vendor // ignore: cast_nullable_to_non_nullable
as Vendor,
  ));
}

/// Create a copy of VendorDetailState
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


class VendorDetailFailure implements VendorDetailState {
  const VendorDetailFailure(this.failure, {this.vendor});
  

 final  Failure failure;
@override final  Vendor? vendor;

/// Create a copy of VendorDetailState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VendorDetailFailureCopyWith<VendorDetailFailure> get copyWith => _$VendorDetailFailureCopyWithImpl<VendorDetailFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VendorDetailFailure&&(identical(other.failure, failure) || other.failure == failure)&&(identical(other.vendor, vendor) || other.vendor == vendor));
}


@override
int get hashCode => Object.hash(runtimeType,failure,vendor);

@override
String toString() {
  return 'VendorDetailState.failure(failure: $failure, vendor: $vendor)';
}


}

/// @nodoc
abstract mixin class $VendorDetailFailureCopyWith<$Res> implements $VendorDetailStateCopyWith<$Res> {
  factory $VendorDetailFailureCopyWith(VendorDetailFailure value, $Res Function(VendorDetailFailure) _then) = _$VendorDetailFailureCopyWithImpl;
@override @useResult
$Res call({
 Failure failure, Vendor? vendor
});


$FailureCopyWith<$Res> get failure;@override $VendorCopyWith<$Res>? get vendor;

}
/// @nodoc
class _$VendorDetailFailureCopyWithImpl<$Res>
    implements $VendorDetailFailureCopyWith<$Res> {
  _$VendorDetailFailureCopyWithImpl(this._self, this._then);

  final VendorDetailFailure _self;
  final $Res Function(VendorDetailFailure) _then;

/// Create a copy of VendorDetailState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? failure = null,Object? vendor = freezed,}) {
  return _then(VendorDetailFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,vendor: freezed == vendor ? _self.vendor : vendor // ignore: cast_nullable_to_non_nullable
as Vendor?,
  ));
}

/// Create a copy of VendorDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res> get failure {
  
  return $FailureCopyWith<$Res>(_self.failure, (value) {
    return _then(_self.copyWith(failure: value));
  });
}/// Create a copy of VendorDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VendorCopyWith<$Res>? get vendor {
    if (_self.vendor == null) {
    return null;
  }

  return $VendorCopyWith<$Res>(_self.vendor!, (value) {
    return _then(_self.copyWith(vendor: value));
  });
}
}

// dart format on
