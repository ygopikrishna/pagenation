//
//  ViewController.swift
//  TestProject
//

import UIKit

class ViewController: UIViewController {
    var imageViewModel = ImageViewModel()
    var hitsModel: [Hits] = [Hits]()
    @IBOutlet weak var tableView: UITableView!
    var largeImageUrl: String?
    fileprivate var isNextPageFetchingInProgress = false
    weak var imageViewDelegate: ImageViewProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        getPreviewImage()
    }
    
    func getPreviewImage() {
        imageViewModel.getImages(onSuccess: { _ in
            guard let hitModel = self.imageViewModel.getHitsModel() else { return }
            self.hitsModel = hitModel
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }) {
            print("Failed to fetch Items")
        }
    }


}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            self.hitsModel.count
        }
        
        func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            UITableView.automaticDimension
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "PreviewImageCell", for: indexPath) as? PreviewImageCell
            if self.hitsModel.count > 0 {
                cell?.configureCell(model: self.hitsModel[indexPath.row])
            }
            if self.hitsModel.count - indexPath.row <= 10 {
                fetchNextPage()
            }
            return cell!
        }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        largeImageUrl = self.hitsModel[indexPath.row].largeImageURL
        performSegue(withIdentifier: "LargeView", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let secondVC = segue.destination as? LargeImageViewController {
            secondVC.largeImageUrl = largeImageUrl
        }
    }
    
    func fetchNextPage() {
        guard !isNextPageFetchingInProgress else {
            return
        }
        self.isNextPageFetchingInProgress = true
        imageViewModel.fetchNextPage({ [weak self] (newHits) in
            self?.isNextPageFetchingInProgress = false
            self?.hitsModel.append(contentsOf: newHits)
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        })
    }
}

