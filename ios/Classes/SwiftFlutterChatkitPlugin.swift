import Flutter
import UIKit

import PusherChatkit


public class SwiftFlutterChatkitPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {

  // Chatkit properties
  public var chatManager: ChatManager?
  public var currentUser: PCCurrentUser?
  private var eventSink:FlutterEventSink?
  var messages = [PCMultipartMessage]()


  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    self.eventSink = events
    return nil
  }
    
  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    
    let channel = FlutterMethodChannel(name: "flutter_chatkit", binaryMessenger: registrar.messenger())
    let eventChannel = FlutterEventChannel(name: "flutter_chatkit_events", binaryMessenger: registrar.messenger())
    
    let instance = SwiftFlutterChatkitPlugin()
    
    eventChannel.setStreamHandler(instance)
    registrar.addMethodCallDelegate(instance, channel: channel)

    
    }
    
    private func sendDataToFlutter(data: NSDictionary) {
        if (eventSink == nil) {
            print("[Maubic - PusherChatkitPlugin] EventSink does not exists")
            return
        }
        eventSink!(data)
    }
    
    private func sendDataToFlutter(data: String) {
        if (eventSink == nil) {
            print("[Maubic - PusherChatkitPlugin] EventSink does not exists")
            return
        }
        eventSink!(data)
    }
    
    private func toNSDictionary(room: PCRoom) -> NSDictionary {
        let dateFormatter = DateFormatter()
        let lastMessageAt = dateFormatter.date(from: room.lastMessageAt ?? "")?.timeIntervalSince1970 ?? 0.0
        
        let dicRoom : NSDictionary = [
            "id" : room.id,
            "name" : room.name,
            "unreadCount" : room.unreadCount!,
            // SNA TODO: Implementar customData
            // "customData" : NSDictionary(dictionary: room.customData),
            // SNA TODO: Verificar que es en miliseconds
            "lastMessageAt" : Int(lastMessageAt*1000),
        ]
        return dicRoom
    }


  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    print("[Maubic - PusherChatkitPlugin] calling: " + call.method)
    switch(call.method) {
    case "getPlatformVersion":
        result("iOS " + UIDevice.current.systemVersion)
        
    case "connect":
        print("[Maubic - PusherChatkitPlugin] Connect: " + call.method)
        
        guard let args = call.arguments else { return }
        
        if let myArgs = args as? [String: Any] {
            let instanceLocator = myArgs["instanceLocator"] as? String
            let accessToken = myArgs["accessToken"] as? String?
            let tokenProviderURL = myArgs["tokenProviderURL"] as? String
            let userId = myArgs["userId"] as? String
            
            self.chatManager = ChatManager(
                instanceLocator: instanceLocator!, //Your Chatkit Instance ID
                tokenProvider: PCTokenProvider(url: tokenProviderURL!),
                userID: userId!
            )
            
            // Connect to Chatkit by passing in the ChatManagerDelegate you defined at the top of this class.
            // https://pusher.com/docs/chatkit/reference/swift#connecting
            self.chatManager!.connect(delegate: SwiftFlutterChatkitPluginChatManagerDelegate(eventSink:eventSink!)) { (currentUser, error) in
                guard(error == nil) else {
                    print("[Maubic - PusherChatkitPlugin] Error connecting: \(error!.localizedDescription)")
                    return
                }
                
                // PCCurrentUser is the main entity you interact with in the Chatkit Swfit SDK
                // You get it in a callback when successfully connected to Chatkit
                // https://pusher.com/docs/chatkit/reference/swift#pccurrentuser
                self.currentUser = currentUser
                
                let rooms = currentUser?.rooms
                
                print("[Maubic - PusherChatkitPlugin] Connected! \(String(describing: currentUser?.name))'s rooms: \(String(describing: rooms))")
                
                var myRooms : Array<NSDictionary> = []
                for room in currentUser!.rooms {
                    myRooms.append(self.toNSDictionary(room: room))
                }
                
                print("[Maubic - PusherChatkitPlugin] MyRooms \(myRooms)")
                
                let myResult: NSDictionary = [
                    "type" : "global",
                    "event" : "CurrentUserReceived",
                    "id" : currentUser?.id ?? "",
                    "name" : currentUser?.name ?? "Unknown user",
                    "rooms" : myRooms,
                ]
                
                DispatchQueue.main.async {
                    self.sendDataToFlutter(data: myResult)
                }

                result(currentUser?.id)
            }

        } else {
            print("[Maubic - PusherChatkitPlugin]: iOS could not extract flutter arguments in method: (connect) \(args)")
            result(FlutterError(
                code: "ERR_RESULT",
                message: "iOS could not extract flutter arguments in method: (connect) \(args)",
                details: nil)
            )
        }
    case "subscribeToRoom":
        print("[Maubic - PusherChatkitPlugin] subscribeToRoom: Start. ")
        guard let args = call.arguments else { return }
        if let myArgs = args as? [String: Any] {
            guard let roomId = myArgs["roomId"] as? String else { return }
            
            print("[Maubic - PusherChatkitPlugin] subscribeToRoom: " + roomId)
            
            currentUser!.subscribeToRoomMultipart(id: roomId, roomDelegate: self, completionHandler: { (error) in
                guard error == nil else {
                    print("[Maubic - PusherChatkitPlugin] Error subscribing to room: \(error!.localizedDescription)")
                    return
                }
                print("[Maubic - PusherChatkitPlugin] Successfully subscribed to the room \(roomId)! 👋")
            })
            // SNA TODO: Guardar lista de salas suscritas.
            result(roomId)
        }
    case "unsubscribeFromRoom":
        print("[Maubic - PusherChatkitPlugin] unsubscribeFromRoom: " + call.method)
        guard let args = call.arguments else {
            return
        }
        if let myArgs = args as? [String: Any] {
            guard let roomId = myArgs["roomId"] as? String else { return }
            print("[Maubic - PusherChatkitPlugin] unsubscribeFromRoom: Room " + roomId)

            // SNA TODO: Unsubscribe de la sala correcta.
            //let room = currentUser!.rooms.first!
            //room.unsubscribe()
            // SNA TODO: Guardar lista de salas suscritas.
            //result(room.id)
            result(true)
        }
    case "sendSimpleMessage":
        // SNA TODO: Enviar mensaje
        result("TODO")
    case "setReadCursor":
        guard let args = call.arguments else {
            return
        }
        if let myArgs = args as? [String: Any] {
            guard let roomId = myArgs["roomId"] as? String else { return }
            guard let messageId = myArgs["messageId"] as? String else { return }
            //currentUser?.setReadCursor(roomId: roomId, position: messageId, completionHandler: { (error) in
            //    guard error == nil else {
            //        print("[Maubic - PusherChatkitPlugin] Error setting cursor: \(error!.localizedDescription)")
            //        return
            //    }
                print("[Maubic - PusherChatkitPlugin] Read cursor successfully updated \(roomId)! 👋")
            result(roomId)
        } else {
            //esult.notImplemented();
        }
    default:
        print("[Maubic - PusherChatkitPlugin]Not implemented")
        result("Not implemented")
    }
  }
}

