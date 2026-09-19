// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'design_ticket.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DesignTicketTransition {

 String get value; String get label;
/// Create a copy of DesignTicketTransition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DesignTicketTransitionCopyWith<DesignTicketTransition> get copyWith => _$DesignTicketTransitionCopyWithImpl<DesignTicketTransition>(this as DesignTicketTransition, _$identity);

  /// Serializes this DesignTicketTransition to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DesignTicketTransition&&(identical(other.value, value) || other.value == value)&&(identical(other.label, label) || other.label == label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,value,label);

@override
String toString() {
  return 'DesignTicketTransition(value: $value, label: $label)';
}


}

/// @nodoc
abstract mixin class $DesignTicketTransitionCopyWith<$Res>  {
  factory $DesignTicketTransitionCopyWith(DesignTicketTransition value, $Res Function(DesignTicketTransition) _then) = _$DesignTicketTransitionCopyWithImpl;
@useResult
$Res call({
 String value, String label
});




}
/// @nodoc
class _$DesignTicketTransitionCopyWithImpl<$Res>
    implements $DesignTicketTransitionCopyWith<$Res> {
  _$DesignTicketTransitionCopyWithImpl(this._self, this._then);

  final DesignTicketTransition _self;
  final $Res Function(DesignTicketTransition) _then;

/// Create a copy of DesignTicketTransition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? value = null,Object? label = null,}) {
  return _then(_self.copyWith(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DesignTicketTransition].
extension DesignTicketTransitionPatterns on DesignTicketTransition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DesignTicketTransition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DesignTicketTransition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DesignTicketTransition value)  $default,){
final _that = this;
switch (_that) {
case _DesignTicketTransition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DesignTicketTransition value)?  $default,){
final _that = this;
switch (_that) {
case _DesignTicketTransition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String value,  String label)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DesignTicketTransition() when $default != null:
return $default(_that.value,_that.label);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String value,  String label)  $default,) {final _that = this;
switch (_that) {
case _DesignTicketTransition():
return $default(_that.value,_that.label);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String value,  String label)?  $default,) {final _that = this;
switch (_that) {
case _DesignTicketTransition() when $default != null:
return $default(_that.value,_that.label);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DesignTicketTransition implements DesignTicketTransition {
  const _DesignTicketTransition({required this.value, required this.label});
  factory _DesignTicketTransition.fromJson(Map<String, dynamic> json) => _$DesignTicketTransitionFromJson(json);

@override final  String value;
@override final  String label;

/// Create a copy of DesignTicketTransition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DesignTicketTransitionCopyWith<_DesignTicketTransition> get copyWith => __$DesignTicketTransitionCopyWithImpl<_DesignTicketTransition>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DesignTicketTransitionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DesignTicketTransition&&(identical(other.value, value) || other.value == value)&&(identical(other.label, label) || other.label == label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,value,label);

@override
String toString() {
  return 'DesignTicketTransition(value: $value, label: $label)';
}


}

/// @nodoc
abstract mixin class _$DesignTicketTransitionCopyWith<$Res> implements $DesignTicketTransitionCopyWith<$Res> {
  factory _$DesignTicketTransitionCopyWith(_DesignTicketTransition value, $Res Function(_DesignTicketTransition) _then) = __$DesignTicketTransitionCopyWithImpl;
@override @useResult
$Res call({
 String value, String label
});




}
/// @nodoc
class __$DesignTicketTransitionCopyWithImpl<$Res>
    implements _$DesignTicketTransitionCopyWith<$Res> {
  __$DesignTicketTransitionCopyWithImpl(this._self, this._then);

  final _DesignTicketTransition _self;
  final $Res Function(_DesignTicketTransition) _then;

/// Create a copy of DesignTicketTransition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? value = null,Object? label = null,}) {
  return _then(_DesignTicketTransition(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$DesignTicketOrder {

 int get id; String get code;@JsonKey(name: 'is_archived') bool get isArchived;
/// Create a copy of DesignTicketOrder
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DesignTicketOrderCopyWith<DesignTicketOrder> get copyWith => _$DesignTicketOrderCopyWithImpl<DesignTicketOrder>(this as DesignTicketOrder, _$identity);

  /// Serializes this DesignTicketOrder to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DesignTicketOrder&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,isArchived);

@override
String toString() {
  return 'DesignTicketOrder(id: $id, code: $code, isArchived: $isArchived)';
}


}

/// @nodoc
abstract mixin class $DesignTicketOrderCopyWith<$Res>  {
  factory $DesignTicketOrderCopyWith(DesignTicketOrder value, $Res Function(DesignTicketOrder) _then) = _$DesignTicketOrderCopyWithImpl;
@useResult
$Res call({
 int id, String code,@JsonKey(name: 'is_archived') bool isArchived
});




}
/// @nodoc
class _$DesignTicketOrderCopyWithImpl<$Res>
    implements $DesignTicketOrderCopyWith<$Res> {
  _$DesignTicketOrderCopyWithImpl(this._self, this._then);

  final DesignTicketOrder _self;
  final $Res Function(DesignTicketOrder) _then;

/// Create a copy of DesignTicketOrder
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = null,Object? isArchived = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [DesignTicketOrder].
extension DesignTicketOrderPatterns on DesignTicketOrder {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DesignTicketOrder value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DesignTicketOrder() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DesignTicketOrder value)  $default,){
final _that = this;
switch (_that) {
case _DesignTicketOrder():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DesignTicketOrder value)?  $default,){
final _that = this;
switch (_that) {
case _DesignTicketOrder() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String code, @JsonKey(name: 'is_archived')  bool isArchived)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DesignTicketOrder() when $default != null:
return $default(_that.id,_that.code,_that.isArchived);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String code, @JsonKey(name: 'is_archived')  bool isArchived)  $default,) {final _that = this;
switch (_that) {
case _DesignTicketOrder():
return $default(_that.id,_that.code,_that.isArchived);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String code, @JsonKey(name: 'is_archived')  bool isArchived)?  $default,) {final _that = this;
switch (_that) {
case _DesignTicketOrder() when $default != null:
return $default(_that.id,_that.code,_that.isArchived);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DesignTicketOrder implements DesignTicketOrder {
  const _DesignTicketOrder({required this.id, required this.code, @JsonKey(name: 'is_archived') this.isArchived = false});
  factory _DesignTicketOrder.fromJson(Map<String, dynamic> json) => _$DesignTicketOrderFromJson(json);

@override final  int id;
@override final  String code;
@override@JsonKey(name: 'is_archived') final  bool isArchived;

/// Create a copy of DesignTicketOrder
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DesignTicketOrderCopyWith<_DesignTicketOrder> get copyWith => __$DesignTicketOrderCopyWithImpl<_DesignTicketOrder>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DesignTicketOrderToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DesignTicketOrder&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,isArchived);

@override
String toString() {
  return 'DesignTicketOrder(id: $id, code: $code, isArchived: $isArchived)';
}


}

/// @nodoc
abstract mixin class _$DesignTicketOrderCopyWith<$Res> implements $DesignTicketOrderCopyWith<$Res> {
  factory _$DesignTicketOrderCopyWith(_DesignTicketOrder value, $Res Function(_DesignTicketOrder) _then) = __$DesignTicketOrderCopyWithImpl;
@override @useResult
$Res call({
 int id, String code,@JsonKey(name: 'is_archived') bool isArchived
});




}
/// @nodoc
class __$DesignTicketOrderCopyWithImpl<$Res>
    implements _$DesignTicketOrderCopyWith<$Res> {
  __$DesignTicketOrderCopyWithImpl(this._self, this._then);

  final _DesignTicketOrder _self;
  final $Res Function(_DesignTicketOrder) _then;

/// Create a copy of DesignTicketOrder
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = null,Object? isArchived = null,}) {
  return _then(_DesignTicketOrder(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$DesignTicket {

 int get id;/// `D7`. Said next to an order or a customer, which is why it carries a letter.
 String get code; String get title; String get description; String? get instructions;@JsonKey(unknownEnumValue: DesignTicketStatus.unknown) DesignTicketStatus get status;/// The status in Arabic, as the server words it. Shown instead of [DesignTicketStatus.label]
/// wherever a ticket is in hand, so an unknown status still names itself.
@JsonKey(name: 'status_label') String get statusLabel;@JsonKey(name: 'is_open') bool get isOpen;@JsonKey(name: 'is_closed') bool get isClosed;@JsonKey(name: 'available_transitions') List<DesignTicketTransition> get availableTransitions;@JsonKey(name: 'customer_id') int get customerId;/// See the note on the class: a snapshot, and the reason this screen needs no grant on
/// customers.
@JsonKey(name: 'customer_name') String get customerName;/// «C12» — joined on the server rather than snapshotted like the name, because a code is
/// allocated once and never edited.
///
/// **Nullable, and absent is ordinary**: the server sends it only where the relation was
/// eager-loaded, so a payload from a path that did not ask carries no key at all rather
/// than a wrong one.
@JsonKey(name: 'customer_code') String? get customerCode;@JsonKey(name: 'order_id') int? get orderId; DesignTicketOrder? get order; DesignTicketActor? get requester;/// **Two people, and they answer different questions.** [designer] is who the ticket is
/// addressed to; [acceptedBy] is who actually took it. A reassignment moves the first and
/// never the second — «لا تضيع هوية المصمم الذي استلم الطلب» is about the second.
 DesignTicketActor? get designer;@JsonKey(name: 'accepted_by') DesignTicketActor? get acceptedBy;@JsonKey(name: 'accepted_at') DateTime? get acceptedAt;/// Addressed to nobody and taken by nobody — what a designer scrolls to find work.
@JsonKey(name: 'is_in_shared_pool') bool get isInSharedPool;@JsonKey(name: 'approved_by') DesignTicketActor? get approvedBy;@JsonKey(name: 'completed_at') DateTime? get completedAt;/// What the approval put on the customer's account — the output of the whole flow.
@JsonKey(name: 'approved_customer_design_id') int? get approvedCustomerDesignId;@JsonKey(name: 'approved_design') CustomerDesign? get approvedDesign;@JsonKey(name: 'cancellation_reason') String? get cancellationReason;@JsonKey(name: 'versions_count') int? get versionsCount;/// كم ردّاً في المحادثة لم يقرأه **هذا** القارئ — شارةُ زرّ المحادثة، وشارةُ صفّ القائمة.
///
/// **رقمٌ عن القارئ لا عن التذكرة**، كالرايات الأربع `can*`: التذكرة الواحدة تحمل رقمَين
/// مختلفَين لطالبها ولمصمّمها في اللحظة نفسها، وصفراً لمديرٍ يقرأ التذاكر كلَّها ولم يُوجَّه
/// إليه شيء منها.
///
/// و`null` تعني «لم يقل الخادم»، لا صفراً: نسخةٌ أقدم من الواجهة لا ترسل المفتاح أصلاً،
/// وشارةٌ تُرسم من تخمينٍ أسوأ من شارةٍ لا تُرسم. انظر [unreadComments].
@JsonKey(name: 'unread_comments_count') int? get unreadCommentsCount;/// The newest version, as one row.
///
/// **Sent on the list as well as the detail**, which [versions] is not: the card draws this
/// as a thumbnail, and a page of forty tickets has no use for four hundred file rows. Null
/// on a ticket nobody has drawn for yet.
@JsonKey(name: 'latest_version') DesignTicketFile? get latestVersion;/// Only the detail endpoint sends these two; a list row carries neither.
 List<DesignTicketFile> get attachments; List<DesignTicketFile> get versions;@JsonKey(name: 'can_accept') bool get canAccept;@JsonKey(name: 'can_submit') bool get canSubmit;@JsonKey(name: 'can_review') bool get canReview;@JsonKey(name: 'can_assign') bool get canAssign;@JsonKey(name: 'can_manage') bool get canManage;@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'updated_at') DateTime? get updatedAt;
/// Create a copy of DesignTicket
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DesignTicketCopyWith<DesignTicket> get copyWith => _$DesignTicketCopyWithImpl<DesignTicket>(this as DesignTicket, _$identity);

  /// Serializes this DesignTicket to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DesignTicket&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.instructions, instructions) || other.instructions == instructions)&&(identical(other.status, status) || other.status == status)&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel)&&(identical(other.isOpen, isOpen) || other.isOpen == isOpen)&&(identical(other.isClosed, isClosed) || other.isClosed == isClosed)&&const DeepCollectionEquality().equals(other.availableTransitions, availableTransitions)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.customerName, customerName) || other.customerName == customerName)&&(identical(other.customerCode, customerCode) || other.customerCode == customerCode)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.order, order) || other.order == order)&&(identical(other.requester, requester) || other.requester == requester)&&(identical(other.designer, designer) || other.designer == designer)&&(identical(other.acceptedBy, acceptedBy) || other.acceptedBy == acceptedBy)&&(identical(other.acceptedAt, acceptedAt) || other.acceptedAt == acceptedAt)&&(identical(other.isInSharedPool, isInSharedPool) || other.isInSharedPool == isInSharedPool)&&(identical(other.approvedBy, approvedBy) || other.approvedBy == approvedBy)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.approvedCustomerDesignId, approvedCustomerDesignId) || other.approvedCustomerDesignId == approvedCustomerDesignId)&&(identical(other.approvedDesign, approvedDesign) || other.approvedDesign == approvedDesign)&&(identical(other.cancellationReason, cancellationReason) || other.cancellationReason == cancellationReason)&&(identical(other.versionsCount, versionsCount) || other.versionsCount == versionsCount)&&(identical(other.unreadCommentsCount, unreadCommentsCount) || other.unreadCommentsCount == unreadCommentsCount)&&(identical(other.latestVersion, latestVersion) || other.latestVersion == latestVersion)&&const DeepCollectionEquality().equals(other.attachments, attachments)&&const DeepCollectionEquality().equals(other.versions, versions)&&(identical(other.canAccept, canAccept) || other.canAccept == canAccept)&&(identical(other.canSubmit, canSubmit) || other.canSubmit == canSubmit)&&(identical(other.canReview, canReview) || other.canReview == canReview)&&(identical(other.canAssign, canAssign) || other.canAssign == canAssign)&&(identical(other.canManage, canManage) || other.canManage == canManage)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,code,title,description,instructions,status,statusLabel,isOpen,isClosed,const DeepCollectionEquality().hash(availableTransitions),customerId,customerName,customerCode,orderId,order,requester,designer,acceptedBy,acceptedAt,isInSharedPool,approvedBy,completedAt,approvedCustomerDesignId,approvedDesign,cancellationReason,versionsCount,unreadCommentsCount,latestVersion,const DeepCollectionEquality().hash(attachments),const DeepCollectionEquality().hash(versions),canAccept,canSubmit,canReview,canAssign,canManage,createdAt,updatedAt]);

@override
String toString() {
  return 'DesignTicket(id: $id, code: $code, title: $title, description: $description, instructions: $instructions, status: $status, statusLabel: $statusLabel, isOpen: $isOpen, isClosed: $isClosed, availableTransitions: $availableTransitions, customerId: $customerId, customerName: $customerName, customerCode: $customerCode, orderId: $orderId, order: $order, requester: $requester, designer: $designer, acceptedBy: $acceptedBy, acceptedAt: $acceptedAt, isInSharedPool: $isInSharedPool, approvedBy: $approvedBy, completedAt: $completedAt, approvedCustomerDesignId: $approvedCustomerDesignId, approvedDesign: $approvedDesign, cancellationReason: $cancellationReason, versionsCount: $versionsCount, unreadCommentsCount: $unreadCommentsCount, latestVersion: $latestVersion, attachments: $attachments, versions: $versions, canAccept: $canAccept, canSubmit: $canSubmit, canReview: $canReview, canAssign: $canAssign, canManage: $canManage, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $DesignTicketCopyWith<$Res>  {
  factory $DesignTicketCopyWith(DesignTicket value, $Res Function(DesignTicket) _then) = _$DesignTicketCopyWithImpl;
@useResult
$Res call({
 int id, String code, String title, String description, String? instructions,@JsonKey(unknownEnumValue: DesignTicketStatus.unknown) DesignTicketStatus status,@JsonKey(name: 'status_label') String statusLabel,@JsonKey(name: 'is_open') bool isOpen,@JsonKey(name: 'is_closed') bool isClosed,@JsonKey(name: 'available_transitions') List<DesignTicketTransition> availableTransitions,@JsonKey(name: 'customer_id') int customerId,@JsonKey(name: 'customer_name') String customerName,@JsonKey(name: 'customer_code') String? customerCode,@JsonKey(name: 'order_id') int? orderId, DesignTicketOrder? order, DesignTicketActor? requester, DesignTicketActor? designer,@JsonKey(name: 'accepted_by') DesignTicketActor? acceptedBy,@JsonKey(name: 'accepted_at') DateTime? acceptedAt,@JsonKey(name: 'is_in_shared_pool') bool isInSharedPool,@JsonKey(name: 'approved_by') DesignTicketActor? approvedBy,@JsonKey(name: 'completed_at') DateTime? completedAt,@JsonKey(name: 'approved_customer_design_id') int? approvedCustomerDesignId,@JsonKey(name: 'approved_design') CustomerDesign? approvedDesign,@JsonKey(name: 'cancellation_reason') String? cancellationReason,@JsonKey(name: 'versions_count') int? versionsCount,@JsonKey(name: 'unread_comments_count') int? unreadCommentsCount,@JsonKey(name: 'latest_version') DesignTicketFile? latestVersion, List<DesignTicketFile> attachments, List<DesignTicketFile> versions,@JsonKey(name: 'can_accept') bool canAccept,@JsonKey(name: 'can_submit') bool canSubmit,@JsonKey(name: 'can_review') bool canReview,@JsonKey(name: 'can_assign') bool canAssign,@JsonKey(name: 'can_manage') bool canManage,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});


$DesignTicketOrderCopyWith<$Res>? get order;$DesignTicketActorCopyWith<$Res>? get requester;$DesignTicketActorCopyWith<$Res>? get designer;$DesignTicketActorCopyWith<$Res>? get acceptedBy;$DesignTicketActorCopyWith<$Res>? get approvedBy;$CustomerDesignCopyWith<$Res>? get approvedDesign;$DesignTicketFileCopyWith<$Res>? get latestVersion;

}
/// @nodoc
class _$DesignTicketCopyWithImpl<$Res>
    implements $DesignTicketCopyWith<$Res> {
  _$DesignTicketCopyWithImpl(this._self, this._then);

  final DesignTicket _self;
  final $Res Function(DesignTicket) _then;

/// Create a copy of DesignTicket
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = null,Object? title = null,Object? description = null,Object? instructions = freezed,Object? status = null,Object? statusLabel = null,Object? isOpen = null,Object? isClosed = null,Object? availableTransitions = null,Object? customerId = null,Object? customerName = null,Object? customerCode = freezed,Object? orderId = freezed,Object? order = freezed,Object? requester = freezed,Object? designer = freezed,Object? acceptedBy = freezed,Object? acceptedAt = freezed,Object? isInSharedPool = null,Object? approvedBy = freezed,Object? completedAt = freezed,Object? approvedCustomerDesignId = freezed,Object? approvedDesign = freezed,Object? cancellationReason = freezed,Object? versionsCount = freezed,Object? unreadCommentsCount = freezed,Object? latestVersion = freezed,Object? attachments = null,Object? versions = null,Object? canAccept = null,Object? canSubmit = null,Object? canReview = null,Object? canAssign = null,Object? canManage = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,instructions: freezed == instructions ? _self.instructions : instructions // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DesignTicketStatus,statusLabel: null == statusLabel ? _self.statusLabel : statusLabel // ignore: cast_nullable_to_non_nullable
as String,isOpen: null == isOpen ? _self.isOpen : isOpen // ignore: cast_nullable_to_non_nullable
as bool,isClosed: null == isClosed ? _self.isClosed : isClosed // ignore: cast_nullable_to_non_nullable
as bool,availableTransitions: null == availableTransitions ? _self.availableTransitions : availableTransitions // ignore: cast_nullable_to_non_nullable
as List<DesignTicketTransition>,customerId: null == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as int,customerName: null == customerName ? _self.customerName : customerName // ignore: cast_nullable_to_non_nullable
as String,customerCode: freezed == customerCode ? _self.customerCode : customerCode // ignore: cast_nullable_to_non_nullable
as String?,orderId: freezed == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as int?,order: freezed == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as DesignTicketOrder?,requester: freezed == requester ? _self.requester : requester // ignore: cast_nullable_to_non_nullable
as DesignTicketActor?,designer: freezed == designer ? _self.designer : designer // ignore: cast_nullable_to_non_nullable
as DesignTicketActor?,acceptedBy: freezed == acceptedBy ? _self.acceptedBy : acceptedBy // ignore: cast_nullable_to_non_nullable
as DesignTicketActor?,acceptedAt: freezed == acceptedAt ? _self.acceptedAt : acceptedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isInSharedPool: null == isInSharedPool ? _self.isInSharedPool : isInSharedPool // ignore: cast_nullable_to_non_nullable
as bool,approvedBy: freezed == approvedBy ? _self.approvedBy : approvedBy // ignore: cast_nullable_to_non_nullable
as DesignTicketActor?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,approvedCustomerDesignId: freezed == approvedCustomerDesignId ? _self.approvedCustomerDesignId : approvedCustomerDesignId // ignore: cast_nullable_to_non_nullable
as int?,approvedDesign: freezed == approvedDesign ? _self.approvedDesign : approvedDesign // ignore: cast_nullable_to_non_nullable
as CustomerDesign?,cancellationReason: freezed == cancellationReason ? _self.cancellationReason : cancellationReason // ignore: cast_nullable_to_non_nullable
as String?,versionsCount: freezed == versionsCount ? _self.versionsCount : versionsCount // ignore: cast_nullable_to_non_nullable
as int?,unreadCommentsCount: freezed == unreadCommentsCount ? _self.unreadCommentsCount : unreadCommentsCount // ignore: cast_nullable_to_non_nullable
as int?,latestVersion: freezed == latestVersion ? _self.latestVersion : latestVersion // ignore: cast_nullable_to_non_nullable
as DesignTicketFile?,attachments: null == attachments ? _self.attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<DesignTicketFile>,versions: null == versions ? _self.versions : versions // ignore: cast_nullable_to_non_nullable
as List<DesignTicketFile>,canAccept: null == canAccept ? _self.canAccept : canAccept // ignore: cast_nullable_to_non_nullable
as bool,canSubmit: null == canSubmit ? _self.canSubmit : canSubmit // ignore: cast_nullable_to_non_nullable
as bool,canReview: null == canReview ? _self.canReview : canReview // ignore: cast_nullable_to_non_nullable
as bool,canAssign: null == canAssign ? _self.canAssign : canAssign // ignore: cast_nullable_to_non_nullable
as bool,canManage: null == canManage ? _self.canManage : canManage // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of DesignTicket
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DesignTicketOrderCopyWith<$Res>? get order {
    if (_self.order == null) {
    return null;
  }

  return $DesignTicketOrderCopyWith<$Res>(_self.order!, (value) {
    return _then(_self.copyWith(order: value));
  });
}/// Create a copy of DesignTicket
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DesignTicketActorCopyWith<$Res>? get requester {
    if (_self.requester == null) {
    return null;
  }

  return $DesignTicketActorCopyWith<$Res>(_self.requester!, (value) {
    return _then(_self.copyWith(requester: value));
  });
}/// Create a copy of DesignTicket
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DesignTicketActorCopyWith<$Res>? get designer {
    if (_self.designer == null) {
    return null;
  }

  return $DesignTicketActorCopyWith<$Res>(_self.designer!, (value) {
    return _then(_self.copyWith(designer: value));
  });
}/// Create a copy of DesignTicket
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DesignTicketActorCopyWith<$Res>? get acceptedBy {
    if (_self.acceptedBy == null) {
    return null;
  }

  return $DesignTicketActorCopyWith<$Res>(_self.acceptedBy!, (value) {
    return _then(_self.copyWith(acceptedBy: value));
  });
}/// Create a copy of DesignTicket
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DesignTicketActorCopyWith<$Res>? get approvedBy {
    if (_self.approvedBy == null) {
    return null;
  }

  return $DesignTicketActorCopyWith<$Res>(_self.approvedBy!, (value) {
    return _then(_self.copyWith(approvedBy: value));
  });
}/// Create a copy of DesignTicket
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CustomerDesignCopyWith<$Res>? get approvedDesign {
    if (_self.approvedDesign == null) {
    return null;
  }

  return $CustomerDesignCopyWith<$Res>(_self.approvedDesign!, (value) {
    return _then(_self.copyWith(approvedDesign: value));
  });
}/// Create a copy of DesignTicket
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DesignTicketFileCopyWith<$Res>? get latestVersion {
    if (_self.latestVersion == null) {
    return null;
  }

  return $DesignTicketFileCopyWith<$Res>(_self.latestVersion!, (value) {
    return _then(_self.copyWith(latestVersion: value));
  });
}
}


/// Adds pattern-matching-related methods to [DesignTicket].
extension DesignTicketPatterns on DesignTicket {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DesignTicket value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DesignTicket() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DesignTicket value)  $default,){
final _that = this;
switch (_that) {
case _DesignTicket():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DesignTicket value)?  $default,){
final _that = this;
switch (_that) {
case _DesignTicket() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String code,  String title,  String description,  String? instructions, @JsonKey(unknownEnumValue: DesignTicketStatus.unknown)  DesignTicketStatus status, @JsonKey(name: 'status_label')  String statusLabel, @JsonKey(name: 'is_open')  bool isOpen, @JsonKey(name: 'is_closed')  bool isClosed, @JsonKey(name: 'available_transitions')  List<DesignTicketTransition> availableTransitions, @JsonKey(name: 'customer_id')  int customerId, @JsonKey(name: 'customer_name')  String customerName, @JsonKey(name: 'customer_code')  String? customerCode, @JsonKey(name: 'order_id')  int? orderId,  DesignTicketOrder? order,  DesignTicketActor? requester,  DesignTicketActor? designer, @JsonKey(name: 'accepted_by')  DesignTicketActor? acceptedBy, @JsonKey(name: 'accepted_at')  DateTime? acceptedAt, @JsonKey(name: 'is_in_shared_pool')  bool isInSharedPool, @JsonKey(name: 'approved_by')  DesignTicketActor? approvedBy, @JsonKey(name: 'completed_at')  DateTime? completedAt, @JsonKey(name: 'approved_customer_design_id')  int? approvedCustomerDesignId, @JsonKey(name: 'approved_design')  CustomerDesign? approvedDesign, @JsonKey(name: 'cancellation_reason')  String? cancellationReason, @JsonKey(name: 'versions_count')  int? versionsCount, @JsonKey(name: 'unread_comments_count')  int? unreadCommentsCount, @JsonKey(name: 'latest_version')  DesignTicketFile? latestVersion,  List<DesignTicketFile> attachments,  List<DesignTicketFile> versions, @JsonKey(name: 'can_accept')  bool canAccept, @JsonKey(name: 'can_submit')  bool canSubmit, @JsonKey(name: 'can_review')  bool canReview, @JsonKey(name: 'can_assign')  bool canAssign, @JsonKey(name: 'can_manage')  bool canManage, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DesignTicket() when $default != null:
return $default(_that.id,_that.code,_that.title,_that.description,_that.instructions,_that.status,_that.statusLabel,_that.isOpen,_that.isClosed,_that.availableTransitions,_that.customerId,_that.customerName,_that.customerCode,_that.orderId,_that.order,_that.requester,_that.designer,_that.acceptedBy,_that.acceptedAt,_that.isInSharedPool,_that.approvedBy,_that.completedAt,_that.approvedCustomerDesignId,_that.approvedDesign,_that.cancellationReason,_that.versionsCount,_that.unreadCommentsCount,_that.latestVersion,_that.attachments,_that.versions,_that.canAccept,_that.canSubmit,_that.canReview,_that.canAssign,_that.canManage,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String code,  String title,  String description,  String? instructions, @JsonKey(unknownEnumValue: DesignTicketStatus.unknown)  DesignTicketStatus status, @JsonKey(name: 'status_label')  String statusLabel, @JsonKey(name: 'is_open')  bool isOpen, @JsonKey(name: 'is_closed')  bool isClosed, @JsonKey(name: 'available_transitions')  List<DesignTicketTransition> availableTransitions, @JsonKey(name: 'customer_id')  int customerId, @JsonKey(name: 'customer_name')  String customerName, @JsonKey(name: 'customer_code')  String? customerCode, @JsonKey(name: 'order_id')  int? orderId,  DesignTicketOrder? order,  DesignTicketActor? requester,  DesignTicketActor? designer, @JsonKey(name: 'accepted_by')  DesignTicketActor? acceptedBy, @JsonKey(name: 'accepted_at')  DateTime? acceptedAt, @JsonKey(name: 'is_in_shared_pool')  bool isInSharedPool, @JsonKey(name: 'approved_by')  DesignTicketActor? approvedBy, @JsonKey(name: 'completed_at')  DateTime? completedAt, @JsonKey(name: 'approved_customer_design_id')  int? approvedCustomerDesignId, @JsonKey(name: 'approved_design')  CustomerDesign? approvedDesign, @JsonKey(name: 'cancellation_reason')  String? cancellationReason, @JsonKey(name: 'versions_count')  int? versionsCount, @JsonKey(name: 'unread_comments_count')  int? unreadCommentsCount, @JsonKey(name: 'latest_version')  DesignTicketFile? latestVersion,  List<DesignTicketFile> attachments,  List<DesignTicketFile> versions, @JsonKey(name: 'can_accept')  bool canAccept, @JsonKey(name: 'can_submit')  bool canSubmit, @JsonKey(name: 'can_review')  bool canReview, @JsonKey(name: 'can_assign')  bool canAssign, @JsonKey(name: 'can_manage')  bool canManage, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _DesignTicket():
return $default(_that.id,_that.code,_that.title,_that.description,_that.instructions,_that.status,_that.statusLabel,_that.isOpen,_that.isClosed,_that.availableTransitions,_that.customerId,_that.customerName,_that.customerCode,_that.orderId,_that.order,_that.requester,_that.designer,_that.acceptedBy,_that.acceptedAt,_that.isInSharedPool,_that.approvedBy,_that.completedAt,_that.approvedCustomerDesignId,_that.approvedDesign,_that.cancellationReason,_that.versionsCount,_that.unreadCommentsCount,_that.latestVersion,_that.attachments,_that.versions,_that.canAccept,_that.canSubmit,_that.canReview,_that.canAssign,_that.canManage,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String code,  String title,  String description,  String? instructions, @JsonKey(unknownEnumValue: DesignTicketStatus.unknown)  DesignTicketStatus status, @JsonKey(name: 'status_label')  String statusLabel, @JsonKey(name: 'is_open')  bool isOpen, @JsonKey(name: 'is_closed')  bool isClosed, @JsonKey(name: 'available_transitions')  List<DesignTicketTransition> availableTransitions, @JsonKey(name: 'customer_id')  int customerId, @JsonKey(name: 'customer_name')  String customerName, @JsonKey(name: 'customer_code')  String? customerCode, @JsonKey(name: 'order_id')  int? orderId,  DesignTicketOrder? order,  DesignTicketActor? requester,  DesignTicketActor? designer, @JsonKey(name: 'accepted_by')  DesignTicketActor? acceptedBy, @JsonKey(name: 'accepted_at')  DateTime? acceptedAt, @JsonKey(name: 'is_in_shared_pool')  bool isInSharedPool, @JsonKey(name: 'approved_by')  DesignTicketActor? approvedBy, @JsonKey(name: 'completed_at')  DateTime? completedAt, @JsonKey(name: 'approved_customer_design_id')  int? approvedCustomerDesignId, @JsonKey(name: 'approved_design')  CustomerDesign? approvedDesign, @JsonKey(name: 'cancellation_reason')  String? cancellationReason, @JsonKey(name: 'versions_count')  int? versionsCount, @JsonKey(name: 'unread_comments_count')  int? unreadCommentsCount, @JsonKey(name: 'latest_version')  DesignTicketFile? latestVersion,  List<DesignTicketFile> attachments,  List<DesignTicketFile> versions, @JsonKey(name: 'can_accept')  bool canAccept, @JsonKey(name: 'can_submit')  bool canSubmit, @JsonKey(name: 'can_review')  bool canReview, @JsonKey(name: 'can_assign')  bool canAssign, @JsonKey(name: 'can_manage')  bool canManage, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _DesignTicket() when $default != null:
return $default(_that.id,_that.code,_that.title,_that.description,_that.instructions,_that.status,_that.statusLabel,_that.isOpen,_that.isClosed,_that.availableTransitions,_that.customerId,_that.customerName,_that.customerCode,_that.orderId,_that.order,_that.requester,_that.designer,_that.acceptedBy,_that.acceptedAt,_that.isInSharedPool,_that.approvedBy,_that.completedAt,_that.approvedCustomerDesignId,_that.approvedDesign,_that.cancellationReason,_that.versionsCount,_that.unreadCommentsCount,_that.latestVersion,_that.attachments,_that.versions,_that.canAccept,_that.canSubmit,_that.canReview,_that.canAssign,_that.canManage,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DesignTicket extends DesignTicket {
  const _DesignTicket({required this.id, required this.code, required this.title, required this.description, this.instructions, @JsonKey(unknownEnumValue: DesignTicketStatus.unknown) required this.status, @JsonKey(name: 'status_label') required this.statusLabel, @JsonKey(name: 'is_open') this.isOpen = true, @JsonKey(name: 'is_closed') this.isClosed = false, @JsonKey(name: 'available_transitions') final  List<DesignTicketTransition> availableTransitions = const <DesignTicketTransition>[], @JsonKey(name: 'customer_id') required this.customerId, @JsonKey(name: 'customer_name') required this.customerName, @JsonKey(name: 'customer_code') this.customerCode, @JsonKey(name: 'order_id') this.orderId, this.order, this.requester, this.designer, @JsonKey(name: 'accepted_by') this.acceptedBy, @JsonKey(name: 'accepted_at') this.acceptedAt, @JsonKey(name: 'is_in_shared_pool') this.isInSharedPool = false, @JsonKey(name: 'approved_by') this.approvedBy, @JsonKey(name: 'completed_at') this.completedAt, @JsonKey(name: 'approved_customer_design_id') this.approvedCustomerDesignId, @JsonKey(name: 'approved_design') this.approvedDesign, @JsonKey(name: 'cancellation_reason') this.cancellationReason, @JsonKey(name: 'versions_count') this.versionsCount, @JsonKey(name: 'unread_comments_count') this.unreadCommentsCount, @JsonKey(name: 'latest_version') this.latestVersion, final  List<DesignTicketFile> attachments = const <DesignTicketFile>[], final  List<DesignTicketFile> versions = const <DesignTicketFile>[], @JsonKey(name: 'can_accept') this.canAccept = false, @JsonKey(name: 'can_submit') this.canSubmit = false, @JsonKey(name: 'can_review') this.canReview = false, @JsonKey(name: 'can_assign') this.canAssign = false, @JsonKey(name: 'can_manage') this.canManage = false, @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt}): _availableTransitions = availableTransitions,_attachments = attachments,_versions = versions,super._();
  factory _DesignTicket.fromJson(Map<String, dynamic> json) => _$DesignTicketFromJson(json);

@override final  int id;
/// `D7`. Said next to an order or a customer, which is why it carries a letter.
@override final  String code;
@override final  String title;
@override final  String description;
@override final  String? instructions;
@override@JsonKey(unknownEnumValue: DesignTicketStatus.unknown) final  DesignTicketStatus status;
/// The status in Arabic, as the server words it. Shown instead of [DesignTicketStatus.label]
/// wherever a ticket is in hand, so an unknown status still names itself.
@override@JsonKey(name: 'status_label') final  String statusLabel;
@override@JsonKey(name: 'is_open') final  bool isOpen;
@override@JsonKey(name: 'is_closed') final  bool isClosed;
 final  List<DesignTicketTransition> _availableTransitions;
@override@JsonKey(name: 'available_transitions') List<DesignTicketTransition> get availableTransitions {
  if (_availableTransitions is EqualUnmodifiableListView) return _availableTransitions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_availableTransitions);
}

@override@JsonKey(name: 'customer_id') final  int customerId;
/// See the note on the class: a snapshot, and the reason this screen needs no grant on
/// customers.
@override@JsonKey(name: 'customer_name') final  String customerName;
/// «C12» — joined on the server rather than snapshotted like the name, because a code is
/// allocated once and never edited.
///
/// **Nullable, and absent is ordinary**: the server sends it only where the relation was
/// eager-loaded, so a payload from a path that did not ask carries no key at all rather
/// than a wrong one.
@override@JsonKey(name: 'customer_code') final  String? customerCode;
@override@JsonKey(name: 'order_id') final  int? orderId;
@override final  DesignTicketOrder? order;
@override final  DesignTicketActor? requester;
/// **Two people, and they answer different questions.** [designer] is who the ticket is
/// addressed to; [acceptedBy] is who actually took it. A reassignment moves the first and
/// never the second — «لا تضيع هوية المصمم الذي استلم الطلب» is about the second.
@override final  DesignTicketActor? designer;
@override@JsonKey(name: 'accepted_by') final  DesignTicketActor? acceptedBy;
@override@JsonKey(name: 'accepted_at') final  DateTime? acceptedAt;
/// Addressed to nobody and taken by nobody — what a designer scrolls to find work.
@override@JsonKey(name: 'is_in_shared_pool') final  bool isInSharedPool;
@override@JsonKey(name: 'approved_by') final  DesignTicketActor? approvedBy;
@override@JsonKey(name: 'completed_at') final  DateTime? completedAt;
/// What the approval put on the customer's account — the output of the whole flow.
@override@JsonKey(name: 'approved_customer_design_id') final  int? approvedCustomerDesignId;
@override@JsonKey(name: 'approved_design') final  CustomerDesign? approvedDesign;
@override@JsonKey(name: 'cancellation_reason') final  String? cancellationReason;
@override@JsonKey(name: 'versions_count') final  int? versionsCount;
/// كم ردّاً في المحادثة لم يقرأه **هذا** القارئ — شارةُ زرّ المحادثة، وشارةُ صفّ القائمة.
///
/// **رقمٌ عن القارئ لا عن التذكرة**، كالرايات الأربع `can*`: التذكرة الواحدة تحمل رقمَين
/// مختلفَين لطالبها ولمصمّمها في اللحظة نفسها، وصفراً لمديرٍ يقرأ التذاكر كلَّها ولم يُوجَّه
/// إليه شيء منها.
///
/// و`null` تعني «لم يقل الخادم»، لا صفراً: نسخةٌ أقدم من الواجهة لا ترسل المفتاح أصلاً،
/// وشارةٌ تُرسم من تخمينٍ أسوأ من شارةٍ لا تُرسم. انظر [unreadComments].
@override@JsonKey(name: 'unread_comments_count') final  int? unreadCommentsCount;
/// The newest version, as one row.
///
/// **Sent on the list as well as the detail**, which [versions] is not: the card draws this
/// as a thumbnail, and a page of forty tickets has no use for four hundred file rows. Null
/// on a ticket nobody has drawn for yet.
@override@JsonKey(name: 'latest_version') final  DesignTicketFile? latestVersion;
/// Only the detail endpoint sends these two; a list row carries neither.
 final  List<DesignTicketFile> _attachments;
/// Only the detail endpoint sends these two; a list row carries neither.
@override@JsonKey() List<DesignTicketFile> get attachments {
  if (_attachments is EqualUnmodifiableListView) return _attachments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_attachments);
}

 final  List<DesignTicketFile> _versions;
@override@JsonKey() List<DesignTicketFile> get versions {
  if (_versions is EqualUnmodifiableListView) return _versions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_versions);
}

@override@JsonKey(name: 'can_accept') final  bool canAccept;
@override@JsonKey(name: 'can_submit') final  bool canSubmit;
@override@JsonKey(name: 'can_review') final  bool canReview;
@override@JsonKey(name: 'can_assign') final  bool canAssign;
@override@JsonKey(name: 'can_manage') final  bool canManage;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;

/// Create a copy of DesignTicket
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DesignTicketCopyWith<_DesignTicket> get copyWith => __$DesignTicketCopyWithImpl<_DesignTicket>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DesignTicketToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DesignTicket&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.instructions, instructions) || other.instructions == instructions)&&(identical(other.status, status) || other.status == status)&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel)&&(identical(other.isOpen, isOpen) || other.isOpen == isOpen)&&(identical(other.isClosed, isClosed) || other.isClosed == isClosed)&&const DeepCollectionEquality().equals(other._availableTransitions, _availableTransitions)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.customerName, customerName) || other.customerName == customerName)&&(identical(other.customerCode, customerCode) || other.customerCode == customerCode)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.order, order) || other.order == order)&&(identical(other.requester, requester) || other.requester == requester)&&(identical(other.designer, designer) || other.designer == designer)&&(identical(other.acceptedBy, acceptedBy) || other.acceptedBy == acceptedBy)&&(identical(other.acceptedAt, acceptedAt) || other.acceptedAt == acceptedAt)&&(identical(other.isInSharedPool, isInSharedPool) || other.isInSharedPool == isInSharedPool)&&(identical(other.approvedBy, approvedBy) || other.approvedBy == approvedBy)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.approvedCustomerDesignId, approvedCustomerDesignId) || other.approvedCustomerDesignId == approvedCustomerDesignId)&&(identical(other.approvedDesign, approvedDesign) || other.approvedDesign == approvedDesign)&&(identical(other.cancellationReason, cancellationReason) || other.cancellationReason == cancellationReason)&&(identical(other.versionsCount, versionsCount) || other.versionsCount == versionsCount)&&(identical(other.unreadCommentsCount, unreadCommentsCount) || other.unreadCommentsCount == unreadCommentsCount)&&(identical(other.latestVersion, latestVersion) || other.latestVersion == latestVersion)&&const DeepCollectionEquality().equals(other._attachments, _attachments)&&const DeepCollectionEquality().equals(other._versions, _versions)&&(identical(other.canAccept, canAccept) || other.canAccept == canAccept)&&(identical(other.canSubmit, canSubmit) || other.canSubmit == canSubmit)&&(identical(other.canReview, canReview) || other.canReview == canReview)&&(identical(other.canAssign, canAssign) || other.canAssign == canAssign)&&(identical(other.canManage, canManage) || other.canManage == canManage)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,code,title,description,instructions,status,statusLabel,isOpen,isClosed,const DeepCollectionEquality().hash(_availableTransitions),customerId,customerName,customerCode,orderId,order,requester,designer,acceptedBy,acceptedAt,isInSharedPool,approvedBy,completedAt,approvedCustomerDesignId,approvedDesign,cancellationReason,versionsCount,unreadCommentsCount,latestVersion,const DeepCollectionEquality().hash(_attachments),const DeepCollectionEquality().hash(_versions),canAccept,canSubmit,canReview,canAssign,canManage,createdAt,updatedAt]);

