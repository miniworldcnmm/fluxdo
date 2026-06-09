import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart' as dio;
import 'package:http/http.dart' as http;
import '../constants.dart';
import 'network/discourse_dio.dart';

/// 包装 Dio 的 http.BaseClient 实现,给 flutter_cache_manager / image 下载用。
///
/// **双 dio 策略**(按 request URL host 选)
/// - **主域** (`linux.do` 及其子域):用 `_mainDomainDio`,带 cookie。
///   原因:`/uploads/secure-uploads/*` 私密图、user_avatar 在某些配置下需要
///   session cookie 才能访问。关掉 cookie 会让这些图 403。
///   但仍关掉 CfChallenge / Retry(图片自动 CF 验证 / 重试意义不大)。
///
/// - **第三方 CDN** (`s.pwsh.us.kg` / `cdn.ldstatic.com` / 其它):用 `_cdnDio`,
///   **完全不带 cookie**。CDN 根本不读 cookie header,带过去也无效;反而每张
///   图都触发 cookie jar 磁盘读写,30 张同屏 = 60 次磁盘 IO + cookie jar 锁
///   争用,这是"PNG 等半天"的根因。
class DioHttpClient extends http.BaseClient {
  static DioHttpClient? _instance;

  final dio.Dio _mainDomainDio;
  final dio.Dio _cdnDio;

  factory DioHttpClient() {
    _instance ??= DioHttpClient._internal();
    return _instance!;
  }

  DioHttpClient._internal()
      : _mainDomainDio = DiscourseDio.create(
          defaultHeaders: _imageHeaders,
          maxConcurrent: null,
          enableCookies: true, // 主域需要 cookie 走 secure-uploads
          enableCfChallenge: false,
          enableRetry: false,
          enableNetworkLog: false, // 几百张图都 log 占主线程
        ),
        _cdnDio = DiscourseDio.create(
          defaultHeaders: _imageHeaders,
          maxConcurrent: null,
          enableCookies: false, // CDN 完全不需要 cookie
          enableCfChallenge: false,
          enableRetry: false,
          enableNetworkLog: false,
        );

  static const Map<String, String> _imageHeaders = {
    'Accept': '*/*',
    'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
  };

  /// 提取 [AppConstants.baseUrl] 的 host(例如 `linux.do`),用于判断主域。
  /// 注意是 host 比对而不是 URL prefix 比对 —— 子域(`auth.linux.do` 等)
  /// 也算主域,会走带 cookie 的 dio。
  static final String _mainHost = Uri.parse(AppConstants.baseUrl).host;

  bool _isMainDomain(Uri url) {
    final host = url.host;
    if (host.isEmpty) return false;
    // 主域精确匹配 或 是主域的子域(*.linux.do)
    return host == _mainHost || host.endsWith('.$_mainHost');
  }

  dio.Dio _selectDio(Uri url) =>
      _isMainDomain(url) ? _mainDomainDio : _cdnDio;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    try {
      // 转换 headers
      final headers = <String, dynamic>{};
      request.headers.forEach((key, value) {
        headers[key] = value;
      });

      // 获取请求体
      Uint8List? bodyBytes;
      if (request is http.Request && request.bodyBytes.isNotEmpty) {
        bodyBytes = request.bodyBytes;
      } else if (request is http.MultipartRequest) {
        // MultipartRequest 需要特殊处理
        final stream = request.finalize();
        final bytes = await stream.toBytes();
        bodyBytes = Uint8List.fromList(bytes);
      }

      // 按 host 选 dio:主域用 _mainDomainDio(带 cookie),CDN 用 _cdnDio(lean)
      final response = await _selectDio(request.url).request<dio.ResponseBody>(
        request.url.toString(),
        options: dio.Options(
          method: request.method,
          headers: headers,
          responseType: dio.ResponseType.stream,
          // 接受所有状态码，让调用方处理
          validateStatus: (status) => true,
        ),
        data: bodyBytes != null ? Stream.fromIterable([bodyBytes]) : null,
      );

      // 转换响应 headers
      final responseHeaders = <String, String>{};
      response.headers.forEach((name, values) {
        responseHeaders[name] = values.join(', ');
      });

      // 获取 Content-Length
      final contentLengthStr = responseHeaders['content-length'];
      final contentLength = contentLengthStr != null ? int.tryParse(contentLengthStr) : null;

      // 获取流式响应体
      final responseBody = response.data;
      final Stream<List<int>> responseStream;

      if (responseBody != null) {
        // 直接使用 Dio 的流式响应
        responseStream = responseBody.stream;
      } else {
        responseStream = Stream.value(<int>[]);
      }

      return http.StreamedResponse(
        responseStream,
        response.statusCode ?? 200,
        headers: responseHeaders,
        contentLength: contentLength,
        request: request,
        reasonPhrase: response.statusMessage,
      );
    } on dio.DioException catch (e) {
      // 将 DioException 转换为 http 包可以理解的异常
      if (e.type == dio.DioExceptionType.connectionTimeout ||
          e.type == dio.DioExceptionType.receiveTimeout) {
        throw http.ClientException('Request timeout: ${e.message}', request.url);
      }
      throw http.ClientException('Dio error: ${e.message}', request.url);
    }
  }

  @override
  void close() {
    // 不关闭共享的 Dio 实例
  }
}
