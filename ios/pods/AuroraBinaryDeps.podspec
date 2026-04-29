Pod::Spec.new do |s|
  s.name             = 'AuroraBinaryDeps'
  s.version          = '1.0.0'
  s.summary          = 'Binary dependencies for AuroraSwift iOS build'
  s.description      = 'Wraps local xcframework dependencies so Xcode/CocoaPods can resolve them in CI.'
  s.homepage         = 'https://example.com/aurora'
  s.license          = { :type => 'MIT', :text => 'Internal' }
  s.author           = { 'Aurora' => 'dev@aurora.local' }
  s.source           = { :path => '.' }
  s.platform         = :ios, '26.0'
  s.vendored_frameworks = [
    '../../SharedDependencies/libgenericcodegen.xcframework',
    '../../SharedDependencies/libglslang.xcframework',
    '../../SharedDependencies/libmachineindependent.xcframework',
    '../../SharedDependencies/libspirv.xcframework',
    '../../SharedDependencies/MoltenVK.xcframework',
    '../../SharedDependencies/libavcodec.xcframework',
    '../../SharedDependencies/libavformat.xcframework',
    '../../SharedDependencies/libavutil.xcframework',
    '../../SharedDependencies/libavfilter.xcframework',
    '../../SharedDependencies/libswresample.xcframework',
    '../../SharedDependencies/libswscale.xcframework',
  ]
  s.preserve_paths = ['../../SharedDependencies/**/*']
end
