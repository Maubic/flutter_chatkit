import 'package:meta/meta.dart';

class ChatkitRoom {
  final String id;
  final String name;
  final int unreadCount;
  final DateTime lastMessageAt;
  final Map customData;
  ChatkitRoom({
    @required this.id,
    this.name,
    this.unreadCount,
    this.lastMessageAt,
    this.customData,
  });

  static ChatkitRoom fromData(dynamic data) {
    try {
      return ChatkitRoom(
        id: data['id'],
        name: data['name'],
        unreadCount: data['unreadCount'],
        lastMessageAt: data['lastMessageAt'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(data['lastMessageAt']),
        customData: data['customData'],
      );
    } catch (err) {
      print('Error parsing ChatkitRoom: $err');
    }
  }

  ChatkitRoom copyWith({
    String id,
    String name,
    int unreadCount,
    DateTime lastMessageAt,
    Map customData,
  }) =>
      ChatkitRoom(
        id: id ?? this.id,
        name: name ?? this.name,
        unreadCount: unreadCount ?? this.unreadCount,
        lastMessageAt: lastMessageAt ?? this.lastMessageAt,
        customData: customData ?? this.customData,
      );
}
