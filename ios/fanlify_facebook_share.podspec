Pod::Spec.new do |s|
  s.name             = 'fanlify_facebook_share'
  s.version          = '0.1.0'
  s.summary          = 'Native Facebook link share plugin for Fanlify.'
  s.description      = 'Opens the native Facebook Share Dialog with a public link URL.'
  s.homepage         = 'https://github.com/KamOus-dotcom/fanlify_facebook_share'
  s.license          = { :type => 'MIT' }
  s.author           = { 'Fanlify' => 'support@fanlify.info' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'FBSDKCoreKit'
  s.dependency 'FBSDKShareKit'
  s.platform = :ios, '13.0'
  s.static_framework = true

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES'
  }
end
