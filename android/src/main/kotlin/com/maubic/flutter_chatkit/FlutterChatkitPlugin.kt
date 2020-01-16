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
import com.pusher.chatkit.rooms.RoomEvent
import com.pusher.chatkit.messages.multipart.Message
import com.pusher.chatkit.messages.multipart.Payload
import com.pusher.util.Result as PusherResult
import elements.Subscription

private const val SUCCESS_RESULT: Int = 0;
private const val FAILURE_RESULT: Int = 1;
private const val SUCCESS_EVENT: Int = 0;
private const val FAILURE_EVENT: Int = 1;

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
                "rooms" to currentUser.rooms.map { room -> hashMapOf(
                  "id" to room.id,
                  "name" to room.name,
                  "unreadCount" to room.unreadCount,
                  "customData" to room.customData
                )}
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
              successEvent(hashMapOf(
                "type" to "room",
                "event" to "MultipartMessage",
                "id" to message.id,
                "roomId" to roomId,
                "senderId" to message.sender.id,
                "senderName" to message.sender.name,
                "parts" to message.parts.map { part ->
                  val payload: Payload = part.payload
                  when (payload) {
                    is Payload.Inline -> hashMapOf(
                      "type" to "inline",
                      "content" to payload.content
                    )
                    // TODO
                    else -> hashMapOf(
                      "type" to "other"
                    )
                  }
                }
              ))
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
