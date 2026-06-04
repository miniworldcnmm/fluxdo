// WebView 内 JS 错误回传：window.error + unhandledrejection。
// 通过 `flutter_inappwebview.callHandler('onWebViewJsError', ...)` 落到 Dart LogWriter，
// 节流到每页 30 条避免极端情况下日志洪水。
//
// 设计为「打开页面就装」，所以走立即执行 IIFE + 全局哨兵防重入。
(function () {
  if (window.__fluxdoErrHooked) return;
  window.__fluxdoErrHooked = true;
  var count = 0;
  var MAX = 30;

  function report(payload) {
    if (count >= MAX) return;
    count++;
    try {
      var h = window.flutter_inappwebview;
      if (h && h.callHandler) {
        h.callHandler('onWebViewJsError', payload);
      }
    } catch (_) {}
  }

  window.addEventListener(
    'error',
    function (e) {
      if (!e) return;
      var err = e.error;
      report({
        source: 'window.error',
        message: e.message || (err && err.message) || 'unknown',
        filename: e.filename || null,
        lineno: e.lineno || null,
        colno: e.colno || null,
        stack: (err && err.stack) || null,
        url: location.href,
        ua: navigator.userAgent,
      });
    },
    true,
  );

  window.addEventListener(
    'unhandledrejection',
    function (e) {
      var reason = e && e.reason;
      var msg = 'unknown';
      var stack = null;
      if (reason) {
        if (typeof reason === 'string') {
          msg = reason;
        } else if (reason.message) {
          msg = reason.message;
          stack = reason.stack || null;
        } else {
          try {
            msg = JSON.stringify(reason);
          } catch (_) {
            msg = String(reason);
          }
        }
      }
      report({
        source: 'unhandledrejection',
        message: msg,
        stack: stack,
        url: location.href,
        ua: navigator.userAgent,
      });
    },
    true,
  );
})();
