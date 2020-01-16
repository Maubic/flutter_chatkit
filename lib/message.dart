import 'package:meta/meta.dart';

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
