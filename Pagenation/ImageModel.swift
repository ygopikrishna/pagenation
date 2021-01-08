//
//  ImageModel.swift
//  TestProject
//
//  Created by Gopi Krishna Gajawada on 1/7/21.
//  Copyright © 2021 Gopi Krishna Gajawada. All rights reserved.
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
