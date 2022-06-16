# Getting Started with iOS AgoraChatCallKit

## Introduction     

Built upon Agora RTC, `AgoraChatCallKit` is a UI library that uses Agora Chat as the signaling channel. This library provides APIs to implement one-to-one audio and video calls and multi-party calls.

## Run through the demo 

`AgoraChatCallKit` is integrated in the Agora Chat demo. You can download the iOS demo from our [open-source repository](https://github.com/AgoraIO-Usecase/AgoraChat-ios) on Github.

### Install the required SDKs and `AgoraChatCallKit`

The source code of the demo does not involve SDKs and `AgoraChatCallKit`. You can directly import them or install them using CocoaPods.

Install CocoaPods if you have not. For details, see [Getting Started with CocoaPods](https://guides.cocoapods.org/using/getting-started.html).

If you use CocoaPods for installation, first navigate to the directory where `podfile` resides and run the following command in the Terminal:

```
pod install
```

### Run the demo

After the required SDKs and `AgoraChatCallKit` are installed, open the workspace `AgoraChat.xcworkspace` on Xcode and connect to the mobile phone to run the demo.

## Prerequisites

Before proceeding, ensure that your development environment meets the following requirements:

- A device running iOS 10.0 or above.
- Agora Chat is integrated to provide basic functions like login, contact, group, and conversation.
- An Agora app (https://docs.agora.io/cn/Video/run_demo_video_call_ios?platform=iOS#1-创建-agora-项目) is created.
- Token authentication is activated. You need to implement your own [App Server](https://github.com/easemob/easemob-im-app).
- A valid Agora Chat account.

## Integrate AgoraChatCallKit`

Follow these steps to integrate `AgoraChatCallKit`:

1. The user calls the API to initialize `AgoraChatCallKit`.
2. The caller calls the API to initiate a call. The call page appears.
3. The callee chooses whether to answer the call on the call request page.
4. The caller or callee click the Hung Up button on the page to end the call.

### Import `AgoraChatCallKit`

`AgoraChatCallKit` depends on the `Agora_Chat_iOS`, `Masonry`, `AgoraRtcEngine_iOS/RtcBasic`, and `SDWebImage` libraries. Therefore, you also need to import these libraries to the project, for example by using CocoaPods.

As `AgoraChatCallKit` is a dynamic library, you must add use_frameworks! to `podfile`.

`AgoraChatCallKit` can be imported manually or using CocoaPods.

#### Import `AgoraChatCallKit` by using CocoaPods

In the Terminal, navigate to the root directory of the project and run the `pod init` command to generate the `Podfile` file in the project folder.

Open the `Podfile` file and modify the file content as follows. Remember to replace `AppName` with your own app name.

```
use_frameworks!
target 'AppName' do
    pod 'AgoraChatCallKit'
end
```

In the Terminal, run the `pod update` command to update the version of the local `AgoraChatCallKit`. 

Run the `pod install` command to install `AgoraChatCallKit`. If the installation succeeds, the message `Pod installation complete!` is displayed in the Terminal. Then the `xcworkspace` file is generated in the project folder.


####  Import `AgoraChatCallKit` manually

1. Copy `AgoraChatCallKit.framework` downloaded when you run through the demo, to the project folder.

2. On Xcode, choose **Project Settings > General**, drag `AgoraChatCallKit.framework` to the project, and set `AgoraChatCallKit.framework` to `Embed & Sign` under `Frameworks`, `libraries`, and `Embedded Content`.

### Add permissions

The app requires permissions of audio/video devices and cameras. In the `info.plist` file, click `+` to add the following information:

| Key | Type | Value|  
| ---- | ---- | ---- |
| Privacy - Microphone Usage Description | String | The description, like "Agora Chat needs to use your microphone." |  
| Privacy - Camera Usage Description | String | The description, like "Agora Chat needs to use your camera."  |  

If you hope to run `AgoraChatCallKit` in the background, you also need to add the permission to play audios and videos in the background: 

1. Click `+` to add `Required background modes` to `info.plist`, with `Type` set as `Array`. 

2. Add the `App plays audio or streams audio/video using AirPlay` element under `Array`. 

If you want to use Apple's `PushKit` or `CallKit` service, you also need to select `Voice over IP` for `Background Modes`. 
