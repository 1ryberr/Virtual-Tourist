//
//  PhotoCollectionViewCell.swift
//  Virtual Tourist
//
//  Created by Ryan Berry on 5/24/18.
//  Copyright © 2018 Ryan Berry. All rights reserved.
//

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {
    
    
  
     var img : UIImage!
    var saveData = [Data]()
    @IBOutlet weak var photoImage: UIImageView!
    override func layoutSubviews() {
        self.layer.cornerRadius = 6
        layer.borderWidth = 2
    }
    
    
    func downloadImage(url: URL, saveData: inout [Data],  completion: @escaping (_ image: UIImage?, _ saveData: [Data]?, _ error: Error? ) -> Void) {
        let imageCache = NSCache<NSString, UIImage>()
        var saveData = saveData
        if let image = imageCache.object(forKey: url.absoluteString as NSString) {
            completion(image,nil, nil)
        } else {
            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                if let error = error {
                    completion(nil,nil, error)
                    
                } else if let data = data, let image = UIImage(data: data) {
                    imageCache.setObject(image, forKey: url.absoluteString as NSString)
                     saveData.append(data)
                    completion(image,saveData, nil)
                } else {
                    completion(nil,nil, error)
                }
            }
            
            task.resume()
        }
    }
    
}
