#import "FlutterChatkitPlugin.h"
#import <flutter_chatkit/flutter_chatkit-Swift.h>

@implementation FlutterChatkitPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterChatkitPlugin registerWithRegistrar:registrar];
}
@end
