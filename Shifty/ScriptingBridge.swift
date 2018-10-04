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
