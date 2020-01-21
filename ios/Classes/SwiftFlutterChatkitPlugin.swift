import Flutter
import UIKit

import PusherChatkit


public class SwiftFlutterChatkitPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {

  // Chatkit properties
  public var chatManager: ChatManager?
  public var currentUser: PCCurrentUser?
  public var rooms: Array<NSDictionary>?
  private var eventSink:FlutterEventSink?
  var messages = [PCMultipartMessage]()

  override init() {
    super.init()
  }
    
    /*
    var timer:Timer?
    
    func startTimer() {
        guard timer == nil else {return}
        timer = Timer.scheduledTimer(timeInterval: 5, target:self, selector: #selector(test), userInfo:nil, repeats:true)
    }
    
    func stopTimer() {
        guard timer != nil else {return}
        timer?.invalidate()
        timer = nil
    }
 
    
    @objc func test() {
        print("[Maubic - PusherChatkitPlugin] Timer Called \(Thread.current)")
        guard self.currentUser != nil else {return}
        let myResult: NSDictionary = [
            "type" : "global",
            "event" : "CurrentUserReceived",
            "id" : "1234567890",
            "name" : "1234567890qwertyuiopasdfghjklzxcvbnm",
//            "id" : self.currentUser?.id ?? "",
//            "name" : self.currentUser?.name ?? "Unknown user",
            "rooms" : self.rooms
        ]
        
        print("[Maubic - PusherChatkitPlugin] Sending Event. CurrentUserReceived Current thread \(Thread.current)")
        //self.eventSink!(myResult)
        DispatchQueue.main.async {
            self.sendDataToFlutter(data: myResult)
        }
    }
 */
  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    self.eventSink = events
    return nil
  }
    
  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
//        NotificationCenter.default.removeObserver(self)
        eventSink = nil
        return nil
  }
    
  public static func register(with registrar: FlutterPluginRegistrar) {
    
    let channel = FlutterMethodChannel(name: "flutter_chatkit", binaryMessenger: registrar.messenger())
    let eventChannel = FlutterEventChannel(name: "flutter_chatkit_events", binaryMessenger: registrar.messenger())
    
    //let snaChannel = FlutterEventChannel(name: "sna_channel", binaryMessenger: registrar.messenger())
    
    let instance = SwiftFlutterChatkitPlugin()
    eventChannel.setStreamHandler(instance)
    //snaChannel.setStreamHandler(instance)
    
    registrar.addMethodCallDelegate(instance, channel: channel)

    
    }
    
    private func sendDataToFlutter(data: NSDictionary) {
        if (eventSink == nil) {
            print("[Maubic] EventSink no existe")
            return
        }
        eventSink!(data)
    }
    
    private func sendDataToFlutter(data: String) {
        if (eventSink == nil) {
            print("[Maubic] EventSink no existe")
            return
        }
        eventSink!(data)
    }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    print("[Maubic - PusherChatkitPlugin] calling: " + call.method)
    switch(call.method) {
    case "getPlatformVersion":
        result("iOS " + UIDevice.current.systemVersion)
        
    case "connect":
        print("[Maubic - PusherChatkitPlugin] Connect: " + call.method)
        guard let args = call.arguments else {
            return
        }
        
        if let myArgs = args as? [String: Any] {
            let instanceLocator = myArgs["instanceLocator"] as? String
            let accessToken = myArgs["accessToken"] as? String?
            let tokenProviderURL = myArgs["tokenProviderURL"] as? String
            let userId = myArgs["userId"] as? String
            
            print("[Maubic - PusherChatkitPlugin] Params received on iOS = instanceLocator: \(instanceLocator ?? "LOCATOR"), accessToken: \(accessToken), tokenProviderURL: \(tokenProviderURL), userId: \(String(describing: userId))")
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
                
                // Subscribe to the first room for the current user
                // RoomDelegate with event listeners is implemented below as an extension to this class
                // https://pusher.com/docs/chatkit/reference/swift#subscribing-to-a-room
                let rooms = currentUser?.rooms
                
                print("[Maubic - PusherChatkitPlugin] Connected! \(String(describing: currentUser?.name))'s rooms: \(String(describing: rooms))")
                
                var myRooms : Array<NSDictionary> = []
                for room in currentUser!.rooms {
                    let dicRoom : NSDictionary = [
                        "id" : room.id,
                        "name" : room.name,
                        "unreadCount" : room.unreadCount!,
                        //"customData" : NSMutableDictionary(dictionary: firstRoom.customData ?? [:]) as NSDictionary,
                        //"lastMessageAt" : room.lastMessageAt!
                    ]
                    myRooms.append(dicRoom)
                }
                
                self.rooms = myRooms
                
                print("[Maubic - PusherChatkitPlugin] MyRooms \(myRooms)")
                
                let myResult: NSDictionary = [
                    "type" : "global",
                    "event" : "CurrentUserReceived",
                    "id" : currentUser?.id ?? "",
                    "name" : currentUser?.name ?? "Unknown user",
                    "rooms" : myRooms,
                ]

                print("[Maubic - PusherChatkitPlugin] Sending Event. CurrentUserReceived Current thread \(Thread.current)")
                
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
        guard let args = call.arguments else {
            return
        }
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
            
            // SNA TODO: Unsubscribe de la sala correcta.
            let room = currentUser!.rooms.first!
            room.unsubscribe()
            // SNA TODO: Guardar lista de salas suscritas.
            result(room.id)
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
        
        /*
        let msg: NSDictionary = [
            "type": "inline",
            "content": "Hello world onMultipartMessage: "]
        
        let myMessage: NSDictionary = [
            "type" : "room",
            "event" : "MultipartMessage",
            "id" : 123,
            "createdAt" : 123, //message.createdAt.getTime()
            "room" : 123, //serializedRoom
            "roomId": 456,
            "senderId": 678,
            "senderName": 901,
            "parts": [ msg ]
        ]
        
        //myself!.eventSink!(myMessage)
        DispatchQueue.main.async {
            self.sendDataToFlutter(data: myMessage)
        }
        */
        
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
            //self.sendDataToFlutter(data: "Mensaje!")
        }

        /*
        let msg: NSDictionary = [
            "type": "inline",
            "content": "hello world"]
        
        let myMessage: NSDictionary = [
            "type" : "global",
            "event" : "MultipartMessage",
            "id" : 123,
            "roomId": 456,
            "senderId": 678,
            "senderName": 901,
            "parts": [ msg ]
        ]

        print("[Maubic - PusherChatkitPlugin] Sending Event. MessageReceived. Outside. Current thread \(Thread.current)")
        
        self.eventSink!(myMessage)
        //DispatchQueue.global().async {
        //    print("[Maubic - PusherChatkitPlugin] Sending Event. MessageReceived. DispatchQueue. Current thread \(Thread.current)")
        //    self.eventSink!(myMessage)
//            self.tableView.reloadData()
        //}
 */

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
