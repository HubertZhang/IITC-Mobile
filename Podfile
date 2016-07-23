source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'

use_frameworks!

abstract_target 'Base' do
    pod 'RxSwift'
    pod 'RxCocoa'
    pod 'RxBlocking'
    pod 'Alamofire'
    pod 'RxAlamofire'
    
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
