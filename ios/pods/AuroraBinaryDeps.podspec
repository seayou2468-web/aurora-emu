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
  vendored_frameworks = [
    '../../SharedDependencies/libboostcontext.xcframework',
    '../../SharedDependencies/libboostiostreams.xcframework',
    '../../SharedDependencies/libboostprogramoptions.xcframework',
    '../../SharedDependencies/libboostserialization.xcframework',
    '../../SharedDependencies/libdynarmic.xcframework',
    '../../SharedDependencies/libfmt.xcframework',
    '../../SharedDependencies/libmcl.xcframework',
    '../../SharedDependencies/libenet.xcframework',
    '../../SharedDependencies/libfaad2.xcframework',
    '../../SharedDependencies/libgenericcodegen.xcframework',
    '../../SharedDependencies/libglslang.xcframework',
    '../../SharedDependencies/libmachineindependent.xcframework',
    '../../SharedDependencies/libspirv.xcframework',
    '../../SharedDependencies/libopenal.xcframework',
    '../../SharedDependencies/libopus.xcframework',
    '../../SharedDependencies/SDL3.xcframework',
    '../../SharedDependencies/libsirit.xcframework',
    '../../SharedDependencies/libsoundtouch.xcframework',
    '../../SharedDependencies/libteakra.xcframework',
    '../../SharedDependencies/MoltenVK.xcframework',
    '../../SharedDependencies/libavcodec.xcframework',
    '../../SharedDependencies/libavformat.xcframework',
    '../../SharedDependencies/libavutil.xcframework',
    '../../SharedDependencies/libavfilter.xcframework',
    '../../SharedDependencies/libswresample.xcframework',
    '../../SharedDependencies/libswscale.xcframework',
  ]
  s.vendored_frameworks = vendored_frameworks
  s.preserve_paths = ['../../SharedDependencies/**/*']

  header_search_paths = vendored_frameworks.map do |framework|
    "\"$(PODS_TARGET_SRCROOT)/#{framework}/**/Headers\""
  end

  s.pod_target_xcconfig = {
    'HEADER_SEARCH_PATHS' => '$(inherited) ' + header_search_paths.join(' '),
    'SYSTEM_HEADER_SEARCH_PATHS' => '$(inherited) ' + header_search_paths.join(' ')
  }
end
