// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'internal_ticket_query.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$InternalTicketQuery {

 bool get allTickets;/// تفتح القائمة على «قيد المعالجة»، ولا «الكل» في الرقاقتين — كبريمولا.
 InternalTicketStatus get status; int? get categoryId;/// تذاكرُ زميلٍ بعينه، أيَّ طرفٍ كان.
 int? get userId; bool get unreadOnly;/// تذاكرُ طلبيةٍ أو عميل — القائمةُ مفتوحةً من صفحتهما.
 int? get orderId; int? get customerId; bool get oldestFirst;
/// Create a copy of InternalTicketQuery
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InternalTicketQueryCopyWith<InternalTicketQuery> get copyWith => _$InternalTicketQueryCopyWithImpl<InternalTicketQuery>(this as InternalTicketQuery, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InternalTicketQuery&&(identical(other.allTickets, allTickets) || other.allTickets == allTickets)&&(identical(other.status, status) || other.status == status)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.unreadOnly, unreadOnly) || other.unreadOnly == unreadOnly)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.oldestFirst, oldestFirst) || other.oldestFirst == oldestFirst));
}


@override
int get hashCode => Object.hash(runtimeType,allTickets,status,categoryId,userId,unreadOnly,orderId,customerId,oldestFirst);

@override
String toString() {
  return 'InternalTicketQuery(allTickets: $allTickets, status: $status, categoryId: $categoryId, userId: $userId, unreadOnly: $unreadOnly, orderId: $orderId, customerId: $customerId, oldestFirst: $oldestFirst)';
}


}

/// @nodoc
abstract mixin class $InternalTicketQueryCopyWith<$Res>  {
  factory $InternalTicketQueryCopyWith(InternalTicketQuery value, $Res Function(InternalTicketQuery) _then) = _$InternalTicketQueryCopyWithImpl;
@useResult
$Res call({
 bool allTickets, InternalTicketStatus status, int? categoryId, int? userId, bool unreadOnly, int? orderId, int? customerId, bool oldestFirst
});




}
/// @nodoc
class _$InternalTicketQueryCopyWithImpl<$Res>
    implements $InternalTicketQueryCopyWith<$Res> {
  _$InternalTicketQueryCopyWithImpl(this._self, this._then);

  final InternalTicketQuery _self;
  final $Res Function(InternalTicketQuery) _then;

/// Create a copy of InternalTicketQuery
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? allTickets = null,Object? status = null,Object? categoryId = freezed,Object? userId = freezed,Object? unreadOnly = null,Object? orderId = freezed,Object? customerId = freezed,Object? oldestFirst = null,}) {
  return _then(_self.copyWith(
allTickets: null == allTickets ? _self.allTickets : allTickets // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as InternalTicketStatus,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int?,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as int?,unreadOnly: null == unreadOnly ? _self.unreadOnly : unreadOnly // ignore: cast_nullable_to_non_nullable
as bool,orderId: freezed == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as int?,customerId: freezed == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as int?,oldestFirst: null == oldestFirst ? _self.oldestFirst : oldestFirst // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [InternalTicketQuery].
extension InternalTicketQueryPatterns on InternalTicketQuery {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InternalTicketQuery value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InternalTicketQuery() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InternalTicketQuery value)  $default,){
final _that = this;
switch (_that) {
case _InternalTicketQuery():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InternalTicketQuery value)?  $default,){
final _that = this;
switch (_that) {
case _InternalTicketQuery() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool allTickets,  InternalTicketStatus status,  int? categoryId,  int? userId,  bool unreadOnly,  int? orderId,  int? customerId,  bool oldestFirst)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InternalTicketQuery() when $default != null:
return $default(_that.allTickets,_that.status,_that.categoryId,_that.userId,_that.unreadOnly,_that.orderId,_that.customerId,_that.oldestFirst);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool allTickets,  InternalTicketStatus status,  int? categoryId,  int? userId,  bool unreadOnly,  int? orderId,  int? customerId,  bool oldestFirst)  $default,) {final _that = this;
switch (_that) {
case _InternalTicketQuery():
return $default(_that.allTickets,_that.status,_that.categoryId,_that.userId,_that.unreadOnly,_that.orderId,_that.customerId,_that.oldestFirst);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool allTickets,  InternalTicketStatus status,  int? categoryId,  int? userId,  bool unreadOnly,  int? orderId,  int? customerId,  bool oldestFirst)?  $default,) {final _that = this;
switch (_that) {
case _InternalTicketQuery() when $default != null:
return $default(_that.allTickets,_that.status,_that.categoryId,_that.userId,_that.unreadOnly,_that.orderId,_that.customerId,_that.oldestFirst);case _:
  return null;

}
}

}

