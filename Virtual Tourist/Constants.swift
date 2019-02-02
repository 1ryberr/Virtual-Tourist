//
//  Constants.swift
//  Virtual Tourist
//
//  Created by Ryan Berry on 2/2/19.
//  Copyright © 2019 Ryan Berry. All rights reserved.
//

import Foundation
struct Constants {
    
    struct Flickr {
        static let APIScheme = "https"
        static let APIHost = "api.flickr.com"
        static let APIPath = "/services/rest"
        
    }
    
    struct FlickrParameterKeys {
        static let Method = "method"
        static let APIKey = "api_key"
        static let Extras = "extras"
        static let Format = "format"
        static let NoJSONCallback = "nojsoncallback"
        static let Page = "page"
        static let Latitude = "lat"
        static let Longitude = "lon"
    }
    
    struct FlickrParameterValues {
        static let SearchMethod = "flickr.photos.search"
        static let APIKey = "ee684b4e6223a2050bf31b5f4ef93f61"
        static let ResponseFormat = "json"
        static let DisableJSONCallback = "1"
        static let MediumURL = "url_m"
    }
    
}
    struct FlickrPagedImageResult:  Codable {
        let photos: Photos?
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
    

