Pod::Spec.new do |s|
    s.name             = 'AgoraChatCallKit'
    s.version          = '1.0.0'
    s.summary          = 'A Ease Call UIKit'
    s.description      = <<-DESC
        ‘‘一套使用环信IM以及声网SDK实现音视频呼叫的UI库，可以实现单人语音、视频呼叫，以及多人音视频通话’’
    DESC
    s.homepage = 'https://www.easemob.com'
    s.license          = 'MIT'
    s.author           = { 'easemob' => 'dev@easemob.com' }
    s.source           = { :git => 'https://github.com/easemob/easecallkitui-ios.git', :tag => s.version.to_s }
    s.frameworks = 'UIKit'
    s.libraries = 'stdc++'
    s.ios.deployment_target = '10.0'
    s.source_files = 'Classes/**/*.{h,m,strings}'
    s.public_header_files = [
      'Classes/Process/EaseCallManager.h',
      'Classes/Utils/EaseCallDefine.h',
      'Classes/Utils/EaseCallError.h',
      'Classes/Store/EaseCallConfig.h',
      'Classes/AgoraChatCallKit.h',
    ]
    s.resources = 'Assets/EaseCall.bundle'
    s.dependency 'Agora_Chat_iOS'
    s.dependency 'Masonry'
    s.dependency 'AgoraRtcEngine_iOS', '3.6.1.2'
    s.dependency 'SDWebImage'
end
