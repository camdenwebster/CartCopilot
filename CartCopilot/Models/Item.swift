//
//  Item.swift
//  CartCopilot
//
//  Created by Camden Webster on 2/22/25.
//

import SwiftData
import SwiftUI

enum ItemError: Error {
    case invalidPrice
    case invalidUnit
    case invalidPhoto
}

@Model
final class Item: PriceCalculatable {
    var name: String
    var currentPrice: Decimal
    @Relationship(deleteRule: .nullify) var category: Category

    var priceHistory: [Date: Decimal]?
    var brand: String?
    var upc: String?
    var emoji: String?
    var isFavorite: Bool
    var unit: Int?
    var unitType: String?
    var preferredStore: Store?
    var dateAdded: Date
    
    @Attribute(.externalStorage) var photoData: Data?
    
    var photo: UIImage? {
        get {
            guard let photoData = photoData else { return nil }
            return UIImage(data: photoData)
        }
        set {
            photoData = newValue?.jpegData(compressionQuality: 0.8)
        }
    }
    
    func updatePhotoData(_ data: Data?) {
        photoData = data
    }
    
    var unitPrice: Decimal {
        guard let unit = unit, unit > 0 else { return 0 }
        return currentPrice / Decimal(unit)
    }
    
    var totalPrice: Decimal {
        currentPrice
    }
    
    var totalTax: Decimal {
        currentPrice * Decimal(category.taxRate)
    }
    
    func updatePrice(_ newPrice: Decimal) throws {
        guard newPrice >= 0 else {
            throw ItemError.invalidPrice
        }
        
        // Update price history
        var history = priceHistory ?? [:]
        history[Date()] = currentPrice
        priceHistory = history
        
        // Set new price
        currentPrice = newPrice
    }
    
    func updateUnit(_ newUnit: Int) throws {
        guard newUnit > 0 else {
            throw ItemError.invalidUnit
        }
        
        unit = newUnit
    }
    
    init(name: String, currentPrice: Decimal, category: Category, priceHistory: [Date : Decimal]? = nil, brand: String? = nil, upc: String? = nil, emoji: String? = nil, isFavorite: Bool = false, unit: Int? = nil, unitType: String? = nil, preferredStore: Store? = nil, photoData: Data? = nil, dateAdded: Date = Date()) {
        self.name = name
        self.currentPrice = currentPrice
        self.category = category
        self.priceHistory = priceHistory
        self.brand = brand
        self.upc = upc
        self.emoji = emoji
        self.isFavorite = isFavorite
        self.unit = unit
        self.unitType = unitType
        self.preferredStore = preferredStore
        self.photoData = photoData
        self.dateAdded = dateAdded
    }
}

