// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Squirrel Play';

  @override
  String get topBarAddGame => '添加游戏';

  @override
  String get topBarGameLibrary => '游戏库';

  @override
  String get topBarRescan => '重新扫描';

  @override
  String get topBarSettings => '设置';

  @override
  String get topBarHome => '主页';

  @override
  String get pageHome => '主页';

  @override
  String get pageLibrary => '库';

  @override
  String get pageSettings => '设置';

  @override
  String get homeEmptyState => '还没有游戏。添加一个游戏开始吧。';

  @override
  String get libraryEmptyState => '您的游戏库是空的。';

  @override
  String timeFormat(String hour, String minute) {
    return '$hour:$minute';
  }

  @override
  String get focusAddGameHint => '将新游戏添加到您的库中';

  @override
  String get focusGameLibraryHint => '查看库中的所有游戏';

  @override
  String get focusRescanHint => '重新扫描目录以查找新游戏';

  @override
  String get topBarRefresh => '刷新';

  @override
  String get topBarScanning => '扫描中...';

  @override
  String topBarScanNewGames(int count) {
    return '发现 $count 个新游戏';
  }

  @override
  String get topBarScanNoNewGames => '未发现新游戏';

  @override
  String get topBarScanNoDirectories => '未配置扫描目录';

  @override
  String get topBarScanError => '扫描错误';

  @override
  String get topBarRefreshHint => '刷新游戏库';

  @override
  String get focusSettingsHint => '打开应用程序设置';

  @override
  String get focusHomeHint => '返回主页';

  @override
  String get dialogAddGameTitle => '添加游戏';

  @override
  String get dialogAddGameManualTab => '手动添加';

  @override
  String get dialogAddGameScanTab => '扫描目录';

  @override
  String get dialogAddGameSteamTab => 'Steam 游戏';

  @override
  String get dialogClose => '关闭';

  @override
  String get buttonBack => '返回';

  @override
  String get buttonCancel => '取消';

  @override
  String get buttonSave => '保存';

  @override
  String get buttonRetry => '重试';

  @override
  String get buttonConfirm => '确认';

  @override
  String get focusCardHint => '游戏卡片 - 按A键选择';

  @override
  String get snackbarRescanPlaceholder => '重新扫描功能即将推出';

  @override
  String get dialogPlaceholderText => '此功能将在未来更新中提供';

  @override
  String get emptyStateAddGame => '添加您的第一个游戏';

  @override
  String get emptyStateSubtitle => '添加您的第一个游戏以开始使用';

  @override
  String get buttonScanDirectory => '扫描目录';

  @override
  String get noDescriptionAvailable => '暂无描述';

  @override
  String get errorLoadGames => '加载游戏失败';

  @override
  String get homeRowRecentlyAdded => '最近添加';

  @override
  String get homeRowAllGames => '所有游戏';

  @override
  String get homeRowFavorites => '收藏';

  @override
  String get homeRowRecentlyPlayed => '最近玩过';

  @override
  String get homeRowFeatured => '精选';

  @override
  String get viewAllGames => '全部游戏';

  @override
  String launchingGame(String gameName) {
    return '正在启动 $gameName...';
  }

  @override
  String get launchCancelHint => '按B键取消';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsLanguageEnglish => '英语';

  @override
  String get settingsLanguageChinese => '中文（简体）';

  @override
  String get settingsApiKey => 'API密钥';

  @override
  String get settingsApiKeyLabel => 'RAWG API密钥';

  @override
  String get settingsApiKeyPlaceholder => '输入您的RAWG API密钥';

  @override
  String get settingsApiKeyHelp => '从rawg.io获取免费API密钥';

  @override
  String get settingsApiKeyDegraded => '降级模式';

  @override
  String get settingsApiKeyConnected => 'API已连接';

  @override
  String get settingsSound => '声音';

  @override
  String get settingsSoundVolume => '主音量';

  @override
  String get settingsSoundMute => '静音';

  @override
  String get settingsSoundTest => '测试声音';

  @override
  String get settingsSoundVolumeHint => '音量滑块 - 使用左右方向键调整';

  @override
  String get settingsSoundMuteHint => '静音切换 - 按下以切换静音开关';

  @override
  String get settingsLanguageEnglishLabel => '英语语言选项';

  @override
  String get settingsLanguageChineseLabel => '中文语言选项';

  @override
  String get settingsAbout => '关于';

  @override
  String settingsAboutVersion(String version) {
    return '版本 $version';
  }

  @override
  String get settingsAboutCredits => '由RAWG API提供支持';

  @override
  String get errorGenericTitle => '出错了';

  @override
  String get errorGenericMessage => '发生意外错误。请重试。';

  @override
  String get errorDatabaseTitle => '数据库错误';

  @override
  String get errorDatabaseMessage => '无法访问游戏数据库。请重新启动应用程序。';

  @override
  String get errorApiTitle => '连接错误';

  @override
  String get errorApiMessage => '无法连接到游戏数据库。您仍然可以玩游戏。';

  @override
  String get errorFileNotFoundTitle => '游戏未找到';

  @override
  String get errorFileNotFoundMessage => '找不到游戏可执行文件。它可能已被移动或删除。';

  @override
  String get errorMissingExecutableTitle => '缺少可执行文件';

  @override
  String get errorMissingExecutableMessage => '游戏可执行文件缺失。请浏览新的位置。';

  @override
  String get emptyStateNoGamesTitle => '还没有游戏';

  @override
  String get emptyStateNoGamesMessage => '添加您的第一个游戏以开始使用';

  @override
  String get emptyStateNoSearchResultsTitle => '无结果';

  @override
  String get emptyStateNoSearchResultsMessage => '尝试不同的搜索词';

  @override
  String get emptyStateApiUnreachableTitle => '无法连接';

  @override
  String get emptyStateApiUnreachableMessage => '游戏信息不可用。您仍然可以玩游戏。';

  @override
  String get favoritesAdded => '已添加到收藏';

  @override
  String get favoritesRemoved => '已从收藏移除';

  @override
  String get favoritesEmptyState => '还没有收藏的游戏';

  @override
  String gameInfoPlayCount(int count) {
    return '已玩$count次';
  }

  @override
  String get gameInfoPlayCountNever => '从未玩过';

  @override
  String gameInfoLastPlayed(String timeAgo) {
    return '上次游玩：$timeAgo';
  }

  @override
  String get gameInfoLastPlayedNever => '从未玩过';

  @override
  String get gameInfoFavoriteButton => '添加到收藏';

  @override
  String get gameInfoUnfavoriteButton => '从收藏移除';

  @override
  String get gameInfoLaunchButton => '启动游戏';

  @override
  String get gamepadAButton => 'A：选择';

  @override
  String get gamepadBButton => 'B：返回';

  @override
  String get gamepadXButton => 'X：详情';

  @override
  String get gamepadYButton => 'Y：收藏';

  @override
  String get gamepadStartButton => 'Start：菜单';

  @override
  String get gamepadBackButton => 'Back：主页';

  @override
  String get gamepadNavSelect => '选择';

  @override
  String get gamepadNavBack => '返回';

  @override
  String get gamepadNavDetails => '详情';

  @override
  String get gamepadNavFavorite => '收藏';

  @override
  String get gamepadNavMenu => '菜单';

  @override
  String get gamepadNavHome => '主页';

  @override
  String get gamepadNavConfirm => '确认';

  @override
  String get gamepadNavCancel => '取消';

  @override
  String get gamepadNavPlay => '启动';

  @override
  String get gamepadNavToggle => '切换';

  @override
  String get gamepadNavScreenshots => '截图';

  @override
  String get settingsGamepad => '手柄';

  @override
  String get settingsGamepadConnected => '手柄：已连接';

  @override
  String get settingsGamepadDisconnected => '手柄：未连接';

  @override
  String get settingsGamepadTest => '测试手柄';

  @override
  String get gamepadTestTitle => '手柄测试';

  @override
  String get gamepadTestConnected => '已连接';

  @override
  String get gamepadTestDisconnected => '未检测到手柄';

  @override
  String get gamepadTestConnectHelp => '连接手柄并按任意按钮';

  @override
  String get gamepadTestInputLog => '输入日志';

  @override
  String get gamepadTestNoGamepad => '未检测到手柄';

  @override
  String get gamepadTestConnectInstructions => '连接手柄并按任意按钮开始测试';

  @override
  String get timeAgoJustNow => '刚刚';

  @override
  String timeAgoMinutes(int minutes) {
    return '$minutes分钟前';
  }

  @override
  String timeAgoHours(int hours) {
    return '$hours小时前';
  }

  @override
  String timeAgoDays(int days) {
    return '$days天前';
  }

  @override
  String timeAgoWeeks(int weeks) {
    return '$weeks周前';
  }

  @override
  String timeAgoMonths(int months) {
    return '$months个月前';
  }

  @override
  String timeAgoYears(int years) {
    return '$years年前';
  }

  @override
  String get fileBrowserTitle => '选择文件';

  @override
  String get fileBrowserSelect => '选择';

  @override
  String get fileBrowserCancel => '取消';

  @override
  String get fileBrowserNoItems => '无内容';

  @override
  String get fileBrowserParentDirectory => '上级目录';

  @override
  String fileBrowserSelectedCount(int count) {
    return '已选择 $count 项';
  }
}
