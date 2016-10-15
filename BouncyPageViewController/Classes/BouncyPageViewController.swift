//  Created by Bohdan Orlov on 10/08/2016.
//  Copyright (c) 2016 Bohdan Orlov. All rights reserved.
//

import Foundation
import UIKit
import RBBAnimation
import CoreGraphics

open class BouncyPageViewController: UIViewController {
    //MARK: - VLC
    fileprivate let scrollView = UIScrollView()
    fileprivate var backgroundViews: [UIView]!
    open fileprivate(set) var pageViewControllers: [UIViewController?]!
    open fileprivate(set) var initialPageViewControllers: [UIViewController]!
    public init(initialPageViewControllers: [UIViewController]) {
        self.initialPageViewControllers = initialPageViewControllers
        super.init(nibName: nil, bundle: nil)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        self.scrollView.panGestureRecognizer.addTarget(self, action: #selector(didPan(recognizer:)))
        self.scrollView.delegate = self
        self.scrollView.decelerationRate = UIScrollViewDecelerationRateFast
        self.view.addSubview(self.scrollView)
    }

    fileprivate var maxOverscroll:CGFloat = 0.5
    fileprivate var baseOffset: CGFloat!
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.preparePageViewControllersArrayIfNeeded()



        if backgroundViews == nil {
            self.backgroundViews = (0 ..< self.maxNumberOfPages()).map { _ in
                let view = UIView.init()
                self.scrollView.addSubview(view)
                return view
            }
        }

        let rects: (slice: CGRect, remainder: CGRect) = self.view.bounds.divided(atDistance: self.view.bounds.midY, from: .minYEdge)
//        self.topBackgrounView.frame = rects.slice
//        self.bottomBackgrounView.frame = rects.remainder
        self.baseOffset = self.pageSize().height
        self.scrollView.frame = self.view.bounds
        self.scrollView.contentSize = CGSize(width: self.view.bounds.width, height: self.pageSize().height * CGFloat(self.maxNumberOfPages()))
        self.scrollView.contentOffset = CGPoint(x:0, y:self.baseOffset)
    }

    private func preparePageViewControllersArrayIfNeeded() {
        if self.pageViewControllers?.count == self.maxNumberOfPages()  {
            return
        }
        assert(initialPageViewControllers.count == self.numberOfVisiblePages(), "All initially visible page controllers must be provided")
        // Constructing model for storing pages view controllers. Symbol | shows boundary of the "viewport"
        // [nil]|[VC][VC]|[nil]
        let initialPage: [UIViewController?] = [nil]
        self.pageViewControllers = initialPage + self.initialPageViewControllers.map(Optional.init)
        self.initialPageViewControllers = nil
        while self.pageViewControllers.count < self.maxNumberOfPages() {
            self.pageViewControllers.append(nil)
        }
    }

