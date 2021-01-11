//
//  PreviewImageCell.swift
//  TestProject
//

import Foundation
import UIKit

class PreviewImageCell: UITableViewCell {
    @IBOutlet weak var imageCell: UIImageView!
    @IBOutlet weak var tagLabel: UILabel!
    
    func configureCell(model: Hits) {
        tagLabel.text = model.tags
        if let previewURL = model.previewURL, let url = URL(string: previewURL) {
            ImageDownloader.sharedInstance.fetchImage(withURL: url, completion: { (imageResult) in    DispatchQueue.main.async { [weak self] in
                    switch imageResult {
                    case let .success(image):
                        self?.imageCell.image = image
                    case .failure:
                        print("error downloading image, showing default image")
                    }
                }
            })
        }
    }
}