// Extension to handle incoming message - PCRoomDelegate
// https://pusher.com/docs/chatkit/reference/swift#receiving-new-messages
extension SwiftFlutterChatkitPlugin: PCRoomDelegate {
    public func onMultipartMessage(_ message: PCMultipartMessage) {

        print("[Maubic - PusherChatkitPlugin] Message received! \(Thread.current)")
        
        var parts : Array<NSDictionary> = []
        for part in message.parts {
            switch part.payload {
            case .inline(let payload):
                let msg: NSDictionary = [
                    "type" : "inline" as String,
                    "content" : payload.content,
                ]
                parts.append(msg)
                print("[Maubic - PusherChatkitPlugin] Message received! " + payload.content)
            default:
                print("[Maubic - PusherChatkitPlugin] Message doesn't have the right payload!")
                let msg: NSDictionary = [
                    "type" : "other" as String,
                ]
                parts.append(msg)
            }
        }

        let myMessage: NSDictionary = [
            "type" : "room",
            "event" : "MultipartMessage",
            "id" : message.id,
            "roomId": message.room.id,
            "senderId": message.sender.id,
            "senderName": message.sender.name!,
            "parts": parts,
        ]
        
        DispatchQueue.global().async {
            self.sendDataToFlutter(data: myMessage)
        }
    }
}

public class SwiftFlutterChatkitPluginChatManagerDelegate: PCChatManagerDelegate {
    
    private var eventSink: FlutterEventSink?

    init(eventSink: @escaping FlutterEventSink) {
        self.eventSink = eventSink
    }
    
    public func onAddedToRoom(_ room: PCRoom) {
        print("[Maubic - PusherChatkitPlugin] Added to room: \(room.name)")
    }
    
    public func onRemovedFromRoom(_ room: PCRoom) {
        print("[Maubic - PusherChatkitPlugin] Removed from room: \(room.name)")
    }
    
    public func onRoomUpdated(room: PCRoom) {
        print("[Maubic - PusherChatkitPlugin] Room updated: \(room)")

    }
    
    public func onRoomDeleted(room: PCRoom) {
        print("[Maubic - PusherChatkitPlugin] Room deleted: \(room.name)")
    }
    
    public func onUserJoinedRoom(_ room: PCRoom, user: PCUser) {
        print("[Maubic - PusherChatkitPlugin] User \(user.displayName) joined room: \(room.name)")
    }
    
    public func onUserLeftRoom(_ room: PCRoom, user: PCUser) {
        print("[Maubic - PusherChatkitPlugin] User \(user.displayName) left room: \(room.name)")
    }
    
    public func onPresenceChanged(stateChange: PCPresenceStateChange, user: PCUser) {
        print("[Maubic - PusherChatkitPlugin] \(user.displayName)'s presence state went from \(stateChange.previous.rawValue) to \(stateChange.current.rawValue)")
    }
    
    public func onUserStartedTyping(inRoom room: PCRoom, user: PCUser) {
        print("[Maubic - PusherChatkitPlugin] \(user.displayName) started typing in room \(room.name)")
    }
    
    public func onUserStoppedTyping(inRoom room: PCRoom, user: PCUser) {
        print("[Maubic - PusherChatkitPlugin] \(user.displayName) stopped typing in room \(room.name)")
    }
    
    public func onError(error: Error) {
        print("[Maubic - PusherChatkitPlugin] Error: \(error.localizedDescription)")
    }
}
