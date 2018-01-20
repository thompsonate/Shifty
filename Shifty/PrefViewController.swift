//
//  PrefViewController.swift
//  Shifty
//
//  Created by Nate Thompson on 1/18/18.
//

import Cocoa

class PrefViewController: NSViewController, NSToolbarDelegate {
    
    var maxWidth: CGFloat!
    var toolbar: NSToolbar!
    var toolbarIdentifiers: [NSToolbarItem.Identifier]!
    var selectedItemTag: Int!

    override func loadView() {
        self.view = NSView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        toolbar = NSToolbar(identifier: .init("Toolbar"))
        toolbar.delegate = self
        toolbar.allowsUserCustomization = false
        toolbar.displayMode = .iconAndLabel
        view.window?.toolbar = toolbar
    }
    
    override func viewWillAppear() {
        if view.window?.toolbar == nil {
            view.window?.toolbar = toolbar
        }
    }
    
    override var childViewControllers: [NSViewController] {
        get {
            return super.childViewControllers
        }
        set {
            super.childViewControllers = newValue
            if toolbarIdentifiers == nil {
                toolbarIdentifiers = []
            }
            for controller in newValue {
                toolbarIdentifiers.append(NSToolbarItem.Identifier(controller.className))
            }
            self.view.setFrameSize(newValue[0].view.fittingSize)
            newValue[0].view.frame = view.bounds
            self.view.addSubview(newValue[0].view)
            toolbar.selectedItemIdentifier = toolbarIdentifiers[0]
        }
    }
    
    @objc
    func toolbarItemClicked(item: NSToolbarItem) {
        if selectedItemTag == nil { selectedItemTag = 0 }
        if selectedItemTag == item.tag { return }
        
        selectedItemTag = item.tag
        
        guard let window = view.window,
            let toVC = viewControllerFor(itemIdentifier: item.itemIdentifier) else { return }
        
        if view.subviews[0] == toVC.view { return }
        
        if maxWidth == nil {
            maxWidth = CGFloat(0.0)
            for controller in childViewControllers {
                let width = controller.view.fittingSize.width
                if width > maxWidth {
                    maxWidth = width
                }
            }
        }
        
        let contentRect = NSRect(x: 0.0, y: 0.0, width: maxWidth, height: toVC.view.fittingSize.height)
        let contentSize = NSMakeSize(contentRect.width, contentRect.height)
        let frameRect = window.frameRect(forContentRect: contentRect)
        let windowHeightDelta = window.frame.size.height - frameRect.size.height
        let newOrigin = NSMakePoint(window.frame.origin.x, window.frame.origin.y + windowHeightDelta)
        let newFrame = NSMakeRect(newOrigin.x, newOrigin.y, frameRect.size.width, frameRect.size.height)
        
        window.setFrame(newFrame, display: true, animate: false)

        toVC.view.alphaValue = 0
        toVC.view.setFrameSize(contentSize)
        view.addSubview(toVC.view)
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            window.animator().setFrame(newFrame, display: false)
            toVC.view.animator().alphaValue = 1
            view.subviews[0].animator().alphaValue = 0
        }) {
            self.view.subviews[0].removeFromSuperview()
        }
    }
    
    func viewControllerFor(itemIdentifier: NSToolbarItem.Identifier) -> PrefPaneViewController? {
        for controller in self.childViewControllers {
            if controller.className == itemIdentifier.rawValue {
                return controller as? PrefPaneViewController
            }
        }
        return nil
    }
    
    
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        let item  = NSToolbarItem(itemIdentifier: itemIdentifier)
        item.label = viewControllerFor(itemIdentifier: itemIdentifier)?.toolbarItemLabel ?? ""
        item.image = viewControllerFor(itemIdentifier: itemIdentifier)?.toolbarItemImage
        item.target = self
        item.action = #selector(toolbarItemClicked(item:))
        item.tag = toolbarIdentifiers.index(of: itemIdentifier)!
        return item
    }
    
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return toolbarIdentifiers
    }
    
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return toolbarIdentifiers
    }
    
    func toolbarSelectableItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return toolbarIdentifiers
    }
}


class PrefPaneViewController: NSViewController {
    var toolbarItemImage: NSImage? {
        return nil
    }
    
    var toolbarItemLabel: String? {
        return nil
    }
}


class PrefWindowController: NSWindowController {
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 13 && event.modifierFlags.contains(.command) {
            window?.close()
        }
    }
}



