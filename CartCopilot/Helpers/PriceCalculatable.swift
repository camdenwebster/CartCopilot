//
//  PriceCalculatable.swift
//  CartCopilot
//
//  Created by Camden Webster on 2/22/25.
//

import Foundation

protocol PriceCalculatable {
    var currentPrice: Decimal { get }
    var totalPrice: Decimal { get }
    var totalTax: Decimal { get }
    var total: Decimal { get }
}

extension PriceCalculatable {
    var total: Decimal {
        totalPrice + totalTax
    }
}
