import 'package:meta/meta.dart';

import 'message.dart';

abstract class ChatkitRoomEvent {
  final String roomId;
  ChatkitRoomEvent({@required this.roomId});
  static ChatkitRoomEvent fromData(dynamic data) {
    switch (data['event']) {
      case 'MultipartMessage':
        return MultipartMessageRoomEvent(
          roomId: data['roomId'],
          message: ChatkitMessage.fromData(data),
        );
      default:
        return UnknownRoomEvent();
    }
  }
}

class MultipartMessageRoomEvent extends ChatkitRoomEvent {
  final ChatkitMessage message;
  MultipartMessageRoomEvent({
    @required this.message,
    @required String roomId,
  }) : super(roomId: roomId);
}

class UnknownRoomEvent extends ChatkitRoomEvent {}
