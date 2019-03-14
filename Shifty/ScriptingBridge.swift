//
//  ScriptingBridge.swift
//  Shifty
//
//  Created by Saagar Jha on 1/14/18.
//

import Cocoa
import ScriptingBridge

@objc public protocol SBObjectProtocol: NSObjectProtocol {
    func get() -> Any!
}

@objc public protocol SBApplicationProtocol: SBObjectProtocol {
    func activate()
    var delegate: SBApplicationDelegate! { get set }
    var isRunning: Bool { get }
}

@objc protocol BrowserProtocol: SBApplicationProtocol {
    @objc optional func windows() -> SBElementArray
}

@objc protocol Window: SBObjectProtocol {
	@objc optional var currentTab: Tab { get }
	@objc optional var activeTab: Tab { get }
}

@objc protocol Tab: SBObjectProtocol {
	@objc optional var URL: String { get }
}

extension SBApplication: BrowserProtocol { }
extension SBObject: Window, Tab { }
