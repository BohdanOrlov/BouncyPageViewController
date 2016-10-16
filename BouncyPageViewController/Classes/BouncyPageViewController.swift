//  Created by Bohdan Orlov on 10/08/2016.
//  Copyright (c) 2016 Bohdan Orlov. All rights reserved.
//

import Foundation
import UIKit
import RBBAnimation
import CoreGraphics

public class BouncyPageViewController: UIViewController, UIScrollViewDelegate {
    //MARK: - VLC
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public init(initialViewControllers: [UIViewController]) {
        self.initialViewControllers = initialViewControllers
        super.init(nibName: nil, bundle: nil)
    }
    private var initialViewControllers: [UIViewController]!

    public override func viewDidLoad() {
        super.viewDidLoad()
        self.addScrollView()
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.addBackgroundViewsIfNeeded()
        self.prepareViewControllersIfNeeded()
        self.layoutScrollView()

    }

    private func layoutScrollView() {
        self.scrollView.delegate = self
        self.scrollView.frame = self.view.bounds
        self.scrollView.contentSize = CGSize(width: self.view.bounds.width, height: self.pageSize().height * CGFloat(self.maxNumberOfPages()))
        self.scrollView.contentOffset = CGPoint(x:0, y:self.baseOffset())
        self.scrollView.showsVerticalScrollIndicator = false
    }

    //MARK: - Public
    public var viewControllerBeforeViewController: ((UIViewController) -> UIViewController?)!
    public var viewControllerAfterViewController: ((UIViewController) -> UIViewController?)!
    public typealias Offset = CGFloat
    public typealias Progress = CGFloat
    public var didScroll: ((BouncyPageViewController, Offset,  Progress) -> Void)?
    public var pageContentInset: CGFloat = 30
    public var pageBounceAnimationDuration: TimeInterval = 1
    public var overscrollBounceMultiplier: CGFloat = 0.5

    public func visibleControllers() -> [UIViewController] {
        return self.viewControllers.flatMap {
            if let vc = $0, vc.view.isHidden == false {
                return vc
            }
            return nil
        }
    }

    //MARK: - Private
    private func addScrollView() -> Void {
        self.scrollView.panGestureRecognizer.addTarget(self, action: #selector(didPan(recognizer:)))
        self.scrollView.decelerationRate = UIScrollViewDecelerationRateFast
        self.view.addSubview(self.scrollView)
    }
    private let scrollView = UIScrollView()

    private func addBackgroundViewsIfNeeded() {
        if backgroundViews == nil {
            self.backgroundViews = (0 ..< self.maxNumberOfPages()).map { _ in
                let view = UIView.init()
                self.scrollView.addSubview(view)
                return view
            }
        }
    }
    private var backgroundViews: [UIView]!

    private func prepareViewControllersIfNeeded() {
        if self.viewControllers?.count == self.maxNumberOfPages()  {
            return
        }
        assert(initialViewControllers.count == self.numberOfVisiblePages(), "All initially visible page controllers must be provided")
        // Constructing model for storing pages view controllers.
        // Symbol | shows boundary of the "viewport":
        // [nil]|[VC][VC]|[nil]
        let initialPage: [UIViewController?] = [nil]
        self.viewControllers = initialPage + self.initialViewControllers.map(Optional.init)
        self.initialViewControllers = nil
        while self.viewControllers.count < self.maxNumberOfPages() {
            self.viewControllers.append(nil)
        }
    }
    private(set) var viewControllers: [UIViewController?]!

    //MARK: - On Did Scroll
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.shiftViewControllerIfNeeded()
        self.resetScrollViewContentOffsetIfNeeded()
        self.layoutPages()
        if self.overscrolledToTop() || self.overscrolledToBottom() {
            self.bounce()
        }
        let offset = self.contentOffset() - self.baseOffset()
        self.didScroll?(self, offset, abs(offset) / self.pageSize().height)
    }

