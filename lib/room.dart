import 'package:meta/meta.dart';

class ChatkitRoom {
  final String id;
  final String name;
  final int unreadCount;
  final Map customData;
  ChatkitRoom({
    @required this.id,
    this.name,
    this.unreadCount,
    this.customData,
  });

  static ChatkitRoom fromData(dynamic data) {
    return ChatkitRoom(
      id: data['id'],
      name: data['name'],
      unreadCount: data['unreadCount'],
      customData: data['customData'],
    );
  }
}
