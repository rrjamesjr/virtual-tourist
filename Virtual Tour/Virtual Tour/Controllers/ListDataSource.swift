//
//  ListDataSource.swift
//  Virtual Tour
//
//  Created by Rudy James Jr on 6/9/20.
//  Copyright © 2020 James Consutling LLC. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class ListDataSource<EntityType: NSManagedObject, CellType: UICollectionViewCell>: NSObject, NSFetchedResultsControllerDelegate, UICollectionViewDataSource {
    
    let fetchedResultsController:NSFetchedResultsController<EntityType>
    let collectionView: UICollectionView!
    let configure: (CellType, EntityType) -> Void
    let managedObjectContext: NSManagedObjectContext
    let cellReuseIdentifier: String
    
    init(collectionView: UICollectionView, managedObjectContext: NSManagedObjectContext, fetchRequest: NSFetchRequest<EntityType>, sectionNameKeyPath: String?, cacheName: String?, cellReuseIdentifier: String, configure: @escaping (CellType, EntityType) -> Void) {
        self.collectionView = collectionView
        self.configure = configure
        self.managedObjectContext = managedObjectContext
        self.cellReuseIdentifier = cellReuseIdentifier
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: sectionNameKeyPath, cacheName: cacheName)
        super.init()
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch  {
            fatalError("The fetch could not be performed \(error.localizedDescription)")
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let entity = fetchedResultsController.object(at: indexPath)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentifier, for: indexPath) as! CellType
        configure(cell, entity)
        
        return cell
    }
    
    func deleteEntity(indexPath: IndexPath) {
        let entityToDelete = fetchedResultsController.object(at: indexPath)
        managedObjectContext.delete(entityToDelete)
        
        do {
            try managedObjectContext.save()
        }
        catch {
            print("deleteEntity \(error)")
        }
    }
    
    // I just implemented that with Swift. So I would like to share my implementation.
    // First initialise an array of BlockOperations:
    var blockOperations: [BlockOperation] = []

        
    // In the did change object method:
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
            
        if type == NSFetchedResultsChangeType.insert {
            print("Insert Object: \(String(describing: newIndexPath))")
                
                blockOperations.append(
                    BlockOperation(block: { [weak self] in
                        if let this = self {
                            this.collectionView!.insertItems(at: [newIndexPath!])
                        }
                    })
                )
            }
        else if type == NSFetchedResultsChangeType.update {
            print("Update Object: \(String(describing: indexPath))")
                blockOperations.append(
                    BlockOperation(block: { [weak self] in
                        if let this = self {
                            this.collectionView!.reloadItems(at: [indexPath!])
                        }
                    })
                )
            }
        else if type == NSFetchedResultsChangeType.move {
            print("Move Object: \(String(describing: indexPath))")
                
                blockOperations.append(
                    BlockOperation(block: { [weak self] in
                        if let this = self {
                            this.collectionView!.moveItem(at: indexPath!, to: newIndexPath!)
                        }
                    })
                )
            }
        else if type == NSFetchedResultsChangeType.delete {
            print("Delete Object: \(String(describing: indexPath))")
                
                blockOperations.append(
                    BlockOperation(block: { [weak self] in
                        if let this = self {
                            this.collectionView!.deleteItems(at: [indexPath!])
                        }
                    })
                )
            }
        }

    // In the did change section method:
         func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
            let indexSet = IndexSet(integer: sectionIndex)
            if type == NSFetchedResultsChangeType.insert {
                print("Insert Section: \(sectionIndex)")
                
                blockOperations.append(
                    BlockOperation(block: { [weak self] in
                        if let this = self {
                            this.collectionView!.insertSections(indexSet)
                        }
                    })
                )
            }
            else if type == NSFetchedResultsChangeType.update {
                print("Update Section: \(sectionIndex)")
                blockOperations.append(
                    BlockOperation(block: { [weak self] in
                        if let this = self {
                            this.collectionView!.reloadSections(indexSet)
                        }
                    })
                )
            }
            else if type == NSFetchedResultsChangeType.delete {
                print("Delete Section: \(sectionIndex)")
                
                blockOperations.append(
                    BlockOperation(block: { [weak self] in
                        if let this = self {
                            this.collectionView!.deleteSections(indexSet)
                        }
                    })
                )
            }
        }

    // And finally, in the did controller did change content method:
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
            collectionView!.performBatchUpdates({ () -> Void in
                for operation: BlockOperation in self.blockOperations {
                    operation.start()
                }
            }, completion: { (finished) -> Void in
                self.blockOperations.removeAll(keepingCapacity: false)
            })
        }

    // I personally added some code in the deinit method as well, in order to cancel the operations when the ViewController is about to get deallocated:
        deinit {
            // Cancel all block operations when VC deallocates
            for operation: BlockOperation in blockOperations {
                operation.cancel()
            }
            
            blockOperations.removeAll(keepingCapacity: false)
        }
}
