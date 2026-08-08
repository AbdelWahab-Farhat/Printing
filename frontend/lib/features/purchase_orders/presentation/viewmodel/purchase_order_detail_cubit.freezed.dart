// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'purchase_order_detail_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PurchaseOrderDetailState {

 PurchaseOrder? get order;
/// Create a copy of PurchaseOrderDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PurchaseOrderDetailStateCopyWith<PurchaseOrderDetailState> get copyWith => _$PurchaseOrderDetailStateCopyWithImpl<PurchaseOrderDetailState>(this as PurchaseOrderDetailState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PurchaseOrderDetailState&&(identical(other.order, order) || other.order == order));
}


@override
int get hashCode => Object.hash(runtimeType,order);

@override
String toString() {
  return 'PurchaseOrderDetailState(order: $order)';
}


}

/// @nodoc
abstract mixin class $PurchaseOrderDetailStateCopyWith<$Res>  {
  factory $PurchaseOrderDetailStateCopyWith(PurchaseOrderDetailState value, $Res Function(PurchaseOrderDetailState) _then) = _$PurchaseOrderDetailStateCopyWithImpl;
@useResult
$Res call({
 PurchaseOrder order
});


$PurchaseOrderCopyWith<$Res>? get order;

}
/// @nodoc
class _$PurchaseOrderDetailStateCopyWithImpl<$Res>
    implements $PurchaseOrderDetailStateCopyWith<$Res> {
  _$PurchaseOrderDetailStateCopyWithImpl(this._self, this._then);

  final PurchaseOrderDetailState _self;
  final $Res Function(PurchaseOrderDetailState) _then;

/// Create a copy of PurchaseOrderDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? order = null,}) {
  return _then(_self.copyWith(
order: null == order ? _self.order! : order // ignore: cast_nullable_to_non_nullable
as PurchaseOrder,
  ));
}
/// Create a copy of PurchaseOrderDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PurchaseOrderCopyWith<$Res>? get order {
    if (_self.order == null) {
    return null;
  }

  return $PurchaseOrderCopyWith<$Res>(_self.order!, (value) {
    return _then(_self.copyWith(order: value));
  });
}
}


/// Adds pattern-matching-related methods to [PurchaseOrderDetailState].
extension PurchaseOrderDetailStatePatterns on PurchaseOrderDetailState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PurchaseOrderDetailLoading value)?  loading,TResult Function( PurchaseOrderDetailReady value)?  ready,TResult Function( PurchaseOrderDetailWorking value)?  working,TResult Function( PurchaseOrderDetailFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PurchaseOrderDetailLoading() when loading != null:
return loading(_that);case PurchaseOrderDetailReady() when ready != null:
return ready(_that);case PurchaseOrderDetailWorking() when working != null:
return working(_that);case PurchaseOrderDetailFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PurchaseOrderDetailLoading value)  loading,required TResult Function( PurchaseOrderDetailReady value)  ready,required TResult Function( PurchaseOrderDetailWorking value)  working,required TResult Function( PurchaseOrderDetailFailure value)  failure,}){
final _that = this;
switch (_that) {
case PurchaseOrderDetailLoading():
return loading(_that);case PurchaseOrderDetailReady():
return ready(_that);case PurchaseOrderDetailWorking():
return working(_that);case PurchaseOrderDetailFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PurchaseOrderDetailLoading value)?  loading,TResult? Function( PurchaseOrderDetailReady value)?  ready,TResult? Function( PurchaseOrderDetailWorking value)?  working,TResult? Function( PurchaseOrderDetailFailure value)?  failure,}){
final _that = this;
switch (_that) {
case PurchaseOrderDetailLoading() when loading != null:
return loading(_that);case PurchaseOrderDetailReady() when ready != null:
return ready(_that);case PurchaseOrderDetailWorking() when working != null:
return working(_that);case PurchaseOrderDetailFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( PurchaseOrder? order)?  loading,TResult Function( PurchaseOrder order)?  ready,TResult Function( PurchaseOrder order)?  working,TResult Function( Failure failure,  PurchaseOrder? order)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PurchaseOrderDetailLoading() when loading != null:
return loading(_that.order);case PurchaseOrderDetailReady() when ready != null:
return ready(_that.order);case PurchaseOrderDetailWorking() when working != null:
return working(_that.order);case PurchaseOrderDetailFailure() when failure != null:
return failure(_that.failure,_that.order);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( PurchaseOrder? order)  loading,required TResult Function( PurchaseOrder order)  ready,required TResult Function( PurchaseOrder order)  working,required TResult Function( Failure failure,  PurchaseOrder? order)  failure,}) {final _that = this;
switch (_that) {
case PurchaseOrderDetailLoading():
return loading(_that.order);case PurchaseOrderDetailReady():
return ready(_that.order);case PurchaseOrderDetailWorking():
return working(_that.order);case PurchaseOrderDetailFailure():
return failure(_that.failure,_that.order);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( PurchaseOrder? order)?  loading,TResult? Function( PurchaseOrder order)?  ready,TResult? Function( PurchaseOrder order)?  working,TResult? Function( Failure failure,  PurchaseOrder? order)?  failure,}) {final _that = this;
switch (_that) {
case PurchaseOrderDetailLoading() when loading != null:
return loading(_that.order);case PurchaseOrderDetailReady() when ready != null:
return ready(_that.order);case PurchaseOrderDetailWorking() when working != null:
return working(_that.order);case PurchaseOrderDetailFailure() when failure != null:
return failure(_that.failure,_that.order);case _:
  return null;

}
}

}

