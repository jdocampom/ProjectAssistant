//
//  DataController.swift
//  My Portfolio
//
//  Created by Juan Diego Ocampo on 18/03/22.
//

import CoreData
import SwiftUI

/// An environment singleton responsible for managing our CoreData stack, including handling saving,
/// counting fetch requests, tracking awards and dealing with sample data.
final class DataController: ObservableObject {
    
    /// The lone CloudKit Container used to store our data.
    let container: NSPersistentCloudKitContainer
    
    /// Initialises a DataController either in memory for temporary use such as testing or preview or on
    /// permanent for regular app usage.
    ///
    /// Defaults to permanent storage.
    /// - Parameter inMemory: Whether to store this data in temporary memory or not.
    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "Main", managedObjectModel: Self.model)
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("❌ FATAL ERROR LOADING DATA MODEL - ERROR: \(error.localizedDescription) ❌")
            }
            #if DEBUG
            if CommandLine.arguments.contains("enable-testing") {
                self.clearAll()
                UIView.setAnimationsEnabled(false)
            }
            #endif
        }
    }
    
    static var preview: DataController = {
        let dataController = DataController(inMemory: true)
        let viewContext = dataController.container.viewContext
        do {
            try dataController.createSampleData()
        } catch {
            fatalError("❌ FATAL ERROR CREATING PREVIEW DATA MODEL - ERROR: \(error.localizedDescription) ❌")
        }
        return dataController
    }()
    
    static let model: NSManagedObjectModel = {
        guard let url = Bundle.main.url(forResource: "Main", withExtension: "momd") else {
            fatalError("❌ FAILED TO LOCATE MODEL FILE ❌")
        }
        guard let managedObjectModel = NSManagedObjectModel(contentsOf: url) else {
            fatalError("❌ FAILED TO LOAD MODEL FILE ❌")
        }
        return managedObjectModel
    }()
    
    /// Creates example projects with items to make manual testing easier.
    /// - Throws: An NSError sent from calling `save()` on the `NSManagedObjectContext`
    func createSampleData () throws {
        let viewContext = container.viewContext
        for projectCounter in 1...5 {
            let project = Project(context: viewContext)
            let timeInterval = Double(360000 * Int.random(in: 1...5))
            project.title = "Project \(projectCounter)"
            project.creationDate = Date()
            project.dueDate = Date() + timeInterval
            project.completed = Bool.random()
            for itemCounter in 1...10 {
                let item = Item(context: viewContext)
                item.title = "Item \(itemCounter)"
                item.creationDate = Date()
                item.completed = Bool.random()
                item.priority = Int16.random(in: 1...3)
                item.project = project
            }
        }
        try viewContext.save()
    }
    
    /// Saves our CoreData context if there are changes. This silently ignores any errors caused by saving
    /// but this should be fine because our attributes are optional.
    func save() {
        if container.viewContext.hasChanges {
            try? container.viewContext.save()
        }
    }
    
    func delete(_ object: NSManagedObject) {
        container.viewContext.delete(object)
    }
    
    func clearAll() {
        let fetchRequest1: NSFetchRequest<NSFetchRequestResult> = Item.fetchRequest()
        let batchDeleteRequest1 = NSBatchDeleteRequest(fetchRequest: fetchRequest1)
        _ = try? container.viewContext.execute(batchDeleteRequest1)
        let fetchRequest2: NSFetchRequest<NSFetchRequestResult> = Project.fetchRequest()
        let batchDeleteRequest2 = NSBatchDeleteRequest(fetchRequest: fetchRequest2)
        _ = try? container.viewContext.execute(batchDeleteRequest2)
    }
    
    func count<T>(for fetchRequest: NSFetchRequest<T>) -> Int {
        (try? container.viewContext.count(for: fetchRequest)) ?? 0
    }
    
    func hasEarnedAward(_ award: Award) -> Bool {
        switch award.criterion {
        case "items":
            // Returns true if they added a certain amount of items.
            let fetchRequest: NSFetchRequest<Item> = NSFetchRequest(entityName: "Item")
            let awardCount = count(for: fetchRequest)
            return awardCount >= award.value
        case "complete":
            // Returns true if they completed a certain amount of items.
            let fetchRequest: NSFetchRequest<Item> = NSFetchRequest(entityName: "Item")
            fetchRequest.predicate = NSPredicate(format: "completed = true")
            let awardCount = count(for: fetchRequest)
            return awardCount >= award.value
        default:
            // Unknown award criterion. The following line with the fatalError shouldn't go into production.
//            fatalError("Unknown award criterion: \(award.criterion)")
            return false
        }
    }
    
}
