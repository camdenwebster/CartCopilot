//
//  ShoppingItem.swift
//  CartCopilot
//
//  Created by Camden Webster on 2/22/25.
//

import Foundation
import SwiftData
import SwiftUI

enum ShoppingItemError: Error {
    case invalidQuantity
}

@Model
final class ShoppingItem: PriceCalculatable {
    var item: Item
    var quantity: Int
    var store: Store
    var dateAdded: Date
    @Relationship(inverse: \ShoppingTrip.items) var trip: ShoppingTrip?
    
    var currentPrice: Decimal {
        item.currentPrice
    }
    
    var totalPrice: Decimal {
        currentPrice * Decimal(quantity)
    }
    
    var totalTax: Decimal {
        totalPrice * Decimal(item.category.taxRate)
    }
    
    var total: Decimal {
        totalPrice + totalTax
    }
    
    func updateQuantity(_ newQuantity: Int) throws {
        guard newQuantity > 0 else {
            throw ShoppingItemError.invalidQuantity
        }
        quantity = newQuantity
    }
    
    init(item: Item, quantity: Int = 1, store: Store, dateAdded: Date = Date(), trip: ShoppingTrip? = nil) throws {
        guard quantity > 0 else {
            throw ShoppingItemError.invalidQuantity
        }
        
        self.item = item
        self.quantity = quantity
        self.store = store
        self.dateAdded = dateAdded
        self.trip = trip
    }
}
