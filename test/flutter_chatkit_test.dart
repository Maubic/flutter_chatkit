import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_chatkit/flutter_chatkit.dart';

void main() {
  const MethodChannel channel = MethodChannel('flutter_chatkit');

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await FlutterChatkit.platformVersion, '42');
  });
}
