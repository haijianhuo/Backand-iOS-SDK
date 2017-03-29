Pod::Spec.new do |s|
  s.name         = "HHBackand-iOS-SDK"
  s.module_name  = 'Backand'
  s.version      = "0.1.1"
  s.summary      = "A Backand SDK for iOS."
  s.description  = <<-DESC
                  A simple SDK for interacting with the Backand REST API for iOS, written in Swift.
                   DESC
  s.homepage     = "https://github.com/haijianhuo/HHBackand-iOS-SDK"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { "Haijian Huo" => "haihuo@yahoo.com" }
  s.source       = { :git => "https://github.com/haijianhuo/HHBackand-iOS-SDK.git", :tag => "#{s.version}" }

  s.platform     = :ios, "8.0"

  s.source_files = 'Source/**'
  s.framework    = "Foundation"
  s.dependency 'Alamofire', '~> 4.4.0'
  s.dependency 'SwiftKeychainWrapper', '~> 3.0.1'
end
