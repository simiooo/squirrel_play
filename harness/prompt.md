# User Prompt

修复 Squirrel Play 应用中的以下手柄导航和 i18n 问题：

## 问题 1: GamepadFileBrowser 中 A 键确认无效（ActivateIntent 未处理）

当焦点在 `GamepadFileBrowser` 的文件列表项上时，按手柄 A 键触发 `GamepadAction.confirm`，`FocusTraversalService.activateCurrentNode()` 尝试调用 `Actions.invoke(context, const ActivateIntent())`，但失败并抛出异常：

```
[FocusTraversalService] Activating node: FileBrowserItem_0
[FocusTraversalService] ActivateIntent not handled for FileBrowserItem_0: Unable to find an action for an Intent with type ActivateIntent in an Actions widget in the given context.
Actions.invoke() was unable to find an Actions widget that contained a mapping for the given intent...
```

根因：`GamepadFileBrowser` 里的 `Focus` widget 包裹了 `Actions` widget，导致 `Actions.invoke` 从 `Focus` 的 context 往上查找时找不到 `Actions` widget。

## 问题 2: GamepadFileBrowser 中 B 键取消无效

在 `GamepadFileBrowser` 中按手柄 B 键（`GamepadAction.cancel`）无法关闭文件浏览器对话框。日志显示 `FocusTraversalService` 接收到了 cancel action，但因为检测到焦点在 dialog 内而直接返回，没有执行任何操作。

## 问题 3: 手动添加页面无法聚焦到 Browse 按钮

在 Add Game 对话框的 "Manual Add" 标签页中，焦点无法落在 "Browse..." 按钮（`PickerButton`）上。用户希望通过摇杆 Y 轴（上下方向）能够从其他控件（如游戏名称输入框）移动到 Browse 按钮。

## 问题 4: 扫描目录页面无法聚焦到 Add Directory 按钮

在 Add Game 对话框的 "Scan Directory" 标签页中，焦点无法落在 "Add Directory" 按钮（`PickerButton`）上。同样希望通过摇杆 Y 轴能够聚焦到它。

## 问题 5: 大量文本未适配 i18n

以下文件中有大量硬编码的英文文本，需要提取到 ARB 文件中并适配中英文：
- `lib/presentation/widgets/manual_add_tab.dart`
- `lib/presentation/widgets/scan_directory_tab.dart`
- `lib/presentation/widgets/steam_games_tab.dart`
- `lib/presentation/widgets/gamepad_file_browser.dart`

## 技术约束

- 使用 Flutter `FocusScope` 架构进行焦点管理
- 手柄输入通过 `GamepadService` → `FocusTraversalService` 路由
- `FocusTraversalService.activateCurrentNode()` 使用 `Actions.invoke(context, const ActivateIntent())`
- `FocusTraversalService._handleCancel()` 在 dialog 内会提前返回
- `PickerButton` 和 `FocusableButton` 外层已添加 `Focus` widget 用于拦截手柄按键，但可能干扰了 `FocusScope` 的默认遍历
- 必须保持所有现有测试通过（370 项）
- 所有代码必须遵循 `always_use_package_imports` 规则
- 新字符串必须同时添加到 `app_en.arb` 和 `app_zh.arb`
- 修改 ARB 后必须运行 `flutter gen-l10n`
