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
    
    var FLICKER_API_KEY = "ee684b4e6223a2050bf31b5f4ef93f61"
    var images = [String]()
    var hasPhotos: Bool!
    var saveData = [Data]()
    var managedObjectContext: NSManagedObjectContext!
    var coordinates: CLLocationCoordinate2D!
    var pin = [Pin]()
    var newPhoto = [Photo]()
    let imageCache = NSCache<NSString, UIImage>()
    var img : UIImage!
    var longPressGesture: UILongPressGestureRecognizer!
    
    
    override func viewWillAppear(_ animated: Bool) {
        
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
    
    override func viewWillDisappear(_ animated: Bool) {
        saveData.removeAll()
        images.removeAll()
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
    
    @objc func savePinData() {
        let saveData = self.saveData.prefix(21)
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
            navigationController?.popViewController(animated: true)
        }
        
    }
    
    func save() {
        
        do{
            try managedObjectContext.save()
            print("saved")
            
        }catch{
            print("caught an error\(error)")
        }
    }
    
    func flickrUpDateBatch() {
        
        let page = Int(arc4random_uniform(3)) + 1
        let FLICKER_LINK = "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(FLICKER_API_KEY)&lat=\(coordinates.latitude)&lon=\(coordinates.longitude)&extras=url_m&page=\(page)&format=json&nojsoncallback=1"
        
        FlickrClient.sharedInstance.displayImageFromFlickrBySearch(url:FLICKER_LINK,completionHandlerForPOST: {myImage,error in
            guard (error == nil) else {
                print("\(error!)")
                return
            }
            
            if let myImage = myImage{
                self.images = Array(Set(myImage))
                print("Printed from flickr method \(self.images.count)")//print statement
                if case 19...40 = self.images.count {
                    self.images = Array(self.images[19..<self.images.count])
                }else if case 40...61 = self.images.count {
                    self.images = Array(self.images[40..<self.images.count])
                }else if case 61...82 = self.images.count {
                    self.images = Array(self.images[61..<self.images.count])
                }else if case 82...103 = self.images.count {
                    self.images = Array(self.images[82..<self.images.count])
                }else if case 103...124 = self.images.count {
                    self.images = Array(self.images[103..<self.images.count])
                }else if case 124...145 = self.images.count {
                    self.images = Array(self.images[124..<self.images.count])
                }else if case 145...166 = self.images.count {
                    self.images = Array(self.images[145..<self.images.count])
                }else if case 166...187 = self.images.count {
                    self.images = Array(self.images[166..<self.images.count])
                }else if case 187...208 = self.images.count {
                    self.images = Array(self.images[187..<self.images.count])
                }else if case 208...229 = self.images.count {
                    self.images = Array(self.images[208..<self.images.count])
                }else if case 229...250 = self.images.count {
                    self.images = Array(self.images[229..<self.images.count])
                }
                
            }
            
            DispatchQueue.main.async {
                self.hasPhotos = false
                self.collectionView.reloadData()
                self.perform(#selector(self.savePinData), with: nil, afterDelay: 7)
                
            }
            
            
        })
        imageCache.removeAllObjects()
        
       
        
    }
    
    func deleteAndCreate() {
        
    
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(savePinData), object: nil)
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
    
    func batchUpdate( _ images : inout [Photo]) {
        
        for image in (0..<images.count).reversed(){
            images.remove(at: image)
            let index = IndexPath(row: images.count, section: 0)
            collectionView.deleteItems(at: [index])
        }
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
                print(self.images)
                let imageURL = URL(string:self.images[indexPath.item])
                if let imageFromCache: UIImage = self.imageCache.object(forKey: ((imageURL?.absoluteString)! + "\(indexPath.row)") as NSString) {
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