/// @nodoc


class PurchaseOrderDetailLoading implements PurchaseOrderDetailState {
  const PurchaseOrderDetailLoading({this.order});
  

@override final  PurchaseOrder? order;

/// Create a copy of PurchaseOrderDetailState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PurchaseOrderDetailLoadingCopyWith<PurchaseOrderDetailLoading> get copyWith => _$PurchaseOrderDetailLoadingCopyWithImpl<PurchaseOrderDetailLoading>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PurchaseOrderDetailLoading&&(identical(other.order, order) || other.order == order));
}


@override
int get hashCode => Object.hash(runtimeType,order);

@override
String toString() {
  return 'PurchaseOrderDetailState.loading(order: $order)';
}


}

/// @nodoc
abstract mixin class $PurchaseOrderDetailLoadingCopyWith<$Res> implements $PurchaseOrderDetailStateCopyWith<$Res> {
  factory $PurchaseOrderDetailLoadingCopyWith(PurchaseOrderDetailLoading value, $Res Function(PurchaseOrderDetailLoading) _then) = _$PurchaseOrderDetailLoadingCopyWithImpl;
@override @useResult
$Res call({
 PurchaseOrder? order
});


@override $PurchaseOrderCopyWith<$Res>? get order;

}
/// @nodoc
class _$PurchaseOrderDetailLoadingCopyWithImpl<$Res>
    implements $PurchaseOrderDetailLoadingCopyWith<$Res> {
  _$PurchaseOrderDetailLoadingCopyWithImpl(this._self, this._then);

  final PurchaseOrderDetailLoading _self;
  final $Res Function(PurchaseOrderDetailLoading) _then;

/// Create a copy of PurchaseOrderDetailState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? order = freezed,}) {
  return _then(PurchaseOrderDetailLoading(
order: freezed == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as PurchaseOrder?,
  ));
}

/// Create a copy of PurchaseOrderDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PurchaseOrderCopyWith<$Res>? get order {
    if (_self.order == null) {
    return null;
  }

  return $PurchaseOrderCopyWith<$Res>(_self.order!, (value) {
    return _then(_self.copyWith(order: value));
  });
}
}

/// @nodoc


class PurchaseOrderDetailReady implements PurchaseOrderDetailState {
  const PurchaseOrderDetailReady(this.order);
  

@override final  PurchaseOrder order;

/// Create a copy of PurchaseOrderDetailState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PurchaseOrderDetailReadyCopyWith<PurchaseOrderDetailReady> get copyWith => _$PurchaseOrderDetailReadyCopyWithImpl<PurchaseOrderDetailReady>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PurchaseOrderDetailReady&&(identical(other.order, order) || other.order == order));
}


@override
int get hashCode => Object.hash(runtimeType,order);

@override
String toString() {
  return 'PurchaseOrderDetailState.ready(order: $order)';
}


}

/// @nodoc
abstract mixin class $PurchaseOrderDetailReadyCopyWith<$Res> implements $PurchaseOrderDetailStateCopyWith<$Res> {
  factory $PurchaseOrderDetailReadyCopyWith(PurchaseOrderDetailReady value, $Res Function(PurchaseOrderDetailReady) _then) = _$PurchaseOrderDetailReadyCopyWithImpl;
@override @useResult
$Res call({
 PurchaseOrder order
});


@override $PurchaseOrderCopyWith<$Res> get order;

}
/// @nodoc
class _$PurchaseOrderDetailReadyCopyWithImpl<$Res>
    implements $PurchaseOrderDetailReadyCopyWith<$Res> {
  _$PurchaseOrderDetailReadyCopyWithImpl(this._self, this._then);

  final PurchaseOrderDetailReady _self;
  final $Res Function(PurchaseOrderDetailReady) _then;

/// Create a copy of PurchaseOrderDetailState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? order = null,}) {
  return _then(PurchaseOrderDetailReady(
null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as PurchaseOrder,
  ));
}

