// 入口：'core-js/stable' 这一行会被 @babel/preset-env (useBuiltIns: 'entry')
// 按 package.json 里的 browserslist (iOS >= 15.0) 展开成精确的
// `import 'core-js/modules/<feature>'` 列表，只引入老 WKWebView 缺失的 API。
// 抬高基线 → 改 package.json 里的 browserslist，build 后产物自动缩小。
import 'core-js/stable';

// WebView 内 JS 运行时错误捕获，回传到 Dart 侧 LogWriter。
import './error-reporter.js';
