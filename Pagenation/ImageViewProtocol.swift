//
//  ImageViewProtocol.swift
//  TestProject
//

import Foundation

protocol ImageViewProtocol: AnyObject {
    func fetchNextPage(_ completion: @escaping (_ hits: [Hits]) -> Void)
}
