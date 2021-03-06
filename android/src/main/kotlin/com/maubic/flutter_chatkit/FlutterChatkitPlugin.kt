package com.maubic.flutter_chatkit

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.StreamHandler
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.PluginRegistry.Registrar
import android.os.Handler
import android.os.Looper
import com.pusher.chatkit.ChatManager
import com.pusher.chatkit.ChatEvent
import com.pusher.chatkit.AndroidChatkitDependencies
import com.pusher.chatkit.ChatkitTokenProvider
import com.pusher.chatkit.CurrentUser
import com.pusher.chatkit.SynchronousCurrentUser
import com.pusher.chatkit.rooms.Room
import com.pusher.chatkit.rooms.RoomEvent
import com.pusher.chatkit.messages.multipart.Message
import com.pusher.chatkit.messages.multipart.Payload
import com.pusher.chatkit.messages.multipart.NewPart
import com.pusher.util.Result as PusherResult
import com.pusher.util.collect
import elements.Subscription
import elements.Error
import java.text.SimpleDateFormat
import java.io.File

class FlutterChatkitPlugin (private val looper: Looper?) : MethodCallHandler, StreamHandler {
  private var currentUser: CurrentUser? = null;
  private var eventSink: EventSink? = null;
  private var roomSubscriptions: MutableMap<String, Subscription> = mutableMapOf()

  companion object {
    @JvmStatic
    fun registerWith(registrar: Registrar) {
      val plugin: FlutterChatkitPlugin = FlutterChatkitPlugin(Looper.myLooper())
      val messenger: BinaryMessenger = registrar.messenger()

      val methodChannel: MethodChannel = MethodChannel(messenger, "flutter_chatkit")
      methodChannel.setMethodCallHandler(plugin)

      val eventChannel: EventChannel = EventChannel(messenger, "flutter_chatkit_events")
      eventChannel.setStreamHandler(plugin)
    }
  }

  private fun successResult(result: Result, obj: Any) {
    val handler: Handler = Handler(looper) { msg ->
      result.success(obj)
      true
    }
    handler.obtainMessage().sendToTarget()
  }

  private fun failureResult(result: Result, err: String?) {
    val handler: Handler = Handler(looper) { msg ->
      result.error("ERR_RESULT", err, null)
      true
    }
    handler.obtainMessage().sendToTarget()
  }

  private fun successEvent(obj: Any) {
    val handler: Handler = Handler(looper) { msg ->
      eventSink?.success(obj)
      true
    }
    handler.obtainMessage().sendToTarget()
  }

