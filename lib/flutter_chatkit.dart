import 'dart:async';

import 'package:meta/meta.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';

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

  Stream<Map> globalEvents() {
    return this.controller.stream.where((data) => data['type'] == 'global');
  }
}
