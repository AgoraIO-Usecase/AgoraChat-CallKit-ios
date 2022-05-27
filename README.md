# iOS 端 AgoraChatCallKit 使用指南

## 简介
`AgoraChatCallKit` 是一套基于声网音视频服务，使用 Agora Chat 作为信令通道的开源音视频 UI 库。该库提供一对一语音通话、视频通话，以及多人会议的功能接口。

## 跑通 Demo 

`AgoraChatCallKit` 集成在声网提供的开源 IM Demo 中，你可以通过进入 [AgoraChat Demo 下载页面](https://www.easemob.com/download/im|)，选择 iOS 端 Demo 下载，或直接进入 Github 开源网站 https://github.com/AgoraIO-Usecase/AgoraChat-ios 下载。  

### 安装 SDK 与 `AgoraChatCallKit`

Demo 源码中不涉及 SDK 和 `AgoraChatCallKit`，你可以通过直接导入或通过 CocoaPods 安装。

如果当前系统上未安装 CocoaPods，需参考 [CocoaPods 安装说明](https://guides.cocoapods.org/using/getting-started.html)进行安装。

使用 CocoaPods 安装需要进入 `podfile` 文件所在目录，然后在终端执行如下命令：

```
pod install
```

### 运行 demo

安装完成 SDK 与 `AgoraChatCallKit` 后，在 Xcode 打开工作空间 `AgoraChat.xcworkspace`，连接手机，即可运行 demo。

## 前提条件

开始前，请确保你的开发环境满足以下条件：

* iOS 10.0 或以上版本的设备  
* 创建 [声网应用](https://docs.agora.io/cn/Video/run_demo_video_call_ios?platform=iOS#1-创建-agora-项目)；      
* 已完成 Agora Chat 的基本功能集成，包括登录、好友、群组和会话等；  
* 开通声网 token 验证时。用户需实现自己的 [App Server](https://github.com/easemob/easemob-im-app)；  
* 有效的 Agora Chat 账户。  

## 快速集成

使用 AgoraChatCallKit 库完成音视频通话的基本流程如下：  
1. 用户调用 AgoraChatCallKit 库初始化接口；  
2. 主叫方调用发起通话邀请接口，自动进入通话页面；  
3. 被叫方自动弹出通话请求页面，在 UI 界面选择接听，进入通话；  
4. 结束通话时，点击 UI 界面挂断按钮。  

### 导入`AgoraChatCallKit`库
`AgoraChatCallKit`UI 库依赖于 `Agora_Chat_iOS`、`Masonry`、`AgoraRtcEngine_iOS/RtcBasic` 和 `SDWebImage` 库，导入该 UI 库时需要同步导入工程，依赖库可通过 CocoaPods 导入。
`AgoraChatCallKit`是动态库，在 podfile 中必须加入 use_frameworks!。
`AgoraChatCallKit`库可通过手动导入，也可利用 CocoaPods 导入。

#### 使用 CocoaPods 导入 AgoraChatCallKit
在`Terminal`里进入项目根目录，并运行`pod init`命令。项目文件夹下会生成一个`Podfile`文本文件。  
打开`Podfile`文件，修改文件为如下内容。注意将`AppName`替换为你的app名称。
```
use_frameworks!
target 'AppName' do
    pod 'AgoraChatCallKit'
end
```
在`Terminal`内运行 pod update 命令更新本地库版本。
运行`pod install`命令安装`AgoraChatCallKit`UI库。成功安装后，`Terminal`中会显示`Pod installation complete!`，此时项目文件夹下会生成一个`xcworkspace`文件。
打开新生成的`xcworkspace`文件，连接手机，运行demo。

#### 手动导入 AgoraChatCallKit

将在跑通 Demo 阶段下载的`AgoraChatCallKit.framework`复制到项目工程目录下；
打开`Xcode`，选择工程设置 > Genaral 菜单，将`AgoraChatCallKit.framework`拖拽到工程下，在`Frameworks`、`libraries`和`Embedded Content`中设置`AgoraChatCallKit.framework`为`Embed & Sign`。

### 添加权限
应用需要音频设备及摄像头权限。在`info.plist`文件中，点击`+`图标，添加如下信息：

| Key | Type | Value|  
| ---- | ---- | ---- |
| Privacy - Microphone Usage Description | String | 描述信息，如“环信需要使用您的麦克风”。 |  
| Privacy - Camera Usage Description | String | 描述信息，如“环信需要使用您的摄像头” 。 |  

如果希望在后台运行，还需要添加后台运行音视频权限，在`info.plist`文件中，点击`+`图标，添加`Required background modes`，`Type`为`Array`，在`Array`下添加元素`App plays audio or streams audio/video using AirPlay`。  
如果要使用苹果的`PushKit`以及`CallKit`服务，还需要在`Background Modes`下勾选`Voice over IP`。
