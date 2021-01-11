//
//  ImageDownloader.swift
//  Pagenation
//

import UIKit

/// ImageResult is the result returned in all the fetch methods.
public enum ImageResult {
    /// The success case will return an UIImage.
    case success(UIImage)
    /// The Failure case will return an ErrorType.
    case failure(Error)
}

/// ImageDownloadError is the failure result returned in all the fetch methods.
public enum ImageDownloadError: Error {
    /// The Failure case will return an ErrorType.
    case imageEmptyDataError
    /// The Failure case will return an ErrorType.
    case imageBadURLError
}

/// The ImageDownloaderCompletionHandler is a closure that will contain an ImageResult object.
public typealias ImageDownloaderCompletionHandler = (ImageResult) -> Void

/// ImageDownloader was created to provide a single solution for image downloading. It uses a cache so we don't have to redownload images.
open class ImageDownloader {

    /// The shared instance of the ImageDownloader. Useful since this keeps track of the internal image cache, and the completion handlers associated with each task.
    public static let sharedInstance = ImageDownloader()

    /// An NSCache for storing previously fetched images.
    fileprivate let imageCache = NSCache<NSString, AnyObject>()

    /// The file manager in charge of looking up paths inside the documents cache directory for storing images.
    fileprivate let fileManager = FileManager()

    /// An operation queue used to asynchronously store images to disk, or retrieving them synchronously.
    fileprivate let cacheQueue = DispatchQueue(label: "com.imageCache.queue")

    /// This property will store the name of the folder inside the cache documents directory.
    fileprivate let cacheDirectory: String

    /// This dictionary keeps track of completion handlers associated with image loading. This way, we are able to keep track of image requests in progress to avoid making duplicate image requests.
    fileprivate var queryDictionary = [URL: [ImageDownloaderCompletionHandler]]()

    /// NSURLSession object to handle the actual data tasks for getting images
    fileprivate let session    = URLSession(configuration: URLSessionConfiguration.default)

