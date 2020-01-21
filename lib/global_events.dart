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
      case 'RoomUpdated':
        return RoomUpdatedGlobalEvent(room: ChatkitRoom.fromData(data['room']));
      case 'AddedToRoom':
        return AddedToRoomGlobalEvent(room: ChatkitRoom.fromData(data['room']));
      case 'RemovedFromRoom':
        return RemovedFromRoomGlobalEvent(roomId: data['roomId']);
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

class RoomUpdatedGlobalEvent extends ChatkitGlobalEvent {
  final ChatkitRoom room;
  RoomUpdatedGlobalEvent({@required this.room});
}

class AddedToRoomGlobalEvent extends ChatkitGlobalEvent {
  final ChatkitRoom room;
  AddedToRoomGlobalEvent({@required this.room});
}

class RemovedFromRoomGlobalEvent extends ChatkitGlobalEvent {
  final String roomId;
  RemovedFromRoomGlobalEvent({@required this.roomId});
}

class UnknownGlobalEvent extends ChatkitGlobalEvent {}
