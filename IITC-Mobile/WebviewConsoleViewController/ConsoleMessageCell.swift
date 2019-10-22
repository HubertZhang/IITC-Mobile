//
//  ConsoleMessageTableViewCell.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 2019/10/18.
//  Copyright © 2019 IITC. All rights reserved.
//

import UIKit

class ConsoleMessageCell: UITableViewCell {
    @IBOutlet weak var levelImage: UIImageView!
    @IBOutlet weak var message: UILabel!

    @IBOutlet weak var location: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
