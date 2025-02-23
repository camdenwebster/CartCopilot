//
//  CartCopilotApp.swift
//  CartCopilot
//
//  Created by Camden Webster on 2/22/25.
//

import SwiftData
import SwiftUI

@main
struct CartCopilotApp: App {
    // Container must be initialized before any views
    let container: ModelContainer
    
    init() {
        do {
            // Initialize container with all model types
            // Note: Don't use array syntax for model types
            container = try ModelContainer(for: 
                                            Category.self,
                                           Item.self,
                                           ShoppingItem.self,
                                           ShoppingTrip.self,
                                           Store.self
            )
            
            // Bootstrap initial data immediately after container creation
            try DataBootstrapper.bootstrapDataIfNeeded(container.mainContext)
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(container)
    }
}