@override
String toString() {
  return 'DesignTicket(id: $id, code: $code, title: $title, description: $description, instructions: $instructions, status: $status, statusLabel: $statusLabel, isOpen: $isOpen, isClosed: $isClosed, availableTransitions: $availableTransitions, customerId: $customerId, customerName: $customerName, customerCode: $customerCode, orderId: $orderId, order: $order, requester: $requester, designer: $designer, acceptedBy: $acceptedBy, acceptedAt: $acceptedAt, isInSharedPool: $isInSharedPool, approvedBy: $approvedBy, completedAt: $completedAt, approvedCustomerDesignId: $approvedCustomerDesignId, approvedDesign: $approvedDesign, cancellationReason: $cancellationReason, versionsCount: $versionsCount, unreadCommentsCount: $unreadCommentsCount, latestVersion: $latestVersion, attachments: $attachments, versions: $versions, canAccept: $canAccept, canSubmit: $canSubmit, canReview: $canReview, canAssign: $canAssign, canManage: $canManage, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$DesignTicketCopyWith<$Res> implements $DesignTicketCopyWith<$Res> {
  factory _$DesignTicketCopyWith(_DesignTicket value, $Res Function(_DesignTicket) _then) = __$DesignTicketCopyWithImpl;
@override @useResult
$Res call({
 int id, String code, String title, String description, String? instructions,@JsonKey(unknownEnumValue: DesignTicketStatus.unknown) DesignTicketStatus status,@JsonKey(name: 'status_label') String statusLabel,@JsonKey(name: 'is_open') bool isOpen,@JsonKey(name: 'is_closed') bool isClosed,@JsonKey(name: 'available_transitions') List<DesignTicketTransition> availableTransitions,@JsonKey(name: 'customer_id') int customerId,@JsonKey(name: 'customer_name') String customerName,@JsonKey(name: 'customer_code') String? customerCode,@JsonKey(name: 'order_id') int? orderId, DesignTicketOrder? order, DesignTicketActor? requester, DesignTicketActor? designer,@JsonKey(name: 'accepted_by') DesignTicketActor? acceptedBy,@JsonKey(name: 'accepted_at') DateTime? acceptedAt,@JsonKey(name: 'is_in_shared_pool') bool isInSharedPool,@JsonKey(name: 'approved_by') DesignTicketActor? approvedBy,@JsonKey(name: 'completed_at') DateTime? completedAt,@JsonKey(name: 'approved_customer_design_id') int? approvedCustomerDesignId,@JsonKey(name: 'approved_design') CustomerDesign? approvedDesign,@JsonKey(name: 'cancellation_reason') String? cancellationReason,@JsonKey(name: 'versions_count') int? versionsCount,@JsonKey(name: 'unread_comments_count') int? unreadCommentsCount,@JsonKey(name: 'latest_version') DesignTicketFile? latestVersion, List<DesignTicketFile> attachments, List<DesignTicketFile> versions,@JsonKey(name: 'can_accept') bool canAccept,@JsonKey(name: 'can_submit') bool canSubmit,@JsonKey(name: 'can_review') bool canReview,@JsonKey(name: 'can_assign') bool canAssign,@JsonKey(name: 'can_manage') bool canManage,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});


@override $DesignTicketOrderCopyWith<$Res>? get order;@override $DesignTicketActorCopyWith<$Res>? get requester;@override $DesignTicketActorCopyWith<$Res>? get designer;@override $DesignTicketActorCopyWith<$Res>? get acceptedBy;@override $DesignTicketActorCopyWith<$Res>? get approvedBy;@override $CustomerDesignCopyWith<$Res>? get approvedDesign;@override $DesignTicketFileCopyWith<$Res>? get latestVersion;

}
/// @nodoc
class __$DesignTicketCopyWithImpl<$Res>
    implements _$DesignTicketCopyWith<$Res> {
  __$DesignTicketCopyWithImpl(this._self, this._then);

  final _DesignTicket _self;
  final $Res Function(_DesignTicket) _then;

/// Create a copy of DesignTicket
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = null,Object? title = null,Object? description = null,Object? instructions = freezed,Object? status = null,Object? statusLabel = null,Object? isOpen = null,Object? isClosed = null,Object? availableTransitions = null,Object? customerId = null,Object? customerName = null,Object? customerCode = freezed,Object? orderId = freezed,Object? order = freezed,Object? requester = freezed,Object? designer = freezed,Object? acceptedBy = freezed,Object? acceptedAt = freezed,Object? isInSharedPool = null,Object? approvedBy = freezed,Object? completedAt = freezed,Object? approvedCustomerDesignId = freezed,Object? approvedDesign = freezed,Object? cancellationReason = freezed,Object? versionsCount = freezed,Object? unreadCommentsCount = freezed,Object? latestVersion = freezed,Object? attachments = null,Object? versions = null,Object? canAccept = null,Object? canSubmit = null,Object? canReview = null,Object? canAssign = null,Object? canManage = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_DesignTicket(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,instructions: freezed == instructions ? _self.instructions : instructions // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DesignTicketStatus,statusLabel: null == statusLabel ? _self.statusLabel : statusLabel // ignore: cast_nullable_to_non_nullable
as String,isOpen: null == isOpen ? _self.isOpen : isOpen // ignore: cast_nullable_to_non_nullable
as bool,isClosed: null == isClosed ? _self.isClosed : isClosed // ignore: cast_nullable_to_non_nullable
as bool,availableTransitions: null == availableTransitions ? _self._availableTransitions : availableTransitions // ignore: cast_nullable_to_non_nullable
as List<DesignTicketTransition>,customerId: null == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as int,customerName: null == customerName ? _self.customerName : customerName // ignore: cast_nullable_to_non_nullable
as String,customerCode: freezed == customerCode ? _self.customerCode : customerCode // ignore: cast_nullable_to_non_nullable
as String?,orderId: freezed == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as int?,order: freezed == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as DesignTicketOrder?,requester: freezed == requester ? _self.requester : requester // ignore: cast_nullable_to_non_nullable
as DesignTicketActor?,designer: freezed == designer ? _self.designer : designer // ignore: cast_nullable_to_non_nullable
as DesignTicketActor?,acceptedBy: freezed == acceptedBy ? _self.acceptedBy : acceptedBy // ignore: cast_nullable_to_non_nullable
as DesignTicketActor?,acceptedAt: freezed == acceptedAt ? _self.acceptedAt : acceptedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isInSharedPool: null == isInSharedPool ? _self.isInSharedPool : isInSharedPool // ignore: cast_nullable_to_non_nullable
as bool,approvedBy: freezed == approvedBy ? _self.approvedBy : approvedBy // ignore: cast_nullable_to_non_nullable
as DesignTicketActor?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,approvedCustomerDesignId: freezed == approvedCustomerDesignId ? _self.approvedCustomerDesignId : approvedCustomerDesignId // ignore: cast_nullable_to_non_nullable
as int?,approvedDesign: freezed == approvedDesign ? _self.approvedDesign : approvedDesign // ignore: cast_nullable_to_non_nullable
as CustomerDesign?,cancellationReason: freezed == cancellationReason ? _self.cancellationReason : cancellationReason // ignore: cast_nullable_to_non_nullable
as String?,versionsCount: freezed == versionsCount ? _self.versionsCount : versionsCount // ignore: cast_nullable_to_non_nullable
as int?,unreadCommentsCount: freezed == unreadCommentsCount ? _self.unreadCommentsCount : unreadCommentsCount // ignore: cast_nullable_to_non_nullable
as int?,latestVersion: freezed == latestVersion ? _self.latestVersion : latestVersion // ignore: cast_nullable_to_non_nullable
as DesignTicketFile?,attachments: null == attachments ? _self._attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<DesignTicketFile>,versions: null == versions ? _self._versions : versions // ignore: cast_nullable_to_non_nullable
as List<DesignTicketFile>,canAccept: null == canAccept ? _self.canAccept : canAccept // ignore: cast_nullable_to_non_nullable
as bool,canSubmit: null == canSubmit ? _self.canSubmit : canSubmit // ignore: cast_nullable_to_non_nullable
as bool,canReview: null == canReview ? _self.canReview : canReview // ignore: cast_nullable_to_non_nullable
as bool,canAssign: null == canAssign ? _self.canAssign : canAssign // ignore: cast_nullable_to_non_nullable
as bool,canManage: null == canManage ? _self.canManage : canManage // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of DesignTicket
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DesignTicketOrderCopyWith<$Res>? get order {
    if (_self.order == null) {
    return null;
  }

  return $DesignTicketOrderCopyWith<$Res>(_self.order!, (value) {
    return _then(_self.copyWith(order: value));
  });
}/// Create a copy of DesignTicket
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DesignTicketActorCopyWith<$Res>? get requester {
    if (_self.requester == null) {
    return null;
  }

  return $DesignTicketActorCopyWith<$Res>(_self.requester!, (value) {
    return _then(_self.copyWith(requester: value));
  });
}/// Create a copy of DesignTicket
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DesignTicketActorCopyWith<$Res>? get designer {
    if (_self.designer == null) {
    return null;
  }

  return $DesignTicketActorCopyWith<$Res>(_self.designer!, (value) {
    return _then(_self.copyWith(designer: value));
  });
}/// Create a copy of DesignTicket
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DesignTicketActorCopyWith<$Res>? get acceptedBy {
    if (_self.acceptedBy == null) {
    return null;
  }

  return $DesignTicketActorCopyWith<$Res>(_self.acceptedBy!, (value) {
    return _then(_self.copyWith(acceptedBy: value));
  });
}/// Create a copy of DesignTicket
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DesignTicketActorCopyWith<$Res>? get approvedBy {
    if (_self.approvedBy == null) {
    return null;
  }

  return $DesignTicketActorCopyWith<$Res>(_self.approvedBy!, (value) {
    return _then(_self.copyWith(approvedBy: value));
  });
}/// Create a copy of DesignTicket
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CustomerDesignCopyWith<$Res>? get approvedDesign {
    if (_self.approvedDesign == null) {
    return null;
  }

  return $CustomerDesignCopyWith<$Res>(_self.approvedDesign!, (value) {
    return _then(_self.copyWith(approvedDesign: value));
  });
}/// Create a copy of DesignTicket
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DesignTicketFileCopyWith<$Res>? get latestVersion {
    if (_self.latestVersion == null) {
    return null;
  }

  return $DesignTicketFileCopyWith<$Res>(_self.latestVersion!, (value) {
    return _then(_self.copyWith(latestVersion: value));
  });
}
}

// dart format on
