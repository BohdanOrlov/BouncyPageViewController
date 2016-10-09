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
        let pageViewController = BouncyPageViewController(viewControllers: Array(pagesQueue[2...3]))
        pageViewController.viewControllerAfterViewController = { prevVC in
            if let idx = self.pagesQueue.index(of: prevVC), idx + 1 < self.pagesQueue.count {
                return self.pagesQueue[idx + 1]
            }
            return nil
        }
        pageViewController.viewControllerBeforeViewController = { prevVC in
            if let idx = self.pagesQueue.index(of: prevVC), idx - 1 >= 0 {
                return self.pagesQueue[idx - 1]
            }
            return nil
        }
        window.rootViewController = pageViewController
    }

    func pageViewController(index: Int) -> UIViewController {
        let pageViewController =  UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as! ViewController
        pageViewController.view.backgroundColor = index % 2 == 0 ? UIColor.purple : UIColor.yellow
        pageViewController.todayLabel.text = "Today \(index)"
        return pageViewController
    }
}
