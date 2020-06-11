//
//  Photo+Extension.swift
//  Virtual Tour
//
//  Created by Rudy James Jr on 6/9/20.
//  Copyright © 2020 James Consutling LLC. All rights reserved.
//

import Foundation
import UIKit

extension FlickrPhoto {
    
    func downloadPhoto(completionHandler handler: @escaping (_ data: Data?) -> Void){

        DispatchQueue.global(qos: .userInitiated).async { () -> Void in

            if let url = URL(string: "https://farm\(self.farm).staticflickr.com/\(self.server)/\(self.id)_\(self.secret)_z.jpg"), let imgData = try? Data(contentsOf: url) {

                // all set and done, run the completion closure!
                DispatchQueue.main.async(execute: { () -> Void in
                    handler(imgData)
                })
            }
            else {
                DispatchQueue.main.async(execute: { () -> Void in
                    handler(nil)
                })
            }
        }
    }
}
