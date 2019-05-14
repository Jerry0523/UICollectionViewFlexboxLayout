//
//  ControlPannel.swift
//  UICollectionViewFlexboxLayout
//
//  Created by Jerry Wong on 2019/5/9.
//  Copyright © 2019 com.jerry. All rights reserved.
//

import UIKit
import UICollectionViewFlexboxLayout

class ControlPannel: UIViewController {

    @IBOutlet weak var justifyContentControl: UISegmentedControl!
    
    @IBOutlet weak var alignItemsControl: UISegmentedControl!
    
    var mJustifyContent = UICollectionViewFlexboxLayout.JustifyContent.start
    
    var mAlignItems = UICollectionViewFlexboxLayout.AlignItems.start
    
    var exportConfig: ((UICollectionViewFlexboxLayout.JustifyContent, UICollectionViewFlexboxLayout.AlignItems) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        justifyContentControl.selectedSegmentIndex = mJustifyContent.rawValue
        alignItemsControl.selectedSegmentIndex = mAlignItems.rawValue
    }
    
    @IBAction func didClickSubmitButton(_ sender: UIButton) {
        parent?.dismiss(animated: true) {
            self.exportConfig?(self.mJustifyContent, self.mAlignItems)
        }
    }
    
    @IBAction func didClickCancelButton(_ sender: UIButton) {
        parent?.dismiss(animated: true)
    }
    
    @IBAction func didUpdateJustifyContent(_ sender: UISegmentedControl) {
        mJustifyContent = UICollectionViewFlexboxLayout.JustifyContent(rawValue: sender.selectedSegmentIndex)!
    }
    
    @IBAction func didUpdateAlignItems(_ sender: UISegmentedControl) {
        mAlignItems = UICollectionViewFlexboxLayout.AlignItems(rawValue: sender.selectedSegmentIndex)!
    }
    
}
