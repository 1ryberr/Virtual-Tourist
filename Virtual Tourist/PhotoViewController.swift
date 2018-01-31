//
//  PhotoViewController.swift
//  Virtual Tourist
//
//  Created by Ryan Berry on 1/1/18.
//  Copyright © 2018 Ryan Berry. All rights reserved.
//

import UIKit
import MapKit
import CoreData


class PhotoViewController: UIViewController{
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollectionBtn: UIButton!
    @IBOutlet weak var removeBtn: UIButton!
    @IBOutlet weak var noImages: UILabel!
    var FLICKER_API_KEY = "ee684b4e6223a2050bf31b5f4ef93f61"
    var images = [String]()
    var hasPhotos: Bool!
    var saveData = [Data]()
    var managedObjectContext: NSManagedObjectContext!
    var coordinates: CLLocationCoordinate2D!
    var photo = [Photo]()
    var pin = [Pin]()
    let imageCache = NSCache<NSString, UIImage>()
    var img : UIImage!
    var longPressGesture: UILongPressGestureRecognizer!
    
    override func viewWillAppear(_ animated: Bool) {
        if !hasPhotos{
            flickrUpDateBatch()
           newCollectionBtn.isEnabled = false
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongGesture(gesture:)))
        collectionView.addGestureRecognizer(longPressGesture)
        
        
        managedObjectContext = CoreDataStack().persistentContainer.viewContext
        loadPinData(latitude: coordinates.latitude, longitude: coordinates.longitude)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinates
        mapView.addAnnotation(annotation)
        setMapRegion(for: coordinates, animated: true, mapView)
        
