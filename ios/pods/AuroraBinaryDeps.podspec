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
    '../../Dependicies/SDL3.xcframework',
    '../../Dependicies/FLAC.xcframework',
    '../../Dependicies/libopus.xcframework',
    '../../Dependicies/ogg.xcframework',
    '../../Dependicies/MoltenVK.xcframework',
    '../../Dependicies/libglslang.xcframework',
    '../../Dependicies/libdynarmic.xcframework',
    '../../Dependicies/libsirit.xcframework',
    '../../Dependicies/libmcl.xcframework',
    '../../Dependicies/libteakra.xcframework',
    '../../Dependicies/libsoundtouch.xcframework',
    '../../Dependicies/libfmt.xcframework',
    '../../Dependicies/libenet.xcframework',
    '../../Dependicies/libopenal.xcframework',
    '../../Dependicies/libboostprogramoptions.xcframework',
    '../../Dependicies/libboostserialization.xcframework',
    '../../Dependicies/libboostcontext.xcframework',
    '../../Dependicies/libboostiostreams.xcframework',
    '../../Dependicies/libgenericcodegen.xcframework',
    '../../Dependicies/libmachineindependent.xcframework',
    '../../Dependicies/libavcodec.xcframework',
    '../../Dependicies/libavformat.xcframework',
    '../../Dependicies/libavutil.xcframework',
    '../../Dependicies/libavfilter.xcframework',
    '../../Dependicies/libswresample.xcframework',
    '../../Dependicies/libswscale.xcframework',
    '../../Dependicies/libfaad2.xcframework'
  ]
  s.preserve_paths = ['../../Dependicies/**/*']
end