    //MARK: - Pagination
    public var overlapDelta:CGFloat = 30
    fileprivate func layoutPages() {
        for idx in (0..<self.maxNumberOfPages()) {
            var pageOffset = self.pageSize().height * CGFloat(idx)
            let origin = CGPoint(x: 0, y: pageOffset)
            var rect = CGRect(origin: origin, size: self.pageSize())


            var viewController = self.pageViewControllers[idx];
            let vcIsVisible: Bool = self.scrollView.bounds.intersects(rect)
            if viewController == nil && vcIsVisible {
                viewController = self.requestViewController(index:idx)
                self.pageViewControllers[idx] = viewController
            }
            self.backgroundViews[idx].frame = rect;
            if let viewController = viewController {
                self.addChildPageViewController(viewController: viewController)
                self.backgroundViews[idx].backgroundColor = viewController.view.backgroundColor
            }
            let vcShouldWigle = viewController != self.pageViewControllers.first! && viewController != self.pageViewControllers.last!
            if let vc = viewController {
                vc.view.isHidden = !vcIsVisible
//                if vcShouldWigle {
//                    vc.view.isHidden = false
//                } else {
//                    vc.view.isHidden = true
//                }
                let velocity = self.scrollView.panGestureRecognizer.velocity(in: self.scrollView.panGestureRecognizer.view).y
//                let velocity:CGFloat = 500.0

                vc.view.frame = rect.insetBy(dx: 0, dy: -overlapDelta)
                if let mask = viewController?.view.layer.mask as? CAShapeLayer {
//                    print(CATransform3DIsIdentity(mask.transform))
                    if mask.path == nil {
                        mask.frame = vc.view.bounds
                        var maskRect = vc.view.bounds.insetBy(dx: -overlapDelta, dy: overlapDelta)
//                        if idx == 0 {
//                            maskRect.origin.y -= overlapDelta
//                            maskRect.size.height += overlapDelta
//                        } else if idx == self.maxNumberOfPages() - 1 {
//                            maskRect.size.height += overlapDelta
//                        }

                        mask.path = UIBezierPath(rect: maskRect).cgPath
                    }
//                    let angle:CGFloat = atan(overlapDelta / (vc.view.bounds.width / 2)) * abs(velocity) / 500.0
////                    mask.transform = CATransform3DIdentity
//
//
////                    if velocity == 0 && mask.animation(forKey: "bounce") == nil {
//                    if mask.animation(forKey: "bounce") == nil {
////                        print("added")
//                        var bounce = RBBSpringAnimation(keyPath: "transform")
//                        bounce.fromValue = NSValue(caTransform3D:mask.transform)
//                        bounce.toValue = NSValue(caTransform3D: CATransform3DMakeRotation(angle, 0.0, 0.0, 1.0))
//                        bounce.velocity = velocity
//                        bounce.mass = 1
//                        bounce.damping = 10
//                        bounce.stiffness = 100
//                        bounce.isAdditive = true
//                        bounce.duration = bounce.duration(forEpsilon: 0.01)
//                        mask.add(bounce, forKey: "bounce")
//                        }
//                    } else {
////                        print(velocity)
//                        mask.transform = CATransform3DMakeRotation(angle, 0.0, 0.0, 1.0)
////                    NSLog("\(mask.bounds)")
////                        print(CATransform3DIsIdentity(mask.transform))
////                        print(" ")
//                    }
                }
            }
        }
    }

    private func pageSize() -> CGSize {
        return CGSize(width:self.view.bounds.width, height:self.view.bounds.midY)
    }

    private func numberOfVisiblePages() -> Int {
        return Int(self.view.bounds.maxY / self.pageSize().height)
    }

    private func maxNumberOfPages() -> Int {
        return self.numberOfVisiblePages() + 2
    }

    //MARK: - Child view controllers
    private func addChildPageViewController(viewController: UIViewController){
        if viewController.parent == self {
            return
        }
        viewController.willMove(toParentViewController: self)
        self.addChildViewController(viewController)
        self.scrollView.addSubview(viewController.view)
        let mask = CAShapeLayer()
        mask.fillRule = kCAFillRuleEvenOdd
        viewController.view.layer.mask = mask
        viewController.didMove(toParentViewController: parent)
    }

    fileprivate func removeChildPageViewController(viewController: UIViewController){
        viewController.willMove(toParentViewController: nil)
        viewController.view.removeFromSuperview()
        viewController.removeFromParentViewController()
    }

    public var viewControllerBeforeViewController: ((UIViewController) -> UIViewController?)!
    public var viewControllerAfterViewController: ((UIViewController) -> UIViewController?)!
    private func requestViewController(index: Int) -> UIViewController? {
        if index + 1 < self.pageViewControllers.count {
            if let controller = self.pageViewControllers[index + 1] {
                return self.viewControllerBeforeViewController(controller)
            }
        }
        if index - 1 > 0 {
            if let controller = self.pageViewControllers[index - 1] {
                return self.viewControllerAfterViewController(controller)
            }
        }
        return nil
    }
    var lastVelocity: CGFloat = 0
    var lastLocationInView = CGPoint.zero
}


