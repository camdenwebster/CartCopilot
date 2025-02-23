//
//  CurrencyFormatter.swift
//  CartCopilot
//
//  Created by Camden Webster on 2/22/25.
//

import Foundation

struct CurrencyFormatter {
    static func format(_ value: Decimal, locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        
        return formatter.string(from: value as NSDecimalNumber) ?? "$0.00"
    }
    
    static func format(_ value: Double, locale: Locale = .current) -> String {
        format(Decimal(value), locale: locale)
    }
}
