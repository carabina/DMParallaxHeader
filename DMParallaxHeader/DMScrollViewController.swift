//
//  DMScrollViewController.swift
//  DMParallaxHeader
//
//  Created by Dominic Miller on 9/11/18.
//  Copyright © 2018 DominicMiller. All rights reserved.
//

import UIKit
import ObjectiveC

@objc public class DMScrollViewController: UIViewController {
    
    static var KVOContext = "kDMScrollViewControllerKVOContext"
    
    /// The scroll view container
    var _scrollView: DMScrollView?
    public var scrollView: DMScrollView {
        if _scrollView == nil {
            _scrollView = DMScrollView(frame: .zero)
            _scrollView!.parallaxHeader.addObserver(self,
                                                   forKeyPath:#keyPath(DMParallaxHeader.minimumHeight),
                                                   options: .new,
                                                   context: &DMScrollViewController.KVOContext)
        }
        return _scrollView!
    }
    
    /// The parallax header view controller to be added to the scroll view
    public var headerViewController: UIViewController? {
        willSet {
            if let _headerViewController = headerViewController, _headerViewController.parent == self {
                _headerViewController.willMove(toParentViewController: nil)
                _headerViewController.view.removeFromSuperview()
                _headerViewController.removeFromParentViewController()
                _headerViewController.didMove(toParentViewController: nil)
            }
            
            if let headerViewController = newValue {
                headerViewController.willMove(toParentViewController: self)
                addChildViewController(headerViewController)
                
                //Set parallaxHeader view
                objc_setAssociatedObject(headerViewController,
                                         &UIScrollView.ParallaxHeaderKey,
                                         scrollView.parallaxHeader,
                                         .OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                
                scrollView.parallaxHeader.view = headerViewController.view
                headerViewController.didMove(toParentViewController: self)
            }
        }
    }
    
    /// The child view controller to be added to the scroll view
    public var childViewController: UIViewController? {
        willSet {
            if let _childViewController = childViewController, _childViewController.parent == self {
                _childViewController.willMove(toParentViewController: nil)
                _childViewController.view.removeFromSuperview()
                _childViewController.removeFromParentViewController()
                _childViewController.didMove(toParentViewController: nil)
            }
            
            if let childViewController = newValue {
                childViewController.willMove(toParentViewController: self)
                addChildViewController(childViewController)
                
                //Set UIViewController's parallaxHeader property
                objc_setAssociatedObject(childViewController,
                                         &UIScrollView.ParallaxHeaderKey,
                                         scrollView.parallaxHeader,
                                         .OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                scrollView.addSubview(childViewController.view)
                childViewController.didMove(toParentViewController: self)
            }
        }
    }
    
    @IBOutlet weak var headerView: UIView?
    @IBInspectable var headerHeight: CGFloat = 100
    @IBInspectable var headerMinimumHeight: CGFloat = 0
    
    
    /*
     *  MARK: - View Life Cycle
     */
    
    override public func loadView() {
        view = scrollView
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        scrollView.parallaxHeader.view = headerView
        scrollView.parallaxHeader.height = headerHeight
        scrollView.parallaxHeader.minimumHeight = headerMinimumHeight
        
        //Hack to perform segues on load
        
        let templates = value(forKey: "storyboardSegueTemplates") as! [AnyObject]
        for item in templates {
            print(String(describing: item.self))
            print(String(describing: item.value(forKey: "identifier")))
            print("")
        }
        let this = String(describing: DMScrollViewControllerSegue.self)
        print(this)
        print(this)
        print(this)
        for template in templates {
            let segueClassName = String(template.value(forKey:"_segueClassName") as! NSString)
            if segueClassName.contains(String(describing: DMScrollViewControllerSegue.self)) ||
                segueClassName.contains(String(describing: DMParallaxHeaderSegue.self)) {
                let identifier = template.value(forKey: "identifier") as! String
                performSegue(withIdentifier: identifier, sender: self)
            }
        }
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.contentSize = scrollView.frame.size
        layoutChildViewController()
    }
    
    func layoutChildViewController() {
        var frame = scrollView.frame
        frame.origin = .zero
        frame.size.height -= scrollView.parallaxHeader.minimumHeight
        childViewController?.view.frame = frame;
    }
    
    /*
     *  MARK: - KVO
     */
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?,
                                      change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &DMScrollViewController.KVOContext else {
            return super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
        if childViewController != nil && keyPath == #keyPath(DMParallaxHeader.minimumHeight) {
            layoutChildViewController()
        }
    }
    
    deinit {
        scrollView.parallaxHeader.removeObserver(self, forKeyPath: #keyPath(DMParallaxHeader.minimumHeight))
    }
    
}

public extension UIViewController {
    var parallaxHeader: DMParallaxHeader? {
        let parallaxHeader = objc_getAssociatedObject(self, &UIScrollView.ParallaxHeaderKey) as? DMParallaxHeader
        if parallaxHeader == nil && parent != nil {
            return parent!.parallaxHeader
        }
        return parallaxHeader
    }
}

/// The DMParallaxHeaderSegue class creates a segue object to get the parallax header view controller from storyboard.
public class DMParallaxHeaderSegue: UIStoryboardSegue {
    override public func perform() {
        guard source.isKind(of: DMScrollViewController.self) else { return }
        let svc = source as! DMScrollViewController
        svc.headerViewController = destination
    }
}

/// The DMScrollViewControllerSegue class creates a segue object to get the child view controller from storyboard.
public class DMScrollViewControllerSegue: UIStoryboardSegue {
    override public func perform() {
        guard source.isKind(of: DMScrollViewController.self) else { return }
        let svc = source as! DMScrollViewController
        svc.childViewController = destination
    }
}
