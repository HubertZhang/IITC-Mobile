source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '9.0'

use_frameworks!

abstract_target 'Base' do
    pod 'RxSwift', '~> 5'
    pod 'RxCocoa', '~> 5'
    pod 'Alamofire', '~> 4'
    pod 'RxAlamofire', '~> 5'
    pod 'TPInAppReceipt'
    pod 'WebViewConsole', :git => 'https://github.com/Hubertzhang/WebViewConsole.git'
    
    target 'BaseFramework'
    abstract_target 'Application' do
        pod 'MBProgressHUD'
        pod 'Firebase/Analytics'

        target 'IITC-Mobile' do
            pod 'InAppSettingsKit'
            pod 'Highlightr'
            pod 'RSKGrowingTextView'
        end
        
        target 'ViewInIITC'
    end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
#      config.build_settings['LD_NO_PIE'] = 'NO'
      if target.name.start_with?("Pods-Base-Application")
        puts "Updating #{target.name} to exclude Firebase"
        target.build_configurations.each do |config|
          xcconfig_path = config.base_configuration_reference.real_path
          xcconfig = File.read(xcconfig_path)
          xcconfig.sub!('-framework "FIRAnalyticsConnector"', '')
          xcconfig.sub!('-framework "FirebaseAnalytics"', '')
          xcconfig.sub!('-framework "GoogleAppMeasurement"', '')
          new_xcconfig = xcconfig + 'OTHER_LDFLAGS[sdk=iphone*] = -framework "FIRAnalyticsConnector" -framework "FirebaseAnalytics" -framework "GoogleAppMeasurement"'
          File.open(xcconfig_path, "w") { |file| file << new_xcconfig }
        end
      end
    end
  end

  require 'fileutils'
  FileUtils.cp_r('Pods/Target Support Files/Pods-Base-Application-IITC-Mobile/Pods-Base-Application-IITC-Mobile-acknowledgements.plist', 'IITC-Mobile/UI/Settings.bundle/Acknowledgements.plist', :remove_destination => true)
end

