import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxdo/services/network/adapters/platform_adapter.dart';

void main() {
  group('requestAllowsRhttpAdapter', () {
    RequestOptions buildOptions({
      ResponseType? responseType,
      Map<String, dynamic>? extra,
    }) {
      return RequestOptions(
        path: '/latest.json',
        baseUrl: 'https://linux.do',
        responseType: responseType,
        extra: extra ?? <String, dynamic>{},
      );
    }

    test('普通 API 请求允许走 rhttp', () {
      expect(requestAllowsRhttpAdapter(buildOptions()), isTrue);
    });

    test('stream 响应默认允许走 rhttp', () {
      expect(
        requestAllowsRhttpAdapter(
          buildOptions(responseType: ResponseType.stream),
        ),
        isTrue,
      );
    });

    test('bytes 响应默认允许走 rhttp', () {
      expect(
        requestAllowsRhttpAdapter(
          buildOptions(responseType: ResponseType.bytes),
        ),
        isTrue,
      );
    });

    test('显式 skipRhttpAdapter 时旁路 rhttp', () {
      expect(
        requestAllowsRhttpAdapter(
          buildOptions(extra: {'skipRhttpAdapter': true}),
        ),
        isFalse,
      );
    });
  });
}
