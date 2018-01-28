//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by Ryan Berry on 1/2/18.
//  Copyright © 2018 Ryan Berry. All rights reserved.
//

import UIKit

class FlickrClient: NSObject {
    
    static let sharedInstance = FlickrClient()
    private override init() {}
    var imageURL: URL!
    var imageData: Data!
    
    fileprivate func collectData( _ photoArray: [[String : AnyObject]])->[String] {
        var image = [String]()
        var photoDictionary:[String:AnyObject]!
        for i in 0..<photoArray.count{
            photoDictionary = photoArray[i] as [String:AnyObject]
            guard let imageUrlString = photoDictionary["url_m"] as? String else {
                print("Cannot find key '\("url_m")' in \(photoDictionary)")
                continue
            }
            
           image.append(imageUrlString)
        }
        

    
    return image
}


func displayImageFromFlickrBySearch(url: String, completionHandlerForPOST: @escaping (_ myImages: [String]?, _ error: NSError?) -> Void) -> URLSessionDataTask{
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
            sendError("There was an error with your request: \(error)")
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
        
        let parsedResult: [String:AnyObject]!
        do {
            parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:AnyObject]
        } catch {
            sendError("Could not parse the data as JSON: '\(data)'")
            return
        }
        
        guard let stat = parsedResult["stat"] as? String, stat == "ok" else {
            sendError("Flickr API returned an error. See error code and message in \(parsedResult)")
            return
        }
        
        guard let photosDictionary = parsedResult["photos"] as? [String:AnyObject]else{
            return
        }
        guard let photoArray = photosDictionary["photo"] as? [[String:AnyObject]] else {
            sendError("Cannot find keys '\("photos")' and '\("photo")' in \(parsedResult)")
            return
        }
        
        if !photoArray.isEmpty {
            let myImages = self.collectData(photoArray)
            completionHandlerForPOST(myImages, nil)
        }else{
            let myImages: [String] = []
            completionHandlerForPOST(myImages, nil)
        }
    }
    task.resume()
    return task
}

}










