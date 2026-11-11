# BuildUE5Project

一个用于 UE5 项目的 Windows 批处理工具箱。无需打开 Visual Studio / IDE，即可在项目根目录完成：

- 生成 Visual Studio 解决方案
- 生成 VS Code 工作区
- 编译 / 重编译编辑器（Editor / Win64 / Development）
- 打包 Development / Shipping 版本

脚本会自动从 `.uproject` 读取引擎版本，并定位本机对应的 UE 安装。

## 环境要求

- Windows 10/11
- Unreal Engine 5（源码版或 Launcher 版均可）
- Windows PowerShell（脚本用它读取 `.uproject` 的 JSON 与注册表）

## 安装

1. 将 `BuildUE5Project.bat` 复制到你的 UE 项目根目录（与 `*.uproject` 同一文件夹）。
2. 双击运行，按菜单操作。

> 项目目录中应只有一个 `.uproject` 文件。

## 交互菜单

```
[1] Generate Visual Studio solution
[2] Generate VS Code workspace
[3] Build project   (Editor / Win64 / Development)
[4] Rebuild project (clean then build)
[5] Package project - Development
[6] Package project - Shipping
[0] Exit
```

## 命令行用法

除了交互菜单，也可以通过参数直接执行任务（适合接入脚本或 CI）：

```bat
BuildUE5Project.bat vs
BuildUE5Project.bat vscode
BuildUE5Project.bat build
BuildUE5Project.bat rebuild
BuildUE5Project.bat package-dev
BuildUE5Project.bat package-shipping
```

数字参数 `1`–`6` 与上面各项等价，用于向后兼容。

带参数运行时不会显示菜单，也不会暂停等待按键。

| 参数 | 任务 | 实际调用 |
| --- | --- | --- |
| `vs` / `1` | 生成 VS 解决方案 | `GenerateProjectFiles.bat`（缺失时回退到 `UnrealBuildTool -ProjectFiles`） |
| `vscode` / `2` | 生成 VS Code 工作区 | 同上，附加 `-VSCode` |
| `build` / `3` | 编译编辑器 | `Build.bat <Project>Editor Win64 Development` |
| `rebuild` / `4` | 清理并重编译 | `Rebuild.bat <Project>Editor Win64 Development` |
| `package-dev` / `5` | 打包 Development | `RunUAT.bat BuildCookRun` |
| `package-shipping` / `6` | 打包 Shipping | `RunUAT.bat BuildCookRun` |

## 引擎定位顺序

脚本从 `.uproject` 的 `EngineAssociation` 字段读取版本号（如 `5.6`），然后按以下顺序查找引擎：

1. `HKCU\Software\Epic Games\Unreal Engine\Builds` 中注册的自定义 / 源码引擎
2. `HKLM\SOFTWARE\EpicGames\Unreal Engine\<版本>` 中注册的 Launcher 安装
3. 默认安装路径 `%ProgramFiles%\Epic Games\UE_<版本>`
4. `%UE_SOURCE_ROOT%\UE_<版本>`（源码编译引擎）

`UE_SOURCE_ROOT` 默认为 `F:\UnrealEngine`，可在运行前通过环境变量覆盖：

```bat
set UE_SOURCE_ROOT=D:\UnrealEngine
BuildUE5Project.bat build
```

## 打包输出

打包使用 `BuildCookRun`，产物位于项目目录：

```
<项目目录>\Packaged\Development\
<项目目录>\Packaged\Shipping\
```

打包命令包含 `-build -cook -stage -pak -compressed -archive`，并关闭 P4（`-noP4`）。

## 注意事项

- 目标平台当前固定为 `Win64`。
- 打包时 `-clientconfig` 与 `-serverconfig` 使用同一配置。
- 非交互模式（带参数）下脚本退出码始终为 `0`，请通过输出中的 `[ERROR]` 行判断任务是否真正失败。
- 生成工程文件时优先调用引擎自带的 `GenerateProjectFiles.bat`；该文件缺失时自动回退到 `UnrealBuildTool.exe -ProjectFiles`。

## 常见问题

**提示 `No *.uproject file in this folder.`**

脚本所在目录没有 `.uproject`，请将它放到项目根目录。

**提示找不到引擎**

检查 `.uproject` 中的 `EngineAssociation` 是否与实际安装版本一致，或按“引擎定位顺序”补齐注册表 / 安装路径。

**提示找不到 PowerShell**

脚本依赖 PowerShell 解析 `.uproject` 与注册表；Windows 10/11 默认自带，若被精简请先安装。
