//
//  customFacebookButton.swift
//  Project1-Instagram
//
//  Created by LinChico on 1/8/18.
//  Copyright © 2018 RJTCOMPUQUEST. All rights reserved.
//

import UIKit
class CustomFacebookButton : UIButton {
    
    var textLabel: UILabel?
    @IBOutlet weak var fbIconImageView: UIImageView!
    
    @IBOutlet weak var myTextLabel: UILabel!
    
    override var isHighlighted : Bool {
        didSet{
            fbIconImageView.image = UIImage(named: "fbIcon")?.withRenderingMode(.alwaysTemplate)
            fbIconImageView.tintColor = isHighlighted ? fbBlue : normalBlue
            myTextLabel.textColor = isHighlighted ? fbBlue: normalBlue
        }
    }
}
