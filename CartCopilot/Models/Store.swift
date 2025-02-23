//
//  Store.swift
//  CartCopilot
//
//  Created by Camden Webster on 2/22/25.
//

import SwiftData

@Model
final class Store {
    var name: String
    var address: String
    var isDefault: Bool
    
    init(name: String, address: String, isDefault: Bool = false) {
        self.name = name
        self.address = address
        self.isDefault = isDefault
    }
}
