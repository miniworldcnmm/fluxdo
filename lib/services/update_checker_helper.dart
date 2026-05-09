import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/dialog_utils.dart';
import '../widgets/download_progress_dialog.dart';
import '../widgets/update_dialog.dart';
import 'apk_download_service.dart';
import 'update_service.dart';

/// 更新检查助手类
///
/// 负责处理自动更新检查的 UI 逻辑
class UpdateCheckerHelper {
  /// 在应用启动时自动检查更新
  ///
  /// 如果发现新版本，会显示更新对话框
  static Future<void> checkUpdateOnStartup(
    BuildContext context,
    UpdateService updateService,
  ) async {
    final updateInfo = await updateService.autoCheckUpdate();
    if (updateInfo != null && context.mounted) {
      await _showAutoUpdateDialog(context, updateInfo, updateService);
    }
  }

  /// 显示自动更新对话框
  static Future<void> _showAutoUpdateDialog(
    BuildContext context,
    UpdateInfo updateInfo,
    UpdateService updateService,
  ) {
    return showAppDialog<void>(
      context: context,
      builder: (context) => UpdateDialog(
        updateInfo: updateInfo,
        onUpdate: () {
          Navigator.of(context).pop();
          _handleUpdate(context, updateInfo);
        },
        onCancel: () => Navigator.of(context).pop(),
        onIgnore: () {
          updateService.setAutoCheckUpdate(false);
          Navigator.of(context).pop();
        },
        onOpenReleasePage: () {
          Navigator.of(context).pop();
          _openInBrowser(updateInfo.releaseUrl);
        },
      ),
    );
  }

  /// 处理更新逻辑
  ///
  /// Android: 尝试应用内下载安装，失败则回退到浏览器
  /// iOS/其他: 跳转到浏览器
  static Future<void> _handleUpdate(
    BuildContext context,
    UpdateInfo updateInfo,
  ) async {
    if (Platform.isAndroid) {
      await _startInAppDownload(context, updateInfo);
    } else {
      _openInBrowser(updateInfo.releaseUrl);
    }
  }

  /// 启动应用内下载
  static Future<void> _startInAppDownload(
    BuildContext context,
    UpdateInfo updateInfo,
  ) async {
    final updateService = UpdateService();
    final apkAsset = await updateService.getMatchingApkAsset(updateInfo);

    if (apkAsset == null) {
      // 无法匹配架构，回退到浏览器
      _openInBrowser(updateInfo.releaseUrl);
      return;
    }

    if (!context.mounted) return;

    showAppDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DownloadProgressDialog(
        asset: apkAsset,
        downloadService: ApkDownloadService(),
      ),
    );
  }

  /// 在浏览器中打开
  static void _openInBrowser(String url) {
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}
