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

    init (name: String, taxRate: Double, isDefault: Bool = false) {
        self.name = name
        self.taxRate = taxRate
        self.isDefault = isDefault
    }
}
