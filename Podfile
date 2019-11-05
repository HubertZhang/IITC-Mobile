source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '9.0'

use_frameworks!

abstract_target 'Base' do
    pod 'RxSwift', '~> 5'
    pod 'Alamofire', '~> 4'
    pod 'RxAlamofire', '~> 5'
    pod 'TPInAppReceipt'
    
    target 'BaseFramework'
    abstract_target 'Application' do
        pod 'MBProgressHUD'
        pod 'Firebase/Core'

        target 'IITC-Mobile' do
            pod 'InAppSettingsKit'
            pod 'Highlightr'
            pod 'RSKGrowingTextView'
            pod 'WBWebViewConsole', :git => 'https://github.com/Hubertzhang/WBWebViewConsole.git', :branch => 'table'
        end
        
        target 'ViewInIITC'
    end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['LD_NO_PIE'] = 'NO'
    end
  end
end
