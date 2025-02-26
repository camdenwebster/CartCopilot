//
//  ThemeProtocol.swift
//  CartCopilot
//
//  Created by Camden Webster on 2/25/25.
//

import SwiftUI

protocol Theme {
    var primaryBackground: Color { get }
    var primaryText: Color { get }
    var secondaryAccent: Color { get }
    var secondaryBackground: Color { get }
    var secondaryText: Color { get }
    var accent: Color { get }
    var accentDanger: Color { get }
}

extension Theme {
    var primaryBackground: Color { .primaryBackground }
    var primaryText: Color { .primaryText }
    var secondaryAccent: Color { .secondaryAccent }
    var secondaryBackground: Color { .secondaryBackground }
    var secondaryText: Color { .secondaryText }
    var accent: Color { .accent }
    var accentDanger: Color { .accentDanger }
}

protocol ColorConvertible {
    init(hex: String)
    init(light: String, dark: String)
}
