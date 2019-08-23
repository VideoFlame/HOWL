source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '11.0'

use_frameworks!

pod 'Audiobus', '~> 2.3'
pod 'AudioKit', git: 'https://github.com/dclelland/AudioKit/', branch: 'protonome'
pod 'AudioUnitExtensions', '~> 0.3'
pod 'Bezzy', '~> 1.4'
pod 'MultitouchGestureRecognizer', '~> 2.2'
pod 'Parity', '~> 2.2'
pod 'Persistable', '~> 1.3'
pod 'ProtonomeAudioKitControls', '~> 1.5'
pod 'ProtonomeRoundedViews', '~> 1.2'
pod 'SnapKit', '~> 5.0'

target 'HOWL'

post_install do |installer|
    
    # Set custom build configurations
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            
            # Fix IBDesignables
            config.build_settings['CONFIGURATION_BUILD_DIR'] = '$PODS_CONFIGURATION_BUILD_DIR'
        end
    end
    
    # Write the acknowledgements
    require 'fileutils'
    FileUtils.cp('Pods/Target Support Files/Pods-HOWL/Pods-HOWL-Acknowledgements.plist', 'HOWL/Resources/Settings.bundle/Acknowledgements.plist')
    
end
