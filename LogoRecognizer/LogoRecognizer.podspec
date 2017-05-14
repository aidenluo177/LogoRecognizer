Pod::Spec.new do |s|
  s.name             = 'LogoRecognizer'
  s.version          = "1.0.0"
  s.summary          = 'A framework for detector logo.'
  s.license          = 'MIT'
  s.author           = { "aidenluo" => "aidenluo.me@icloud.com" }

  s.homepage         = 'http://git.oschina.net/aidenluo/logorecognizer'
  s.source           = { :git => "https://git.oschina.net/aidenluo/logorecognizer.git", :tag => s.version.to_s }
  s.platform         = :ios
  s.ios.deployment_target = "8.0"
  s.frameworks       = 'UIKit', 'AVFoundation'
#   s.libraries        = 'icucore', 'z.1.2.5', 'stdc++'

#   s.default_subspecs    = 'XXX'
  s.vendored_frameworks = 'Products/LogoRecognizer.framework'
#   s.dependency 'XXX'    
end