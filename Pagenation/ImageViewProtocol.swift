//
//  ImageViewProtocol.swift
//  TestProject
//
//  Created by Gopi Krishna Gajawada on 1/7/21.
//  Copyright © 2021 Gopi Krishna Gajawada. All rights reserved.
//

import Foundation

protocol ImageViewProtocol: AnyObject {
    func fetchNextPage(_ completion: @escaping (_ hits: [Hits]) -> Void)
}
