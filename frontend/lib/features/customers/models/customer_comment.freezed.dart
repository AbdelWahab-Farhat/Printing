// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'customer_comment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CustomerComment {

 int get id;@JsonKey(name: 'customer_id') int get customerId; String get body; CommentAuthor get author;@JsonKey(name: 'created_at') DateTime? get createdAt;/// When it was last rewritten. Null means «as it was written» — a note that changed says
/// so, because a sentence that quietly becomes a different sentence is worse than none.
@JsonKey(name: 'edited_at') DateTime? get editedAt;@JsonKey(name: 'can_edit') bool get canEdit;@JsonKey(name: 'can_delete') bool get canDelete;
/// Create a copy of CustomerComment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustomerCommentCopyWith<CustomerComment> get copyWith => _$CustomerCommentCopyWithImpl<CustomerComment>(this as CustomerComment, _$identity);

  /// Serializes this CustomerComment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomerComment&&(identical(other.id, id) || other.id == id)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.body, body) || other.body == body)&&(identical(other.author, author) || other.author == author)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.editedAt, editedAt) || other.editedAt == editedAt)&&(identical(other.canEdit, canEdit) || other.canEdit == canEdit)&&(identical(other.canDelete, canDelete) || other.canDelete == canDelete));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,customerId,body,author,createdAt,editedAt,canEdit,canDelete);

@override
String toString() {
  return 'CustomerComment(id: $id, customerId: $customerId, body: $body, author: $author, createdAt: $createdAt, editedAt: $editedAt, canEdit: $canEdit, canDelete: $canDelete)';
}


}

/// @nodoc
abstract mixin class $CustomerCommentCopyWith<$Res>  {
  factory $CustomerCommentCopyWith(CustomerComment value, $Res Function(CustomerComment) _then) = _$CustomerCommentCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'customer_id') int customerId, String body, CommentAuthor author,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'edited_at') DateTime? editedAt,@JsonKey(name: 'can_edit') bool canEdit,@JsonKey(name: 'can_delete') bool canDelete
});


$CommentAuthorCopyWith<$Res> get author;

}
/// @nodoc
class _$CustomerCommentCopyWithImpl<$Res>
    implements $CustomerCommentCopyWith<$Res> {
  _$CustomerCommentCopyWithImpl(this._self, this._then);

  final CustomerComment _self;
  final $Res Function(CustomerComment) _then;

/// Create a copy of CustomerComment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? customerId = null,Object? body = null,Object? author = null,Object? createdAt = freezed,Object? editedAt = freezed,Object? canEdit = null,Object? canDelete = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,customerId: null == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as int,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as CommentAuthor,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,editedAt: freezed == editedAt ? _self.editedAt : editedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,canEdit: null == canEdit ? _self.canEdit : canEdit // ignore: cast_nullable_to_non_nullable
as bool,canDelete: null == canDelete ? _self.canDelete : canDelete // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of CustomerComment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CommentAuthorCopyWith<$Res> get author {
  
  return $CommentAuthorCopyWith<$Res>(_self.author, (value) {
    return _then(_self.copyWith(author: value));
  });
}
}


/// Adds pattern-matching-related methods to [CustomerComment].
extension CustomerCommentPatterns on CustomerComment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CustomerComment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CustomerComment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CustomerComment value)  $default,){
final _that = this;
switch (_that) {
case _CustomerComment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CustomerComment value)?  $default,){
final _that = this;
switch (_that) {
case _CustomerComment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'customer_id')  int customerId,  String body,  CommentAuthor author, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'edited_at')  DateTime? editedAt, @JsonKey(name: 'can_edit')  bool canEdit, @JsonKey(name: 'can_delete')  bool canDelete)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CustomerComment() when $default != null:
return $default(_that.id,_that.customerId,_that.body,_that.author,_that.createdAt,_that.editedAt,_that.canEdit,_that.canDelete);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'customer_id')  int customerId,  String body,  CommentAuthor author, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'edited_at')  DateTime? editedAt, @JsonKey(name: 'can_edit')  bool canEdit, @JsonKey(name: 'can_delete')  bool canDelete)  $default,) {final _that = this;
switch (_that) {
case _CustomerComment():
return $default(_that.id,_that.customerId,_that.body,_that.author,_that.createdAt,_that.editedAt,_that.canEdit,_that.canDelete);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'customer_id')  int customerId,  String body,  CommentAuthor author, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'edited_at')  DateTime? editedAt, @JsonKey(name: 'can_edit')  bool canEdit, @JsonKey(name: 'can_delete')  bool canDelete)?  $default,) {final _that = this;
switch (_that) {
case _CustomerComment() when $default != null:
return $default(_that.id,_that.customerId,_that.body,_that.author,_that.createdAt,_that.editedAt,_that.canEdit,_that.canDelete);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CustomerComment extends CustomerComment {
  const _CustomerComment({required this.id, @JsonKey(name: 'customer_id') required this.customerId, required this.body, required this.author, @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'edited_at') this.editedAt, @JsonKey(name: 'can_edit') this.canEdit = false, @JsonKey(name: 'can_delete') this.canDelete = false}): super._();
  factory _CustomerComment.fromJson(Map<String, dynamic> json) => _$CustomerCommentFromJson(json);

@override final  int id;
@override@JsonKey(name: 'customer_id') final  int customerId;
@override final  String body;
@override final  CommentAuthor author;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
/// When it was last rewritten. Null means «as it was written» — a note that changed says
/// so, because a sentence that quietly becomes a different sentence is worse than none.
@override@JsonKey(name: 'edited_at') final  DateTime? editedAt;
@override@JsonKey(name: 'can_edit') final  bool canEdit;
@override@JsonKey(name: 'can_delete') final  bool canDelete;

/// Create a copy of CustomerComment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CustomerCommentCopyWith<_CustomerComment> get copyWith => __$CustomerCommentCopyWithImpl<_CustomerComment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CustomerCommentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CustomerComment&&(identical(other.id, id) || other.id == id)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.body, body) || other.body == body)&&(identical(other.author, author) || other.author == author)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.editedAt, editedAt) || other.editedAt == editedAt)&&(identical(other.canEdit, canEdit) || other.canEdit == canEdit)&&(identical(other.canDelete, canDelete) || other.canDelete == canDelete));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,customerId,body,author,createdAt,editedAt,canEdit,canDelete);

@override
String toString() {
  return 'CustomerComment(id: $id, customerId: $customerId, body: $body, author: $author, createdAt: $createdAt, editedAt: $editedAt, canEdit: $canEdit, canDelete: $canDelete)';
}


}

/// @nodoc
abstract mixin class _$CustomerCommentCopyWith<$Res> implements $CustomerCommentCopyWith<$Res> {
  factory _$CustomerCommentCopyWith(_CustomerComment value, $Res Function(_CustomerComment) _then) = __$CustomerCommentCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'customer_id') int customerId, String body, CommentAuthor author,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'edited_at') DateTime? editedAt,@JsonKey(name: 'can_edit') bool canEdit,@JsonKey(name: 'can_delete') bool canDelete
});


