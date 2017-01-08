source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '9.0'

use_frameworks!

abstract_target 'Base' do
    pod 'RxSwift', '~> 3'
    pod 'Alamofire', '~> 4'
    pod 'RxAlamofire', '~> 3'
    
    target 'BaseFramework'
    abstract_target 'Application' do
        pod 'MBProgressHUD'
        pod 'Google/Analytics'
#        pod 'Google/SignIn'

        target 'IITC-Mobile' do
            pod 'InAppSettingsKit'
        end
        
        target 'ViewInIITC'
    end
end
