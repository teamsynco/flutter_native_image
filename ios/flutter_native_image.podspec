#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'flutter_native_image'
  s.version          = '0.0.1'
  s.summary          = 'Image compression and manipulation plugin for Flutter.'
  s.description      = <<-DESC
A Flutter plugin for compressing, cropping, and retrieving image properties natively on iOS.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }

  s.source_files     = 'Classes/**/*.{h,m,swift}'
  s.public_header_files = 'Classes/**/*.h'

  s.dependency 'Flutter'
  s.ios.deployment_target = '9.0'
  s.swift_version = '5.0'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES'
  }
end
