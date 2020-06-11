//
//  FlickrFailedResponse.swift
//  Virtual Tour
//
//  Created by Rudy James Jr on 6/9/20.
//  Copyright © 2020 James Consutling LLC. All rights reserved.
//

import Foundation

class FlickrFailedResponse: Codable {
    let stat: String
    let code: Int
    let message: String
}


extension FlickrFailedResponse: LocalizedError {
    var errorDescription: String? {
        return message
    }
}
