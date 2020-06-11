//
//  MapViewController.swift
//  Virtual Tour
//
//  Created by Rudy James Jr on 6/8/20.
//  Copyright © 2020 James Consutling LLC. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController {
    @IBOutlet weak var map: MKMapView!
    
    var dataController:DataController!
    
    var fetchedResultsController:NSFetchedResultsController<Pin>!
    
    
    private var mapChangedFromUserInteraction = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.mapLongPress(_:))) // colon needs to pass through info
        longPress.minimumPressDuration = 1 // in seconds
        longPress.numberOfTouchesRequired = 1
        //add gesture recognition
        map.addGestureRecognizer(longPress)
        map.delegate = self
    
        if let region = UserDefaults.standard.getMapRegion() {
            map.setRegion(region, animated: true)
            map.camera.altitude = CLLocationDistance(UserDefaults.standard.double(forKey: UserDefaultsKeys.altitude.rawValue))
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupFetchedResultsController()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    
    func savePin(coordinate: CLLocationCoordinate2D) {
        let newPin = Pin(context: dataController.viewContext)
        newPin.latitude = coordinate.latitude
        newPin.longitude = coordinate.longitude
        newPin.currentPage = 1
        dataController.backgroundContext.perform {
            self.dataController.save()
        }
    }
    
    @objc func mapLongPress(_ recognizer: UIGestureRecognizer) {

        if recognizer.state != UIGestureRecognizer.State.began {
            return
        }
        
        print("A long press has been detected.")
        // Get the coordinates of the point you pressed long.
        let location = recognizer.location(in: map)
        
        // Convert location to CLLocationCoordinate2D.
        let coordinate: CLLocationCoordinate2D = map.convert(location, toCoordinateFrom: map)
        savePin(coordinate: coordinate)
    }
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "latitude", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "pins")
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
        
        bindPins()
    }
    
    func bindPins() {
        if let pin = fetchedResultsController.fetchedObjects {
            for travelLocation in pin {
                map.addAnnotation(VirtualTourMKPointAnnotation(pin: travelLocation))
            }
        }
    }
}

extension MapViewController : MKMapViewDelegate {
    
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if (mapChangedFromUserInteraction) {
            print("New Region \(map.region)")
            UserDefaults.standard.saveRegion(map: map)
        }
    }
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        mapChangedFromUserInteraction = mapViewRegionDidChangeFromUserInteraction()
    }
    private func mapViewRegionDidChangeFromUserInteraction() -> Bool {
        let view = self.map.subviews[0]
        //  Look through gesture recognizers to determine whether this region change is from user interaction
        if let gestureRecognizers = view.gestureRecognizers {
            for recognizer in gestureRecognizers {
                if( recognizer.state == UIGestureRecognizer.State.began || recognizer.state == UIGestureRecognizer.State.ended ) {
                    return true
                }
            }
        }
        return false
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView

        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = .red
            pinView!.rightCalloutAccessoryView = UIButton(type: .custom)
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        print("Pin tapped")
        self.performSegue(withIdentifier: "viewPhotos", sender: view.annotation)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let annotation = sender as! VirtualTourMKPointAnnotation
        let photoViewController = segue.destination as! PhotoViewController
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "OK", style: .plain, target: nil, action: nil)
        photoViewController.annotation = annotation
        photoViewController.dataController = dataController
    }
}

class VirtualTourMKPointAnnotation: MKPointAnnotation {
    let pin:Pin
    init(pin: Pin) {
        self.pin = pin
        super.init()
        self.coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(pin.latitude), longitude: CLLocationDegrees(pin.longitude))
    }
}


extension MapViewController:NSFetchedResultsControllerDelegate {

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        guard let pin = anObject as? Pin else {
            preconditionFailure("All changes observed in the map view controller should be for Pin instances")
        }
        print("adding to map")
        let annotation = VirtualTourMKPointAnnotation(pin: pin)

        switch type {
        case .insert:
            map.addAnnotation(annotation)
            break
        case .delete:
            map.removeAnnotation(annotation)
            break
        case .update:
            map.removeAnnotation(annotation)
            map.addAnnotation(annotation)
        default:
            break
        }
    }
}

extension UserDefaults {
    func saveRegion(map: MKMapView) {
        UserDefaults.standard.set(map.region.center.latitude, forKey: UserDefaultsKeys.centerCoordinateLatitude.rawValue)
        UserDefaults.standard.set(map.region.center.longitude, forKey: UserDefaultsKeys.centerCoordinateLongitude.rawValue)
        UserDefaults.standard.set(map.region.span.latitudeDelta, forKey: UserDefaultsKeys.regionLatitudeDelta.rawValue)
        UserDefaults.standard.set(map.region.span.longitudeDelta, forKey: UserDefaultsKeys.regionLongitudeDelta.rawValue)
        UserDefaults.standard.set(map.camera.altitude, forKey: UserDefaultsKeys.altitude.rawValue)
    }
    
    func getMapRegion() -> MKCoordinateRegion? {
        let centerCoordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(UserDefaults.standard.double(forKey: UserDefaultsKeys.centerCoordinateLatitude.rawValue)),
        longitude: CLLocationDegrees(UserDefaults.standard.double(forKey: UserDefaultsKeys.centerCoordinateLongitude.rawValue)))
        
        let span = MKCoordinateSpan(latitudeDelta: CLLocationDegrees(UserDefaults.standard.double(forKey: UserDefaultsKeys.regionLongitudeDelta.rawValue)),
                                    longitudeDelta: CLLocationDegrees(UserDefaults.standard.double(forKey: UserDefaultsKeys.regionLatitudeDelta.rawValue)))
        return MKCoordinateRegion(center: centerCoordinate, span: span)
    }
}
