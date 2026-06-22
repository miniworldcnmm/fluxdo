import 'package:flutter/material.dart';
import 'package:app_icons/app_icons.dart';

/// Callout 配置类
class CalloutConfig {
  final Color color;
  final IconData icon;
  final String defaultTitle;

  const CalloutConfig(this.color, this.icon, this.defaultTitle);
}

/// 获取 Callout 配置
CalloutConfig getCalloutConfig(String type) {
  switch (type) {
    case 'note':
      return CalloutConfig(Colors.blue, Symbols.edit_note_rounded, 'Note');
    case 'abstract':
    case 'summary':
    case 'tldr':
      return CalloutConfig(Colors.cyan, Symbols.subject_rounded, 'Summary');
    case 'info':
      return CalloutConfig(Colors.blue, Symbols.info_rounded, 'Info');
    case 'todo':
      return CalloutConfig(Colors.blue, Symbols.check_circle_rounded, 'Todo');
    case 'tip':
    case 'hint':
    case 'important':
      return CalloutConfig(Colors.teal, Symbols.tips_and_updates_rounded, 'Tip');
    case 'success':
    case 'check':
    case 'done':
      return CalloutConfig(Colors.green, Symbols.check_circle_rounded, 'Success');
    case 'question':
    case 'help':
    case 'faq':
      return CalloutConfig(Colors.orange, Symbols.help_rounded, 'Question');
    case 'warning':
    case 'caution':
    case 'attention':
      return CalloutConfig(Colors.orange, Symbols.warning_amber_rounded, 'Warning');
    case 'failure':
    case 'fail':
    case 'missing':
      return CalloutConfig(Colors.red, Symbols.close_rounded, 'Failure');
    case 'danger':
    case 'error':
      return CalloutConfig(Colors.red, Symbols.dangerous_rounded, 'Danger');
    case 'bug':
      return CalloutConfig(Colors.red, Symbols.bug_report_rounded, 'Bug');
    case 'example':
      return CalloutConfig(Colors.purple, Symbols.list_rounded, 'Example');
    case 'quote':
    case 'cite':
      return CalloutConfig(Colors.grey, Symbols.format_quote_rounded, 'Quote');
    default:
      // 未知类型使用灰色，标题首字母大写
      final defaultTitle = type.isNotEmpty
          ? type[0].toUpperCase() + type.substring(1)
          : 'Note';
      return CalloutConfig(Colors.grey, Symbols.format_quote_rounded, defaultTitle);
  }
}

bool isKnownCalloutType(String type) {
  switch (type) {
    case 'note':
    case 'abstract':
    case 'summary':
    case 'tldr':
    case 'info':
    case 'todo':
    case 'tip':
    case 'hint':
    case 'important':
    case 'success':
    case 'check':
    case 'done':
    case 'question':
    case 'help':
    case 'faq':
    case 'warning':
    case 'caution':
    case 'attention':
    case 'failure':
    case 'fail':
    case 'missing':
    case 'danger':
    case 'error':
    case 'bug':
    case 'example':
    case 'quote':
    case 'cite':
      return true;
    default:
      return false;
  }
}