    private func shiftViewControllerIfNeeded() {
        if self.scrolledToNextPage() {
            if let removedVC = self.viewControllers.removeFirst() {
                self.removeChild(viewController: removedVC)
            }
            self.viewControllers.append(nil)
        } else if self.scrolledToPreviousPage() {
            if let removedVC = self.viewControllers.removeLast() {
                self.removeChild(viewController: removedVC)
            }
            self.viewControllers.insert(nil, at: 0)
        }
    }

    private func resetScrollViewContentOffsetIfNeeded() {
        if self.scrolledToNextPage() {
            self.scrollView.contentOffset.y -= self.baseOffset()
        } else if self.scrolledToPreviousPage() {
            self.scrollView.contentOffset.y += self.baseOffset()
        }
    }

    private func scrolledToPreviousPage() -> Bool {
        return self.contentOffset() < 0
    }

    private func scrolledToNextPage() -> Bool {
        return self.contentOffset() > self.baseOffset() * 2
    }

    private func cancelPanGesture() {
        self.scrollView.panGestureRecognizer.isEnabled = false
        self.scrollView.panGestureRecognizer.isEnabled = true
    }

    //MARK: - Layout Pages

    private func layoutPages() {
        for idx in (0..<self.maxNumberOfPages()) {
            let pageOffset = self.pageSize().height * CGFloat(idx)
            let origin = CGPoint(x: 0, y: pageOffset)
            let pageRect = CGRect(origin: origin, size: self.pageSize())
            let isPageVisible = self.scrollView.bounds.intersects(pageRect)
            var viewControllerForPage = self.viewControllers[idx];
            if isPageVisible && viewControllerForPage == nil {
                viewControllerForPage = self.requestViewController(index:idx)

            }
            self.backgroundViews[idx].frame = pageRect;
            if let viewController = viewControllerForPage {
                self.addChild(viewController: viewController)
                self.backgroundViews[idx].backgroundColor = viewController.view.backgroundColor
            }
            if let viewControllerForPage = viewControllerForPage {
                viewControllerForPage.view.isHidden = !isPageVisible
                viewControllerForPage.view.frame = pageRect.insetBy(dx: 0, dy: -self.pageContentInset)
                self.addMaskTo(viewController: viewControllerForPage)
            }
        }
    }

    private func addMaskTo(viewController: UIViewController) {
        guard viewController.view.layer.mask == nil else {
            return
        }
        let maskRect = viewController.view.bounds.insetBy(dx: -self.pageContentInset, dy: self.pageContentInset)
        let mask = CAShapeLayer()
        mask.frame = viewController.view.bounds
        mask.path = UIBezierPath(rect: maskRect).cgPath
        mask.fillRule = kCAFillRuleEvenOdd
        viewController.view.layer.mask = mask
    }

