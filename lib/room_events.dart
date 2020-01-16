import 'package:meta/meta.dart';

import 'message.dart';

abstract class ChatkitRoomEvent {
  final String roomId;
  ChatkitRoomEvent({@required this.roomId});
  static ChatkitRoomEvent fromData(dynamic data) {
    switch (data['event']) {
      case 'MultipartMessage':
        return MultipartMessageRoomEvent(
          id: data['id'],
          senderId: data['senderId'],
          senderName: data['senderName'],
          parts: data['parts']
              .map<ChatkitMessagePart>(ChatkitMessagePart.fromData)
              .toList(),
        );
      default:
        return UnknownRoomEvent();
    }
  }
}

class MultipartMessageRoomEvent extends ChatkitRoomEvent {
  final int id;
  final String senderId;
  final String senderName;
  final List<ChatkitMessagePart> parts;
  MultipartMessageRoomEvent({
    @required this.id,
    @required this.senderId,
    this.senderName,
    @required this.parts,
  });
}

class UnknownRoomEvent extends ChatkitRoomEvent {}
