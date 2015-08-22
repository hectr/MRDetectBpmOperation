
Pod::Spec.new do |s|
  s.name             = "MRDetectBpmOperation"
  s.version          = "0.0.2"
  s.summary          = "Subclass of NSOperation for detecting BPM using SoundTouch"

  s.description      = <<-DESC
                       `MRDetectBpmOperation` is a concrete subclass of `NSOperation` that uses the **SoundTouch Audio Processing Library** for detecting BPM of a media resource.
                       DESC

  s.homepage         = "https://github.com/hectr/MRDetectBpmOperation"
  s.license          = 'MIT'
  s.author           = { "hectr" => "h@mrhector.me" }
  s.source           = { :git => "https://github.com/hectr/MRDetectBpmOperation.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/hectormarquesra'

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.default_subspec = 'Operation'

  s.subspec 'Operation' do |op|
    op.public_header_files = 'MRDetectBpmOperation/*.h'
    op.source_files = 'MRDetectBpmOperation'
    op.dependency 'MROperation', '~> 0.0.1'
    op.dependency 'MRDetectBpmOperation/SoundTouch'

  end

  s.subspec 'SoundTouch' do |st|
    st.public_header_files = 'external/soundtouch-1.9.0/include/*.h'
    st.source_files = 'external/soundtouch-1.9.0/include/', 'external/soundtouch-1.9.0/source/SoundTouch/'
    st.xcconfig = { "GCC_PREPROCESSOR_DEFINITIONS" => '$(inherited) ANDROID=1 SOUNDTOUCH_INTEGER_SAMPLES=1' }
  end

end
