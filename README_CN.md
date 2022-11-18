# AgoraChatCallKit iOS 快速开始

## 概述

`AgoraChatCallKit` 基于 Agora RTC 构建，利用即时通讯 IM 作为信令通道。该库提供各类 API 实现一对一音视频通话和多人音视频通话。

## 跑通 Demo

`AgoraChatCallKit` 集成在即时通讯 IM demo 中。你可以从我们的 GitHub [开源仓库](https://github.com/AgoraIO-Usecase/AgoraChat-ios)中下载 iOS demo。

### 安装相关 SDK 和 `AgoraChatCallKit`

若 Demo 的源码中不包含 SDK 和 `AgoraChatCallKit`，可直接导入或利用 CocoaPods 安装。

安装 CocoaPods，详见 [CocoaPods 快速入门](https://guides.cocoapods.org/using/getting-started.html)。

若利用 CocoaPods 安装，首先打开 `podfile` 文件的目录，在终端中运行以下命令：

```
pod install
```

### 运行 Demo

安装完毕所需的 SDK 和 `AgoraChatCallKit`后，在 Xcode 上打开 `AgoraChat.xcworkspace` 工作空间，连接手机，运行 Demo。

## 前提条件

开始前，请确保你的开发环境满足以下条件：

- 一台运行 iOS 10.0 或以上版本的设备；
- 已集成即时通讯 IM，提供登录、联系人、群组和会话等基本功能；
- 已创建 [Agora app](https://docs.agora.io/cn/Video/run_demo_video_call_ios?platform=iOS#1-创建-agora-项目)；
- 已激活 Token 验证。你需要实现自己的 [App Server](https://github.com/AgoraIO/Agora-Chat-API-Examples/tree/main/chat-app-server)； 
- 一个有效的即时通讯 IM 账号。

## 集成 `AgoraChatCallKit`

按照以下步骤集成 `AgoraChatCallKit`：

1. 用户调用 API 初始化 `AgoraChatCallKit`。
2. 主叫方调用 API 进行发起通话，弹出通话页面。
3. 被叫方确认是否在呼叫请求页面接听来电。
4. 主叫方或被叫方点击 `挂断` 按钮结束通话。

### 导入 `AgoraChatCallKit`

`AgoraChatCallKit` 依赖于 `Agora_Chat_iOS`、`Masonry`、`AgoraRtcEngine_iOS/RtcBasic` 和 `SDWebImage` 库。因此，你需要将这些库导入到项目中，例如，通过 CocoaPods 导入。

由于 `AgoraChatCallKit` 是一个动态库，你必须在 `podfile` 中添加 use_frameworks!。

你可以手动导入 `AgoraChatCallKit`，也可以通过 CocoaPods 自动导入。

#### 利用 CocoaPods 导入 `AgoraChatCallKit`

在终端中，访问该项目的根目录，运行 `pod init` 命令在项目文件夹中生成 `Podfile` 文件。

打开 `Podfile` 文件，修改文件内容。注意将 `AppName` 替换为你的 app 名称。

```
use_frameworks!
target 'AppName' do
    pod 'AgoraChatCallKit'
end
```

在终端中，运行 `pod update` 命令更新本地 `AgoraChatCallKit` 的版本。

运行 `pod install` 命令安装 `AgoraChatCallKit`。若安装成功，终端上会显示 `Pod installation complete!`。该项目文件夹中会生成 `xcworkspace` 文件。

#### 手动导入 `AgoraChatCallKit`

1. 在跑通 Demo 时，将下载的 `AgoraChatCallKit.framework` 复制到项目文件夹。
2. 在 Xcode 中，选择 **Project Settings > General**，将 `AgoraChatCallKit.framework` 拖到项目中，在 `Frameworks, Libraries, and Embedded Content` 中将`AgoraChatCallKit.framework` 设置为 `Embed & Sign`。

### 添加权限

App 需要音视频设备和相机权限。在 `info.plist` 文件中，点击 `+` 添加以下信息：

| Key                                    | 类型   | Value                                                        |
| -------------------------------------- | ------ | ------------------------------------------------------------ |
| Privacy - Microphone Usage Description | String | 描述，例如，“即时通讯 IM 需要使用你的耳机。”  |
| Privacy - Camera Usage Description     | String | 描述，例如，“即时通讯 IM 需要使用你的相机。” |

如果希望在后台运行 `AgoraChatCallKit`，你需要在后台添加播放音视频的权限：

1. 点击 `+` 将 `Required background modes` 添加到 `info.plist` 中，将 `Type` 设置为 `Array`。
2. 在 `Array` 中，添加 `App plays audio or streams audio/video using AirPlay` 元素。

如果想要使用苹果的 `PushKit` 或 `CallKit` 服务，你需要将 `Background Modes` 设置为 `Voice over IP`。


