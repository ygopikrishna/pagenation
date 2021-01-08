//
//  LargeImageViewController.swift
//  TestProject
//
//  Created by Gopi Krishna Gajawada on 1/7/21.
//  Copyright © 2021 Gopi Krishna Gajawada. All rights reserved.
//

import Foundation
import UIKit

class LargeImageViewController: UIViewController {
    @IBOutlet weak var largeImageView: UIImageView!
    var largeImageUrl: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setImage(imageUrl: largeImageUrl)
    }
    
    func setImage(imageUrl: String?) {
        guard let urlString = imageUrl else { return }
        let url = URL(string: urlString)
        if let data = try? Data(contentsOf: url!) {
            largeImageView.image = UIImage(data: data)
        }
    }
}