        // let dataPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        //print(dataPath)
    }
    @objc func handleLongGesture(gesture: UILongPressGestureRecognizer) {
        switch(gesture.state) {
            
        case .began:
            guard let selectedIndexPath = collectionView.indexPathForItem(at: gesture.location(in: collectionView)) else {
                break
            }
            collectionView.beginInteractiveMovementForItem(at: selectedIndexPath)
        case .changed:
            collectionView.updateInteractiveMovementTargetPosition(gesture.location(in: gesture.view!))
        case .ended:
            collectionView.endInteractiveMovement()
        default:
            collectionView.cancelInteractiveMovement()
        }
        
    }
    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    
    
    override func viewWillDisappear(_ animated: Bool) {
        saveData.removeAll()
        images.removeAll()
    }
    
    func loadPinData(latitude: Double, longitude: Double) {
        
        let pinRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        pinRequest.fetchLimit = 1
        pinRequest.returnsObjectsAsFaults = false
        pinRequest.predicate = NSPredicate(format: "latitude == %@ && longitude == %@" , argumentArray: [latitude,longitude])
        
        let photoRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        photoRequest.returnsObjectsAsFaults = false
        
        do{
            pin = try managedObjectContext.fetch(pinRequest)
            photo = try managedObjectContext.fetch(photoRequest)
            
            if images.isEmpty && hasPhotos{
                photo = photo.filter{$0.pin?.objectID == pin[0].objectID}
            }
            
        }catch{
            print("caught an error\(error)")
        }
        
    }
    
    
    func setMapRegion(for location: CLLocationCoordinate2D, animated: Bool, _ mapView: MKMapView){
        let viewRegion = MKCoordinateRegionMakeWithDistance(location,60000, 60000)
        mapView.setRegion(viewRegion, animated: animated)
    }
    
    
    @objc func savePinData(){
        newCollectionBtn.isEnabled = true
        var dataArray = [Data]()
        dataArray = Array(Set(saveData))
        
        if dataArray.count > 21{
            
            dataArray = Array(dataArray.prefix(21))
        }
        
        let pinObject = Pin(context: managedObjectContext)
        pinObject.latitude = coordinates.latitude
        pinObject.longitude = coordinates.longitude
        
        for data in 0..<dataArray.count{
            let photoObject = Photo(context: managedObjectContext)
            photoObject.photoURL = dataArray[data]
            pinObject.addToPhoto(photoObject)
            
        }
        if !dataArray.isEmpty{
            save()
        }else{
            if !pin.isEmpty{
                managedObjectContext.delete(pin[0])
                save()
            }
            navigationController?.popViewController(animated: true)
        }
        
        newCollectionBtn.isEnabled = true
        dataArray.removeAll()
        
    }
    
    
    func save(){
        
        do{
            try managedObjectContext.save()
            print("saved")
            
        }catch{
            print("caught an error\(error)")
        }
    }
    
    func flickrUpDateBatch() {
        
        var page = Int(arc4random_uniform(3)) + 1
        let FLICKER_LINK = "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(FLICKER_API_KEY)&lat=\(coordinates.latitude)&lon=\(coordinates.longitude)&extras=url_m&page=\(page)&format=json&nojsoncallback=1"
      
        var spinnerView: UIView
        spinnerView = MapViewController.displaySpinner(onView: view)
        
        FlickrClient.sharedInstance.displayImageFromFlickrBySearch(url:FLICKER_LINK,completionHandlerForPOST: {myImage,error in
            guard (error == nil) else {
                print("\(error!)")
                return
            }
            if let myImage = myImage{
                self.images = Array(Set(myImage))
                print(self.images.count)
                if self.images.count > 21 && self.images.count < 42{
                    self.images = Array(self.images[22..<self.images.count])
                }else if self.images.count > 43 {
                    self.images = Array(self.images[43..<64])
                }
            }
            MapViewController.removeSpinner(spinner: spinnerView)
            DispatchQueue.main.async{
                self.collectionView.reloadData()
            }
        })
        self.newCollectionBtn.isEnabled = true
        imageCache.removeAllObjects()
        perform(#selector(savePinData), with: nil, afterDelay: 7)
        
    }
    
    func deleteAndCreate(){
        newCollectionBtn.isEnabled = false
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(savePinData), object: nil)
        loadPinData(latitude: coordinates.latitude, longitude: coordinates.longitude)
        var twoDArray = collectionView.indexPathsForVisibleItems
        var array = [Int]()
        let allItems = collectionView.indexPathsForVisibleItems
        for i in 0..<allItems.count{
            array.append(collectionView.indexPathsForVisibleItems[i][1])
        }
        
        if !pin.isEmpty{
            for i in 0..<pin.count{
                if pin[i].latitude == coordinates.latitude && pin[i].longitude == coordinates.longitude{
                    managedObjectContext.delete(pin[i])
                }
                for num in array.sorted(by:>){
                    let photos = photo[num]
                    managedObjectContext.delete(photos)
                }
                save()
            }
        }
        
        collectionView.performBatchUpdates({
            
            if !images.isEmpty && !hasPhotos{
                if !array.isEmpty && !(twoDArray.isEmpty){
                    imageBatchUpdate(array, twoDArray,&images)
                }
            }
            
            if images.isEmpty && hasPhotos{
                if !array.isEmpty && !(twoDArray.isEmpty){
                    batchUpdate(array, twoDArray,&photo)
                }
                
            }
            flickrUpDateBatch()
        }, completion: nil)
        
        hasPhotos = false
        array.removeAll()
        twoDArray.removeAll()
        
    }
    
    func batchUpdate(_ array: [Int], _ twoDArray: [IndexPath]?, _ images : inout [Photo]) {
        
        if array.count == twoDArray?.count{
            for num in array.sorted(by: >){
                images.remove(at:num)
            }
            for index in (twoDArray?.sorted(by: >))!{
                collectionView.deleteItems(at: [index])
            }
        }
    }
    
    func imageBatchUpdate(_ array: [Int], _ twoDArray: [IndexPath], _ images : inout [String]) {
        
        if array.count == twoDArray.count{
            for num in array.sorted(by: >){
                images.remove(at:num)
            }
            for index in (twoDArray.sorted(by: >)){
                collectionView.deleteItems(at: [index])
            }
        }
    }
    
    func delete() {
        loadPinData(latitude: coordinates.latitude, longitude: coordinates.longitude)
        var twoDArray = collectionView.indexPathsForSelectedItems
        var array = [Int]()
        let collectionSelectedItems = collectionView.indexPathsForSelectedItems
        for i in 0..<collectionSelectedItems!.count{
            array.append(collectionView.indexPathsForSelectedItems![i][1])
        }
        
        if !pin.isEmpty{
            if pin[0].latitude == coordinates.latitude && pin[0].longitude == coordinates.longitude{
                for num in array.sorted(by:>){
                    let photos = photo[num]
                    managedObjectContext.delete(photos)
                }
                save()
            }
        }
        
        collectionView.performBatchUpdates({
            
            if !images.isEmpty && !hasPhotos{
                if !array.isEmpty && !((twoDArray?.isEmpty)!){
                    imageBatchUpdate(array, twoDArray!,&images)
                }
            }
            
            if images.isEmpty && hasPhotos{
                if !array.isEmpty && !((twoDArray?.isEmpty)!){
                    batchUpdate(array, twoDArray,&photo)
                }
                
            }
        }, completion: nil)
        
        twoDArray?.removeAll()
        array.removeAll()
        newCollectionBtn.isHidden = false
        removeBtn.isHidden = true
    }
    
    @IBAction func newCollectionBtn(_ sender: Any) {
        deleteAndCreate()
    }
    
    @IBAction func deleteButton(_ sender: Any) {
        delete()
    }
    
}

