Pod::Spec.new do |s|
  s.name         = "SMobiLogger"
  s.version      = "1.0.0"
  s.summary      = "A delightful iOS loging framework"
  s.description  = "SMobiLogger is logger library, which provide logs from iOS device and also provide email logs facility."
  s.homepage     = "https://github.com/zsheikh-systango/SMobiLogger"
  s.license      = "MIT"
  s.author             = { "Zoeb Sheikh" => "zoeb@systango.com" }
  s.platform     = :ios, "7.0"
  #s.source       = { :git => "https://github.com/zsheikh-systango/SMobiLogger.git", :tag => s.version.to_s }
  s.source       = { :git => "https://github.com/zsheikh-systango/SMobiLogger.git", :commit => "eb8a5c5329cfcc704258409f307c0d6fb2100965" }

  s.requires_arc = true
  s.source_files  = "SMobiLogger", "SMobiLogger/**/*.{h,m}"
  s.resources = "SMobiLogger/Resources/*"
  s.vendored_frameworks = "Realm.framework"
  s.dependency 'Realm'
end
