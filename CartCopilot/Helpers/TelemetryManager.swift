//
//  TelemetryManager.swift
//  CartCopilot
//
//  Created by Camden Webster on 2/23/25.
//

import Foundation
import TelemetryDeck

/// Centralized manager for tracking app analytics via TelemetryDeck
class TelemetryManager {
    static let shared = TelemetryManager()
    
    private init() {}
    
    // MARK: - Items
    
    func trackItemCreated(name: String, price: Double, category: String?) {
        TelemetryManager.signal("item-created", with: [
            "price_range": getPriceRange(price),
            "has_category": (category != nil && !category!.isEmpty) ? "yes" : "no"
        ])
    }
    
    func trackItemEdited(name: String) {
        TelemetryManager.signal("item-edited")
    }
    
    func trackItemDeleted() {
        TelemetryManager.signal("item-deleted")
    }
    
    // MARK: - Shopping Items
    
    func trackShoppingItemAdded(name: String, price: Double, fromExisting: Bool) {
        TelemetryManager.signal("shopping-item-added", with: [
            "price_range": getPriceRange(price),
            "source": fromExisting ? "existing" : "new"
        ])
    }
    
    func trackShoppingItemEdited(name: String) {
        TelemetryManager.signal("shopping-item-edited")
    }
    
    func trackShoppingItemDeleted() {
        TelemetryManager.signal("shopping-item-deleted")
    }
    
    // MARK: - Shopping Trips
    
    func trackShoppingTripCreated(store: String?, itemCount: Int) {
        TelemetryManager.signal("shopping-trip-created", with: [
            "has_store": (store != nil && !store!.isEmpty) ? "yes" : "no",
            "item_count": String(itemCount)
        ])
    }
    
    func trackShoppingTripCompleted(store: String?, itemCount: Int, totalAmount: Double) {
        TelemetryManager.signal("shopping-trip-completed", with: [
            "has_store": (store != nil && !store!.isEmpty) ? "yes" : "no",
            "item_count": String(itemCount),
            "total_range": getPriceRange(totalAmount)
        ])
    }
    
    // MARK: - Settings
    
    func trackCategoryCreated(name: String) {
        TelemetryManager.signal("category-created")
    }
    
    func trackCategoryEdited(name: String) {
        TelemetryManager.signal("category-edited")
    }
    
    func trackCategoryDeleted() {
        TelemetryManager.signal("category-deleted")
    }
    
    func trackStoreCreated(name: String) {
        TelemetryManager.signal("store-created")
    }
    
    func trackStoreEdited(name: String) {
        TelemetryManager.signal("store-edited")
    }
    
    func trackStoreDeleted() {
        TelemetryManager.signal("store-deleted")
    }
    
    // MARK: - Navigation
    
    func trackTabSelected(tab: String) {
        TelemetryManager.signal("tab-selected", with: [
            "tab": tab
        ])
    }
    
    // MARK: - Helper
    
    private static func signal(_ name: String, with additionalInfo: [String: String] = [:]) {
        TelemetryDeck.signal(name, parameters: additionalInfo)
    }
    
    /// Converts a price to a categorical range for analytics
    /// - Parameter price: The price value
    /// - Returns: A string representing the price range category
    private func getPriceRange(_ price: Double) -> String {
        switch price {
        case 0..<1:
            return "under_1"
        case 1..<5:
            return "1_to_5"
        case 5..<10:
            return "5_to_10"
        case 10..<20:
            return "10_to_20"
        case 20..<50:
            return "20_to_50"
        case 50..<100:
            return "50_to_100"
        default:
            return "over_100"
        }
    }
}
