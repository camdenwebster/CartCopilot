//
//  ThemeProtocol.swift
//  CartCopilot
//
//  Created by Camden Webster on 2/25/25.
//

import SwiftUI

protocol ThemeProvider {
    var primaryBackground: Color { get }
    var primaryText: Color { get }
    var secondaryAccent: Color { get }
    var secondaryBackground: Color { get }
    var accent: Color { get }
    var accentDanger: Color { get }
}

protocol ColorConvertible {
    init(hex: String)
    init(light: String, dark: String)
}
