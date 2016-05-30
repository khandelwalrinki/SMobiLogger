Pod::Spec.new do |s|
  s.name         = "SMobiLogger"
  s.version      = "0.0.1"
  s.summary      = "Provide logs from iOS device"
  s.description  = <<-DESC
                   SMobiLogger is logger library, which provide logs from iOS device and also provide email logs facility.
DESC
  s.homepage     = "https://github.com/zsheikh-systango/SMobiLogger"
  s.license      = { :type => "BSD", :file => "LICENSE" }
  s.author             = { "Zoeb Sheikh" => "zsheikh@isystango.com" }
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/zsheikh-systango/SMobiLogger.git", :tag => "1.0.0" }
  s.source_files  = "SMobiLogger"
  s.exclude_files = "Classes/Exclude"
end
