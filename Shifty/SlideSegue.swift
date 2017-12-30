//
//  SlideSegue.swift
//  Shifty
//
//  Created by Nate Thompson on 12/29/17.
//

import Cocoa

class SlideSegue: NSStoryboardSegue {
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
        let targetSize = destinationViewController.view.frame.size
        
        // prepare for animation
        sourceViewController.view.wantsLayer = true
        sourceViewController.view.superview?.wantsLayer = true
        destinationViewController.view.wantsLayer = true
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.4
            sourceViewController.view.setFrameSize(targetSize)
            destinationViewController.view.setFrameSize(targetSize)
            containerViewController.transition(from: sourceViewController, to: destinationViewController, options: animation, completionHandler: nil)
        }, completionHandler: {
            containerViewController.view.topAnchor.constraint(equalTo: destinationViewController.view.topAnchor).isActive = true
        })
        
        // lose the sourceViewController, it's no longer visible
        containerViewController.removeChildViewController(at: 0)
    }
}

class SlideForwardSegue: SlideSegue {
    override var animation: NSViewController.TransitionOptions {
        return NSViewController.TransitionOptions.slideForward
    }
}

class SlideBackwardSegue: SlideSegue {
    override var animation: NSViewController.TransitionOptions {
        return NSViewController.TransitionOptions.slideBackward
    }
}
