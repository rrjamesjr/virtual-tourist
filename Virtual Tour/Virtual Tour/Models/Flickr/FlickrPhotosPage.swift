//
//  FlickrPhotosPage.swift
//  Virtual Tour
//
//  Created by Rudy James Jr on 6/9/20.
//  Copyright © 2020 James Consutling LLC. All rights reserved.
//

import Foundation

struct FlickrPhotosPage: Codable {
    let page: Int
    let pages: Int
    let perPage: Int
    let total: String
    let photos: [FlickrPhoto]
    
    enum CodingKeys: String, CodingKey {
        case page
        case pages
        case perPage = "perpage"
        case total
        case photos = "photo"
    }
}