/// @nodoc


class _InternalTicketQuery extends InternalTicketQuery {
  const _InternalTicketQuery({this.allTickets = false, this.status = InternalTicketStatus.inProgress, this.categoryId, this.userId, this.unreadOnly = false, this.orderId, this.customerId, this.oldestFirst = false}): super._();
  

@override@JsonKey() final  bool allTickets;
/// تفتح القائمة على «قيد المعالجة»، ولا «الكل» في الرقاقتين — كبريمولا.
@override@JsonKey() final  InternalTicketStatus status;
@override final  int? categoryId;
/// تذاكرُ زميلٍ بعينه، أيَّ طرفٍ كان.
@override final  int? userId;
@override@JsonKey() final  bool unreadOnly;
/// تذاكرُ طلبيةٍ أو عميل — القائمةُ مفتوحةً من صفحتهما.
@override final  int? orderId;
@override final  int? customerId;
@override@JsonKey() final  bool oldestFirst;

/// Create a copy of InternalTicketQuery
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InternalTicketQueryCopyWith<_InternalTicketQuery> get copyWith => __$InternalTicketQueryCopyWithImpl<_InternalTicketQuery>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InternalTicketQuery&&(identical(other.allTickets, allTickets) || other.allTickets == allTickets)&&(identical(other.status, status) || other.status == status)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.unreadOnly, unreadOnly) || other.unreadOnly == unreadOnly)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.oldestFirst, oldestFirst) || other.oldestFirst == oldestFirst));
}


@override
int get hashCode => Object.hash(runtimeType,allTickets,status,categoryId,userId,unreadOnly,orderId,customerId,oldestFirst);

@override
String toString() {
  return 'InternalTicketQuery(allTickets: $allTickets, status: $status, categoryId: $categoryId, userId: $userId, unreadOnly: $unreadOnly, orderId: $orderId, customerId: $customerId, oldestFirst: $oldestFirst)';
}


}

/// @nodoc
abstract mixin class _$InternalTicketQueryCopyWith<$Res> implements $InternalTicketQueryCopyWith<$Res> {
  factory _$InternalTicketQueryCopyWith(_InternalTicketQuery value, $Res Function(_InternalTicketQuery) _then) = __$InternalTicketQueryCopyWithImpl;
@override @useResult
$Res call({
 bool allTickets, InternalTicketStatus status, int? categoryId, int? userId, bool unreadOnly, int? orderId, int? customerId, bool oldestFirst
});




}
/// @nodoc
class __$InternalTicketQueryCopyWithImpl<$Res>
    implements _$InternalTicketQueryCopyWith<$Res> {
  __$InternalTicketQueryCopyWithImpl(this._self, this._then);

  final _InternalTicketQuery _self;
  final $Res Function(_InternalTicketQuery) _then;

/// Create a copy of InternalTicketQuery
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? allTickets = null,Object? status = null,Object? categoryId = freezed,Object? userId = freezed,Object? unreadOnly = null,Object? orderId = freezed,Object? customerId = freezed,Object? oldestFirst = null,}) {
  return _then(_InternalTicketQuery(
allTickets: null == allTickets ? _self.allTickets : allTickets // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as InternalTicketStatus,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int?,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as int?,unreadOnly: null == unreadOnly ? _self.unreadOnly : unreadOnly // ignore: cast_nullable_to_non_nullable
as bool,orderId: freezed == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as int?,customerId: freezed == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as int?,oldestFirst: null == oldestFirst ? _self.oldestFirst : oldestFirst // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$InternalTicketSubject {

 int? get orderId; String? get orderCode; int? get customerId; String? get customerName;
/// Create a copy of InternalTicketSubject
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InternalTicketSubjectCopyWith<InternalTicketSubject> get copyWith => _$InternalTicketSubjectCopyWithImpl<InternalTicketSubject>(this as InternalTicketSubject, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InternalTicketSubject&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.orderCode, orderCode) || other.orderCode == orderCode)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.customerName, customerName) || other.customerName == customerName));
}


