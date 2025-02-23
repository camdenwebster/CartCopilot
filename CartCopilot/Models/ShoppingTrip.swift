//
//  ShoppingTrip.swift
//  CartCopilot
//
//  Created by Camden Webster on 2/22/25.
//

import Foundation
import SwiftData

@Model
final class ShoppingTrip {
    var store: Store
    var date: Date
    @Relationship(deleteRule: .cascade) var items: [ShoppingItem]

    init (store: Store, date: Date = Date(), items: [ShoppingItem] = []) {
        self.store = store
        self.date = date
        self.items = items
    }
}
