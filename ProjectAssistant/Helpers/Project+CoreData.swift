//
//  Project-CoreDataHelpers.swift
//  My Portfolio
//
//  Created by Juan Diego Ocampo on 18/03/22.
//

import Foundation
import SwiftUI

extension Project {
    static let colors = ["Pink", "Purple", "Red", "Orange", "Gold", "Green", "Teal", "Light Blue", "Dark Blue",
                         "Midnight", "Dark Gray", "Gray"]
    
    var projectTitle: String { title ?? NSLocalizedString("New Project", comment: "Create a New Project") }
    var projectDetail: String { detail ?? "" }
    var projectCreationDate: Date { creationDate ?? Date() }
    var projectDueDate: Date { dueDate ?? Date() }
    var projectColor: String { color ?? "Light Blue" }
    
    var projectItems: [Item] {
        return items?.allObjects as? [Item] ?? []
    }
    
    var label: LocalizedStringKey {
        let num = completionAmount * 100
        return LocalizedStringKey("\(projectTitle), \(projectItems.count) items. Completion: \(num, specifier: "%g")%.")
    }
    
    var projectItemsDefaultSorted: [Item] {
        return projectItems.sorted { first, second in
            if !first.completed {
                if second.completed {
                    return true
                }
            } else if first.completed {
                if second.completed {
                    return false
                }
            }
            if first.priority > second.priority {
                return true
            } else if first.priority < second.priority {
                return false
            }
            return first.itemCreationDate < second.itemCreationDate
        }
    }
    
    var completionAmount: Double {
        let originalItems = items?.allObjects as? [Item] ?? []
        guard originalItems.isEmpty == false else { return 0 }
        let completedItems = originalItems.filter(\.completed)
        return Double(completedItems.count) / Double(originalItems.count)
    }
    
    static var example: Project {
        let controller = DataController.preview
        let viewContext = controller.container.viewContext
        let project = Project(context: viewContext)
        project.title = "Example Item"
        project.detail = "This is an example."
        project.creationDate = Date()
        project.dueDate = Date() + 36000
        project.completed = true
        project.color = "Light Blue"
        return project
    }
    
    func projectItems(using sortOrder: Item.SortOrder) -> [Item] {
        switch sortOrder {
        case .title:
            return projectItems.sorted(by: \Item.itemTitle)
        case .creationDate:
            return projectItems.sorted(by: \Item.itemCreationDate)
        case .optimized:
            return projectItemsDefaultSorted
        }
    }
    
}