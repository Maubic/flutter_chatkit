import 'dart:async';

import 'package:meta/meta.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';

import 'global_events.dart';
export 'global_events.dart';
import 'room_events.dart';
export 'room_events.dart';
import 'room.dart';
export 'room.dart';
import 'message.dart';
export 'message.dart';

class FlutterChatkit {
  static const MethodChannel _methodChannel =
      const MethodChannel('flutter_chatkit');
  static const EventChannel _eventChannel =
      const EventChannel('flutter_chatkit_events');

  static FlutterChatkit _instance;
  static get instance {
    if (_instance == null) _instance = FlutterChatkit();
    return _instance;
  }

  final StreamController<Map> controller = BehaviorSubject<Map>();
  FlutterChatkit() {
    _eventChannel.receiveBroadcastStream().cast<Map>().pipe(this.controller);
  }

  Stream<Map> get stream => this.controller.stream;

  static Future<String> get platformVersion async {
    final String version =
        await _methodChannel.invokeMethod('getPlatformVersion');
    return version;
  }

  Future<void> connect({
    @required String instanceLocator,
    @required String userId,
    String accessToken,
    @required String tokenProviderURL,
  }) async {
    try {
      final String res = await _methodChannel.invokeMethod('connect', {
        'instanceLocator': instanceLocator,
        'userId': userId,
        'accessToken': accessToken,
        'tokenProviderURL': tokenProviderURL,
      });
    } catch (err) {
      print('Error: ${err}');
    }
  }

  Stream<ChatkitGlobalEvent> globalEvents() {
    return this
        .stream
        .where((data) => data['type'] == 'global')
        .map(ChatkitGlobalEvent.fromData);
  }

  Stream<ChatkitRoomEvent> roomEvents(String roomId) {
    final StreamController<ChatkitRoomEvent> roomEventsController =
        BehaviorSubject<ChatkitRoomEvent>(
      onListen: () {
        _methodChannel.invokeMethod('subscribeToRoom', {'roomId': roomId});
      },
      onCancel: () {
        _methodChannel.invokeMethod('unsubscribeFromRoom', {'roomId': roomId});
      },
    );
    this
        .stream
        .where((data) => data['type'] == 'room' && data['roomId'] == roomId)
        .map(ChatkitRoomEvent.fromData)
        .cast<ChatkitRoomEvent>()
        .pipe(roomEventsController);
    return roomEventsController.stream;
  }
}
