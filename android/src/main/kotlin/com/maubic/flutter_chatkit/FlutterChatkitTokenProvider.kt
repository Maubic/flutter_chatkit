package com.maubic.flutter_chatkit

import com.maubic.flutter_chatkit.util.parseAs
import com.pusher.chatkit.*
import com.pusher.platform.network.Futures
import com.pusher.platform.tokenProvider.TokenProvider
import com.pusher.util.*
import elements.Error
import elements.Errors
import okhttp3.*
import java.util.*
import java.util.concurrent.Future

/**
 * Simple token provider for Chatkit. Uses an in-memory cache for storing token.
 * @param endpoint location of this token provider.
 * @param authData data to be sent alongside each request to the token providing endpoint.
 * @param client
 * @param tokenCache
 * */
data class FlutterChatkitTokenProvider
@JvmOverloads constructor(
        val endpoint: String,
        internal var userId: String,
        private val authData: Map<String, String> = emptyMap(),
        private val authHeader: String = "",
        private val client: OkHttpClient = OkHttpClient(),
        private val tokenCache: TokenCache = InMemoryTokenCache(Clock())
) : TokenProvider {

    private val httpUrl =
            HttpUrl.parse(endpoint)
                    ?.newBuilder()
                    ?.apply { addQueryParameter("user_id", userId) }
                    ?.build()
                    ?: throw IllegalArgumentException("Token Provider endpoint is not valid URL")

    override fun fetchToken(tokenParams: Any?): Future<Result<String, Error>> {
        val cachedToken = tokenCache.getTokenFromCache()
        return when (cachedToken) {
            null -> fetchTokenFromEndpoint(tokenParams)
            else -> Futures.now(cachedToken.asSuccess())
        }
    }

    override fun clearToken(token: String?) {
        tokenCache.clearCache()
    }

    private fun fetchTokenFromEndpoint(tokenParams: Any?): Future<Result<String, Error>> =
            Futures.schedule {
                val request = Request.Builder()
                        .url(httpUrl)
                        .header("Authorization", requestAuthHeader())
                        .post(requestBody(tokenParams))
                        .build()
                val response = client.newCall(request).execute()

                if (response.isSuccessful && response.code() in 200..299) {
                    parseTokenResponse(response)
                } else {
                    response.asError().asFailure()
                }
            }

    private fun requestBody(tokenParams: Any?) = FormBody.Builder().apply {
        add("grant_type", "client_credentials")
        add(authData)
        if (tokenParams is ChatkitTokenParams) add(tokenParams.extras)
    }.build()

    private fun requestAuthHeader(): String {
      return authHeader
    }

    private fun FormBody.Builder.add(map: Map<String, String>) = run {
        for ((k, v) in map) {
            add(k, v)
        }
    }

    private fun Response.asError(): Error = Errors.response(
            statusCode = code(),
            headers = headers().toMultimap(),
            error = body()?.string() ?: ""
    )

    private fun parseTokenResponse(response: Response): Result<String, Error> {
        return response.body()
                ?.string()
                ?.parseAs<TokenResponse>()
                .orElse { Errors.network("Could not parse token from response: $response") }
                .flatten()
                .map { token ->
                    tokenCache.cache(token.accessToken, token.expiresIn.toLong())
                    token.accessToken
                }
    }
}
