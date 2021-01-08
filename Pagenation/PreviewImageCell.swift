//
//  PreviewImageCell.swift
//  TestProject
//
//  Created by Gopi Krishna Gajawada on 1/7/21.
//  Copyright © 2021 Gopi Krishna Gajawada. All rights reserved.
//

import Foundation
import UIKit

class PreviewImageCell: UITableViewCell {
    @IBOutlet weak var imageCell: UIImageView!
    @IBOutlet weak var tagLabel: UILabel!
    
    func configureCell(model: Hits) {
        tagLabel.text = model.tags
        if let previewURL = model.previewURL, let url = URL(string: previewURL), let data = try? Data(contentsOf: url) {
                imageCell.image = UIImage(data: data)
        }
    }
}

