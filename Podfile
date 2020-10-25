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
      config.build_settings['LD_NO_PIE'] = 'NO'
      if config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] == '8.0'
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '9.0'
                 end
    end
  end
  
  require 'fileutils'
  FileUtils.cp_r('Pods/Target Support Files/Pods-Base-Application-IITC-Mobile/Pods-Base-Application-IITC-Mobile-acknowledgements.plist', 'IITC-Mobile/UI/Settings.bundle/Acknowledgements.plist', :remove_destination => true)
end
