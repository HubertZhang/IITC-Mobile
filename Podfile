source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '9.0'

use_frameworks!

abstract_target 'Base' do
    pod 'RxSwift', '~> 4'
    pod 'Alamofire', '~> 4'
    pod 'RxAlamofire', '~> 4'
    
    target 'BaseFramework'
    abstract_target 'Application' do
        pod 'MBProgressHUD'
        pod 'Firebase/Core'

        target 'IITC-Mobile' do
            pod 'InAppSettingsKit'
            pod 'Highlightr'
            pod 'WBWebViewConsole', :git => 'https://github.com/Hubertzhang/WBWebViewConsole.git', :branch => 'table'
        end
        
        target 'ViewInIITC'
    end
end
