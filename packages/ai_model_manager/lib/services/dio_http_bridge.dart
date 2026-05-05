import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

/// 把 [HttpClientAdapter] 包装成 [http.Client]，让基于 `package:http` 的 SDK
/// （langchain_dart / openai_core 等）复用应用的 dio 网络栈（代理、TLS 适配器等）。
///
/// 透传策略：
/// - 请求体走流式（不落内存），保留 SSE 等长连接场景
/// - 响应同样以流形式向上抛，不在桥接层缓冲
/// - 响应头多值用逗号合并，符合 RFC 7230 §3.2.2
class DioBackedHttpClient extends http.BaseClient {
  DioBackedHttpClient(this._adapter);

  final HttpClientAdapter _adapter;
  bool _closed = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (_closed) {
      throw http.ClientException(
        'DioBackedHttpClient has been closed.',
        request.url,
      );
    }

    final body = request.finalize();
    final requestStream = body.cast<Uint8List>();

    final options = RequestOptions(
      method: request.method,
      path: request.url.toString(),
      headers: <String, dynamic>{...request.headers},
      responseType: ResponseType.stream,
      followRedirects: request.followRedirects,
      maxRedirects: request.maxRedirects,
      // 让 dio 自己根据请求 body 推断 Content-Length；显式 null 表示不强制
      contentType: request.headers['content-type'] ??
          request.headers['Content-Type'],
    );

    final ResponseBody responseBody;
    try {
      responseBody = await _adapter.fetch(options, requestStream, null);
    } on DioException catch (e) {
      throw http.ClientException(
        e.message ?? e.toString(),
        request.url,
      );
    }

    final headers = _flattenHeaders(responseBody.headers);
    final contentLength = _parseContentLength(responseBody.headers);

    return http.StreamedResponse(
      responseBody.stream.cast<List<int>>(),
      responseBody.statusCode,
      contentLength: contentLength,
      request: request,
      headers: headers,
      isRedirect: responseBody.isRedirect,
      reasonPhrase: responseBody.statusMessage,
    );
  }

  @override
  void close() {
    if (_closed) return;
    _closed = true;
    _adapter.close(force: false);
  }

  static Map<String, String> _flattenHeaders(
    Map<String, List<String>> headers,
  ) {
    return {
      for (final entry in headers.entries)
        entry.key.toLowerCase(): entry.value.join(', '),
    };
  }

  static int? _parseContentLength(Map<String, List<String>> headers) {
    final raw = headers['content-length']?.firstOrNull ??
        headers['Content-Length']?.firstOrNull;
    if (raw == null) return null;
    return int.tryParse(raw);
  }
}
