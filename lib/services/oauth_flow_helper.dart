import 'dart:math';

import 'package:dio/dio.dart';

/// linux.do 系 OAuth 链路 (cdk / credit / 未来其他) 共用的拟人化工具。
///
/// 解决两类被反爬识别的特征:
/// 1. 固定 400ms gap 的"机械节奏" — [humanGap] 改为带抖动的随机区间。
/// 2. 裸 GET 缺失浏览器导航请求头 — [navigationHeaders] 补齐 Sec-Fetch / Referer /
///    Upgrade-Insecure-Requests, 让 connect.linux.do 上的 authorize / approve 请求
///    在反爬看来与真人浏览器跳转一致。
class OAuthFlowHelper {
  OAuthFlowHelper._();

  static final Random _random = Random();

  /// 真人级别的随机延迟。
  ///
  /// 真人浏览器跳转 OAuth 同意页时, 上一步到下一步的间隔通常呈现:
  /// - 网络请求自然延迟 (几百毫秒级)
  /// - 用户手指反应 / 渲染时间 (几百毫秒到 1 秒级)
  ///
  /// 固定 400ms 极容易被识别为脚本, 这里改为 [minMs, maxMs] 之间均匀分布。
  static Future<void> humanGap({
    required int minMs,
    required int maxMs,
  }) async {
    assert(minMs > 0 && maxMs >= minMs);
    final delay = minMs + _random.nextInt(maxMs - minMs + 1);
    await Future<void>.delayed(Duration(milliseconds: delay));
  }

  /// 构造模拟"浏览器导航"的请求头。
  ///
  /// connect.linux.do 上的 /oauth2/authorize 与 /oauth2/approve 在真人浏览
  /// 器里是顶层导航请求 (而不是 XHR), 必须带:
  /// - `Sec-Fetch-Dest: document`
  /// - `Sec-Fetch-Mode: navigate`
  /// - `Sec-Fetch-Site`: 首次从 cdk/credit 跳到 connect 是 `cross-site`,
  ///   approve 是同站后续跳转, 用 `same-origin`
  /// - `Sec-Fetch-User: ?1` (用户触发的导航)
  /// - `Upgrade-Insecure-Requests: 1`
  /// - `Accept`: HTML 优先
  /// - `Referer`: 上一个页面 URL
  ///
  /// [RequestHeaderInterceptor] 只在 `X-Requested-With=XMLHttpRequest`
  /// 分支下注入 Sec-Fetch-*, 这里手动补齐覆盖 OAuth 链路这种"裸 GET"场景。
  static Map<String, String> navigationHeaders({
    required String referer,
    required bool crossSite,
  }) {
    return {
      'Accept':
          'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
      'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
      'Upgrade-Insecure-Requests': '1',
      'Sec-Fetch-Dest': 'document',
      'Sec-Fetch-Mode': 'navigate',
      'Sec-Fetch-Site': crossSite ? 'cross-site' : 'same-origin',
      'Sec-Fetch-User': '?1',
      'Referer': referer,
    };
  }

  /// 把 [navigationHeaders] 合并进 dio Options 的 headers, 同时保留调用方
  /// 已经传入的其他设置 (followRedirects / extra / validateStatus 等)。
  static Options buildNavigationOptions({
    required String referer,
    required bool crossSite,
    bool followRedirects = false,
    bool Function(int?)? validateStatus,
    Map<String, dynamic>? extra,
  }) {
    return Options(
      followRedirects: followRedirects,
      validateStatus: validateStatus,
      headers: navigationHeaders(referer: referer, crossSite: crossSite),
      extra: extra,
    );
  }
}
