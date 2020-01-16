import 'package:meta/meta.dart';

import 'room.dart';

abstract class ChatkitGlobalEvent {
  static ChatkitGlobalEvent fromData(dynamic data) {
    switch (data['event']) {
      case 'CurrentUserReceived':
        return CurrentUserReceivedGlobalEvent(
          id: data['id'],
          name: data['name'],
          rooms: data['rooms'].map<ChatkitRoom>(ChatkitRoom.fromData).toList(),
        );
      default:
        return UnknownGlobalEvent();
    }
  }
}

class CurrentUserReceivedGlobalEvent extends ChatkitGlobalEvent {
  final String id;
  final String name;
  final List<ChatkitRoom> rooms;
  CurrentUserReceivedGlobalEvent({
    @required this.id,
    @required this.name,
    @required this.rooms,
  });
}

class UnknownGlobalEvent extends ChatkitGlobalEvent {}
