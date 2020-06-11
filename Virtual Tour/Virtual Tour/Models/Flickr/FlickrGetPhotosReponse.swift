//
//  FlickrGetPhotosResponse.swift
//  Virtual Tour
//
//  Created by Rudy James Jr on 6/9/20.
//  Copyright © 2020 James Consutling LLC. All rights reserved.
//

import Foundation

class FlickrGetPhotosResponse: Codable {
    let photos: FlickrPhotosPage
    let stat: String
}