extension BouncyPageViewController: UIScrollViewDelegate {
    private func contentOffset() -> CGFloat {
        return self.scrollView.contentOffset.y
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        var vc: UIViewController?
        if self.contentOffset() > self.baseOffset * 2 {
            print("remove first")
            vc = self.pageViewControllers.removeFirst()
            self.pageViewControllers.append(nil)
//            self.resetGestureRecongizer()
            self.scrollView.contentOffset.y -= self.baseOffset
        } else if self.contentOffset() < 0 {
            print("remove last")
            vc = self.pageViewControllers.removeLast()
            self.pageViewControllers.insert(nil, at: 0)
//            self.resetGestureRecongizer()
            self.scrollView.contentOffset.y += self.baseOffset
        }
        if let vc = vc {
            self.removeChildPageViewController(viewController: vc)
        }
        self.layoutPages()

//        if self.contentOffset() <= self.baseOffset {
//            self.view.backgroundColor =
//        } else {
//            self.view.backgroundColor = self.existingControllers().last!.view.backgroundColor
//        }
        if self.contentOffset() > self.baseOffset + self.baseOffset * self.maxOverscroll && self.pageViewControllers.last! == nil {
            self.resetGestureRecongizer()
            UIView.animate(withDuration: 0.3, animations: {   self.scrollView.contentOffset = CGPoint(x:0, y:self.baseOffset) })
        } else if self.contentOffset() < baseOffset * self.maxOverscroll && self.pageViewControllers.first! == nil{
            self.resetGestureRecongizer()
            UIView.animate(withDuration: 0.3, animations: {   self.scrollView.contentOffset = CGPoint(x:0, y:self.baseOffset) })

        }
//        self.topBackgrounView.backgroundColor = self.vivibleControllers().first!.view.backgroundColor
//        self.bottomBackgrounView.backgroundColor = self.vivibleControllers().last!.view.backgroundColor
    }

    private func vivibleControllers() -> [UIViewController] {
        return self.pageViewControllers.flatMap {
            if let vc = $0, vc.view.isHidden == false {
                return vc
            }
            return nil
        }
    }

    private func resetGestureRecongizer() {
        self.scrollView.panGestureRecognizer.isEnabled = false
        self.scrollView.panGestureRecognizer.isEnabled = true
    }


    @objc fileprivate func didPan(recognizer: UIPanGestureRecognizer) {

        switch recognizer.state {
        case .changed:
            for vc in self.childViewControllers {
                let mask = vc.view.layer.mask!
            }
        case .ended, .cancelled, .failed:
            let offset:CGFloat
            if abs(self.baseOffset - self.contentOffset()) < self.baseOffset / 2  {
                offset = self.baseOffset
            } else if (self.contentOffset() - self.baseOffset > 0) {
                offset = self.baseOffset * 2
            } else {
                offset = 0
            }
            self.scrollView.setContentOffset(CGPoint(x:0, y:offset), animated: true)
        default: break
        }
//        print(self.lastVelocity)
        let view = recognizer.view
        var velocity = self.scrollView.isDragging ? recognizer.velocity(in: view).y : 0
        let locationInView = recognizer.location(in: view)
        let fromAngle = self.angle(velocity: self.lastVelocity, relativeLocation: self.lastLocationInView)
        let toAngle = self.angle(velocity: velocity, relativeLocation: locationInView)
//        let toAngle = CGFloat(0.3)

        self.lastVelocity = velocity
        self.lastLocationInView = locationInView

        for vc in self.childViewControllers {
            let mask = vc.view.layer.mask!
//            var bounce = RBBSpringAnimation(keyPath: "transform")
//            bounce.fromValue = NSValue(caTransform3D: CATransform3DMakeRotation(fromAngle, 0.0, 0.0, 1.0))
//            bounce.toValue = NSValue(caTransform3D: CATransform3DMakeRotation(toAngle, 0.0, 0.0, 1.0))
//            bounce.velocity = 0
//            bounce.mass = 10
//            bounce.damping = 50
//            bounce.stiffness = 1000
//            bounce.allowsOverdamping = true
//            bounce.duration = bounce.duration(forEpsilon: 0.01)
            var bounce = RBBTweenAnimation(keyPath: "transform")
            bounce.fromValue = NSValue(caTransform3D: CATransform3DMakeRotation(fromAngle, 0.0, 0.0, 1.0))
            bounce.toValue = NSValue(caTransform3D: CATransform3DMakeRotation(toAngle, 0.0, 0.0, 1.0))
            bounce.easing = RBBEasingFunctionEaseOutBounce
            bounce.duration = 1
            mask.add(bounce, forKey: "bounce")
        }
    }

    private func angle(velocity: CGFloat, relativeLocation: CGPoint) -> CGFloat {
        var currentOverlap = self.overlapDelta * max(-1, min(1, velocity / 1500.0))
        let halfWidth = view!.bounds.width / 2
        let distanceToCenterMultiplier = (relativeLocation.x - halfWidth) / halfWidth
        currentOverlap *= distanceToCenterMultiplier
        let angle:CGFloat = atan(currentOverlap / (view!.bounds.width / 2))
        return angle
    }
}
