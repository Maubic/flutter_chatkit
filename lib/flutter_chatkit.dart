import 'dart:async';

import 'package:meta/meta.dart';
import 'package:flutter/services.dart';

class FlutterChatkit {
  static const MethodChannel _channel = const MethodChannel('flutter_chatkit');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<String> connect({
    @required String instanceLocator,
    @required String userId,
    String accessToken,
    @required String tokenProviderURL,
  }) async {
    try {
      final String res = await _channel.invokeMethod('connect', {
        'instanceLocator': instanceLocator,
        'userId': userId,
        'accessToken': accessToken,
        'tokenProviderURL': tokenProviderURL,
      });
      return res;
    } catch (err) {
      print('Error: ${err}');
    }
  }
}
