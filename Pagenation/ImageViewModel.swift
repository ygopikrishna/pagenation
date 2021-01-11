//
//  ImageViewModel.swift
//  TestProject
//

import Foundation

class ImageViewModel {
    var model: ImageModel?
    var hitsModel: [Hits]?
    var currentPage = 1
    var delegate: ImageViewProtocol?
    
    func getImages(onSuccess success:@escaping (_ hits: [Hits]) -> Void, onFailure failure:@escaping () -> Void)  {
        DispatchQueue.global(qos: .background).async {
            let urlString = "https://pixabay.com/api/?key=16319352-2bb88398aa817f97a71677f6d&q=cats&image_type=photo@page=\(self.currentPage)"
        if let url = URL(string: urlString) {
            URLSession.shared.dataTask(with: url) { (data, response, error) in
                if error == nil, let data = data {
                    do {
                        let decoder = JSONDecoder()
                        let imageData = try decoder.decode(ImageModel.self, from: data)
                        self.model = imageData
                        DispatchQueue.main.async {
                            success(imageData.hits)
                        }
                    } catch {
                        self.model = nil
                        DispatchQueue.main.async {
                            failure()
                        }
                    }
                }
            }.resume()
        }
        }
    }
    
    func getHitsModel() -> [Hits]? {
        hitsModel = self.model?.hits
        
        return hitsModel
    }
}

extension ImageViewModel {
    func fetchNextPage(_ completion: @escaping ([Hits]) -> Void) {
        currentPage += 1
        if let newImageModel = self.model,  newImageModel.hits.count > newImageModel.total {
            completion([Hits]())
            return
        }
        getImages(onSuccess: { newHits in
            self.model?.hits.append(contentsOf: newHits)
            completion(newHits)
        }) {
            completion([Hits]())
            print("Failed to Fetch Items")
        }
    }
    
    
}
