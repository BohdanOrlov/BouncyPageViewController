//
//  PageViewControllerPresenter.swift
//  BouncyPageViewController
//
//  Created by Bohdan Orlov on 08/10/2016.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import Foundation
import UIKit
import BouncyPageViewController

final class PageViewControllerPresenter: NSObject {
    final var pagesQueue = [UIViewController]()
    init(window: UIWindow) {
        super.init()
        for idx in (0...5) {
            let pageViewController = self.pageViewController(index: idx)
            pagesQueue.append(pageViewController)
        }
        let pageViewController = BouncyPageViewController(initialViewControllers: Array(pagesQueue[2...3]))
        pageViewController.viewControllerAfterViewController = self.viewControllerAfterViewController
        pageViewController.viewControllerBeforeViewController = self.viewControllerBeforeViewController
        pageViewController.didScroll = self.pageViewControllerDidScroll

        let navigationController = UINavigationController(rootViewController: pageViewController)
        navigationController.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController.navigationBar.shadowImage = UIImage()
        pageViewController.navigationItem.leftBarButtonItem = UIBarButtonItem.init(image: UIImage(named:"menu"), style: .plain, target: nil, action: nil)
        pageViewController.navigationItem.rightBarButtonItem = UIBarButtonItem.init(image: UIImage(named:"settings"), style: .plain, target: nil, action: nil)
        window.rootViewController = navigationController
    }

    func pageViewControllerDidScroll(pageViewController: BouncyPageViewController, offset: CGFloat, progress: CGFloat) {
        for vc in pageViewController.visibleControllers() {
            let vc = (vc as! ViewController)
            vc.progress = progress

        }
        let firstVC = pageViewController.visibleControllers().first as! ViewController
        let color = firstVC.tintColor
        pageViewController.navigationItem.leftBarButtonItem!.tintColor = color
        pageViewController.navigationItem.rightBarButtonItem!.tintColor = color
    }

    func viewControllerAfterViewController(prevVC: UIViewController) -> UIViewController? {
        if let idx = self.pagesQueue.index(of: prevVC), idx + 1 < self.pagesQueue.count {
            return self.pagesQueue[idx + 1]
        }
        return nil
    }
    func viewControllerBeforeViewController(prevVC: UIViewController) -> UIViewController? {
        if let idx = self.pagesQueue.index(of: prevVC), idx - 1 >= 0 {
            return self.pagesQueue[idx - 1]
        }
        return nil
    }

    func pageViewController(index: Int) -> UIViewController {
        let pageViewController =  UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as! ViewController
        let firstColor = UIColor.white
        let secondColor = UIColor(red:0.96, green:0.16, blue:0.39, alpha:1.00)
        pageViewController.tintColor = index % 2 == 0 ?  secondColor : firstColor
        pageViewController.view.backgroundColor = index % 2 == 0 ? firstColor : secondColor
        pageViewController.dayLabel.text = index % 2 == 0 ? "Today" : "Yesterday"
        pageViewController.heartRateLabel.text = index % 2 == 0 ? "120/280" : "90/320"
        return pageViewController
    }
}