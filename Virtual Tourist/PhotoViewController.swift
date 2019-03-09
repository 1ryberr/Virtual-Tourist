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
import Network


class PhotoViewController: UIViewController{
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var noImages: UILabel!
    @IBOutlet weak var deleteBarBtn: UIBarButtonItem!
    
    private var images = [URL]()
    private var hasPhotos: Bool!
    private var saveData = [Data]()
    private var managedObjectContext: NSManagedObjectContext!
    private var coordinates: CLLocationCoordinate2D!
    private var pin = [Pin]()
    private var newPhoto = [Photo]()
    private let imageCache = NSCache<NSString, UIImage>()
    private var img : UIImage!
    private var longPressGesture: UILongPressGestureRecognizer!
    
   
    override func viewWillAppear(_ animated: Bool) {
        uploadData(hasPhotos)
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
        navigationItem.rightBarButtonItem = editButtonItem
        
        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(self.refresh), for: UIControl.Event.valueChanged)
        collectionView?.refreshControl = refresh

    }
    
    func setHasPhotos(hasPhotos: Bool){
        self.hasPhotos = hasPhotos
    }
    
    func setCoordinates(coordinates: CLLocationCoordinate2D){
        self.coordinates = coordinates
    }

    @objc func refresh() {
       deleteAndCreate()
       collectionView?.refreshControl?.endRefreshing()
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
    
    func loadPinData(latitude: Double, longitude: Double) {
        var photo = [Photo]()
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
                
                for image in photo where image.pin?.objectID == pin[0].objectID{
                    newPhoto.append(image)
                }
                
            }
            
            newPhoto = Array(Set(newPhoto))
            
        }catch{
            print("caught an error\(error)")
        }
        photo.removeAll()
    }
    
    func setMapRegion(for location: CLLocationCoordinate2D, animated: Bool, _ mapView: MKMapView) {
        let viewRegion = MKCoordinateRegion.init(center: location,latitudinalMeters: 60000, longitudinalMeters: 60000)
        mapView.setRegion(viewRegion, animated: animated)
    }
    
    func savePinData() {
        let saveData = self.saveData
        let pinObject = Pin(context: managedObjectContext)
        pinObject.latitude = coordinates.latitude
        pinObject.longitude = coordinates.longitude
        
        for data in 0..<saveData.count{
            let photoObject = Photo(context: managedObjectContext)
            photoObject.photoURL = saveData[data]
            pinObject.addToPhoto(photoObject)
            
        }
        if !saveData.isEmpty {
            save()
        } else if !pin.isEmpty{
            managedObjectContext.delete(pin[0])
            save()
        }
        
    }
    
     func uploadData(_ hasPhotos: Bool) {
        if !hasPhotos{
            if #available(iOS 12.0, *) {
                let monitor = NWPathMonitor()
                
                monitor.pathUpdateHandler = { path in
                    if path.status == .satisfied {
                        self.flickrUpDateBatch()
                        print("We're connected!")
                    } else {
                        print("No connection.")
                    }
                    
                    print(path.isExpensive)
                }
                let queue = DispatchQueue(label: "Monitor")
                monitor.start(queue: queue)
            } else {
                self.flickrUpDateBatch()
            }
            
        }
    }
    
    func save() {
        
        do{
            try managedObjectContext.save()
            DispatchQueue.main.async {
            self.navigationController?.popViewController(animated: true)
            }
            
            print("saved")
            
        }catch{
            print("caught an error\(error)")
        }
    }
    
    func flickrUpDateBatch() {
        
        let methodParameters = [
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod,
            Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
            Constants.FlickrParameterKeys.Latitude:  "\(coordinates.latitude)",
            Constants.FlickrParameterKeys.Longitude: "\(coordinates.longitude)",
            Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,
            Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
            Constants.FlickrParameterKeys.Page:  "\(Int(arc4random_uniform(UInt32(10))) + 1)",
            Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback
        ]
        
        FlickrClient.sharedInstance.displayImageFromFlickrBySearch(url:"\(flickrURLFromParameters(methodParameters as [String : AnyObject]))",completionHandlerForPOST: {[weak self] myImages,error in
            guard (error == nil) else {
                print("\(error!)")
                return
            }
          
            if myImages != nil{
                self?.images = myImages!
            }
            
            DispatchQueue.main.async {
                self?.hasPhotos = false
                self?.collectionView.reloadData()
            }
        })
        imageCache.removeAllObjects()
    }
    
    func deleteAndCreate() {
    
        loadPinData(latitude: coordinates.latitude, longitude: coordinates.longitude)
        
        if !pin.isEmpty{
            managedObjectContext.delete(pin[0])
            
            for image in (0..<newPhoto.count).reversed(){
                let photo = self.newPhoto[image]
                managedObjectContext.delete(photo)
            }
            save()
        }
        
        collectionView.performBatchUpdates({
            if images.isEmpty && hasPhotos{
                batchUpdate(&newPhoto)
            }
            flickrUpDateBatch()
        }, completion: nil)
    }
    
    func batchUpdate( _ images: inout [Photo]) {
        
        for image in (0..<images.count).reversed(){
            images.remove(at: image)
            let index = IndexPath(row: images.count, section: 0)
            collectionView.deleteItems(at: [index])
        }
    }
    
    func flickrURLFromParameters(_ parameters: [String:AnyObject]) -> URL {
        
        var components = URLComponents()
        components.scheme = Constants.Flickr.APIScheme
        components.host = Constants.Flickr.APIHost
        components.path = Constants.Flickr.APIPath
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }
    
    
    func deleteItems(){
        
        if let selected = collectionView.indexPathsForSelectedItems {
            let items = selected.map{$0.item}.sorted().reversed()
            if newPhoto.isEmpty && !hasPhotos{
                for item in items {
                    images.remove(at: item)
                    let index = IndexPath(row: item, section: 0)
                    collectionView.deleteItems(at: [index])
                }
            }else if images.isEmpty && hasPhotos{
                
                for item in items {
                    newPhoto.remove(at: item)
                    let index = IndexPath(row: item, section: 0)
                    collectionView.deleteItems(at: [index])
                }
            }
        }
        
    }
    
    func delete() {
        
        if !pin.isEmpty{
            
            var twoDArray = collectionView.indexPathsForSelectedItems
            for image in (twoDArray?.sorted(by: >))!{
                let photos = newPhoto[image.row]
                managedObjectContext.delete(photos)
            }
            save()
            twoDArray?.removeAll()
        }
        
        collectionView.performBatchUpdates({
            deleteItems()
        }, completion: nil)
        
     navigationController?.isToolbarHidden = true
        
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        if !editing {
           navigationController?.isToolbarHidden = true
        } else {
            collectionView.allowsMultipleSelection = true
            self.navigationItem.rightBarButtonItem = self.deleteBarBtn
        }
        
    }
    
    @IBAction func deleteBtn(_ sender: Any) {
        delete()
        isEditing = false
         self.navigationItem.rightBarButtonItem = self.editButtonItem
        
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

extension PhotoViewController: UICollectionViewDataSource,UICollectionViewDelegate, UICollectionViewDelegateFlowLayout{
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if !hasPhotos {
            noImages.isHidden = !(self.images.count == 0)
            print("Number of items in section \(images.count)")//print statement
            return images.count
        }else{
            
            print("Number of items in section \(newPhoto.count)")//print statement
            return newPhoto.count
            
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CELL", for: indexPath) as! PhotoCollectionViewCell
        
        if !hasPhotos{
            var spinnerView: UIView!
            spinnerView = MapViewController.displaySpinner(onView: cell)
            
            DispatchQueue.global(qos:.userInitiated).async {
                let imageURL = self.images[indexPath.item]
                if let imageFromCache: UIImage = self.imageCache.object(forKey: ((imageURL.absoluteString) + "\(indexPath.row)") as NSString) {
                    self.img = imageFromCache
                }else{
                    if let imageData = try? Data(contentsOf: imageURL){
                        self.img = UIImage(data: imageData)
                        self.saveData.append(imageData)
                     if  self.saveData.count == 21{
                         self.savePinData()
                        self.saveData.removeAll()
                       }
                        self.imageCache.setObject(self.img, forKey:((imageURL.absoluteString) + "\(indexPath.row)")as NSString)
                    }
                }
                DispatchQueue.main.async {
                    cell.photoImage.image = self.img
                    MapViewController.removeSpinner(spinner:spinnerView)
                }
            }
            
            
        } else {
            
            DispatchQueue.global(qos:.userInitiated).async {
                let img = UIImage(data: self.newPhoto[indexPath.row].photoURL! as Data)
                DispatchQueue.main.async {
                    cell.photoImage.image = img
                }
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width:(UIScreen.main.bounds.width - 20)/3, height:(UIScreen.main.bounds.width - 20)/3)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        
        if isEditing{
            let cell = collectionView.cellForItem(at: indexPath)
            cell?.alpha = cell?.alpha == 1 ? 0.5 : 1
            if cell?.alpha == 1 && (collectionView.indexPathsForSelectedItems?.contains(indexPath))!{
                collectionView.deselectItem(at: indexPath, animated: true)
                if (collectionView.indexPathsForSelectedItems?.isEmpty)!{
                   navigationController?.isToolbarHidden = true
                }
                
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        print("Starting Index:  \(sourceIndexPath.item)" )
        print("Ending Index: \(destinationIndexPath.item)")
    }
    
}


