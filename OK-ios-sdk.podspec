Pod::Spec.new do |s|
  s.name         = "OK-ios-sdk"
  s.version      = "1.0"
  s.summary      = "iOS library for working with Odnoklassniki API."
  s.homepage     = "https://github.com/apiok/ok-ios-sdk"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "Ivanov Denis" => "denis.ivanov@odnoklassniki.ru" }
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/apiok/ok-ios-sdk.git", :branch => "master" }
  s.source_files = "OKSdk", "OKSdk/**/*.{h,m}"
  s.public_header_files = "OKSdk/**/*.h"
  s.requires_arc = true
end
