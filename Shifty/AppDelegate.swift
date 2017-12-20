//
//  AppDelegate.swift
//  Shifty
//
//  Created by Nate Thompson on 5/3/17.
//
//

import Cocoa
import ServiceManagement
import Fabric
import Crashlytics
import MASPreferences_Shifty
import AXSwift

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let prefs = UserDefaults.standard
    @IBOutlet weak var statusMenu: NSMenu!
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    var statusItemClicked: (() -> Void)?
    
    lazy var preferenceWindowController: PrefWindowController = {
        return PrefWindowController(
            viewControllers: [
                PrefGeneralViewController(),
                PrefShortcutsViewController(),
                PrefAboutViewController()],
            title: NSLocalizedString("prefs.title", comment: "Preferences"))
    }()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        UserDefaults.standard.register(defaults: ["NSApplicationCrashOnExceptions": true])
        Fabric.with([Crashlytics.self])
        Event.appLaunched.record()
                
        if !ProcessInfo().isOperatingSystemAtLeast(OperatingSystemVersion(majorVersion: 10, minorVersion: 12, patchVersion: 4)) {
            Event.oldMacOSVersion(version: ProcessInfo().operatingSystemVersionString).record()
            let alert: NSAlert = NSAlert()
            alert.messageText = NSLocalizedString("alert.version_message", comment: "This version of macOS does not support Night Shift")
            alert.informativeText = NSLocalizedString("alert.version_informative", comment: "Update your Mac to version 10.12.4 or higher to use Shifty.")
            alert.alertStyle = NSAlert.Style.warning
            alert.addButton(withTitle: NSLocalizedString("general.ok", comment: "OK"))
            alert.runModal()
            
            NSApplication.shared.terminate(self)
        }
        
        if !CBBlueLightClient.supportsBlueLightReduction() {
            Event.unsupportedHardware.record()
            let alert: NSAlert = NSAlert()
            alert.messageText = NSLocalizedString("alert.hardware_message", comment: "Your Mac does not support Night Shift")
            alert.informativeText = NSLocalizedString("alert.hardware_informative", comment: "A newer Mac is required to use Shifty.")
            alert.alertStyle = NSAlert.Style.warning
            alert.addButton(withTitle: NSLocalizedString("general.ok", comment: "OK"))
            alert.runModal()
            
            NSApplication.shared.terminate(self)
        }
        
        let launcherAppIdentifier = "io.natethompson.ShiftyHelper"
        
        var startedAtLogin = false
        for app in NSWorkspace.shared.runningApplications {
            if app.bundleIdentifier == launcherAppIdentifier {
                startedAtLogin = true
            }
        }
        
        if startedAtLogin {
            DistributedNotificationCenter.default().post(name: Notification.Name("killme"), object: Bundle.main.bundleIdentifier!)
        }
        
        //Show alert if accessibility permissions have been revoked while app is not running
        if UserDefaults.standard.bool(forKey: Keys.isWebsiteControlEnabled) &&
            !UIElement.isProcessTrusted(withPrompt: false) {
            let alert: NSAlert = NSAlert()
            alert.messageText = NSLocalizedString("alert.accessibility_disabled_message", comment: "Accessibility permissions for Shifty have been disabled")
            alert.informativeText = NSLocalizedString("alert.accessibility_informative", comment: "Grant access to Shifty in Security & Privacy preferences, located in System Preferences.")
            alert.alertStyle = NSAlert.Style.warning
            alert.addButton(withTitle: NSLocalizedString("alert.open_preferences", comment: "Open System Preferences"))
            alert.addButton(withTitle: NSLocalizedString("alert.not_now", comment: "Not now"))
            if alert.runModal() == .alertFirstButtonReturn {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
            } else {
                UserDefaults.standard.set(false, forKey: Keys.isWebsiteControlEnabled)
            }
        }
    
        setMenuBarIcon()
        setStatusToggle()
    }
    
    func setMenuBarIcon() {
        var icon: NSImage
        if UserDefaults.standard.bool(forKey: Keys.isIconSwitchingEnabled) {
            if !BLClient.isNightShiftEnabled {
                icon = #imageLiteral(resourceName: "sunOpenIcon")
            } else {
                icon = #imageLiteral(resourceName: "shiftyMenuIcon")
            }
        } else {
            icon = #imageLiteral(resourceName: "shiftyMenuIcon")
        }
        icon.isTemplate = true
        DispatchQueue.main.async {
            self.statusItem.button?.image = icon
        }
    }
    
    func setStatusToggle() {
        if prefs.bool(forKey: Keys.isStatusToggleEnabled) {
            statusItem.menu = nil
            if let button = statusItem.button {
                button.action = #selector(self.statusBarButtonClicked(sender:))
                button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            }
        } else {
            statusItem.menu = statusMenu
        }
    }
    
    @objc func statusBarButtonClicked(sender: NSStatusBarButton) {
        let event = NSApp.currentEvent!
        
        if event.type == NSEvent.EventType.rightMouseUp || event.modifierFlags.contains(.control)  {
            statusItem.menu = statusMenu
            statusItem.popUpMenu(statusMenu)
            statusItem.menu = nil
        } else {
            statusItemClicked?()
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

