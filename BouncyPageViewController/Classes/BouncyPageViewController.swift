//  Created by Bohdan Orlov on 10/08/2016.
//  Copyright (c) 2016 Bohdan Orlov. All rights reserved.
//

import Foundation

open class BouncyPageViewController: UIViewController {
    //MARK: - VLC
    fileprivate let scrollView = UIScrollView()
    open fileprivate(set) var viewControllers: [UIViewController?] = [nil]
    public init(viewControllers: [UIViewController]) {
        assert(viewControllers.count > 0)
        let optionalViewControllers = viewControllers.map(Optional.init)
        self.viewControllers.append(contentsOf: optionalViewControllers)
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
        self.appendPlaceholdersIfNeeded()
        self.baseOffset = self.pageSize().height
        self.scrollView.frame = self.view.bounds
        self.scrollView.contentSize = CGSize(width: self.view.bounds.width, height: self.pageSize().height * CGFloat(self.maxNumberOfPages()))
        self.scrollView.contentOffset = CGPoint(x:0, y:self.baseOffset)
    }

    private func appendPlaceholdersIfNeeded() {
        while self.viewControllers.count < self.maxNumberOfPages() {
            self.viewControllers.append(nil)
        }
    }

    //MARK: - Pagination

    fileprivate func layoutPages() {
        for idx in (0..<self.maxNumberOfPages()) {
            var pageOffset = self.pageSize().height * CGFloat(idx)
            let origin = CGPoint(x: 0, y: pageOffset)
            var rect = CGRect(origin: origin, size: self.pageSize())

            var viewController = self.viewControllers[idx];
            if viewController == nil && self.scrollView.bounds.intersects(rect) {
                viewController = self.requestViewController(index:idx)
                self.viewControllers[idx] = viewController
            }
            if let viewController = viewController {
                self.addChildPageViewController(viewController: viewController)
            }
            viewController?.view.frame = rect
        }
    }

    private func pageSize() -> CGSize {
        return CGSize(width:self.view.bounds.width, height:self.view.bounds.midY)
    }

    private func maxNumberOfPages() -> Int {
        var numberOfPages = Int(self.view.bounds.maxY / self.pageSize().height)
        numberOfPages += 2
        return numberOfPages
    }

    //MARK: - Child view controllers
    private func addChildPageViewController(viewController: UIViewController){
        viewController.willMove(toParentViewController: self)
        self.addChildViewController(viewController)
        self.scrollView.addSubview(viewController.view)
        viewController.didMove(toParentViewController: parent)
    }

    private func removeChildPageViewController(viewController: UIViewController){
        viewController.willMove(toParentViewController: nil)
        viewController.view.removeFromSuperview()
        viewController.removeFromParentViewController()
    }

    public var viewControllerBeforeViewController: ((UIViewController) -> UIViewController?)!
    public var viewControllerAfterViewController: ((UIViewController) -> UIViewController?)!
    private func requestViewController(index: Int) -> UIViewController? {
        if index + 1 < self.viewControllers.count {
            if let controller = self.viewControllers[index + 1] {
                return self.viewControllerBeforeViewController(controller)
            }
        }
        if index - 1 > 0 {
            if let controller = self.viewControllers[index - 1] {
                return self.viewControllerAfterViewController(controller)
            }
        }
        return nil
    }

}


extension BouncyPageViewController: UIScrollViewDelegate {
    private func contentOffset() -> CGFloat {
        return self.scrollView.contentOffset.y
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if self.contentOffset() > self.baseOffset * 2 {
            self.viewControllers.removeFirst()
            self.viewControllers.append(nil)
//            self.resetGestureRecongizer()
            self.scrollView.contentOffset.y -= self.baseOffset
        } else if self.contentOffset() < 0 {
            self.viewControllers.removeLast()
            self.viewControllers.insert(nil, at: 0)
//            self.resetGestureRecongizer()
            self.scrollView.contentOffset.y += self.baseOffset
        }
        self.layoutPages()
        if self.contentOffset() > self.baseOffset + self.baseOffset * self.maxOverscroll && self.viewControllers.last! == nil {
            self.resetGestureRecongizer()
            self.scrollView.setContentOffset(CGPoint(x:0, y:self.baseOffset), animated: true)
        } else if self.contentOffset() < baseOffset * self.maxOverscroll && self.viewControllers.first! == nil{
            self.resetGestureRecongizer()
            self.scrollView.setContentOffset(CGPoint(x:0, y:self.baseOffset), animated: true)
        }
    }

    private func resetGestureRecongizer() {
        self.scrollView.panGestureRecognizer.isEnabled = false
        self.scrollView.panGestureRecognizer.isEnabled = true
    }

    @objc fileprivate func didPan(recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
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
    }
}
