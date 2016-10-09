//  Created by Bohdan Orlov on 10/08/2016.
//  Copyright (c) 2016 Bohdan Orlov. All rights reserved.
//

import Foundation

open class BouncyPageViewController: UIViewController, UIScrollViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
    //MARK: - VLC
    private let flowLayout = UICollectionViewFlowLayout()
    private var collectionView: UICollectionView!
    open private(set) var viewControllers: [UIViewController?] = [nil]
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
        self.collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: flowLayout)
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        self.flowLayout.scrollDirection = .vertical
        self.flowLayout.minimumInteritemSpacing = 0
        self.flowLayout.minimumLineSpacing = 0
        self.collectionView.collectionViewLayout = flowLayout
        self.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        self.collectionView.decelerationRate = UIScrollViewDecelerationRateFast
        self.collectionView.panGestureRecognizer.addTarget(self, action: #selector(didPan(recognizer:)))

        self.view.addSubview(self.collectionView)
//        self.addViewControllersAsChildren()
//        self.addPanGestureRecongizer()
    }

    private func addViewControllersAsChildren(){
        for viewController in self.viewControllers {
            guard let viewController = viewController else {
                continue;
            }
            self.addChildPageViewController(viewController: viewController)
        }
    }
    private func addChildPageViewController(viewController: UIViewController){
        viewController.willMove(toParentViewController: self)
        self.addChildViewController(viewController)
        self.collectionView.addSubview(viewController.view)
        viewController.didMove(toParentViewController: parent)
    }
    private func addChildPageViewController(viewController: UIViewController, toView: UIView){
        viewController.willMove(toParentViewController: self)
        self.addChildViewController(viewController)
        viewController.view.frame = toView.bounds
        toView.addSubview(viewController.view)
        viewController.didMove(toParentViewController: parent)
    }
    private func removeChildPageViewController(viewController: UIViewController){
        viewController.willMove(toParentViewController: nil)
        viewController.view.removeFromSuperview()
        viewController.removeFromParentViewController()
    }

    var panRecognizer: UIPanGestureRecognizer!
    func addPanGestureRecongizer() {
        self.panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(didPan(recognizer:)))
        self.view.addGestureRecognizer(panRecognizer)
    }

    private func contentOffset() -> CGFloat {
        return self.collectionView.contentOffset.y
    }

    var baseOffset: CGFloat!
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.flowLayout.itemSize = self.pageSize()
        self.appendPlaceholdersIfNeeded()
        self.baseOffset = self.pageSize().height
        self.collectionView.frame = self.view.bounds
        self.collectionView.contentOffset = CGPoint(x:0, y:self.baseOffset)

//        self.layoutPages()
    }
    private func appendPlaceholdersIfNeeded() {
        while self.viewControllers.count < self.maxNumberOfVisisblePages() {
            self.viewControllers.append(nil)
        }
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        self.reloadingData = false
        return self.maxNumberOfVisisblePages()
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)

        return cell;
    }

    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if reloadingData {
            return
        }
        var viewController = self.viewControllers[indexPath.item];
        if viewController == nil {
        viewController = self.requestViewController(index:indexPath.item)
            self.viewControllers[indexPath.item] = viewController
        }
        if let viewController = viewController {
            self.addChildPageViewController(viewController: viewController, toView: cell.contentView)
        }
    }

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
    private var reloadingData = false
    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if reloadingData {
            return
        }
        if let vc = self.viewControllers[indexPath.item] {
            self.removeChildPageViewController(viewController: vc)
        }

        guard let vc = self.viewControllers[indexPath.item] else {
            return
        }
        self.viewControllers.remove(at:indexPath.item)
        if self.contentOffset() > self.baseOffset {
            self.viewControllers.append(nil)
            // let current CV updates to finish
            DispatchQueue.main.async {
                self.reloadingData = true
                self.collectionView.reloadData()
//                if self.contentOffset() > self.baseOffset * 2 {
                    self.collectionView.contentOffset.y -= self.baseOffset
//                }
            }
        } else {
            self.viewControllers.insert(nil, at: 0)
            // let current CV updates to finish
            DispatchQueue.main.async {
                self.reloadingData = true
                self.collectionView.reloadData()
//                if self.contentOffset() < self.baseOffset  {
                    self.collectionView.contentOffset.y += self.baseOffset
//                }
            }
        }
    }

