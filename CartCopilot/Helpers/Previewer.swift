//
//  Previewer.swift
//  CartCopilot
//
//  Created by Camden Webster on 2/22/25.
//

import Foundation
import SwiftData

@MainActor
struct Previewer {
    let container: ModelContainer
    let category: Category
    let item: Item
    let shoppingItem: ShoppingItem
    let shoppingTrip: ShoppingTrip
    let store: Store
    
    init() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let schema = Schema([ShoppingItem.self, ShoppingTrip.self, Item.self, Category.self, Store.self])
        container = try ModelContainer(for: schema, configurations: config)
        
        category = Category(name: "Produce", taxRate: 1.0)
        item = Item(name: "Apple", currentPrice: 1.00, category: category)
        store = Store(name: "Whole Foods Market", address: "123 Main St")
        
        shoppingItem = try ShoppingItem(item: item, quantity: 2, store: store)
        shoppingTrip = ShoppingTrip(store: store, items: [shoppingItem])
        
        container.mainContext.insert(category)
        container.mainContext.insert(item)
        container.mainContext.insert(store)
        container.mainContext.insert(shoppingItem)
        container.mainContext.insert(shoppingTrip)
    }
}