  private fun failureEvent(err: String?) {
    val handler: Handler = Handler(looper) { msg ->
      eventSink?.error("ERR_RESULT", err, null)
      true
    }
    handler.obtainMessage().sendToTarget()
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    if (call.method == "getPlatformVersion") {
      result.success("Android ${android.os.Build.VERSION.RELEASE}")
    } else if (call.method == "connect") {
      val instanceLocator: String = call.argument<String>("instanceLocator")!!
      val userId: String = call.argument<String>("userId")!!
      val accessToken: String? = call.argument<String?>("accessToken")
      val tokenProviderURL: String = call.argument<String>("tokenProviderURL")!!
      val chatManager: ChatManager = ChatManager(
        instanceLocator = instanceLocator,
        userId = userId,
        dependencies = AndroidChatkitDependencies(
          tokenProvider = FlutterChatkitTokenProvider(
            endpoint = tokenProviderURL,
            userId = userId,
            authHeader = accessToken ?: ""
          )
        )
      )
      chatManager.connect(
        consumer = { event ->
          when (event) {
            is ChatEvent.CurrentUserReceived -> {
              val currentUser: SynchronousCurrentUser = event.currentUser
              successEvent(hashMapOf(
                "type" to "global",
                "event" to "CurrentUserReceived",
                "id" to currentUser.id,
                "name" to currentUser.name,
                "rooms" to currentUser.rooms.map(::serializeRoom)
              ))
            }
            is ChatEvent.RoomUpdated -> {
              val room: Room = event.room
              successEvent(hashMapOf(
                "type" to "global",
                "event" to "RoomUpdated",
                "room" to serializeRoom(room)
              ))
            }
            is ChatEvent.AddedToRoom -> {
              val room: Room = event.room
              successEvent(hashMapOf(
                "type" to "global",
                "event" to "AddedToRoom",
                "room" to serializeRoom(room)
              ))
            }
            is ChatEvent.RemovedFromRoom -> {
              val roomId: String = event.roomId
              successEvent(hashMapOf(
                "type" to "global",
                "event" to "RemovedFromRoom",
                "roomId" to roomId
              ))
            }
          }
        },
        callback = { res ->
          when (res) {
            is PusherResult.Success -> {
              currentUser = res.value
              successResult(result, res.value.id)
            }
            is PusherResult.Failure -> {
              failureResult(result, res.error.message)
            }
          }
        }
      )
    } else if (call.method == "subscribeToRoom") {
      val roomId: String = call.argument<String>("roomId")!!
      currentUser?.subscribeToRoomMultipart(
        roomId = roomId,
        consumer = { event ->
          when (event) {
            is RoomEvent.MultipartMessage -> {
              val message: Message = event.message
              
              val partsResults: List<PusherResult<HashMap<String, Any>, Error>> = message.parts.map { part ->
                val payload: Payload = part.payload
                val res: PusherResult<HashMap<String, Any>, Error> = when (payload) {
                  is Payload.Inline -> PusherResult.success<HashMap<String, Any>, Error>(hashMapOf(
                    "type" to "inline",
                    "content" to payload.content
                  ))
                  is Payload.Attachment -> payload.url().map { url -> hashMapOf(
                    "type" to "attachment",
                    "size" to payload.size,
                    "url" to url
                  )}
                  // TODO
                  else -> PusherResult.success<HashMap<String, Any>, Error>(hashMapOf(
                    "type" to "other"
                  ))
                }
                res
              }

              partsResults.collect<HashMap<String, Any>, Error>().map { parts ->
                successEvent(hashMapOf(
                  "type" to "room",
                  "event" to "MultipartMessage",
                  "id" to message.id,
                  "roomId" to roomId,
                  "room" to serializeRoom(message.room),
                  "createdAt" to message.createdAt.getTime(),
                  "senderId" to message.sender.id,
                  "senderName" to message.sender.name,
                  "parts" to parts
                ))
              }
            }
          }
        },
        callback = { subscription ->
          roomSubscriptions.put(roomId, subscription)
          successResult(result, roomId)
        }
      )
    } else if (call.method == "unsubscribeFromRoom") {
      val roomId: String = call.argument<String>("roomId")!!
      roomSubscriptions.get(roomId)?.unsubscribe()
    } else if (call.method == "sendSimpleMessage") {
      val roomId: String = call.argument<String>("roomId")!!
      val messageText: String = call.argument<String>("messageText")!!
      
      currentUser?.sendSimpleMessage(
        roomId = roomId,
        messageText = messageText,
        callback = { res ->
          when (res) {
            is PusherResult.Success -> {
              successResult(result, roomId)
            }
            is PusherResult.Failure -> {
              failureResult(result, res.error.message)
            }
          }
        }
      )
    } else if (call.method == "sendAttachmentMessage") {
      val roomId: String = call.argument<String>("roomId")!!
      val filename: String = call.argument<String>("filename")!!
      val type: String = call.argument<String>("type")!!
      
      val parts : List<NewPart> = listOf(NewPart.Attachment(
        type = type,
        file = File(filename).inputStream()
      ))

      currentUser?.sendMultipartMessage(
        roomId = roomId,
        parts = parts,
        callback = { res ->
          when (res) {
            is PusherResult.Success -> {
              successResult(result, roomId)
            }
            is PusherResult.Failure -> {
              failureResult(result, res.error.message)
            }
          }
        }
      )
    } else if (call.method == "setReadCursor") {
      val roomId: String = call.argument<String>("roomId")!!
      val messageId: Int = call.argument<Int>("messageId")!!
      currentUser?.setReadCursor(
        roomId = roomId,
        position = messageId
      )
      successResult(result, roomId)
    } else {
      result.notImplemented()
    }
  }

  override fun onListen(arguments: Any?, events: EventSink) {
    eventSink = events
  }

  override fun onCancel(arguments: Any?) {
    eventSink = null
  }
}

fun serializeRoom(room: Room) : HashMap<String, Any?> {
  return hashMapOf(
    "id" to room.id,
    "name" to room.name,
    "unreadCount" to room.unreadCount,
    "customData" to room.customData,
    "lastMessageAt" to room.lastMessageAt?.let {
      try {
        SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ssX").parse(it).getTime()
      } catch (e: Exception) {
        println("Error parsing date: $e");
        null
      }
    }
  )
}
