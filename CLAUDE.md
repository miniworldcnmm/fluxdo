# Project Guidelines

## Language

Use Chinese for all communication and code comments.

## Dependencies

When adding or updating dependencies in `pubspec.yaml`:

- **MUST** use the latest stable version of any package.
- **MUST** check [pub.dev](https://pub.dev) for the current version before adding a dependency.
- **NEVER** copy outdated version numbers from memory or examples.

## Time Handling

All time strings from the Discourse API are in UTC format. The project uses a unified `TimeUtils` class (`lib/utils/time_utils.dart`) for all time parsing and formatting.

### Rules

- **MUST** use `TimeUtils.parseUtcTime()` to parse any time string from the API. It handles UTC-to-local conversion internally.
- **MUST** use `TimeUtils.formatRelativeTime()` / `formatDetailTime()` / `formatCompactTime()` / `formatShortDate()` / `formatFullDate()` for display.
- **NEVER** use `DateTime.parse()` or `DateTime.tryParse()` directly in model or UI code.
- **NEVER** call `.toLocal()` outside of `TimeUtils`.

### Correct

```dart
createdAt: TimeUtils.parseUtcTime(json['created_at'] as String?),
```

### Wrong

```dart
createdAt: DateTime.parse(json['created_at'] as String),
createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
```

## Product Review Preferences

- 默认关闭且需要用户主动开启的功能，不要仅因其启用后会触发系统级提示就判定为 PR 阻塞。
- 剪贴板自动识别功能默认关闭；用户主动开启后，回到前台读取剪贴板属于预期行为，不需要额外增加启用确认弹窗，除非用户明确要求。

## Recent Clipboard Quick Access Review

- 剪贴板话题链接提示不能在 `showSnackBar` 后立即持久化为已提示；应先避开启动弹窗遮挡，并通过 `ScaffoldFeatureController.closed` 覆盖超时、隐藏、替换等关闭路径。
- 对外暴露的 Deep Link 入口必须自行校验 scheme/host，不能依赖调用方保证 URL 已验证，避免非 `linux.do` 的 `/t/...` 被站内路由接管。
