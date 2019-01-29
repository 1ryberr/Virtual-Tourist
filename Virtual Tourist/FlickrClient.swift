//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by Ryan Berry on 1/2/18.
//  Copyright © 2018 Ryan Berry. All rights reserved.
//

import UIKit

struct FlickrPagedImageResult:  Codable {
    let photos: Photos?
  //  let stat: String
}
struct Photos: Codable {
    var photo: [ImageURL]
}
struct ImageURL: Codable{
    let url: URL?
    enum CodingKeys: String, CodingKey{
        case url = "url_m"
    }
}

class FlickrClient: NSObject {
    
    static let sharedInstance = FlickrClient()
    private override init() {}
    var imageURL: URL!
    var imageData: Data!
   

func displayImageFromFlickrBySearch(url: String, completionHandlerForPOST: @escaping (_ myImages: [URL]?, _ error: NSError?) -> Void) -> URLSessionDataTask{
    
    let url = URL(string: url)!
    let request = URLRequest(url: url)
    let session = URLSession.shared
    
    let task = session.dataTask(with: request) { (data, response, error) in
        
        func sendError(_ error: String) {
            print(error)
            let userInfo = [NSLocalizedDescriptionKey : error]
            completionHandlerForPOST(nil, NSError(domain: "getStudentInfo", code: 1, userInfo: userInfo))
        }
        
        guard (error == nil) else {
            sendError("There was an error with your request: \(error?.localizedDescription)")
            return
        }
        
        guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
            sendError("Your request returned a status code other than 2xx!")
            return
        }
        
        guard let data = data else {
            sendError("No data was returned by the request!")
            return
        }
     
        let parsedResult: FlickrPagedImageResult?
        let decoder = JSONDecoder()

        do {
            parsedResult =  try decoder.decode(FlickrPagedImageResult.self, from: data)
          
            
        }catch{
            sendError("Could not parse the data as JSON: '\(data)'")
            return

        }
        
        var imageArray: [URL] = []
        
        for item in (parsedResult?.photos?.photo)! {
            imageArray.append(item.url!)
        }

        if !imageArray.isEmpty {
            completionHandlerForPOST(imageArray, nil)
        }else{
            let myImages: [URL] = []
            completionHandlerForPOST(myImages, nil)
        }
    }
    task.resume()
    return task
}
    

}










