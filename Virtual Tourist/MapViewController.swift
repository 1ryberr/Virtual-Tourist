//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by Ryan Berry on 12/30/17.
//  Copyright © 2017 Ryan Berry. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController{
    
    var FLICKER_API_KEY = "ee684b4e6223a2050bf31b5f4ef93f61"
    var coordinates: CLLocationCoordinate2D!
    var managedObjectContext: NSManagedObjectContext!
    var photo = [Photo]()
    var pin = [Pin]()
    var newPin = [Pin]()
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var deleteLabel: UILabel!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        loadPinData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(addAnnotation(press:)))
        mapView.addGestureRecognizer(longPress)
    
    }
    
    func removePinCoordinates() {
        let annotations = mapView.annotations
        mapView.removeAnnotations(annotations)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        removePinCoordinates()
    }
    
    func pinCoordinates(_ coordinates: CLLocationCoordinate2D) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinates
        mapView.addAnnotation(annotation)
    }
    
    @objc func addAnnotation(press: UILongPressGestureRecognizer){
        
        if press.state == .began{
            let longTouchPoint = press.location(in: mapView)
            let coordinates = mapView.convert(longTouchPoint, toCoordinateFrom: mapView)
            pinCoordinates(coordinates)
        }
    }
    
    func loadPinData(latitude: Double, longitude: Double) {
        
        let pinRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        pinRequest.fetchLimit = 1
        pinRequest.returnsObjectsAsFaults = false
        pinRequest.predicate = NSPredicate(format: "latitude == %@ && longitude == %@" , argumentArray: [latitude,longitude])
        
        do{
            newPin = try managedObjectContext.fetch(pinRequest)
            
        }catch{
            
            print("caught an error\(error)")
        }
        
    }
    
    func loadPinData() {
        
        managedObjectContext = CoreDataStack().persistentContainer.viewContext
        let pinRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        pinRequest.returnsObjectsAsFaults = false
        let photoRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        photoRequest.returnsObjectsAsFaults = false
        
        do{
            photo = try managedObjectContext.fetch(photoRequest)
            pin = try managedObjectContext.fetch(pinRequest)
            for i in 0..<pin.count{
                let coordinates = CLLocationCoordinate2D(latitude: (pin[i].latitude), longitude:  (pin[i].longitude))
                pinCoordinates(coordinates)
            }
            
        }catch{
            print("caught an error\(error)")
        }
    }
    
    func save(){
        
        do{
            try managedObjectContext.save()
            print("saved")
            
        }catch{
            print("caught an error\(error)")
        }
    }
    
    func processPhoto(_ newPin:[Pin]) {
        if deleteLabel.isHidden{
            
            let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            let viewController = storyboard.instantiateViewController(withIdentifier: "PhotoViewController") as! PhotoViewController
            viewController.hasPhotos = !newPin.isEmpty
            viewController.coordinates = self.coordinates
            self.navigationController?.pushViewController(viewController, animated: true)
        }
        
    }
    
    @IBAction func editBtn(_ sender: Any) {
        deleteLabel.isHidden = !deleteLabel.isHidden
        if deleteLabel.isHidden == true{
            
        }
        
    }
    
}

extension MapViewController: MKMapViewDelegate{
    
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
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        coordinates = view.annotation?.coordinate
        loadPinData(latitude: coordinates.latitude, longitude: coordinates.longitude)
        
//        if !newPhoto.isEmpty && !deleteLabel.isHidden{
//            for photo in newPhoto{
//                managedObjectContext.delete(photo)
//            }
//            managedObjectContext.delete(newPin[0])
//            if let annotations = view.annotation{
//                mapView.removeAnnotation(annotations)
//            }
//            print(newPin)
//            save()
//
//        }else{
        
            processPhoto(newPin)
   //    }
    }
    
}

extension MapViewController {
    
    class func displaySpinner(onView : UIView) -> UIView {
        let spinnerView = UIView.init(frame: onView.bounds)
        spinnerView.backgroundColor = UIColor.darkGray//UIColor.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
        
        let ai = UIActivityIndicatorView.init(activityIndicatorStyle: .whiteLarge)
        ai.startAnimating()
        ai.center = spinnerView.center
        DispatchQueue.main.async {
            spinnerView.addSubview(ai)
            onView.addSubview(spinnerView)
        }
        
        return spinnerView
    }
    
    class func removeSpinner(spinner :UIView) {
        
        DispatchQueue.main.async {
            spinner.removeFromSuperview()
        }
    }
}


