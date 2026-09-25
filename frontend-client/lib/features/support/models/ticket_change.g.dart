// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket_change.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TicketChange _$TicketChangeFromJson(Map<String, dynamic> json) =>
    _TicketChange(
      ticket: SupportTicket.fromJson(json['ticket'] as Map<String, dynamic>),
      message: json['message'] == null
          ? null
          : TicketMessage.fromJson(json['message'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TicketChangeToJson(_TicketChange instance) =>
    <String, dynamic>{
      'ticket': instance.ticket.toJson(),
      'message': instance.message?.toJson(),
    };