@override
int get hashCode => Object.hash(runtimeType,orderId,orderCode,customerId,customerName);

@override
String toString() {
  return 'InternalTicketSubject(orderId: $orderId, orderCode: $orderCode, customerId: $customerId, customerName: $customerName)';
}


}

/// @nodoc
abstract mixin class $InternalTicketSubjectCopyWith<$Res>  {
  factory $InternalTicketSubjectCopyWith(InternalTicketSubject value, $Res Function(InternalTicketSubject) _then) = _$InternalTicketSubjectCopyWithImpl;
@useResult
$Res call({
 int? orderId, String? orderCode, int? customerId, String? customerName
});




}
/// @nodoc
class _$InternalTicketSubjectCopyWithImpl<$Res>
    implements $InternalTicketSubjectCopyWith<$Res> {
  _$InternalTicketSubjectCopyWithImpl(this._self, this._then);

  final InternalTicketSubject _self;
  final $Res Function(InternalTicketSubject) _then;

/// Create a copy of InternalTicketSubject
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? orderId = freezed,Object? orderCode = freezed,Object? customerId = freezed,Object? customerName = freezed,}) {
  return _then(_self.copyWith(
orderId: freezed == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as int?,orderCode: freezed == orderCode ? _self.orderCode : orderCode // ignore: cast_nullable_to_non_nullable
as String?,customerId: freezed == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as int?,customerName: freezed == customerName ? _self.customerName : customerName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [InternalTicketSubject].
extension InternalTicketSubjectPatterns on InternalTicketSubject {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InternalTicketSubject value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InternalTicketSubject() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InternalTicketSubject value)  $default,){
final _that = this;
switch (_that) {
case _InternalTicketSubject():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InternalTicketSubject value)?  $default,){
final _that = this;
switch (_that) {
case _InternalTicketSubject() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? orderId,  String? orderCode,  int? customerId,  String? customerName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InternalTicketSubject() when $default != null:
return $default(_that.orderId,_that.orderCode,_that.customerId,_that.customerName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? orderId,  String? orderCode,  int? customerId,  String? customerName)  $default,) {final _that = this;
switch (_that) {
case _InternalTicketSubject():
return $default(_that.orderId,_that.orderCode,_that.customerId,_that.customerName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? orderId,  String? orderCode,  int? customerId,  String? customerName)?  $default,) {final _that = this;
switch (_that) {
case _InternalTicketSubject() when $default != null:
return $default(_that.orderId,_that.orderCode,_that.customerId,_that.customerName);case _:
  return null;

}
}

}

/// @nodoc


class _InternalTicketSubject extends InternalTicketSubject {
  const _InternalTicketSubject({this.orderId, this.orderCode, this.customerId, this.customerName}): super._();
  

@override final  int? orderId;
@override final  String? orderCode;
@override final  int? customerId;
@override final  String? customerName;

/// Create a copy of InternalTicketSubject
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InternalTicketSubjectCopyWith<_InternalTicketSubject> get copyWith => __$InternalTicketSubjectCopyWithImpl<_InternalTicketSubject>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InternalTicketSubject&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.orderCode, orderCode) || other.orderCode == orderCode)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.customerName, customerName) || other.customerName == customerName));
}


