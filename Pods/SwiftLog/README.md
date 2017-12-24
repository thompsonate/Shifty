SwiftLog
========

Simple and easy logging in Swift.

## Features

- Super simple. Only one method to log.
- Rolled logs.
- Simple concise codebase at just at barely two hundred LOC.

First thing is to import the framework. See the Installation instructions on how to add the framework to your project.

```swift
//iOS
import SwiftLog
//OS X
import SwiftLogOSX
```

## Example

SwiftLog can be used right out of the box with no configuration, simply call the logging function.

```swift
logw("write to the log!")
```

That will create a log file in the proper directory on both OS X and iOS.

OS X log files will be created in the OS X log directory (found under: /Library/Logs). The iOS log files will be created in your apps document directory under a folder called Logs.

## Configuration

There are a few configurable options in SwiftLog.

```swift
//This writes to the log
logw("write to the log!")

//Set the name of the log files
Log.logger.name = "test" //default is "logwile"

//Set the max size of each log file. Value is in KB
Log.logger.maxFileSize = 2048 //default is 1024

//Set the max number of logs files that will be kept
Log.logger.name = 8 //default is 4

//Set the directory in which the logs files will be written
Log.logger.directory = "/Library/somefolder" //default is the standard logging directory for each platform.

```

## Installation

### Cocoapods

### [CocoaPods](http://cocoapods.org/)
At this time, Cocoapods support for Swift frameworks is supported in a [pre-release](http://blog.cocoapods.org/Pod-Authors-Guide-to-CocoaPods-Frameworks/).

To use SwiftLog in your project add the following 'Podfile' to your project

    source 'https://github.com/CocoaPods/Specs.git'

    xcodeproj 'YourProjectName.xcodeproj'
    platform :ios, '8.0'

    pod 'SwiftLog', :git => "https://github.com/daltoniam/SwiftLog.git", :tag => "0.9.1"

    target 'YourProjectNameTests' do
        pod 'SwiftLog', :git => "https://github.com/daltoniam/SwiftLog.git", :tag => "0.9.1"
    end

Then run:

    pod install

#### Updating the Cocoapod
You can validate SwiftLog.podspec using:

    pod spec lint SwiftLog.podspec

This should be tested with a sample project before releasing it. This can be done by adding the following line to a ```Podfile```:

    pod 'SwiftLog', :git => 'https://github.com/username/SwiftLog.git'

Then run:

    pod install

If all goes well you are ready to release. First, create a tag and push:

    git tag 'version'
    git push --tags

Once the tag is available you can send the library to the Specs repo. For this you'll have to follow the instructions in [Getting Setup with Trunk](http://guides.cocoapods.org/making/getting-setup-with-trunk.html).

    pod trunk push SwiftLog.podspec

### Carthage

Check out the [Carthage](https://github.com/Carthage/Carthage) docs on how to add a install. The `SwiftLog` framework is already setup with shared schemes.

[Carthage Install](https://github.com/Carthage/Carthage#adding-frameworks-to-an-application)

### Rogue

First see the [installation docs](https://github.com/acmacalister/Rogue) for how to install Rogue.

To install SwiftLog run the command below in the directory you created the rogue file.

```
rogue add https://github.com/daltoniam/SwiftLog
```

Next open the `libs` folder and add the `SwiftLog.xcodeproj` to your Xcode project. Once that is complete, in your "Build Phases" add the `SwiftLog.framework` to your "Link Binary with Libraries" phase. Make sure to add the `libs` folder to your `.gitignore` file.

### Other

Simply grab the framework (either via git submodule or another package manager).

Add the `SwiftLog.xcodeproj` to your Xcode project. Once that is complete, in your "Build Phases" add the `SwiftLog.framework` to your "Link Binary with Libraries" phase.

### Add Copy Frameworks Phase

If you are running this in an OSX app or on a physical iOS device you will need to make sure you add the `SwiftLog.framework` or `SwiftLogOSX.framework` to be included in your app bundle. To do this, in Xcode, navigate to the target configuration window by clicking on the blue project icon, and selecting the application target under the "Targets" heading in the sidebar. In the tab bar at the top of that window, open the "Build Phases" panel. Expand the "Link Binary with Libraries" group, and add `SwiftLog.framework` or `SwiftLogOSX.framework` depending on if you are building an iOS or OSX app. Click on the + button at the top left of the panel and select "New Copy Files Phase". Rename this new phase to "Copy Frameworks", set the "Destination" to "Frameworks", and add `SwiftLog.framework` or `SwiftLogOSX.framework` respectively.

## TODOs

- [ ] Complete Docs
- [ ] Add Unit Tests

## License

SwiftLog is licensed under the MIT License.

## Contact

### Dalton Cherry
* https://github.com/daltoniam
* http://twitter.com/daltoniam
* http://daltoniam.com
