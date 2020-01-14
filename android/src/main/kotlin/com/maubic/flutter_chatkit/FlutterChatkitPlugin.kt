package com.maubic.flutter_chatkit

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import android.os.Handler
import com.pusher.chatkit.ChatManager
import com.pusher.chatkit.AndroidChatkitDependencies
import com.pusher.chatkit.ChatkitTokenProvider
import com.pusher.chatkit.CurrentUser
import com.pusher.util.Result as PusherResult

class FlutterChatkitPlugin: MethodCallHandler {
  private var currentUser: CurrentUser? = null;
  private val SUCCESS: Int = 0;
  private val FAILURE: Int = 0;

  companion object {
    @JvmStatic
    fun registerWith(registrar: Registrar) {
      val channel = MethodChannel(registrar.messenger(), "flutter_chatkit")
      channel.setMethodCallHandler(FlutterChatkitPlugin())
    }
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    val handler: Handler = Handler { msg ->
      when (msg.what) {
        SUCCESS -> {
          val value = msg.obj
          result.success(value)
        }
        FAILURE -> {
          val err: String? = msg.obj as? String
          result.error("ERR", err, null)
        }
      }
      true
    }
    fun resSuccess(obj: Any) { handler.obtainMessage(SUCCESS, obj).sendToTarget() }
    fun resFailure(err: String?) { handler.obtainMessage(FAILURE, err).sendToTarget() }

    if (call.method == "getPlatformVersion") {
      result.success("Android ${android.os.Build.VERSION.RELEASE}")
    } else if (call.method == "connect") {
      val instanceLocator: String = call.argument<String>("instanceLocator")!!
      val userId: String = call.argument<String>("userId")!!
      val tokenProviderURL: String = call.argument<String>("tokenProviderURL")!!
      val chatManager: ChatManager = ChatManager(
        instanceLocator = instanceLocator,
        userId = userId,
        dependencies = AndroidChatkitDependencies(
          tokenProvider = ChatkitTokenProvider(
            endpoint = tokenProviderURL,
            userId = userId
          )
        )
      )
      chatManager.connect { res ->
        when (res) {
          is PusherResult.Success -> {
            currentUser = res.value
            resSuccess(res.value.id)
          }
          is PusherResult.Failure -> {
            resFailure(res.error.message)
          }
        }
      }
    } else {
      result.notImplemented()
    }
  }
}