//    private func layoutPages() {
//        for idx in (0..<self.maxNumberOfVisisblePages()) {
//            var pageOffset = self.pageSize().height * CGFloat(idx)
//            let origin = CGPoint(x: 0, y: pageOffset)
//            var rect = CGRect(origin: origin, size: self.pageSize())
//            let viewController = self.viewControllers[idx]
//            viewController?.view.frame = rect
//        }
//    }

    //MARK: - Pagination
    private func pageSize() -> CGSize {
        return CGSize(width:self.view.bounds.width, height:self.view.bounds.midY)
    }
//    private func numberOfVisisblePages() -> Int {
//
//        var numberOfPages = Int(self.view.bounds.maxY / self.pageSize().height)
//        if (self.scrollView.contentOffset.y != self.pageSize().height) {
//            numberOfPages += 1
//        }
//        return numberOfPages
//    }
    private func maxNumberOfVisisblePages() -> Int {
        var numberOfPages = Int(self.view.bounds.maxY / self.pageSize().height)
        numberOfPages += 2
        return numberOfPages
    }

    private var initialContentOffset: CGFloat = 0
    @objc private func didPan(recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
//        case .began: brea
        case .changed:
            if self.contentOffset() > self.baseOffset * 2 || self.contentOffset() < 0 {
//                recognizer.isEnabled = false
//                recognizer.isEnabled = true
            }
        case .ended, .cancelled, .failed:
            let offset:CGFloat
            if abs(self.baseOffset - self.contentOffset()) < self.baseOffset / 2  {
                offset = self.baseOffset - 1
            } else if (self.contentOffset() - self.baseOffset > 0) {
                offset = self.baseOffset * 2
            } else {
                offset = 0
            }
            self.collectionView.setContentOffset(CGPoint(x:0, y:offset), animated: true)
        default: break
        }

    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {

//        self.updateViewControllersArray()
//        self.updateContentOffset()
//        self.layoutPages()
    }
//    private func updateContentOffset() {
//        if self.contentOffset() > self.pageSize().height * 2 {
//            self.scrollView.contentOffset.y -= self.pageSize().height
//        }
//        if self.contentOffset() < -self.pageSize().height * 2 {
//            self.scrollView.contentOffset.y += self.pageSize().height
//        }
//    }


    private func panOffset() -> CGFloat {
        return self.panRecognizer.translation(in: self.panRecognizer.view).y
    }

    public var viewControllerBeforeViewController: ((UIViewController) -> UIViewController?)!
    public var viewControllerAfterViewController: ((UIViewController) -> UIViewController?)!
    private func updateViewControllersArray() {
//        if self.contentOffset() > self.baseOffset {
//            self.removeChildPageViewController(viewController: self.viewControllers.removeFirst())
//            self.insertVCToBottom()
//        }
//        if (self.numberOfVisisblePages() > self.viewControllers.count) {
//            if self.contentOffset() > self.pageSize().height {
//                self.insertVCToBottom()
//            } else if self.contentOffset() < self.pageSize().height {
//                self.insertVCToTop()
//            }
//        }
//        else if self.contentOffset() > self.pageSize().height {
//            self.removeChildPageViewController(viewController: self.viewControllers.removeFirst())
//            self.insertVCToBottom()
//        }
//        else if self.contentOffset() < -self.pageSize().height {
//            self.removeChildPageViewController(viewController: viewControllers.removeLast())
//            self.insertVCToTop()
//        }
//}
//
//    private func insertVCToBottom() {
//        guard let nextVC = self.viewControllerAfterViewController(self.viewControllers.last!) else {
//             return
//            }
//        self.viewControllers.append(nextVC)
//        self.addChildPageViewController(viewController: nextVC)
//        self.scrollView.contentOffset.y -= self.pageSize().height
//    }
//    private func insertVCToTop() {
//    guard let nextVC = self.viewControllerBeforeViewController(self.viewControllers.first!) else {
//            return
//        }
//        self.viewControllers.insert(nextVC, at: 0)
//        self.addChildPageViewController(viewController: nextVC)
//        self.scrollView.contentOffset.y += self.pageSize().height
    }

}

