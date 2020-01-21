import 'package:meta/meta.dart';
import 'room.dart';

class ChatkitMessage {
  final int id;
  final String roomId;
  final String senderId;
  final String senderName;
  final DateTime createdAt;
  final ChatkitRoom room;
  final List<ChatkitMessagePart> parts;
  ChatkitMessage({
    @required this.id,
    @required this.roomId,
    @required this.senderId,
    this.senderName,
    @required this.createdAt,
    @required this.room,
    this.parts = const [],
  });
  static ChatkitMessage fromData(dynamic data) {
    try {
      return ChatkitMessage(
        id: data['id'],
        roomId: data['roomId'],
        senderId: data['senderId'],
        createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt']),
        senderName: data['senderName'],
        room: ChatkitRoom.fromData(data['room']),
        parts: data['parts']
            .map<ChatkitMessagePart>(ChatkitMessagePart.fromData)
            .toList(),
      );
    } catch (err) {
      print('Error parsing ChatkitMessage: $err');
    }
  }
}

abstract class ChatkitMessagePart {
  static ChatkitMessagePart fromData(dynamic data) {
    switch (data['type']) {
      case 'inline':
        return InlineMessagePart(content: data['content']);
      default:
        return UnknownMessagePart();
    }
  }
}

class InlineMessagePart extends ChatkitMessagePart {
  final String content;
  InlineMessagePart({this.content});
}

class UnknownMessagePart extends ChatkitMessagePart {}