/// Create a copy of PurchaseOrderDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PurchaseOrderCopyWith<$Res> get order {
  
  return $PurchaseOrderCopyWith<$Res>(_self.order, (value) {
    return _then(_self.copyWith(order: value));
  });
}
}

/// @nodoc


class PurchaseOrderDetailWorking implements PurchaseOrderDetailState {
  const PurchaseOrderDetailWorking(this.order);
  

@override final  PurchaseOrder order;

/// Create a copy of PurchaseOrderDetailState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PurchaseOrderDetailWorkingCopyWith<PurchaseOrderDetailWorking> get copyWith => _$PurchaseOrderDetailWorkingCopyWithImpl<PurchaseOrderDetailWorking>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PurchaseOrderDetailWorking&&(identical(other.order, order) || other.order == order));
}


@override
int get hashCode => Object.hash(runtimeType,order);

@override
String toString() {
  return 'PurchaseOrderDetailState.working(order: $order)';
}


}

/// @nodoc
abstract mixin class $PurchaseOrderDetailWorkingCopyWith<$Res> implements $PurchaseOrderDetailStateCopyWith<$Res> {
  factory $PurchaseOrderDetailWorkingCopyWith(PurchaseOrderDetailWorking value, $Res Function(PurchaseOrderDetailWorking) _then) = _$PurchaseOrderDetailWorkingCopyWithImpl;
@override @useResult
$Res call({
 PurchaseOrder order
});


@override $PurchaseOrderCopyWith<$Res> get order;

}
/// @nodoc
class _$PurchaseOrderDetailWorkingCopyWithImpl<$Res>
    implements $PurchaseOrderDetailWorkingCopyWith<$Res> {
  _$PurchaseOrderDetailWorkingCopyWithImpl(this._self, this._then);

  final PurchaseOrderDetailWorking _self;
  final $Res Function(PurchaseOrderDetailWorking) _then;

/// Create a copy of PurchaseOrderDetailState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? order = null,}) {
  return _then(PurchaseOrderDetailWorking(
null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as PurchaseOrder,
  ));
}

/// Create a copy of PurchaseOrderDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PurchaseOrderCopyWith<$Res> get order {
  
  return $PurchaseOrderCopyWith<$Res>(_self.order, (value) {
    return _then(_self.copyWith(order: value));
  });
}
}

/// @nodoc


class PurchaseOrderDetailFailure implements PurchaseOrderDetailState {
  const PurchaseOrderDetailFailure(this.failure, {this.order});
  

 final  Failure failure;
@override final  PurchaseOrder? order;

/// Create a copy of PurchaseOrderDetailState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PurchaseOrderDetailFailureCopyWith<PurchaseOrderDetailFailure> get copyWith => _$PurchaseOrderDetailFailureCopyWithImpl<PurchaseOrderDetailFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PurchaseOrderDetailFailure&&(identical(other.failure, failure) || other.failure == failure)&&(identical(other.order, order) || other.order == order));
}


@override
int get hashCode => Object.hash(runtimeType,failure,order);

@override
String toString() {
  return 'PurchaseOrderDetailState.failure(failure: $failure, order: $order)';
}


}

/// @nodoc
abstract mixin class $PurchaseOrderDetailFailureCopyWith<$Res> implements $PurchaseOrderDetailStateCopyWith<$Res> {
  factory $PurchaseOrderDetailFailureCopyWith(PurchaseOrderDetailFailure value, $Res Function(PurchaseOrderDetailFailure) _then) = _$PurchaseOrderDetailFailureCopyWithImpl;
@override @useResult
$Res call({
 Failure failure, PurchaseOrder? order
});


$FailureCopyWith<$Res> get failure;@override $PurchaseOrderCopyWith<$Res>? get order;

}
/// @nodoc
class _$PurchaseOrderDetailFailureCopyWithImpl<$Res>
    implements $PurchaseOrderDetailFailureCopyWith<$Res> {
  _$PurchaseOrderDetailFailureCopyWithImpl(this._self, this._then);

  final PurchaseOrderDetailFailure _self;
  final $Res Function(PurchaseOrderDetailFailure) _then;

/// Create a copy of PurchaseOrderDetailState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? failure = null,Object? order = freezed,}) {
  return _then(PurchaseOrderDetailFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,order: freezed == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as PurchaseOrder?,
  ));
}

/// Create a copy of PurchaseOrderDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res> get failure {
  
  return $FailureCopyWith<$Res>(_self.failure, (value) {
    return _then(_self.copyWith(failure: value));
  });
}/// Create a copy of PurchaseOrderDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PurchaseOrderCopyWith<$Res>? get order {
    if (_self.order == null) {
    return null;
  }

  return $PurchaseOrderCopyWith<$Res>(_self.order!, (value) {
    return _then(_self.copyWith(order: value));
  });
}
}

// dart format on
