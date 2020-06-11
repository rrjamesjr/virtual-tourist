//
//  FlickrClient.swift
//  Virtual Tour
//
//  Created by Rudy James Jr on 6/9/20.
//  Copyright © 2020 James Consutling LLC. All rights reserved.
//

import Foundation

class FlickrClient {
    struct Credentials {
        static let key:String = "f682b40f4269195dbbd1e9dd456e74c4"
        static let secret:String = "8bae785af63d06b8"
    }
    
    struct Paging {
        static var currentPage: Int = 1
        static var totalPages: Int?
    }
    
    enum Endpoints {
        
        static let base = "https://api.flickr.com/services/rest?api_key=\(Credentials.key)"
        
        case getPhotos(Double, Double, Int)
        
        var stringValue: String {
            switch self {
            case let .getPhotos(latitude, longitude, page): return Endpoints.base + "&method=flickr.photos.search&format=json&lat=\(latitude)&lon=\(longitude)&page=\(page)"
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    class func getPhotos(latitude: Double, longitude: Double, page:Int, completion: @escaping (FlickrGetPhotosResponse?, Error?) -> Void) {
        let decoder = JSONDecoder()
        
        _ = taskForGETRequest(url: Endpoints.getPhotos(latitude, longitude, page).url) { response, data, error in
            if let response = response {
              //  print(response)
                let startIndex = response.firstIndex(of: "(")!
                let strippedJson = response[response.index(after: startIndex)..<response.index(response.endIndex, offsetBy: -1)]
                print(strippedJson)
                
                if let data  = strippedJson.data(using: String.Encoding.utf8) {
                do {
                    let responseObject = try decoder.decode(FlickrGetPhotosResponse.self, from: data)
                    DispatchQueue.main.async {
                        completion(responseObject, nil)
                    }
                } catch {
                    do {
                        let errorResponse = try decoder.decode(FlickrFailedResponse?.self, from: data)
                        DispatchQueue.main.async {
                            completion(nil, errorResponse)
                        }
                    } catch {
                        DispatchQueue.main.async {
                            completion(nil, error)
                        }
                    }
                    }
                }
                
            } else {
                do {
                    let errorResponse = try decoder.decode(FlickrFailedResponse?.self, from: data!)
                    DispatchQueue.main.async {
                        completion(nil, errorResponse)
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(nil, error)
                    }
                }
                completion(nil, error)
            }
        }
    }
    
    class func taskForGETRequest(url: URL, completion: @escaping (String?, Data?, Error?) -> Void) -> URLSessionDataTask {
        print(url)
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, nil, error)
                }
                return
            }
            //let decoder = JSONDecoder()
            
            
                
            if let responseObject = String(data: data, encoding: String.Encoding.utf8) {
                DispatchQueue.main.async {
                    completion(responseObject, nil, nil)
                }
            } else {
                DispatchQueue.main.async {
                    let error = NSError(domain: "biz.jamesconsulting.error", code: 0, userInfo: [NSLocalizedDescriptionKey: "Error dowloading \(url.absoluteString)"])
                    completion(nil, data, error)
                }

            }
            
        }
        task.resume()
        
        return task
    }
}
