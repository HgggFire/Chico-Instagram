//
//  ChatCell.swift
//  Project1-Instagram
//
//  Created by LinChico on 1/17/18.
//  Copyright © 2018 RJTCOMPUQUEST. All rights reserved.
//

import UIKit

class ChatCell:  UITableViewCell {
    
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var labelContainerView: UIView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
//        labelContainerView.layer.cornerRadius = 5.0
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}

