Pod::Spec.new do |s|
    s.name             = 'AgoraChatCallKit'
    s.version          = '1.0.0'
    s.summary          = 'A AgoraChat Call UIKit'
    s.description      = <<-DESC
        ‘‘AgoraChatCallKit is a UI library that implements audio and video calls by using Agora Chat and Agora RTC. Using this SDK, you can make one-to-one audio and video calls and multi-party audio and video calls.’’
    DESC
    s.homepage = 'https://www.easemob.com'
    s.license          = 'MIT'
    s.author           = { 'easemob' => 'dev@easemob.com' }
    s.source           = { :git => 'https://github.com/374139544/AgoraChatCallKit.git', :tag => s.version.to_s }
    s.frameworks = 'UIKit'
    s.libraries = 'stdc++'
    s.ios.deployment_target = '10.0'
    s.source_files = 'Classes/**/*.{h,m}'
    s.public_header_files = [
      'Classes/Process/AgoraChatCallManager.h',
      'Classes/Utils/AgoraChatCallDefine.h',
      'Classes/Utils/AgoraChatCallError.h',
      'Classes/Store/AgoraChatCallConfig.h',
      'Classes/AgoraChatCallKit.h',
    ]
    s.static_framework = true
    s.resource_bundle = {
      'AgoraChatCallKit' => [
        'Assets/AgoraChatCallKit.xcassets',
        'Assets/music.mp3',
        'Classes/*.lproj'
      ]
    }
    s.dependency 'Agora_Chat_iOS'
    s.dependency 'Masonry'
    s.dependency 'AgoraRtcEngine_iOS/RtcBasic','3.6.3'
    s.dependency 'SDWebImage'
end
