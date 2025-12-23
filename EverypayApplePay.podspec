#
# Be sure to run `pod lib lint EverypayApplePay.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'EverypayApplePay'
  s.version          = '0.1.0'
  s.summary          = 'Apple Pay for Everypay'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Apple Pay wrapper for Everypay users.
                       DESC

  s.homepage         = 'https://github.com/Märt Saarmets/EverypayApplePay'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Märt Saarmets' => 'mart.saarmets@datanor.ee' }
  s.source           = { :git => 'https://github.com/Märt Saarmets/EverypayApplePay.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '12.4'

  s.source_files = 'EverypayApplePay/Classes/**/*'
  s.public_header_files = 'EverypayApplePay/Classes/**/*.h'
  s.frameworks = 'UIKit', 'PassKit'

  # s.resource_bundles = {
  #   'EverypayApplePay' => ['EverypayApplePay/Assets/*.png']
  # }

  # s.dependency 'AFNetworking', '~> 2.3'
end
