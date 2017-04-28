Pod::Spec.new do |s|
  s.name         = "SMobiLogger"
  s.version      = "1.0.0"
  s.summary      = "A delightful iOS loging framework"
  s.description  = "SMobiLogger is logger library, which provide logs from iOS device and also provide email logs facility."
  s.homepage     = "https://github.com/zsheikh-systango/SMobiLogger"
  s.license      = "MIT"
  s.author             = { "Zoeb Sheikh" => "zoeb@systango.com" }
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/zsheikh-systango/SMobiLogger.git", :tag => "1.0.1" }
  s.source_files  = "SMobiLogger", "SMobiLogger/**/*.{h,m}"
  s.resources = "SMobiLogger/Resources/*"
  s.vendored_frameworks = "Realm.framework"
end