    /// In this method, we will setup the observer in case the app is under heavy memory pressure.
    internal init() {

        cacheDirectory = NSTemporaryDirectory().appending("com.pagenation.cache/images/")

        if !fileManager.fileExists(atPath: cacheDirectory) {
            do {
                try fileManager.createDirectory(atPath: cacheDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating the image cache directory at: \(cacheDirectory)")
            }
        }

        NotificationCenter.default.addObserver(forName: UIApplication.didReceiveMemoryWarningNotification,
                                               object: nil,
                                               queue: OperationQueue.main) { [weak self] (_) in
                                                self?.imageCache.removeAllObjects()
        }

    }

    /// In this method, we need to cleaning up by removing the observer.
    deinit {
        NotificationCenter.default.removeObserver(self)
        print("Deinitialized ImageDownloader")
    }

    // MARK: - Fetch

    /// Fetch an image from the web using a URL.
    ///
    /// - Parameters:
    ///   - url: An image URL for which to obtain an image
    ///   - completion: A closure to be executed when the call is finished. If successful then it contains UIImage object. Otherwise it will contain an error
    func fetchImage(withURL url: URL, andSaveToCache shouldSaveOnCache: Bool = true, completion: @escaping ImageDownloaderCompletionHandler) {
        // First, check to see if the image is on the cache. If it is, we just return that
        if let image = self.hasImageOnCache(withURL: url) {
            completion(.success(image))
            return
        }
        let urlString = url.absoluteString
        downloadImage(url: url, andSaveToCache: shouldSaveOnCache, key: urlString, path: path(withKey: urlString), completion: completion)
    }

    // MARK: - Download
    /// This method will try to fetch the image based on the url.
    /// Use the closure provided to handle anything the user wants to use the image obtained like cached and writtern to disk.
    private func downloadImage(url: URL, andSaveToCache shouldSaveOnCache: Bool = true, key: String? = nil, path: String? = nil, completion: @escaping ImageDownloaderCompletionHandler) {
        let request = URLRequest(url: url)
        let task = session.dataTask(with: request, completionHandler: { [weak self] (data, _, error) -> Void in
            guard let strongSelf = self else { return }
            let result = strongSelf.processImageRequest(data, error: error as NSError?)

            guard case let .success(image) = result else {
                // If there was an error with the request, we return it
                if error != nil {
                    completion(.failure(error!))
                } else {  // Otherwise, we return the image processing error
                    completion(result)
                }
                return
            }
            print("image downloaded with url: \(url)")
            if shouldSaveOnCache, let key = key, let path = path {
                strongSelf.saveImageOnCache(image: image, key: key, path: path)
            }
            completion(.success(image))
        })
        task.resume()
    }

    // MARK: - Fetch

    /// Fetch an image from the web using a URL. This method uses an internal dictionary to store tasks associated with fetching an image.

    private func fetchImage(imageURL: URL, completion: @escaping ImageDownloaderCompletionHandler) {
        let decompress: (UIImage) -> UIImage = { (image) in
            UIGraphicsBeginImageContext(image.size)
            image.draw(in: CGRect(origin: .zero, size: image.size))
            guard let decompressedImage = UIGraphicsGetImageFromCurrentImageContext() else { return image }
            UIGraphicsEndImageContext()
            return decompressedImage
        }

        // First, check to see if the image is on the cache. If it is, we just return that
        if let image = self.hasImageOnCache(imageURL: imageURL) {
            completion(.success(decompress(image)))
            return
        }

        self.fetchImage(withURL: imageURL) { (imageResult) in
            switch imageResult {
            case let .success(image):
                completion(.success(decompress(image)))
            case .failure:
                completion(.failure(ImageDownloadError.imageBadURLError))
            }
        }
        return
    }

    private func hasImageOnCache(withURL url: URL, checkDisk: Bool = true) -> UIImage? {
        let urlString = url.absoluteString
        return hasImageOnCache(urlString, checkDisk: checkDisk, path: self.path(withKey: urlString))
    }

    /// This methods checks if the image is already stored on Cache.
    ///
    /// - Parameter url: An image URL for which to obtain an image.
    /// - Parameter checkDisk: Should check disk for cached image. Default value is true.
    /// - Returns: An image that is already on the cache.
    private func hasImageOnCache(_ key: String, checkDisk: Bool = true, path: @autoclosure () -> String) -> UIImage? {
        if let image = imageCache.object(forKey: key as NSString) as? UIImage {
            print("ImageDownloader - using cached image forKey: \(key)")
            return image
        } else if checkDisk {
            // Then check if image is on Documents Cache.
            var image: UIImage?
            cacheQueue.sync {
                let cachePath = path()
                if fileManager.fileExists(atPath: cachePath), let cachePathURL = URL(string: cachePath) {
                    do {
                        let rawdata = try Data(contentsOf: cachePathURL)
                        image = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(rawdata) as? UIImage
                    } catch {
                        print("ImageDownloader - No cached image on disk for \(key)")
                    }
                    print("ImageDownloader - using cached image on disk for \(key)")
                } else {
                    print("ImageDownloader - No cached image on disk for \(key)")
                }
            }
            if let image = image {
                // Since the image was not on the NSCache, we add it back for quicker loading
                print("ImageDownloader - saving image from disk to cache forKey: \(key)")
                self.imageCache.setObject(image, forKey: key as NSString)
            }
            return image
        }
        print("ImageDownloader - no image avilable in cache for \(key)")
        return nil
    }

    /// This methods checks if the image is already stored on Cache.
    /// - Parameter imageURL: An image URL for which to obtain an image.
    /// - Returns: An image that is already on the cache.
    private func hasImageOnCache(imageURL: URL, checkDisk: Bool = true) -> UIImage? {
        return hasImageOnCache(withURL: imageURL, checkDisk: checkDisk)
    }

    private func getArchivedImage(forKey key: URL) -> UIImage? {
        var image: UIImage?
        cacheQueue.sync {
            let path = self.path(withKey: key.absoluteString)
            if fileManager.fileExists(atPath: path), let pathURL = URL(string: path) {
                do {
                    let rawdata = try Data(contentsOf: pathURL)
                    image = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(rawdata) as? UIImage
                } catch {
                    print("ImageDownloader - No cached image on disk for \(key)")
                }
            }
        }
        return image
    }

    /// This methods stores an image on the Cache. It will both save it on the NSCache and on the documents cache.
    /// - Parameter image: The image to store on the cache.
    /// - Parameter url: An image URL for which to obtain an image.
    fileprivate func saveImageOnCache(image: UIImage, key: String, path: String) {
        self.imageCache.setObject(image, forKey: key as NSString)
        print("ImageDownloader - Image saved to cache forKey: \(key)")
        // Also store it on Documents Cache
        cacheQueue.async {
            if let pathURL = URL(string: path) {
                do {
                    let data = try NSKeyedArchiver.archivedData(withRootObject: image, requiringSecureCoding: false)
                    try data.write(to: pathURL)
                    print("ImageDownloader - Image saved on disk forKey: \(key)")
                } catch {
                    print("ImageDownloader - Image cannot be disk forKey: \(key)")
                }
            } else {
                print("ImageDownloader - Image cannot be disk forKey: \(key)")
            }
        }
    }

    /// This methods returns the path of an image stored on the documents directory.
    /// - Parameter forKey: An image URL used as the name of the file in the documents directory.
    /// - Returns: A String, with the absolute file path of an image.
    private func path(withKey key: String) -> String {
        let prefixToRemove = key.hasPrefix("https") ? "https://" : "http://"
        var path = key.replacingOccurrences(of: prefixToRemove, with: "")
        path = path.replacingOccurrences(of: "/", with: "-")
        return cacheDirectory.appending(path).appending("cache.jpg")
    }

    // MARK: - ProcessImage

    /// Converts data into an image.
    /// - Parameter data: An NSData object from a web service that will be converted into an image.
    /// - Parameter error: An NSError object that will be used to catch any error.
    /// - Returns: An ImageResult that contains the image or an error
    private func processImageRequest(_ data: Data?, error: NSError?) -> ImageResult {
        guard let imageData = data, let image = UIImage(data: imageData) else {
            if data == nil { // We couldn't create an image because there was no data.
                return .failure(ImageDownloadError.imageEmptyDataError)
            } else {
                if error != nil { // We couldn't create an image because there was an error on the query.
                    return .failure(error!)
                } else {
                    // We couldn't create an image, because URL provided did not contain an image.
                    return .failure(ImageDownloadError.imageBadURLError)
                }
            }
        }
        return .success(image)
    }

    // TODO:
    /// Need to determine the use for this as we cannot keep on downloding and writing images to disk, we have to delete images on disk when new images are being downloaded.
    /// This function provides list of files in given path and can delete the files or dictonary as per requirement.
    func deleteImagesOnDisk() {
        let documentsPath = NSTemporaryDirectory().appending("com.pagenation.cache/images/")
        do {
            let fileNames = try fileManager.contentsOfDirectory(atPath: "\(documentsPath)")
            print("all files in cache: \(fileNames)")
            for files in fileNames {
                let fileToDelete = documentsPath + files
                try fileManager.removeItem(atPath: fileToDelete)
                print("deleted files on disk: \(fileToDelete)")
            }
        } catch {
            print("Could not clear temp folder: \(error)")
        }
    }
}
