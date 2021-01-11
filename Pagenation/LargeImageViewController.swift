//
//  LargeImageViewController.swift
//  TestProject
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
        DispatchQueue.global(qos: .background).async {
            if let data = try? Data(contentsOf: url!) {
                DispatchQueue.main.async { [weak self] in
                    self?.largeImageView.image = UIImage(data: data)
                }
            }
        }
    }
}


