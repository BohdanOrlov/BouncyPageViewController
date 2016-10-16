//
//  ViewController.swift
//  BouncyPageViewController
//
//  Created by Bohdan Orlov on 10/08/2016.
//  Copyright (c) 2016 Bohdan Orlov. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    var progress: CGFloat = 0 {
        didSet {
            let progressRelativeToEnd = abs(progress - 0.5) * 2
            let alpha = pow(progressRelativeToEnd, 6)
            self.moreInfoButton.alpha = alpha
            self.settingsButton.alpha = alpha
            let scale = 0.7 + 0.3 * progressRelativeToEnd
            self.heartImageView.transform = CGAffineTransform(scaleX:scale, y:scale)
            self.dayLabel.transform = CGAffineTransform(scaleX:scale, y:scale)
//            self.heartRateLabel.transform = CGAffineTransform(scaleX:scale, y:scale)
        }
    }
    var tintColor: UIColor!
    @IBOutlet weak var moreInfoButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var heartImageView: UIImageView!
    @IBOutlet weak var dayLabel: UILabel!
    @IBOutlet weak var heartRateLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.moreInfoButton.tintColor = self.tintColor
        self.settingsButton.tintColor = self.tintColor
        self.dayLabel.textColor = self.tintColor
        self.heartRateLabel.textColor = self.tintColor
        self.heartImageView.tintColor = self.tintColor
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
