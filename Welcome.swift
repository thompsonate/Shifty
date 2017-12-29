//
//  Welcome.swift
//  
//
//  Created by Nate Thompson on 12/28/17.
//

import Cocoa

extension NSWindow {
    var titlebarHeight: CGFloat {
        let contentHeight = contentRect(forFrameRect: frame).height
        return frame.height - contentHeight
    }
}

class WelcomeWindowController: NSWindowController {
    override var storyboard: NSStoryboard {
        return NSStoryboard(name: .init("Welcome"), bundle: nil)
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        window?.styleMask.remove(.resizable)
    }
}


class ContainerViewController: NSViewController {
    var sourceViewController: NSViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let welcomeStoryboard = NSStoryboard(name: .init("Welcome"), bundle: nil)
        sourceViewController = welcomeStoryboard.instantiateController(withIdentifier: .init("sourceViewController")) as! NSViewController
        self.insertChildViewController(sourceViewController, at: 0)
        self.view.addSubview(sourceViewController.view)
        self.view.frame = sourceViewController.view.frame
    }
}

class SlideStoryboard: NSStoryboardSegue {
    open var animation: NSViewController.TransitionOptions {
        return NSViewController.TransitionOptions.slideForward
    }
    
    // make references to the source controller and destination controller
    override init(identifier: NSStoryboardSegue.Identifier,
                  source sourceController: Any,
                  destination destinationController: Any) {
        super.init(identifier: identifier, source: sourceController, destination: destinationController)
    }
    
    override func perform() {
        // build from-to and parent-child view controller relationships
        let sourceViewController  = self.sourceController as! NSViewController
        let destinationViewController = self.destinationController as! NSViewController
        let containerViewController = sourceViewController.parent! as NSViewController
        
        // add destinationViewController as child
        containerViewController.insertChildViewController(destinationViewController, at: 1)
        
        // get the size of destinationViewController
        let titleBarHeight = containerViewController.view.window?.titlebarHeight ?? 0

        let targetSize = destinationViewController.view.frame.size
        let targetWidth = destinationViewController.view.frame.size.width
        let targetHeight = destinationViewController.view.frame.size.height + titleBarHeight
        
        // prepare for animation
        sourceViewController.view.wantsLayer = true
        sourceViewController.view.superview?.wantsLayer = true
        destinationViewController.view.wantsLayer = true
        
        //perform transition
        containerViewController.transition(from: sourceViewController, to: destinationViewController, options: animation, completionHandler: nil)
        
        //resize view controllers
        sourceViewController.view.animator().setFrameSize(targetSize)
        destinationViewController.view.animator().setFrameSize(targetSize)
        
        //resize and shift window
        let currentFrame = containerViewController.view.window?.frame
        let currentRect = NSRectToCGRect(currentFrame!)
        let horizontalChange = (targetWidth - containerViewController.view.frame.size.width)/2
        let verticalChange = (targetHeight - containerViewController.view.frame.size.height)/2
        let newWindowRect = NSMakeRect(currentRect.origin.x - horizontalChange,
                                       currentRect.origin.y - verticalChange + titleBarHeight/2,
                                       targetWidth, targetHeight)
        containerViewController.view.window?.setFrame(newWindowRect, display: true, animate: true)
        
        // lose the sourceViewController, it's no longer visible
        containerViewController.removeChildViewController(at: 0)
    }
}

class SlideForwardStoryboard: SlideStoryboard {
    override var animation: NSViewController.TransitionOptions {
        return NSViewController.TransitionOptions.slideForward
    }
}

class SlideBackwardStoryboard: SlideStoryboard {
    override var animation: NSViewController.TransitionOptions {
        return NSViewController.TransitionOptions.slideBackward
    }
}



