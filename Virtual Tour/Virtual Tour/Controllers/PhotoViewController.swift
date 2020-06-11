//
//  PhotoViewController.swift
//  Virtual Tour
//
//  Created by Rudy James Jr on 6/9/20.
//  Copyright © 2020 James Consutling LLC. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import MapKit

class PhotoViewController: UIViewController{
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    @IBOutlet weak var progressView: UIProgressView!
    var dataController:DataController!
    
    var annotation:VirtualTourMKPointAnnotation!
    var pin:Pin!
    
    var listDataSource: ListDataSource<Photo, PhotoCollectionViewCell>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        mapView.isUserInteractionEnabled = false
        
        let space:CGFloat = 3.0
        let dimension  = (view.frame.size.width - (2 * space)) / 3.0
        
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
        
        photoCollectionView.delegate = self
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        photoCollectionView.reloadData()
    }
    
    fileprivate func updatePin(_ response: FlickrGetPhotosResponse) {
        self.pin.totalPages = Int32(response.photos.pages)
        self.pin.currentPage = Int32(response.photos.page)
        self.pin.photos = nil
        
        self.dataController.viewContext.perform {
//            let backgroundPin = self.dataController.backgroundContext.object(with: self.pin.objectID) as! Pin
//            backgroundPin.totalPages = Int32(response.photos.pages)
//            backgroundPin.currentPage = Int32(response.photos.page)
//            backgroundPin.photos = nil
            self.dataController.backgroundSave()
        }
    }
    
    fileprivate func createNewPhoto() -> Photo {
        let newPhoto = Photo(context: self.dataController.viewContext)
        newPhoto.creationDate = Date()
        newPhoto.image = #imageLiteral(resourceName: "VirtualTourist_152").pngData()
        newPhoto.pin = self.pin
        
        pin.addToPhotos(newPhoto)
        
        return newPhoto
    }
    
    fileprivate func initializePhotos(_ response: FlickrGetPhotosResponse) {
        for _ in response.photos.photos {
            
            _ = self.createNewPhoto()
            
            
        }
        
        self.dataController.viewContext.perform {
            self.dataController.save()
        }
    }
    
    fileprivate func downloadPhotos() {
        var page = 1
        if let photos = pin.photos {
            if photos.count > 0 {
                page = Int(pin.currentPage + 1)
                
                if page > pin.totalPages {
                    page = 1
                }
            }
        }
        
        
        newCollectionButton.isEnabled = false
        photoCollectionView.allowsSelection = false
        
        FlickrClient.getPhotos(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude, page: page) { (response, error) in
            guard let response = response else {
                print(error!)
                return
            }
            var downloaded = 0
            
            self.updatePin(response)
            
            self.initializePhotos(response)
            var failedDownloads:[Int] = []
            self.progressView.observedProgress = Progress(totalUnitCount: Int64(response.photos.photos.count))
            for i in 0..<response.photos.photos.count {
                let photo = response.photos.photos[i]
                
                photo.downloadPhoto { (data) in
                    downloaded += 1
                    self.progressView.observedProgress?.completedUnitCount = Int64(downloaded)
                    print("\(downloaded) count")
                    if downloaded == response.photos.photos.count {
                        DispatchQueue.main.async {
                            
                            if !failedDownloads.isEmpty {
                                failedDownloads = failedDownloads.sorted(by: >)
                                for index in failedDownloads {
                                    self.dataController.viewContext.perform {
                                        self.listDataSource.deleteEntity(indexPath: IndexPath(item: index, section: 0))
                                    }
                                }
                            }
                            self.newCollectionButton.isEnabled = true
                            self.photoCollectionView.allowsSelection = true
                        }
                    }
                    
                    if let data = data {
                        
                        self.dataController.viewContext.perform {
                            let fetchedPhoto = self.listDataSource.fetchedResultsController.object(at: IndexPath(item: i, section: 0))
                            fetchedPhoto.image = data
                            self.dataController.save()
                        }
                    } else {
                        print("failed \(i)")
                        failedDownloads.append(i)
                    }
                }
            }
            
            
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        pin = annotation.pin
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotation(annotation)
        let region = MKCoordinateRegion(center: annotation.coordinate, latitudinalMeters: CLLocationDistance(20000) , longitudinalMeters: CLLocationDistance(20000))
        mapView.setRegion(region, animated: false)
        
        
        setupFetchResultsController()
        
        if listDataSource.fetchedResultsController.fetchedObjects == nil || listDataSource.fetchedResultsController.fetchedObjects!.count == 0 {
            downloadPhotos()
        }
    }
    
    fileprivate func setupFetchResultsController() {
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "pin == %@", pin)
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        listDataSource = ListDataSource(collectionView: photoCollectionView, managedObjectContext: dataController.viewContext, fetchRequest: fetchRequest, sectionNameKeyPath: nil,
                                        cacheName: "photos", cellReuseIdentifier: PhotoCollectionViewCell.defaultReuseIdentifier, configure: configureCell(cell:entity:))
        
        photoCollectionView.dataSource = listDataSource
    }
    
    func configureCell(cell: UICollectionViewCell, entity: NSManagedObject) {
        if let cell = cell as? PhotoCollectionViewCell,
            let photo = entity as? Photo {
            if let image = photo.image {
                cell.imageView.image = UIImage(data: image)
            }
        }
    }
    
    @IBAction func getNewPhotoCollection(_ sender: Any) {
        downloadPhotos()
    }
}

extension PhotoViewController : MKMapViewDelegate {
    
    
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
}

extension PhotoViewController : UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath){
        print("tapped")
        listDataSource.deleteEntity(indexPath: indexPath)
    }
}

