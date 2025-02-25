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
        print("Starting data bootstrap check...")
        
        // Check if we've already bootstrapped using fetch descriptors
        let storeDescriptor = FetchDescriptor<Store>()
        let categoryDescriptor = FetchDescriptor<Category>()
        
        let existingStores = try modelContext.fetch(storeDescriptor)
        let existingCategories = try modelContext.fetch(categoryDescriptor)
        
        print("Found \(existingStores.count) existing stores")
        print("Found \(existingCategories.count) existing categories")
        
        // Only bootstrap if we have no data
        if existingStores.isEmpty && existingCategories.isEmpty {
            print("No existing data found. Starting bootstrap process...")
            
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
            
            // Update categories with emojis
            let categories = [
                // Main categories
                Category(name: "Groceries", taxRate: 0.0175, isDefault: true, emoji: "🛒"),
                Category(name: "Prepared Food", taxRate: 0.0825, isDefault: true, emoji: "🍱"),
                Category(name: "Household", taxRate: 0.0825, isDefault: true, emoji: "🏠"),
                Category(name: "Clothing", taxRate: 0.0825, isDefault: true, emoji: "👕"),
                Category(name: "Electronics", taxRate: 0.0825, isDefault: true, emoji: "📱"),
                
                // Grocery subcategories
                Category(name: "Bakery", taxRate: 0.0175, isDefault: true, emoji: "🥖"),
                Category(name: "Baking Items", taxRate: 0.0175, isDefault: true, emoji: "🥄"),
                Category(name: "Beverages", taxRate: 0.0175, isDefault: true, emoji: "🥤"),
                Category(name: "Breads & Cereals", taxRate: 0.0175, isDefault: true, emoji: "🥐"),
                Category(name: "Canned Foods & Soups", taxRate: 0.0175, isDefault: true, emoji: "🥫"),
                Category(name: "Coffee & Tea", taxRate: 0.0175, isDefault: true, emoji: "☕"),
                Category(name: "Dairy, Eggs & Cheese", taxRate: 0.0175, isDefault: true, emoji: "🥛"),
                Category(name: "Deli", taxRate: 0.0175, isDefault: true, emoji: "🥪"),
                Category(name: "Frozen Foods", taxRate: 0.0175, isDefault: true, emoji: "🧊"),
                Category(name: "Meat", taxRate: 0.0175, isDefault: true, emoji: "🥩"),
                Category(name: "Pantry", taxRate: 0.0175, isDefault: true, emoji: "🏺"),
                Category(name: "Pasta, Rice & Beans", taxRate: 0.0175, isDefault: true, emoji: "🍝"),
                Category(name: "Pet Care", taxRate: 0.0175, isDefault: true, emoji: "🐾"),
                Category(name: "Produce", taxRate: 0.0175, isDefault: true, emoji: "🥬"),
                Category(name: "Sauces & Condiments", taxRate: 0.0175, isDefault: true, emoji: "🥫"),
                Category(name: "Seafood", taxRate: 0.0175, isDefault: true, emoji: "🐟"),
                Category(name: "Snacks & Candy", taxRate: 0.0175, isDefault: true, emoji: "🍬"),
                Category(name: "Spices & Seasonings", taxRate: 0.0175, isDefault: true, emoji: "🌶️"),
                Category(name: "Wine, Beer & Spirits", taxRate: 0.0825, isDefault: true, emoji: "🍷"),
                
                // Home subcategories
                Category(name: "Baby Care", taxRate: 0.0825, isDefault: true, emoji: "👶"),
                Category(name: "Childcare", taxRate: 0.0825, isDefault: true, emoji: "🧸"),
                Category(name: "Cleaning Supplies", taxRate: 0.0825, isDefault: true, emoji: "🧹"),
                Category(name: "Laundry", taxRate: 0.0825, isDefault: true, emoji: "🧺"),
                Category(name: "Paper Products", taxRate: 0.0825, isDefault: true, emoji: "🧻"),
                Category(name: "Personal Care", taxRate: 0.0825, isDefault: true, emoji: "🧴"),
                Category(name: "Other", taxRate: 0.0825, isDefault: true, emoji: "❓")
            ]
            
            print("Inserting \(stores.count) stores...")
            // Insert all default data
            for store in stores {
                modelContext.insert(store)
            }
            
            print("Inserting \(categories.count) categories...")
            for category in categories {
                modelContext.insert(category)
            }
            
            // Save changes
            do {
                try modelContext.save()
                print("Successfully saved bootstrap data")
                
                // Verify the data was actually saved
                let verifyStores = try modelContext.fetch(storeDescriptor)
                let verifyCategories = try modelContext.fetch(categoryDescriptor)
                
                print("Verification: Found \(verifyStores.count) stores and \(verifyCategories.count) categories after bootstrap")
            } catch {
                print("Failed to save bootstrap data: \(error)")
                throw error
            }
        } else {
            print("Bootstrap data already exists. Skipping...")
        }
    }
}
