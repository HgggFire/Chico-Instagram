//
//  FriendUserCell.swift
//  Project1-Instagram
//
//  Created by LinChico on 1/8/18.
//  Copyright © 2018 RJTCOMPUQUEST. All rights reserved.
//

import UIKit

class FriendUserCell: UITableViewCell {

    @IBOutlet weak var cellContainerView: UIView!
    @IBOutlet weak var button: UIButton!
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
