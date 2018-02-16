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
import SwiftLog

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

    var setupWindow: NSWindow!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        UserDefaults.standard.register(defaults: ["NSApplicationCrashOnExceptions": true])
        Fabric.with([Crashlytics.self])
        Event.appLaunched.record()

        logw("")
        logw("App launched")
        logw("macOS \(ProcessInfo().operatingSystemVersionString)")
        logw("Shifty Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")")

        if !ProcessInfo().isOperatingSystemAtLeast(OperatingSystemVersion(majorVersion: 10, minorVersion: 12, patchVersion: 4)) {
            Event.oldMacOSVersion(version: ProcessInfo().operatingSystemVersionString).record()
            logw("Operating system version not supported")
            NSApplication.shared.activate(ignoringOtherApps: true)

            let alert: NSAlert = NSAlert()
            alert.messageText = NSLocalizedString("alert.version_message", comment: "This version of macOS does not support Night Shift")
            alert.informativeText = NSLocalizedString("alert.version_informative", comment: "Update your Mac to version 10.12.4 or higher to use Shifty.")
            alert.alertStyle = NSAlert.Style.warning
            alert.addButton(withTitle: NSLocalizedString("general.ok", comment: "OK"))
            alert.runModal()

            NSApplication.shared.terminate(self)
        }

        if !NightShiftManager.supportsNightShift {
            Event.unsupportedHardware.record()
            logw("System does not support Night Shift")
            NSApplication.shared.activate(ignoringOtherApps: true)

            let alert: NSAlert = NSAlert()
            alert.messageText = NSLocalizedString("alert.hardware_message", comment: "Your Mac does not support Night Shift")
            alert.informativeText = NSLocalizedString("alert.hardware_informative", comment: "A newer Mac is required to use Shifty.")
            alert.alertStyle = NSAlert.Style.warning
            alert.addButton(withTitle: NSLocalizedString("general.ok", comment: "OK"))
            alert.runModal()

            NSApplication.shared.terminate(self)
        }

        let launcherAppIdentifier = "io.natethompson.ShiftyHelper"

        let startedAtLogin = NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == launcherAppIdentifier
        }

        if startedAtLogin {
            DistributedNotificationCenter.default().post(name: .terminateApp, object: Bundle.main.bundleIdentifier!)
        }

        //Show alert if accessibility permissions have been revoked while app is not running
        if UserDefaults.standard.bool(forKey: Keys.isWebsiteControlEnabled) && !UIElement.isProcessTrusted() {
            logw("Accessibility permissions revoked while app was not running")
            showAccessibilityDeniedAlert()
            UserDefaults.standard.set(false, forKey: Keys.isWebsiteControlEnabled)
        }

        logw("Night Shift state: \(BLClient.isNightShiftEnabled)")
        logw("Schedule: \(BLClient.schedule)")
        if BLClient.isSunSchedule {
            logw("sunrise: \(String(describing: BSClient.sunrise))")
            logw("sunset: \(String(describing: BSClient.sunset))")
        }
        logw("")

        updateMenuBarIcon()
        setStatusToggle()

        if (!UserDefaults.standard.bool(forKey: Keys.hasSetupWindowShown) && !UIElement.isProcessTrusted()) || ProcessInfo.processInfo.environment["show_setup"] == "true" {
            let storyboard = NSStoryboard(name: .init("Setup"), bundle: nil)
            let controller = storyboard.instantiateInitialController() as! NSWindowController
            setupWindow = controller.window

            NSApplication.shared.activate(ignoringOtherApps: true)
            controller.showWindow(self)
            setupWindow.makeMain()

            UserDefaults.standard.set(true, forKey: Keys.hasSetupWindowShown)
        }
    }

    func updateMenuBarIcon() {
        var icon: NSImage
        if UserDefaults.standard.bool(forKey: Keys.isIconSwitchingEnabled),
            !NightShiftManager.isNightShiftEnabled {
            icon = #imageLiteral(resourceName: "sunOpenIcon")
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
                button.action = #selector(statusBarButtonClicked)
                button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            }
        } else {
            statusItem.menu = statusMenu
        }
    }

    @objc func statusBarButtonClicked(sender: NSStatusBarButton) {
        let event = NSApp.currentEvent!

        if event.type == NSEvent.EventType.rightMouseUp || event.modifierFlags.contains(.control) {
            statusItem.menu = statusMenu
            statusItem.popUpMenu(statusMenu)
            statusItem.menu = nil
        } else {
            statusItemClicked?()
        }
    }

    func showAccessibilityDeniedAlert() {
        NSApplication.shared.activate(ignoringOtherApps: true)

        let alert: NSAlert = NSAlert()
        alert.messageText = NSLocalizedString("alert.accessibility_disabled_message", comment: "Accessibility permissions for Shifty have been disabled")
        alert.informativeText = NSLocalizedString("alert.accessibility_disabled_informative", comment: "Accessibility must be allowed to enable website shifting. Grant access to Shifty in Security & Privacy preferences, located in System Preferences.")
        alert.alertStyle = NSAlert.Style.warning
        alert.addButton(withTitle: NSLocalizedString("alert.open_preferences", comment: "Open System Preferences"))
        alert.addButton(withTitle: NSLocalizedString("alert.not_now", comment: "Not now"))
        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
            logw("Open System Preferences button clicked")
        } else {
            logw("Not now button clicked")
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        logw("App terminated")
    }


}
