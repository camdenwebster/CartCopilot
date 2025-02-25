//
//  Category.swift
//  CartCopilot
//
//  Created by Camden Webster on 2/22/25.
//

import SwiftData

@Model
final class Category {
    var name: String
    var taxRate: Double
    var isDefault: Bool
    var emoji: String?

    init (name: String, taxRate: Double, isDefault: Bool = false, emoji: String? = nil) {
        self.name = name
        self.taxRate = taxRate
        self.isDefault = isDefault
        self.emoji = emoji
    }
}