extension PhotoViewController: MKMapViewDelegate{
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "MyPin"
        
        if annotation is MKUserLocation {
            return nil
        }
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        annotationView?.canShowCallout = false
        annotationView?.annotation = annotation
        return  annotationView
    }
}

extension PhotoViewController: UICollectionViewDataSource,UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if !hasPhotos {
            noImages.isHidden = !(self.images.count == 0)
            newCollectionBtn.isEnabled = !(self.images.count == 0)
            return images.count
        }else{
            return photo.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CELL", for: indexPath) as! PhotoCollectionViewCell
        cell.layer.borderWidth = 1
        cell.layer.cornerRadius = 6
        
        if !hasPhotos{
            var spinnerView: UIView!
            spinnerView = MapViewController.displaySpinner(onView: cell)
            DispatchQueue.global(qos:.userInitiated).async {
                let imageURL = URL(string:self.images[indexPath.row])
                if let imageFromCache = self.imageCache.object(forKey: ((imageURL?.absoluteString)! + "\(indexPath.row)") as NSString) {
                    self.img = imageFromCache
                }else{
                    if let imageData = try? Data(contentsOf: imageURL!){
                        self.img = UIImage(data: imageData)!
                        self.saveData.append(imageData)
                        self.imageCache.setObject(self.img, forKey:((imageURL?.absoluteString)! + "\(indexPath.row)")as NSString)
                    }
                }
                DispatchQueue.main.async {
                    cell.photoImage.image = self.img
                    MapViewController.removeSpinner(spinner:spinnerView)
                }
                
            }
            
            
        }else {
            
            DispatchQueue.global(qos:.userInitiated).async {
                let img = UIImage(data: self.photo[indexPath.row].photoURL! as Data)
                DispatchQueue.main.async {
                    cell.photoImage.image = img
                }
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width:(UIScreen.main.bounds.width-20)/3, height:95)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.alpha = cell?.alpha == 1 ? 0.5 : 1
        collectionView.allowsMultipleSelection = true
        newCollectionBtn.isHidden = true
        removeBtn.isHidden = false
        if cell?.alpha == 1 && (collectionView.indexPathsForSelectedItems?.contains(indexPath))!{
            collectionView.deselectItem(at: indexPath, animated: true)
            if (collectionView.indexPathsForSelectedItems?.isEmpty)!{
                newCollectionBtn.isHidden = false
                removeBtn.isHidden = true
            }
            
        }
        
    }
    
    
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        print("Starting Index:  \(sourceIndexPath.item)" )
           print("Ending Index: \(destinationIndexPath.item)")
    }
    

}