    //MARK: - On Did Pan
    @objc private func didPan(recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .ended, .cancelled, .failed:
            self.scrollToNearestPage()
        default: break
        }
        self.animatePageBounce(recognizer: recognizer)
    }
    private func scrollToNearestPage() {
        let offset: CGFloat
        if abs(self.baseOffset() - self.contentOffset()) < self.baseOffset() / 2  {
            offset = self.baseOffset()
        } else if (self.contentOffset() - self.baseOffset() > 0) {
            offset = self.baseOffset() * 2
        } else {
            offset = 0
        }
        self.scrollView.setContentOffset(CGPoint(x:0, y:offset), animated: true)
    }

    //MARK: - Child view controllers
    private func addChild(viewController: UIViewController){
        if viewController.parent == self {
            return
        }
        viewController.willMove(toParentViewController: self)
        self.addChildViewController(viewController)
        self.scrollView.addSubview(viewController.view)
        viewController.didMove(toParentViewController: parent)
    }

    private func removeChild(viewController: UIViewController){
        viewController.willMove(toParentViewController: nil)
        viewController.view.removeFromSuperview()
        viewController.removeFromParentViewController()
    }

    private func requestViewController(index: Int) -> UIViewController? {
        var newViewController: UIViewController?
        if index + 1 < self.viewControllers.count {
            if let controllerAfterNewOne = self.viewControllers[index + 1] {
                newViewController = self.viewControllerBeforeViewController(controllerAfterNewOne)
            }
        }
        if index - 1 > 0 {
            if let controllerBeforeNewOne = self.viewControllers[index - 1] {
                newViewController = self.viewControllerAfterViewController(controllerBeforeNewOne)
            }
        }
        if let viewController = newViewController {
            self.viewControllers[index] = viewController
        }
        return newViewController
    }

    //MARK: - Page Rotation/Bounce Animation
    func animatePageBounce(recognizer: UIPanGestureRecognizer) {
        let view = recognizer.view
        let velocity = self.scrollView.isDragging ? recognizer.velocity(in: view).y : 0
        let locationInView = recognizer.location(in: view)
        let fromAngle = self.angle(velocity: self.lastVelocity, relativeLocation: self.lastLocationInView)
        let toAngle = self.angle(velocity: velocity, relativeLocation: locationInView)

        self.lastVelocity = velocity
        self.lastLocationInView = locationInView

        for vc in self.visibleControllers() {
            let mask = vc.view.layer.mask!
            let bounceAnimation = RBBTweenAnimation(keyPath: "transform")
            bounceAnimation.fromValue = NSValue(caTransform3D: CATransform3DMakeRotation(fromAngle, 0.0, 0.0, 1.0))
            bounceAnimation.toValue = NSValue(caTransform3D: CATransform3DMakeRotation(toAngle, 0.0, 0.0, 1.0))
            bounceAnimation.easing = RBBEasingFunctionEaseOutBounce
            bounceAnimation.duration = self.pageBounceAnimationDuration
            mask.add(bounceAnimation, forKey: "bounce")
        }
    }
    private var lastVelocity: CGFloat = 0
    private var lastLocationInView = CGPoint.zero

    private func angle(velocity: CGFloat, relativeLocation: CGPoint) -> CGFloat {
        var currentOverlap = self.pageContentInset * max(-1, min(1, velocity / 1000.0))
        let halfWidth = view!.bounds.width / 2
        let distanceToCenterMultiplier = (relativeLocation.x - halfWidth) / halfWidth
        currentOverlap *= distanceToCenterMultiplier
        let angle:CGFloat = atan(currentOverlap / (view!.bounds.width / 2))
        return angle
    }

    //MARK: - Overscroll Bounce
    private func overscrolledToBottom() -> Bool {
        let overscrolledToBottom = self.contentOffset() > self.baseOffset() + self.maxOverscroll()
        let noLastPage =  self.viewControllers.last! == nil
        return overscrolledToBottom && noLastPage
    }

    private func overscrolledToTop() -> Bool {
        let overscrolledToTop = self.contentOffset() < self.maxOverscroll()
        let noFirstPage = self.viewControllers.first! == nil
        return overscrolledToTop && noFirstPage
    }

    private func maxOverscroll() -> CGFloat {
        return self.baseOffset() * self.overscrollBounceMultiplier
    }

    private func bounce() {
        self.cancelPanGesture()
        UIView.animate(withDuration: 0.3, animations: {
            self.scrollView.contentOffset = CGPoint(x:0, y:self.baseOffset())
        })
    }

    //MARK: - Page Layout Computed Attributes
    private func pageSize() -> CGSize {
        return CGSize(width:self.view.bounds.width, height:self.view.bounds.midY)
    }

    private func baseOffset() -> CGFloat {
        return pageSize().height
    }

    private func contentOffset() -> CGFloat {
        return self.scrollView.contentOffset.y
    }

    private func numberOfVisiblePages() -> Int {
        return Int(self.view.bounds.maxY / self.pageSize().height)
    }

    private func maxNumberOfPages() -> Int {
        return self.numberOfVisiblePages() + 2
    }
}