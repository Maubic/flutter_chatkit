import 'package:meta/meta.dart';

class ChatkitMessage {
  final int id;
  final String roomId;
  final String senderId;
  final String senderName;
  final List<ChatkitMessagePart> parts;
  ChatkitMessage({
    @required this.id,
    @required this.roomId,
    @required this.senderId,
    this.senderName,
    this.parts = const [],
  });
  static ChatkitMessage fromData(dynamic data) {
    return ChatkitMessage(
      id: data['id'],
      roomId: data['roomId'],
      senderId: data['senderId'],
      senderName: data['senderName'],
      parts: data['parts']
          .map<ChatkitMessagePart>(ChatkitMessagePart.fromData)
          .toList(),
    );
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
