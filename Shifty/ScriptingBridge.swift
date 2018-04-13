//
//  ScriptingBridge.swift
//  Shifty
//
//  Created by Saagar Jha on 1/14/18.
//

import Cocoa
import ScriptingBridge

@objc protocol Browser {
	@objc optional var windows: SBElementArray { get }
}

@objc protocol Window {
	@objc optional var currentTab: Tab { get }
	@objc optional var activeTab: Tab { get }
}

@objc protocol Tab {
	@objc optional var URL: String { get }
}

extension SBApplication: Browser {
    convenience init?(_ application: NSRunningApplication) {
        self.init(processIdentifier: application.processIdentifier)
    }
}
extension SBObject: Window, Tab { }

//@objc protocol Browser {
//	var windows: [Window] { get }
//}
//
//protocol Window {
//	var currentTab: Tab { get }
//}
//
//protocol Tab {
//	var URL: String { get }
//}
//
//// MARK: - Safari Scripting Bridge "header"
//
//@objc protocol SafariApplication: Browser {
//	@objc optional var windows: SBElementArray { get }
//}
//
//@objc protocol SafariWindow {
//	@objc optional var currentTab: SafariTab { get }
//}
//
//@objc protocol SafariTab {
//	@objc optional var URL: String { get }
//}
//
//// MARK: - Chrome Scripting Bridge "header"
//
//@objc protocol ChromeApplication {
//	@objc optional var windows: SBElementArray { get }
//}
//
//@objc protocol ChromeWindow {
//	@objc optional var activeTab: ChromeTab { get }
//}
//
//extension ChromeWindow {
//	@objc optional var currentTab: ChromeTab {
//		return activeTab
//	}
//}
//
//@objc protocol ChromeTab {
//	@objc optional var URL: String { get }
//}
//
//extension SBApplication: SafariApplication, ChromeApplication { }
//extension SBObject: SafariWindow, SafariTab, ChromeWindow, ChromeTab { }

//@objcMembers class Foo: NSObject {
//	var windows: [Window]? {
//		return nil
//	}
//	var currentTab: Tab? {
//		return nil
//	}
//	var activeTab: Tab? {
//		return nil
//	}
//	func URL() -> String? {
//		return nil
//	}
//}
//
//@objc class Browser: SBApplication {
//	var windows: [Window]? {
//		return (perform(Selector(("windows"))).takeUnretainedValue() as? SBElementArray)?.flatMap {
//			return $0 as? Window
//		}
//	}
//}
//
//@objc class Window: SBObject {
//	var currentTab: Tab? {
//		let selector: Selector
//		if let c = NSClassFromString("SafariWindow"),
//			isKind(of: c) {
//				selector = Selector(("currentTab"))
//		} else if let c = NSClassFromString("ChromeWindow"),
//			isKind(of: c) {
//				selector = Selector(("activeTab"))
//		} else {
//			return nil
//		}
//		return perform(selector).takeUnretainedValue() as? Tab
//	}
//}
//
//@objc class Tab: SBObject {
//	var URL: String? {
//		return perform(Selector(("URL"))).takeUnretainedValue() as? String
//	}
//}
//

//protocol SwiftBrowser {
//	associatedtype Sequence: Swift.Sequence where Sequence.Element == Window
//	var _windows: Sequence { get }
//}
//
//protocol ObjcBrowser {
//	var windows: SBElementArray { get }
//}
//
//typealias Browser = SwiftBrowser & ObjcBrowser
//
//extension SwiftBrowser where Self: ObjcBrowser {
//	var _windows: [Window] {
//		return windows.flatMap {
//			$0 as? Window
//		}
//	}
//}
//
//protocol Window {
//	var currentTab: Tab { get }
//}
//
//@objc protocol Tab {
//}
//
//extension SafariApplication: Browser { }
//
//extension SafariTab: Tab {
//}
//
//extension SafariWindow: Window {
////	var _currentTab: Tab {
////		return currentTab
////	}
//
//}
//
//extension ChromeApplication: Browser { }
//