@override
int get hashCode => Object.hash(runtimeType,orderId,orderCode,customerId,customerName);

@override
String toString() {
  return 'InternalTicketSubject(orderId: $orderId, orderCode: $orderCode, customerId: $customerId, customerName: $customerName)';
}


}

/// @nodoc
abstract mixin class _$InternalTicketSubjectCopyWith<$Res> implements $InternalTicketSubjectCopyWith<$Res> {
  factory _$InternalTicketSubjectCopyWith(_InternalTicketSubject value, $Res Function(_InternalTicketSubject) _then) = __$InternalTicketSubjectCopyWithImpl;
@override @useResult
$Res call({
 int? orderId, String? orderCode, int? customerId, String? customerName
});




}
/// @nodoc
class __$InternalTicketSubjectCopyWithImpl<$Res>
    implements _$InternalTicketSubjectCopyWith<$Res> {
  __$InternalTicketSubjectCopyWithImpl(this._self, this._then);

  final _InternalTicketSubject _self;
  final $Res Function(_InternalTicketSubject) _then;

/// Create a copy of InternalTicketSubject
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? orderId = freezed,Object? orderCode = freezed,Object? customerId = freezed,Object? customerName = freezed,}) {
  return _then(_InternalTicketSubject(
orderId: freezed == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as int?,orderCode: freezed == orderCode ? _self.orderCode : orderCode // ignore: cast_nullable_to_non_nullable
as String?,customerId: freezed == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as int?,customerName: freezed == customerName ? _self.customerName : customerName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$InternalTicketDraft {

 int get assigneeId; String get title; String get description; InternalTicketPriority get priority; int? get categoryId; int? get customerId; int? get orderId;
/// Create a copy of InternalTicketDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InternalTicketDraftCopyWith<InternalTicketDraft> get copyWith => _$InternalTicketDraftCopyWithImpl<InternalTicketDraft>(this as InternalTicketDraft, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InternalTicketDraft&&(identical(other.assigneeId, assigneeId) || other.assigneeId == assigneeId)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.orderId, orderId) || other.orderId == orderId));
}


@override
int get hashCode => Object.hash(runtimeType,assigneeId,title,description,priority,categoryId,customerId,orderId);

@override
String toString() {
  return 'InternalTicketDraft(assigneeId: $assigneeId, title: $title, description: $description, priority: $priority, categoryId: $categoryId, customerId: $customerId, orderId: $orderId)';
}


}

/// @nodoc
abstract mixin class $InternalTicketDraftCopyWith<$Res>  {
  factory $InternalTicketDraftCopyWith(InternalTicketDraft value, $Res Function(InternalTicketDraft) _then) = _$InternalTicketDraftCopyWithImpl;
@useResult
$Res call({
 int assigneeId, String title, String description, InternalTicketPriority priority, int? categoryId, int? customerId, int? orderId
});




}
/// @nodoc
class _$InternalTicketDraftCopyWithImpl<$Res>
    implements $InternalTicketDraftCopyWith<$Res> {
  _$InternalTicketDraftCopyWithImpl(this._self, this._then);

  final InternalTicketDraft _self;
  final $Res Function(InternalTicketDraft) _then;

/// Create a copy of InternalTicketDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? assigneeId = null,Object? title = null,Object? description = null,Object? priority = null,Object? categoryId = freezed,Object? customerId = freezed,Object? orderId = freezed,}) {
  return _then(_self.copyWith(
assigneeId: null == assigneeId ? _self.assigneeId : assigneeId // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as InternalTicketPriority,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int?,customerId: freezed == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as int?,orderId: freezed == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [InternalTicketDraft].
extension InternalTicketDraftPatterns on InternalTicketDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InternalTicketDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InternalTicketDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InternalTicketDraft value)  $default,){
final _that = this;
switch (_that) {
case _InternalTicketDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InternalTicketDraft value)?  $default,){
final _that = this;
switch (_that) {
case _InternalTicketDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int assigneeId,  String title,  String description,  InternalTicketPriority priority,  int? categoryId,  int? customerId,  int? orderId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InternalTicketDraft() when $default != null:
return $default(_that.assigneeId,_that.title,_that.description,_that.priority,_that.categoryId,_that.customerId,_that.orderId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int assigneeId,  String title,  String description,  InternalTicketPriority priority,  int? categoryId,  int? customerId,  int? orderId)  $default,) {final _that = this;
switch (_that) {
case _InternalTicketDraft():
return $default(_that.assigneeId,_that.title,_that.description,_that.priority,_that.categoryId,_that.customerId,_that.orderId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int assigneeId,  String title,  String description,  InternalTicketPriority priority,  int? categoryId,  int? customerId,  int? orderId)?  $default,) {final _that = this;
switch (_that) {
case _InternalTicketDraft() when $default != null:
return $default(_that.assigneeId,_that.title,_that.description,_that.priority,_that.categoryId,_that.customerId,_that.orderId);case _:
  return null;

}
}

}

/// @nodoc


class _InternalTicketDraft implements InternalTicketDraft {
  const _InternalTicketDraft({required this.assigneeId, required this.title, required this.description, this.priority = InternalTicketPriority.medium, this.categoryId, this.customerId, this.orderId});
  

@override final  int assigneeId;
@override final  String title;
@override final  String description;
@override@JsonKey() final  InternalTicketPriority priority;
@override final  int? categoryId;
@override final  int? customerId;
@override final  int? orderId;

/// Create a copy of InternalTicketDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InternalTicketDraftCopyWith<_InternalTicketDraft> get copyWith => __$InternalTicketDraftCopyWithImpl<_InternalTicketDraft>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InternalTicketDraft&&(identical(other.assigneeId, assigneeId) || other.assigneeId == assigneeId)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.orderId, orderId) || other.orderId == orderId));
}


@override
int get hashCode => Object.hash(runtimeType,assigneeId,title,description,priority,categoryId,customerId,orderId);

@override
String toString() {
  return 'InternalTicketDraft(assigneeId: $assigneeId, title: $title, description: $description, priority: $priority, categoryId: $categoryId, customerId: $customerId, orderId: $orderId)';
}


}

/// @nodoc
abstract mixin class _$InternalTicketDraftCopyWith<$Res> implements $InternalTicketDraftCopyWith<$Res> {
  factory _$InternalTicketDraftCopyWith(_InternalTicketDraft value, $Res Function(_InternalTicketDraft) _then) = __$InternalTicketDraftCopyWithImpl;
@override @useResult
$Res call({
 int assigneeId, String title, String description, InternalTicketPriority priority, int? categoryId, int? customerId, int? orderId
});




}
/// @nodoc
class __$InternalTicketDraftCopyWithImpl<$Res>
    implements _$InternalTicketDraftCopyWith<$Res> {
  __$InternalTicketDraftCopyWithImpl(this._self, this._then);

  final _InternalTicketDraft _self;
  final $Res Function(_InternalTicketDraft) _then;

/// Create a copy of InternalTicketDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? assigneeId = null,Object? title = null,Object? description = null,Object? priority = null,Object? categoryId = freezed,Object? customerId = freezed,Object? orderId = freezed,}) {
  return _then(_InternalTicketDraft(
assigneeId: null == assigneeId ? _self.assigneeId : assigneeId // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as InternalTicketPriority,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int?,customerId: freezed == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as int?,orderId: freezed == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
