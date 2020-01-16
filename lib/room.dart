import 'package:meta/meta.dart';

class ChatkitRoom {
  final String id;
  final String name;
  final int unreadCount;
  ChatkitRoom({
    @required this.id,
    this.name,
    this.unreadCount,
  });

  static ChatkitRoom fromData(dynamic data) {
    return ChatkitRoom(
      id: data['id'],
      name: data['name'],
      unreadCount: data['unreadCount'],
    );
  }
}
