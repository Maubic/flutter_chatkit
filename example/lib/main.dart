import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_chatkit/flutter_chatkit.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _userId = 'Unknown';
  String _roomId = 'Unknown';
  String _message = '';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    /*
    try {
      platformVersion = await FlutterChatkit.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
    */

    await Future.delayed(Duration(seconds: 4));
    final FlutterChatkit chatkit = FlutterChatkit.instance;

    await chatkit.connect(
      instanceLocator: 'v1:us1:b7eea6ee-98d7-4527-bed0-e13d7515bafe',
      userId: 'ce2f362d-1f08-4201-9d72-3d736c90660f',
      tokenProviderURL:
          'https://us1.pusherplatform.io/services/chatkit_token_provider/v1/b7eea6ee-98d7-4527-bed0-e13d7515bafe/token',
    );

    Stream<Map> globalEvents = chatkit.globalEvents();
    final Map data = await globalEvents
        .where((data) => data['event'] == 'CurrentUserReceived')
        .first;
    final String roomId = data['rooms'][0]['id'];

    setState(() {
      _userId = data['id'];
      _roomId = roomId;
    });

    chatkit.roomEvents(roomId).forEach((data) {
      if (data['event'] == 'MultipartMessage') {
        setState(() {
          final Map part = data['parts'][0];
          if (part['type'] == 'inline') {
            _message = '${part['content']}';
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('User ID: $_userId'),
              Text('Room ID: $_roomId'),
              Text('$_message'),
            ],
          ),
        ),
      ),
    );
  }
}
