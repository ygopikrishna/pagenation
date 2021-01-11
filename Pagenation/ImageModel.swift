//
//  ImageModel.swift
//  TestProject
//

import Foundation

struct ImageModel: Codable {
    let total: Int
    var hits: [Hits]
}

struct Hits: Codable {
    let largeImageURL: String?
    let previewURL: String?
    let tags: String?
}