@override $CommentAuthorCopyWith<$Res> get author;

}
/// @nodoc
class __$CustomerCommentCopyWithImpl<$Res>
    implements _$CustomerCommentCopyWith<$Res> {
  __$CustomerCommentCopyWithImpl(this._self, this._then);

  final _CustomerComment _self;
  final $Res Function(_CustomerComment) _then;

/// Create a copy of CustomerComment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? customerId = null,Object? body = null,Object? author = null,Object? createdAt = freezed,Object? editedAt = freezed,Object? canEdit = null,Object? canDelete = null,}) {
  return _then(_CustomerComment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,customerId: null == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as int,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as CommentAuthor,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,editedAt: freezed == editedAt ? _self.editedAt : editedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,canEdit: null == canEdit ? _self.canEdit : canEdit // ignore: cast_nullable_to_non_nullable
as bool,canDelete: null == canDelete ? _self.canDelete : canDelete // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of CustomerComment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CommentAuthorCopyWith<$Res> get author {
  
  return $CommentAuthorCopyWith<$Res>(_self.author, (value) {
    return _then(_self.copyWith(author: value));
  });
}
}


/// @nodoc
mixin _$CommentAuthor {

 int get id; String? get name;
/// Create a copy of CommentAuthor
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommentAuthorCopyWith<CommentAuthor> get copyWith => _$CommentAuthorCopyWithImpl<CommentAuthor>(this as CommentAuthor, _$identity);

  /// Serializes this CommentAuthor to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommentAuthor&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'CommentAuthor(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class $CommentAuthorCopyWith<$Res>  {
  factory $CommentAuthorCopyWith(CommentAuthor value, $Res Function(CommentAuthor) _then) = _$CommentAuthorCopyWithImpl;
@useResult
$Res call({
 int id, String? name
});




}
/// @nodoc
class _$CommentAuthorCopyWithImpl<$Res>
    implements $CommentAuthorCopyWith<$Res> {
  _$CommentAuthorCopyWithImpl(this._self, this._then);

  final CommentAuthor _self;
  final $Res Function(CommentAuthor) _then;

/// Create a copy of CommentAuthor
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CommentAuthor].
extension CommentAuthorPatterns on CommentAuthor {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CommentAuthor value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CommentAuthor() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CommentAuthor value)  $default,){
final _that = this;
switch (_that) {
case _CommentAuthor():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CommentAuthor value)?  $default,){
final _that = this;
switch (_that) {
case _CommentAuthor() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String? name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CommentAuthor() when $default != null:
return $default(_that.id,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String? name)  $default,) {final _that = this;
switch (_that) {
case _CommentAuthor():
return $default(_that.id,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String? name)?  $default,) {final _that = this;
switch (_that) {
case _CommentAuthor() when $default != null:
return $default(_that.id,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CommentAuthor extends CommentAuthor {
  const _CommentAuthor({required this.id, this.name}): super._();
  factory _CommentAuthor.fromJson(Map<String, dynamic> json) => _$CommentAuthorFromJson(json);

@override final  int id;
@override final  String? name;

/// Create a copy of CommentAuthor
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CommentAuthorCopyWith<_CommentAuthor> get copyWith => __$CommentAuthorCopyWithImpl<_CommentAuthor>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CommentAuthorToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CommentAuthor&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'CommentAuthor(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class _$CommentAuthorCopyWith<$Res> implements $CommentAuthorCopyWith<$Res> {
  factory _$CommentAuthorCopyWith(_CommentAuthor value, $Res Function(_CommentAuthor) _then) = __$CommentAuthorCopyWithImpl;
@override @useResult
$Res call({
 int id, String? name
});




}
/// @nodoc
class __$CommentAuthorCopyWithImpl<$Res>
    implements _$CommentAuthorCopyWith<$Res> {
  __$CommentAuthorCopyWithImpl(this._self, this._then);

  final _CommentAuthor _self;
  final $Res Function(_CommentAuthor) _then;

/// Create a copy of CommentAuthor
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = freezed,}) {
  return _then(_CommentAuthor(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
