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
    @Environment(\.modelContext) private var modelContext

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onAppear {
                    Task {
                        do {
                            try DataBootstrapper.bootstrapDataIfNeeded(modelContext)
                        } catch {
                            print("Failed to bootstrap data: \(error)")
                        }
                    }
                }
        }
        .modelContainer(for: [
            Category.self,
            Item.self,
            ShoppingItem.self,
            ShoppingTrip.self,
            Store.self
        ])
    }
}
