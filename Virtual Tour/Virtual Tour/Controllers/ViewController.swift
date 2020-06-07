//
//  ViewController.swift
//  Virtual Tour
//
//  Created by Rudy James Jr on 6/7/20.
//  Copyright © 2020 James Consulting LLC. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    @IBOutlet weak var map: MKMapView!
    
    let locationManager =  CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        map.delegate = self
        locationManager.delegate = self
        
        if #available(iOS 8.0, *) {
            locationManager.requestAlwaysAuthorization()
        } else {
            // Fallback on earlier versions
        }
        locationManager.startUpdatingLocation()

        // add gesture recognizer
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.mapLongPress(_:))) // colon needs to pass through info
        longPress.minimumPressDuration = 1.5 // in seconds
        longPress.numberOfTouchesRequired = 1
        //add gesture recognition
        map.addGestureRecognizer(longPress)
    }

    @objc func mapLongPress(_ recognizer: UIGestureRecognizer) {

        print("A long press has been detected.")

        let touchedAt = recognizer.location(in: self.map) // adds the location on the view it was pressed
        let touchedAtCoordinate : CLLocationCoordinate2D = map.convert(touchedAt, toCoordinateFrom: self.map) // will get coordinates
        let magnitude: Double = touchedAtCoordinate.latitude
        let newPin = MKPointAnnotation()
        newPin.coordinate = touchedAtCoordinate
        map.addAnnotation(newPin)

    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView

        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = .red
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }

    
    // This delegate method is implemented to respond to taps. It opens the system browser
    // to the URL specified in the annotationViews subtitle property.
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl){
        if control == view.rightCalloutAccessoryView {
           // openUrl(url: (view.annotation?.subtitle!)!)
        }
    }
}

