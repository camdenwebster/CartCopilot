//
//  DataBootstrapper.swift
//  CartCopilot
//
//  Created by Camden Webster on 2/22/25.
//

import SwiftData
import SwiftUI

class DataBootstrapper {
    static func bootstrapDataIfNeeded(_ modelContext: ModelContext) throws {
        // Check if we've already bootstrapped using fetch descriptors
        let storeDescriptor = FetchDescriptor<Store>()
        let categoryDescriptor = FetchDescriptor<Category>()
        
        let existingStores = try modelContext.fetch(storeDescriptor)
        let existingCategories = try modelContext.fetch(categoryDescriptor)
        
        // Only bootstrap if we have no data
        if existingStores.isEmpty && existingCategories.isEmpty {
            // Default stores remain the same
            let stores = [
                Store(name: "Aldi", address: "", isDefault: true),
                Store(name: "Amazon", address: "", isDefault: true),
                Store(name: "Costco", address: "", isDefault: true),
                Store(name: "Instacart", address: "", isDefault: true),
                Store(name: "Meijer", address: "", isDefault: true),
                Store(name: "Target", address: "", isDefault: true),
                Store(name: "Trader Joe's", address: "", isDefault: true),
                Store(name: "Walmart", address: "", isDefault: true),
                Store(name: "Whole Foods", address: "", isDefault: true),
                Store(name: "Other", address: "", isDefault: true)
            ]
            
            // Flattened categories with isDefault set to true for all
            let categories = [
                // Main categories
                Category(name: "Groceries", taxRate: 0.0175, isDefault: true),
                Category(name: "Prepared Food", taxRate: 0.0825, isDefault: true),
                Category(name: "Household", taxRate: 0.0825, isDefault: true),
                Category(name: "Clothing", taxRate: 0.0825, isDefault: true),
                Category(name: "Electronics", taxRate: 0.0825, isDefault: true),
                
                // Grocery subcategories
                Category(name: "Bakery", taxRate: 0.0175, isDefault: true),
                Category(name: "Baking Items", taxRate: 0.0175, isDefault: true),
                Category(name: "Beverages", taxRate: 0.0175, isDefault: true),
                Category(name: "Breads and Cereals", taxRate: 0.0175, isDefault: true),
                Category(name: "Canned Foods & Soups", taxRate: 0.0175, isDefault: true),
                Category(name: "Coffee and Tea", taxRate: 0.0175, isDefault: true),
                Category(name: "Dairy, & and Cheese", taxRate: 0.0175, isDefault: true),
                Category(name: "Deli", taxRate: 0.0175, isDefault: true),
                Category(name: "Frozen Foods", taxRate: 0.0175, isDefault: true),
                Category(name: "Meat", taxRate: 0.0175, isDefault: true),
                Category(name: "Pantry", taxRate: 0.0175, isDefault: true),
                Category(name: "Pasta, Rice & Beans", taxRate: 0.0175, isDefault: true),
                Category(name: "Pet Care", taxRate: 0.0175, isDefault: true),
                Category(name: "Produce", taxRate: 0.0175, isDefault: true),
                Category(name: "Sauces & Condiments", taxRate: 0.0175, isDefault: true),
                Category(name: "Seafood", taxRate: 0.0175, isDefault: true),
                Category(name: "Snacks & Candy", taxRate: 0.0175, isDefault: true),
                Category(name: "Spices & Seasonings", taxRate: 0.0175, isDefault: true),
                Category(name: "Wine, Beer & Spirits", taxRate: 0.0825, isDefault: true),
                
                // Home subcategories
                Category(name: "Baby Care", taxRate: 0.0825, isDefault: true),
                Category(name: "Childcare", taxRate: 0.0825, isDefault: true),
                Category(name: "Cleaning Supplies", taxRate: 0.0825, isDefault: true),
                Category(name: "Laundry", taxRate: 0.0825, isDefault: true),
                Category(name: "Paper Products", taxRate: 0.0825, isDefault: true),
                Category(name: "Personal Care", taxRate: 0.0825, isDefault: true),
                Category(name: "Other", taxRate: 0.0825, isDefault: true)
            ]
            
            // Insert all default data
            stores.forEach { modelContext.insert($0) }
            categories.forEach { modelContext.insert($0) }
            
            // Save changes
            try modelContext.save()
        }
    }
}
